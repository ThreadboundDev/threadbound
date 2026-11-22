"""Fit the original Base pieces in the existing armor review file and export the trial."""
from pathlib import Path
from statistics import median
import sys

import bpy
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "Assets/Threadborne/Player/LocalDoll/Equipment/OutfitATrial"
layer = bpy.context.scene.view_layers["A - Original pieces"]
bpy.context.window.view_layer = layer
outfit = bpy.data.collections["Outfit A"].objects[0]
mesh = outfit.data
body = bpy.data.objects["Threadborne_Doll"]
right = bpy.data.objects["Base_Bracer.R"]
right.hide_set(True, view_layer=layer)


def smooth(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3 - 2 * value)


def surface(obj, faces):
    return BVHTree.FromPolygons([v.co.copy() for v in obj.data.vertices], faces)


def fit():
    body_tree = surface(body, [p.vertices[:] for p in body.data.polygons])
    cloth_ids = {i for p in mesh.polygons if p.material_index in (0, 3) for i in p.vertices}
    for i in cloth_ids:
        point = mesh.vertices[i].co
        hit, normal, _, distance = body_tree.find_nearest(point)
        signed = (point - hit).dot(normal)
        if distance < .035 and signed < .004:
            point += normal * min(.022, .004 - signed)

    tunic = surface(outfit, [p.vertices[:] for p in mesh.polygons if p.material_index == 0])
    cowl_ids = {i for p in mesh.polygons if p.material_index == 2 for i in p.vertices}
    before, after = [], []
    for i in cowl_ids:
        point = mesh.vertices[i].co
        height = point.z
        hit, _, _, gap = tunic.find_nearest(point)
        # Drape the lower folds onto the chest, easing out toward the neck opening.
        contact = smooth((1.575 - height) / .102)
        if gap > .004:
            point += (hit - point) * (contact * (gap - .004) / gap)
        if height < 1.422:
            before.append(gap)
            after.append(tunic.find_nearest(point)[3])
    print("Lower cowl median clearance (mm)", 1000 * median(before), 1000 * median(after))
    mesh.update()


if not outfit.get("original_cloth_fit_v1"):
    fit()
    outfit["original_cloth_fit_v1"] = True

def set_weights(vertex, values):
    for weight in tuple(vertex.groups):
        outfit.vertex_groups[weight.group].remove([vertex.index])
    for name, value in values.items():
        if value > 0:
            outfit.vertex_groups[name].add([vertex.index], value, "REPLACE")


# Keep each loose hem with its own limb even when the arm or thigh lifts.
if not outfit.get("original_cloth_motion_v1"):
    sections = {i: p.material_index for p in mesh.polygons for i in p.vertices}
    for vertex in mesh.vertices:
        x, y, z = vertex.co
        side = "L" if x >= 0 else "R"
        section = sections.get(vertex.index)
        if section == 0 and abs(x) > .15 and z > 1.35:
            arm = smooth((abs(x) - .155) / .115)
            set_weights(vertex, {"chest": 1-arm, "upper_arm."+side: arm})
        elif section == 3 or (section == 0 and z < 1.05):
            thigh = smooth((1.08-z)/.22)
            left = smooth((x+.045)/.09)
            if section == 3 and z < .79:
                left = float(x >= 0)
            set_weights(vertex, {"pelvis": 1-thigh, "thigh.L": thigh*left, "thigh.R": thigh*(1-left)})
    outfit["original_cloth_motion_v1"] = True

# Raised thighs start rotating above the belt line. Carry the side panels
# with the hip early and leave a little room around the seat and upper leg.
if not outfit.get("original_cloth_hip_fit_v1"):
    from mathutils import Vector
    sections = {i: p.material_index for p in mesh.polygons for i in p.vertices}
    for vertex in mesh.vertices:
        x, y, z = vertex.co
        if sections.get(vertex.index) not in (0, 1, 3) or z > 1.20:
            continue
        side = 1 if x >= 0 else -1
        hip = 1.12 + .05 * smooth((abs(x)-.045)/.12)
        thigh = smooth((hip-z)/.19)
        left = smooth((x+.05)/.10)
        spine = .20 * smooth((z-1.12)/.10)
        set_weights(vertex, {"pelvis": (1-thigh)*(1-spine), "spine": (1-thigh)*spine,
                             "thigh.L": thigh*left, "thigh.R": thigh*(1-left)})
        allowance = smooth((z-.77)/.12) * smooth((1.17-z)/.10)
        outward = Vector((x-side*.08, y, 0))
        if outward.length > .007:
            vertex.co += outward.normalized() * (.018 * allowance)
    outfit["original_cloth_hip_fit_v1"] = True

if "--save-fit" in sys.argv:
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)

# Reuse the game's existing skin exporter after saving the editable working file.
sys.path.insert(0, str(ROOT / "tools/art"))
import export_base_outfit_b as exporter

bpy.context.window.view_layer = layer
exporter.LAYER = layer
OUTPUT.mkdir(parents=True, exist_ok=True)
exporter.apply_budget(outfit, .55)
template = exporter.RIG.data
exporter.export_item(template, [outfit], OUTPUT / "base_outfit_a.glb")
bracer = bpy.data.objects["Base_Bracer.L"]
coil = bpy.data.objects["Base_Grapple_Coil"]
needle = bpy.data.objects["Grapple_Needle_Base"]
exporter.flatten_hardware_finishes([coil, needle])
for obj, ratio in [(bracer, .27), (coil, .26), (needle, .62)]:
    exporter.apply_budget(obj, ratio)
exporter.export_item(template, [bracer, coil, needle], OUTPUT / "base_grapple_glove.glb")
