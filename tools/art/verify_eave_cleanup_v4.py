"""Inspect the separate Eave Runner cleanup candidate in background Blender.

Run: blender --background --factory-startup --python THIS_FILE --
     [--source FILE] [--report FILE]
This validates geometry/rig contracts; passing does not accept visual quality.
"""
from pathlib import Path
import argparse
import json
import math
import sys

import bpy
import numpy as np


ROOT = Path(__file__).resolve().parents[2]
BASELINE = ROOT / "ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend"
DEFAULT_SOURCE = ROOT / "ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v4.blend"
DEFAULT_REPORT = ROOT / "work/eave-runner-v4/source_verification.json"
EXPECTED_BONES = {"root", "pelvis", "spine", "chest", "neck", "head", "blade", "held_pin"}
for side in ("L", "R"):
    EXPECTED_BONES.update(name + "." + side for name in (
        "clavicle", "upper_arm", "forearm", "hand", "thigh", "shin", "foot", "toe"))
    EXPECTED_BONES.update("finger%d-%d.%s" % (digit, segment, side)
                          for digit in range(1, 6) for segment in range(1, 4))
    EXPECTED_BONES.update("tail_%s_%d" % (side, segment) for segment in range(1, 4))
EXPECTED_CLIPS = {"idle", "run", "wall_attach", "wall_perch", "wall_windup",
                  "wall_launch", "jump_slash", "land_recover", "throw_windup",
                  "throw_release", "hurt", "death"}
checks = 0
failures = []


def check(condition, message):
    global checks
    checks += 1
    if not condition:
        failures.append(message)
        print("EAVE_V4_SOURCE_FAIL", message, flush=True)


def coordinates(mesh):
    values = np.empty(len(mesh.vertices) * 3, dtype=np.float64)
    mesh.vertices.foreach_get("co", values)
    return values.reshape((-1, 3))


def world_coordinates(obj, evaluated=False):
    target = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()) if evaluated else obj
    points = coordinates(target.data)
    transform = np.asarray(target.matrix_world, dtype=np.float64)
    return points @ transform[:3, :3].T + transform[:3, 3]


