"""Read-only inspection of fitted hand skinning and mixed boot seam geometry.

Run through Blender --background --factory-startup --python-exit-code 1 --python.
Only the JSON report under LocalOnly is written; no model or texture is exported.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Assets/Threadborne/Player/LocalDoll"
OUT = ROOT / "LocalOnly/Equipment/FeedbackReview2026_11_07"
OUT.mkdir(parents=True, exist_ok=True)
(OUT / ".gdignore").touch()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps = 30
bpy.ops.import_scene.gltf(filepath=str(SOURCE / "threadborne_doll_equipped.glb"))
master = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
master.data.pose_position = "REST"
rest = {bone.name: master.matrix_world @ bone.matrix_local for bone in master.data.bones}
actions = {name: bpy.data.actions[name] for name in ("idle_4", "run_1", "casting_2", "slash_2")}
report = {"models": {}, "hands": {}, "seams": {}, "mixed_boot_seams": {}}


def seam_points(obj, side):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    points = set()
    for edge in bm.edges:
        world = [obj.matrix_world @ vertex.co for vertex in edge.verts]
        if edge.is_boundary and all(abs(point.z - .415) < .0002 and side * point.x > 0 for point in world):
            points.update(tuple(point) for point in world)
    bm.free()
    return sorted(points)


def inspect_hands(obj, rig):
    canonical = []
    influence_counts = Counter()
    for vertex in obj.data.vertices:
        weights = sorted((obj.vertex_groups[g.group].name, round(g.weight, 7)) for g in vertex.groups if g.weight > .00001)
        influence_counts[len(weights)] += 1
        canonical.append((tuple(round(c, 7) for c in vertex.co), weights))
    finger_edges = []
    for edge in obj.data.edges:
        a, b = edge.vertices
        length = (obj.data.vertices[a].co - obj.data.vertices[b].co).length
        weights = [obj.vertex_groups[g.group].name for index in (a, b) for g in obj.data.vertices[index].groups]
        if length > .001 and any(name.startswith(("index.", "middle.", "ring.", "pinky.", "thumb.")) for name in weights):
            finger_edges.append((a, b, length))
    samples = []
    rig.data.pose_position = "POSE"
    rig.animation_data_create()
    for name, action in actions.items():
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        for fraction in (0, .35, .7, .95):
            start, end = action.frame_range
            frame = start + (end - start) * fraction
            bpy.context.scene.frame_set(int(frame), subframe=frame - int(frame))
            evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
            mesh = evaluated.to_mesh()
            errors = [abs((mesh.vertices[a].co - mesh.vertices[b].co).length / length - 1) for a, b, length in finger_edges]
            samples.append({"action": name, "fraction": fraction, "maximum_relative_edge_change": max(errors),
                            "edges_over_10_percent_change": sum(error > .1 for error in errors)})
            evaluated.to_mesh_clear()
    rig.data.pose_position = "REST"
    return {"vertices": len(obj.data.vertices), "influence_counts": dict(influence_counts),
            "geometry_and_named_weights_sha256": hashlib.sha256(json.dumps(sorted(canonical)).encode()).hexdigest(),
            "finger_edges_per_pose": len(finger_edges), "samples": samples,
            "scope": "Finger-region edges including blended joints; no painted brown/tan material segmentation inferred."}


seams = {}
for name in ("base_gloves", "blue_gloves", "base_head_chest", "blue_head_chest", "base_boots", "blue_boots"):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / "Equipment/FittedSets" / (name + ".glb")))
    imported = set(bpy.context.scene.objects) - before
    rig = next(obj for obj in imported if obj.type == "ARMATURE")
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    matrices = [(bone.name, rig.matrix_world @ bone.matrix_local) for bone in rig.data.bones if bone.name in rest]
    report["models"][name] = {
        "bones": len(rig.data.bones),
        "maximum_shared_rest_translation_error": max((matrix.translation - rest[n].translation).length for n, matrix in matrices),
        "maximum_shared_rest_rotation_error": max(matrix.to_quaternion().rotation_difference(rest[n].to_quaternion()).angle for n, matrix in matrices),
        "negative_bone_rest_determinants": [n for n, matrix in matrices if matrix.determinant() < 0]}
    meshes = [obj for obj in imported if obj.type == "MESH" and obj.find_armature() == rig]
    if name.endswith("gloves"):
        hands = next(obj for obj in meshes if obj.name.startswith("Shared_Wooden_Hands"))
        report["hands"][name] = inspect_hands(hands, rig)
    else:
        mesh = next(obj for obj in meshes if not obj.name.startswith("Shared_"))
        seams[name] = {}
        report["seams"][name] = {}
        for side in (-1, 1):
            points = seam_points(mesh, side)
            seams[name][side] = points
            report["seams"][name][side] = {"count": len(points),
                "minimum": [min(p[axis] for p in points) for axis in range(3)],
                "maximum": [max(p[axis] for p in points) for axis in range(3)]} if points else {"count": 0}
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)

for trousers in ("base_head_chest", "blue_head_chest"):
    for boots in ("base_boots", "blue_boots"):
        label = trousers + "+" + boots
        report["mixed_boot_seams"][label] = {}
        for side in (-1, 1):
            a, b = seams[trousers][side], seams[boots][side]
            if a and b:
                # Symmetric maximum nearest-point distance on the actual cut rings.
                distances = [min(sum((x-y)**2 for x,y in zip(p,q))**.5 for q in target)
                             for source, target in ((a,b),(b,a)) for p in source]
                report["mixed_boot_seams"][label][side] = {"maximum_ring_mismatch_m": max(distances)}
            else:
                report["mixed_boot_seams"][label][side] = {"missing_open_ring": True}
(OUT / "fit_diagnostics.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("EQUIPMENT_FEEDBACK_INSPECTION", json.dumps({"models": len(report["models"]),
      "hands": {name: {"vertices": data["vertices"], "influence_counts": data["influence_counts"],
          "maximum_relative_edge_change": max(sample["maximum_relative_edge_change"] for sample in data["samples"])}
          for name, data in report["hands"].items()}, "mixed_boot_seams": report["mixed_boot_seams"]}), flush=True)
