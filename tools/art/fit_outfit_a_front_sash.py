"""Seat Outfit A's front sash lining outside the wooden abdomen in the fitting pose."""
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

scene = bpy.context.scene
outfit = bpy.data.objects["A - Original pieces, unified outfit"]
body = bpy.data.objects["Threadborne_Doll"]
rig = bpy.data.objects["Threadborne_Rig"]
assert bpy.path.basename(bpy.data.filepath) == "Threadbound_Base_Armor_Fit.blend"
assert rig.animation_data.action.name == "Fit | T-pose, seated wrists"
assert not outfit.get("front_sash_extended"), "Front sash is already fitted"
mesh = outfit.data
slot = list(mesh.materials).index(bpy.data.materials["Base tunic | dark sash backing"])
ids = {i for poly in mesh.polygons if poly.material_index == slot for i in poly.vertices}
deps = bpy.context.evaluated_depsgraph_get()
tree = BVHTree.FromObject(body, deps)
evaluated = outfit.evaluated_get(deps)
points = {i: evaluated.data.vertices[i].co.copy() for i in ids}
changed = 0
for i, p in points.items():
    v = mesh.vertices[i]
    if p.y >= 0:
        continue
    lift = .050 * max(0, min(1, (v.co.z-1.09)/.035)) * max(0, min(1, -p.y/.055))
    p.z += lift
    start = Vector((p.x, -.5, p.z))
    hit = tree.ray_cast(start, Vector((0,1,0)), .5)[0]
    if hit is None:
        continue
    # Measure at neighboring heights too so the lining spans the curved belly
    # between rings, including the lowest opening between the leather wraps.
    ys = [hit.y]
    for dz in (-.012, .012):
        near = tree.ray_cast(start + Vector((0,0,dz)), Vector((0,1,0)), .5)[0]
        if near is not None:
            ys.append(near.y)
    offset = min(ys) - .006 - p.y
    offset = min(0, offset)
    if not lift and not offset:
        continue
    deform = Matrix(((0,0,0),(0,0,0),(0,0,0)))
    for weight in v.groups:
        bone = rig.pose.bones.get(outfit.vertex_groups[weight.group].name)
        if bone:
            deform += (bone.matrix @ bone.bone.matrix_local.inverted()).to_3x3() * weight.weight
    v.co += deform.inverted_safe() @ Vector((0, offset, lift))
    changed += 1
mesh.update()
bpy.context.view_layer.update()
print("Front lining vertices corrected", changed)
if changed and not outfit.get("front_sash_extended"):
    outfit["front_sash_extended"] = True
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)
