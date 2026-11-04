"""Reopen mask delivery and independently check topology, fit, poses and GLBs."""

import bpy
import bmesh
import hashlib
import json
import math
import struct
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "LocalOnly/Equipment/Masks"
SOURCE = ROOT / "LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend"
report = {"checks": [], "fit": {}, "poses": {}, "exports": {}}


def check(label, condition):
    report["checks"].append({"name": label, "passed": bool(condition)})


def geometry_hash(obj):
    value = ([tuple(v.co) for v in obj.data.vertices], [tuple(p.vertices) for p in obj.data.polygons])
    return hashlib.sha256(repr(value).encode()).hexdigest()


def geometry(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    pts = [obj.matrix_world @ v.co for v in mesh.vertices]
    faces = [list(p.vertices) for p in mesh.polygons]
    evaluated.to_mesh_clear()
    return pts, BVHTree.FromPolygons(pts, faces)


bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
source_meshes = {o.name: geometry_hash(o) for o in bpy.context.scene.objects if o.type == "MESH"}
bpy.ops.wm.open_mainfile(filepath=str(OUT / "Threadborne_Master_Mask.blend"))
for name, expected in source_meshes.items():
    check("Preserved reference " + name, geometry_hash(bpy.data.objects[name]) == expected)

master = bpy.data.objects["MASTER_Shell"]
loomed = bpy.data.objects["Loomed_Shell"]
hermit = bpy.data.objects["Hermit_Shell"]
rig = bpy.data.objects["Threadborne_Rig"]
check("One shared shell datablock", master.data is loomed.data is hermit.data)
check("Separate finish materials", loomed.material_slots[0].material != hermit.material_slots[0].material)
check("Distinct baked finishes", (OUT/"loomed_basecolor.png").read_bytes() != (OUT/"hermit_basecolor.png").read_bytes())
bm = bmesh.new()
bm.from_mesh(master.data)
check("Watertight shell including eye-cut walls", all(e.is_manifold for e in bm.edges))
check("No zero-area shell faces", all(f.calc_area() > 1e-12 for f in bm.faces))
bm.free()
check("Finite shell coordinates", all(math.isfinite(c) for v in master.data.vertices for c in v.co))
check("Packed file textures", all(i.packed_file for i in bpy.data.images if i.source == "FILE" and i.name != "Render Result"))
for name in ("Loomed_Shell", "Hermit_Shell"):
    obj = bpy.data.objects[name]
    check(name + " binds only to head", all(len(v.groups) == 1 and obj.vertex_groups[v.groups[0].group].name == "head" and abs(v.groups[0].weight - 1) < 1e-7 for v in obj.data.vertices))
for key in ("Loomed", "Hermit"):
    embroidery=[o for o in bpy.context.scene.objects if o.name.startswith(key+"_Fitted_Repeat_")]
    check(key + " embroidery has normalized donor weights", len(embroidery)==9 and all(
        1 <= len(v.groups) <= 4 and abs(sum(g.weight for g in v.groups)-1)<1e-5
        and all(o.vertex_groups[g.group].name in rig.data.bones for g in v.groups)
        for o in embroidery for v in o.data.vertices))

for obj in bpy.context.scene.objects:
    obj.hide_set(False)
rig.data.pose_position = "POSE"
head = rig.pose.bones["head"]
head.rotation_mode = "XYZ"
pose_angles = [(0,0,0),(.25,0,0),(-.25,0,0),(0,.45,0),(0,-.45,0),(0,0,.25),(0,0,-.25)]
for angles in pose_angles:
    head.rotation_euler = angles
    bpy.context.view_layer.update()
    points, tree = geometry(loomed)
    pose_key = str(angles)
    report["poses"][pose_key] = {}
    for name in ("Threadborne_Doll", "base_HeadChest", "blue_HeadChest"):
        _, reference = geometry(bpy.data.objects[name])
        overlaps = tree.overlap(reference)
        clearance = min(reference.find_nearest(p)[3] for p in points)
        report["poses"][pose_key][name] = {"intersection_pairs": len(overlaps), "minimum_vertex_clearance_m": clearance}
        check(f"No shell intersections: {name}, {pose_key}", not overlaps)
    expected_matrix = rig.matrix_world @ head.matrix @ head.bone.matrix_local.inverted()
    error = max((actual - expected_matrix @ vertex.co).length for actual,vertex in zip(points,loomed.data.vertices))
    check("Rigid head attachment " + pose_key, error < 2e-6)
head.rotation_euler = (0,0,0)

# Round-trip each standalone export in a fresh scene. These checks inspect the
# deliverables, not the in-memory objects used by the builder.
for key in ("loomed", "hermit"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUT / (key + "_mask.glb")))
    rigs = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    widgets = {bone.custom_shape for armature in rigs for bone in armature.pose.bones if bone.custom_shape}
    # Blender's glTF importer creates an unskinned Icosphere bone widget. It is
    # editor scaffolding, not a mesh in the exported file.
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o not in widgets]
    raw=(OUT/(key+"_mask.glb")).read_bytes()
    json_length=struct.unpack_from("<I",raw,12)[0]
    gltf=json.loads(raw[20:20+json_length])
    check(key + " imported mesh count matches GLB",len(meshes)==len(gltf["meshes"]))
    check(key + " standalone rig", len(rigs) == 1 and "head" in rigs[0].data.bones)
    check(key + " no donor geometry exported", not any(o.name in source_meshes for o in meshes))
    check(key + " all exported vertices head-weighted", all(len(v.groups) == 1 and o.vertex_groups[v.groups[0].group].name == "head" and abs(v.groups[0].weight-1) < 1e-5 for o in meshes for v in o.data.vertices))
    check(key + " embedded finish texture", any(i.size[0] == 2048 and i.size[1] == 2048 for i in bpy.data.images))
    check(key + " no animation clips", not list(bpy.data.actions))
    report["exports"][key] = {"meshes": len(meshes), "vertices": sum(len(o.data.vertices) for o in meshes), "sha256": hashlib.sha256((OUT/(key+"_mask.glb")).read_bytes()).hexdigest()}

report["passed"] = sum(c["passed"] for c in report["checks"])
report["failed"] = [c["name"] for c in report["checks"] if not c["passed"]]
(OUT/"verification.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("MASK_VERIFICATION", json.dumps(report), flush=True)
if report["failed"]:
    raise RuntimeError("Mask verification failed: " + "; ".join(report["failed"]))