def geometry_row(obj):
    mesh = obj.data
    points = world_coordinates(obj)
    mesh.calc_loop_triangles()
    indices = np.empty(len(mesh.loop_triangles) * 3, dtype=np.int32)
    mesh.loop_triangles.foreach_get("vertices", indices)
    indices = indices.reshape((-1, 3))
    corners = points[indices]
    edge_a = corners[:, 1] - corners[:, 0]
    edge_b = corners[:, 2] - corners[:, 0]
    edge_c = corners[:, 2] - corners[:, 1]
    double_area = np.linalg.norm(np.cross(edge_a, edge_b), axis=1)
    longest = np.maximum.reduce([np.linalg.norm(edge_a, axis=1),
                                 np.linalg.norm(edge_b, axis=1),
                                 np.linalg.norm(edge_c, axis=1)])
    # Weld exact UV-seam positions for adjacency analysis only. Source data is
    # never altered. An isolated single triangle is not an intentional cord tube.
    _, welded = np.unique(np.round(points, 6), axis=0, return_inverse=True)
    uses = np.bincount(welded[indices].ravel(), minlength=int(welded.max()) + 1)
    isolated = np.all(uses[welded[indices]] == 1, axis=1)
    degenerate = int(np.count_nonzero(double_area < 1e-12))
    huge = int(np.count_nonzero(longest > 0.8))
    needle = int(np.count_nonzero((longest > 0.08) &
                 (longest * longest / np.maximum(double_area, 1e-30) > 500)))
    row = {"name": obj.name, "vertices": len(points), "triangles": len(indices),
           "degenerate_triangles": degenerate, "edges_over_0_8m": huge,
           "long_needle_triangles": needle, "isolated_single_triangles": int(isolated.sum()),
           "maximum_edge_metres": float(longest.max()) if len(longest) else 0.0}
    check(np.isfinite(points).all(), obj.name + ": finite geometry")
    check(degenerate == 0, obj.name + ": no zero-area or collapsed triangles")
    check(huge == 0 and needle == 0, obj.name + ": no huge or needle-shaped triangles")
    check(not isolated.any(), obj.name + ": no isolated floating single triangles")
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    arguments = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    bpy.ops.wm.open_mainfile(filepath=str(BASELINE))
    baseline_fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
    durations = {action.name: (action.frame_range[1] - action.frame_range[0]) / baseline_fps
                 for action in bpy.data.actions if action.name in EXPECTED_CLIPS}
    check(len(durations) == 12, "Baseline retains all twelve expected clips")
    if not arguments.source.is_file():
        check(False, "Candidate source exists: " + str(arguments.source))
        return finish(arguments.report, {"source": str(arguments.source)})
    bpy.ops.wm.open_mainfile(filepath=str(arguments.source))
    scene = bpy.context.scene
    rigs = [obj for obj in scene.objects if obj.type == "ARMATURE"]
    check(len(rigs) == 1, "Exactly one candidate armature")
    if len(rigs) != 1:
        return finish(arguments.report, {"source": str(arguments.source)})
    rig = rigs[0]
    check(set(rig.data.bones.keys()) == EXPECTED_BONES, "Exactly sixty retained named bones")
    check(set(bpy.data.actions.keys()) == EXPECTED_CLIPS, "Exactly twelve retained named clips")
    if rig.pose.bones.get("root") is None:
        return finish(arguments.report, {"source": str(arguments.source), "bones": len(rig.data.bones)})
    check(not any(pose.constraints for pose in rig.pose.bones), "No runtime dependency on authoring constraints")
    for child, parent in [("blade", "hand.R"), ("held_pin", "hand.L")]:
        bone = rig.data.bones.get(child)
        check(bone is not None and bone.parent is not None and bone.parent.name == parent,
              child + ": retained wrist attachment hierarchy")
    meshes = [obj for obj in scene.objects if obj.type == "MESH" and not obj.get("review_only", False)]
    check(bool(meshes), "Candidate contains actor meshes")
    rows = []
    for obj in meshes:
        check(any(modifier.type == "ARMATURE" and modifier.object == rig for modifier in obj.modifiers),
              obj.name + ": actor retains skin modifier")
        check(bool(obj.data.uv_layers), obj.name + ": UVs exist")
        if not obj.data.vertices:
            check(False, obj.name + ": mesh has vertices")
            continue
        weights_valid = True
        for vertex in obj.data.vertices:
            groups = [(obj.vertex_groups[weight.group].name, weight.weight)
                      for weight in vertex.groups if weight.weight > 1e-7]
            weights_valid &= (1 <= len(groups) <= 4 and
                abs(sum(value for _, value in groups) - 1) < 0.0002 and
                all(name in EXPECTED_BONES and math.isfinite(value) and value > 0 for name, value in groups))
        check(weights_valid, obj.name + ": one to four normalized valid skin weights")
        rows.append(geometry_row(obj))
    triangles = sum(row["triangles"] for row in rows)
    check(0 < triangles <= 800000, "Triangle budget stays below conspicuous 800k limit")
    if not rows:
        return finish(arguments.report, {"source": str(arguments.source), "triangles": triangles, "components": 0})
    rig.animation_data_create()
    rig.animation_data.action = None
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    rest = np.concatenate([world_coordinates(obj, True) for obj in meshes])
    rest_min, rest_max = rest.min(axis=0), rest.max(axis=0)
    check(np.isfinite(rest).all() and 1.5 <= rest_max[2] - rest_min[2] <= 2.1,
          "Rest character remains at the established world scale")
    check(-0.1 <= rest_min[2] <= 0.15 and np.max(rest_max - rest_min) < 3.2,
          "Rest feet and extent stay in the established frame")
    rig.data.pose_position = "POSE"
    clips = []
    fps = scene.render.fps / scene.render.fps_base
    for name in sorted(EXPECTED_CLIPS):
        action = bpy.data.actions.get(name)
        if action is None:
            continue
        start, end = map(float, action.frame_range)
        seconds = (end - start) / fps
        check(abs(seconds - durations[name]) < 0.0001, name + ": retained duration")
        rig.animation_data.action = action
        maximum_span = 0.0
        roots = []
        finite_geometry = True
        finite_bones = True
        for fraction in (0.0, 0.5, 1.0):
            frame = start + (end - start) * fraction
            scene.frame_set(int(frame), subframe=frame % 1)
            matrices = [np.asarray(pose.matrix, dtype=np.float64) for pose in rig.pose.bones]
            finite_bones &= all(np.isfinite(matrix).all() for matrix in matrices)
            points = np.concatenate([world_coordinates(obj, True) for obj in meshes])
            finite_geometry &= np.isfinite(points).all()
            if np.isfinite(points).all():
                maximum_span = max(maximum_span, float(np.max(points.max(axis=0) - points.min(axis=0))))
            roots.append(np.asarray(rig.pose.bones["root"].matrix.translation, dtype=np.float64))
        drift = max(float(np.linalg.norm(position - roots[0])) for position in roots)
        check(finite_geometry and finite_bones and maximum_span < 3.5,
              name + ": sampled skin and bones remain finite and bounded")
        check(drift < 0.0001, name + ": root stays in place")
        clips.append({"name": name, "seconds": seconds, "maximum_span": maximum_span,
                      "root_drift": drift, "samples": 3})
    finish(arguments.report, {"source": str(arguments.source), "triangles": triangles,
           "vertices": sum(row["vertices"] for row in rows), "components": len(rows),
           "bones": len(rig.data.bones), "rest_bounds": [rest_min.tolist(), rest_max.tolist()],
           "meshes": rows, "clips": clips,
           "visual_acceptance": "Pending; these geometry/rig checks do not accept resemblance or rendered quality."})


def finish(path, asset):
    report = {"passed": not failures, "checks": checks, "failures": failures, "asset": asset}
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("EAVE_V4_SOURCE_CHECK " + json.dumps({"passed": not failures, "checks": checks,
          "failures": failures, "report": str(path)}), flush=True)
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
