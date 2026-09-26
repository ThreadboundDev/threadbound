"""Build the complete Threadborne review library from untouched Mixamo FBXs.

Run with Blender in background mode. The script opens the corrected three-clip
equipped test, retargets every source clip onto Threadborne_Rig, creates a
sequential NLA review reel, writes an inventory, and saves a new master file.
"""

import bpy
import csv
import json
import re
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector


ROOT = Path(__file__).resolve().parents[2]
BLENDER_ROOT = ROOT / "ArtSource/Player/Blender/imported_character"
SOURCE_DIR = BLENDER_ROOT / "mixamo_library/source"
WORKING_FILE = BLENDER_ROOT / "mixamo_test/Threadborne_Equipped_Animation_Test.blend"
OUTPUT_DIR = BLENDER_ROOT / "mixamo_library"
OUTPUT_FILE = OUTPUT_DIR / "Threadborne_Animation_Library.blend"
JSON_INVENTORY = OUTPUT_DIR / "animation_inventory.json"
CSV_INVENTORY = OUTPUT_DIR / "animation_inventory.csv"


def canonical_name(filename: str) -> str:
    stem = Path(filename).stem.lower()
    variant_match = re.search(r"\s*\((\d+)\)$", stem)
    variant = int(variant_match.group(1)) if variant_match else 1
    if variant_match:
        stem = stem[: variant_match.start()]
    stem = re.sub(r"^sword and shield\s+", "", stem).strip()
    stem = re.sub(r"\s+", "_", stem)
    if stem == "180_turn":
        return f"turn_180_{variant}"
    # Explicitly numbered filenames such as draw sword 1 already carry a
    # meaningful variant number and should not receive a second suffix.
    explicit_match = re.search(r"_(\d+)$", stem)
    if explicit_match:
        return stem
    return f"{stem}_{variant}"


MAPPING = {
    "pelvis": "Hips",
    "spine": "Spine1",
    "chest": "Spine2",
    "neck": "Neck",
    "head": "Head",
}
for side, prefix in (("L", "Left"), ("R", "Right")):
    for target, source in (
        ("clavicle", "Shoulder"),
        ("upper_arm", "Arm"),
        ("forearm", "ForeArm"),
        ("hand", "Hand"),
        ("thigh", "UpLeg"),
        ("shin", "Leg"),
        ("foot", "Foot"),
        ("toe", "ToeBase"),
    ):
        MAPPING[f"{target}.{side}"] = prefix + source
    for finger in ("thumb", "index", "middle", "ring", "pinky"):
        source_finger = finger.title()
        for index in (1, 2, 3):
            MAPPING[f"{finger}.{index:02d}.{side}"] = f"{prefix}Hand{source_finger}{index}"


def find_source_armature(imported_objects):
    for obj in imported_objects:
        if obj.type != "ARMATURE":
            continue
        if "mixamorig:Hips" in obj.data.bones:
            return obj
    raise RuntimeError("Imported FBX did not contain the expected Mixamo armature")


def retarget(source, rig, action_name):
    source_action = source.animation_data.action
    if source_action is None:
        raise RuntimeError(f"{source.name} has no animation action")
    first, last = (int(round(value)) for value in source_action.frame_range)
    count = last - first + 1

    usable_mapping = {
        target: source_name
        for target, source_name in MAPPING.items()
        if target in rig.data.bones and f"mixamorig:{source_name}" in source.data.bones
    }
    rest_source = {
        target: (
            source.matrix_world @ source.data.bones[f"mixamorig:{source_name}"].matrix_local
        ).to_quaternion()
        for target, source_name in usable_mapping.items()
    }
    rest_target = {bone.name: bone.matrix_local.to_quaternion() for bone in rig.data.bones}
    source_hip_rest = source.matrix_world @ source.data.bones["mixamorig:Hips"].head_local

    rig.animation_data_create()
    rig.animation_data.action = None
    for pose_bone in rig.pose.bones:
        pose_bone.matrix_basis = Matrix.Identity(4)
        pose_bone.rotation_mode = "QUATERNION"

    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    # Blender 4.4+ actions require an explicit slot before keyframe_insert can
    # create layered F-curves. Without this, Blender 5.2 silently leaves the
    # action empty even though it can still be placed in an NLA strip.
    slot = action.slots.new("OBJECT", rig.name)
    rig.animation_data.action = action
    rig.animation_data.action_slot = slot
    previous = {}
    vertical_values = []

    for source_frame in range(first, last + 1):
        target_frame = source_frame - first + 1
        bpy.context.scene.frame_set(source_frame)
        evaluated = source.evaluated_get(bpy.context.evaluated_depsgraph_get())
        hip_world = evaluated.matrix_world @ evaluated.pose.bones["mixamorig:Hips"].head
        hip_delta = hip_world - source_hip_rest
        vertical_values.append(hip_delta.z)

        desired = {
            target: (
                evaluated.matrix_world
                @ evaluated.pose.bones[f"mixamorig:{source_name}"].matrix
            ).to_quaternion()
            @ rest_source[target].inverted()
            @ rest_target[target]
            for target, source_name in usable_mapping.items()
        }
        global_rotation = {}
        for bone in rig.data.bones:
            pose_bone = rig.pose.bones[bone.name]
            parent_rotation = global_rotation[bone.parent.name] if bone.parent else Quaternion()
            relative_rest = (
                rest_target[bone.parent.name].inverted() @ rest_target[bone.name]
                if bone.parent
                else rest_target[bone.name]
            )
            if bone.name in desired:
                rotation = (
                    relative_rest.inverted()
                    @ parent_rotation.inverted()
                    @ desired[bone.name]
                )
                rotation.normalize()
                if bone.name in previous and previous[bone.name].dot(rotation) < 0:
                    rotation.negate()
                previous[bone.name] = rotation.copy()
                pose_bone.rotation_quaternion = rotation
                pose_bone.keyframe_insert(
                    data_path="rotation_quaternion", frame=target_frame, group=bone.name
                )
                global_rotation[bone.name] = desired[bone.name]
            else:
                pose_bone.rotation_quaternion = Quaternion()
                global_rotation[bone.name] = parent_rotation @ relative_rest

        # Gameplay clips are in-place horizontally. Retaining vertical travel
        # preserves jumps, impacts, and stance bounce.
        local_delta = rest_target["pelvis"].inverted() @ Vector((0, 0, hip_delta.z))
        rig.pose.bones["pelvis"].location = local_delta
        rig.pose.bones["pelvis"].keyframe_insert(
            data_path="location", frame=target_frame, group="pelvis"
        )

    action.use_frame_range = True
    action.frame_start = 1
    action.frame_end = count
    rig.animation_data.action = None
    return action, count, [min(vertical_values), max(vertical_values)]


