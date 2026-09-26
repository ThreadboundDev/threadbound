"""Validate the generated Threadborne Blender animation library."""

import bpy
import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "ArtSource/Player/Blender/imported_character/mixamo_library"
BLEND = LIBRARY / "Threadborne_Animation_Library.blend"
CSV_INVENTORY = LIBRARY / "animation_inventory.csv"
REPORT = LIBRARY / "validation_report.json"

bpy.ops.wm.open_mainfile(filepath=str(BLEND))
scene = bpy.context.scene
rig = bpy.data.objects["Threadborne_Rig"]
with CSV_INVENTORY.open(newline="", encoding="utf-8") as handle:
    inventory = list(csv.DictReader(handle))

expected = [item["action"] for item in inventory]
missing_actions = [name for name in expected if bpy.data.actions.get(name) is None]
empty_actions = []
action_keyframes = {}
for name in expected:
    action = bpy.data.actions.get(name)
    if action is None:
        continue
    keyframes = 0
    for layer in action.layers:
        for layered_strip in layer.strips:
            if layered_strip.type != "KEYFRAME":
                continue
            for channelbag in layered_strip.channelbags:
                keyframes += sum(len(curve.keyframe_points) for curve in channelbag.fcurves)
    action_keyframes[name] = keyframes
    if keyframes == 0:
        empty_actions.append(name)
track = rig.animation_data.nla_tracks.get(f"REVIEW_REEL_{len(expected)}_CLIPS")
strip_names = [strip.name for strip in track.strips] if track else []
missing_strips = [name for name in expected if name not in strip_names]

scene.frame_set(1)
bpy.context.view_layer.update()
pose_at_1 = [value for row in rig.pose.bones["upper_arm.L"].matrix for value in row]
scene.frame_set(20)
bpy.context.view_layer.update()
pose_at_20 = [value for row in rig.pose.bones["upper_arm.L"].matrix for value in row]
pose_changes = pose_at_1 != pose_at_20
relationship_lines_hidden = all(
    not area.spaces.active.overlay.show_relationship_lines
    for screen in bpy.data.screens
    for area in screen.areas
    if area.type == "VIEW_3D"
)

report = {
    "valid": not missing_actions and not empty_actions and not missing_strips and len(expected) >= 51 and pose_changes and relationship_lines_hidden,
    "inventory_count": len(expected),
    "retargeted_action_count": sum(name in bpy.data.actions for name in expected),
    "review_strip_count": len(strip_names),
    "missing_actions": missing_actions,
    "empty_actions": empty_actions,
    "total_keyframes": sum(action_keyframes.values()),
    "missing_review_strips": missing_strips,
    "review_pose_changes_between_frames_1_and_20": pose_changes,
    "relationship_lines_hidden": relationship_lines_hidden,
    "fps": scene.render.fps,
    "timeline": [scene.frame_start, scene.frame_end],
    "camera_type": scene.camera.data.type if scene.camera else None,
    "render_resolution": [scene.render.resolution_x, scene.render.resolution_y],
    "sword_present": "Threadborne_Sword_ROOT" in bpy.data.objects,
    "shield_present": "Threadborne_Shield_ROOT" in bpy.data.objects,
    "base_grapple_present": "Threadborne_Base_Grapple_ROOT_FOLLOW" in bpy.data.objects,
    "rig_bones": len(rig.data.bones),
}
REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
print("VALIDATION", json.dumps(report), flush=True)
if not report["valid"]:
    raise RuntimeError("Animation library validation failed")