def remove_import(imported_objects):
    for obj in imported_objects:
        bpy.data.objects.remove(obj, do_unlink=True)


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(WORKING_FILE))
    scene = bpy.context.scene
    rig = bpy.data.objects["Threadborne_Rig"]
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    rig.animation_data_create()
    rig.animation_data.action = None
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)

    source_files = sorted(SOURCE_DIR.glob("*.fbx"), key=lambda path: canonical_name(path.name))
    if len(source_files) < 51:
        raise RuntimeError(f"Expected at least the original 51 source FBXs, found {len(source_files)}")
    names = [canonical_name(path.name) for path in source_files]
    if len(names) != len(set(names)):
        raise RuntimeError("Canonical action names are not unique")

    actions = []
    inventory = []
    for index, source_path in enumerate(source_files, start=1):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(source_path), use_anim=True)
        imported = list(set(bpy.data.objects) - before)
        source_armature = find_source_armature(imported)
        action_name = canonical_name(source_path.name)
        action, frame_count, vertical_range = retarget(source_armature, rig, action_name)
        actions.append((action_name, action, frame_count))
        inventory.append(
            {
                "index": index,
                "action": action_name,
                "source_file": source_path.name,
                "frames": frame_count,
                "fps": 30,
                "duration_seconds": round(frame_count / 30.0, 4),
                "vertical_range": vertical_range,
            }
        )
        remove_import(imported)
        print(
            f"RETARGETED {index:02d}/{len(source_files)} {source_path.name} "
            f"-> {action_name} ({frame_count} frames)",
            flush=True,
        )

    track = rig.animation_data.nla_tracks.new()
    track.name = f"REVIEW_REEL_{len(actions)}_CLIPS"
    cursor = 1
    gap = 6
    for item, (action_name, action, frame_count) in zip(inventory, actions):
        strip = track.strips.new(action_name, cursor, action)
        strip.action_frame_start = 1
        strip.action_frame_end = frame_count
        strip.extrapolation = "NOTHING"
        strip.blend_type = "REPLACE"
        item["timeline_start"] = cursor
        item["timeline_end"] = cursor + frame_count - 1
        scene.timeline_markers.new(action_name, frame=cursor)
        cursor += frame_count + gap

    scene.frame_start = 1
    scene.frame_end = cursor - gap - 1
    scene.render.fps = 30
    scene.frame_set(1)
    scene["animation_library_note"] = (
        f"{len(actions)} numbered Mixamo clips retargeted to Threadborne_Rig. Use the NLA review reel "
        "or select individual actions by canonical name. Horizontal root travel is removed; "
        "vertical motion is retained. Camera and equipment match the live 3D test."
    )
    rig["action_count"] = len(actions)
    rig["review_reel_fps"] = 30

    JSON_INVENTORY.write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    with CSV_INVENTORY.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=(
                "index",
                "action",
                "source_file",
                "frames",
                "fps",
                "duration_seconds",
                "timeline_start",
                "timeline_end",
            ),
        )
        writer.writeheader()
        for item in inventory:
            writer.writerow({key: item[key] for key in writer.fieldnames})

    # Keep attachment relationship lines and the armature overlay out of the
    # artist-facing review view. These are viewport guides, not renderable art.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.overlay.show_relationship_lines = False
    rig.show_in_front = False
    bpy.ops.object.select_all(action="DESELECT")
    review_mesh = bpy.data.objects.get("Threadborne_Posing_Preview") or bpy.data.objects.get("Threadborne_Character")
    if review_mesh:
        review_mesh.hide_set(False)
        review_mesh.select_set(True)
        bpy.context.view_layer.objects.active = review_mesh
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"LIBRARY_SAVED {OUTPUT_FILE}", flush=True)


if __name__ == "__main__":
    main()
