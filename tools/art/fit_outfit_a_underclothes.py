"""Replace Outfit A's standalone sash filler with a fitted torso and shorts underlayer."""
import bpy
import bmesh
from mathutils import Vector

outfit = bpy.data.objects["A - Original pieces, unified outfit"]
body = bpy.data.objects["Threadborne_Doll"]
collection = bpy.data.collections["Outfit A"]
assert bpy.context.window.view_layer.name == "A - Original pieces"
assert not bpy.data.objects.get("A - Fitted underclothes")

# Identify the original 56 x 5 lining grid by its isolated topology before
# removing it. The woven sash pass reused these vertices inside the joined tunic.
first = 29872
lining = set(range(first, first + 5 * 56))
faces = [p for p in outfit.data.polygons if lining.intersection(p.vertices)]
assert len(faces) == 224 and all(len(p.vertices) == 4 and set(p.vertices) <= lining for p in faces)

under = body.copy()
under.data = body.data.copy()
under.name = "A - Fitted underclothes"
under.data.name = "Fitted torso and short legs"
# The duplicate keeps the exact skinned body coordinates, weights and armature.
for modifier in list(under.modifiers):
    if modifier.type != "ARMATURE":
        under.modifiers.remove(modifier)
assert under.find_armature() == body.find_armature()
bm = bmesh.new()
bm.from_mesh(under.data)

# A shallow scoop leaves the neck and the opening inside the cowl bare.
def neckline(x, y):
    side = min(1., abs(x) / .15)
    front = min(1., max(0., -y / .09))
    return 1.545 + .044 * side - .050 * front * (1. - side)

for vertex in bm.verts:
    vertex.co.z -= neckline(vertex.co.x, vertex.co.y)
def trim(point, normal):
    bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                           plane_co=point, plane_no=normal, clear_outer=True, dist=.000001)

trim((0,0,0), (0,0,1))
for vertex in bm.verts:
    vertex.co.z += neckline(vertex.co.x, vertex.co.y)
trim((0,0,.728), (0,0,-1))
trim((.317,0,0), (1,0,0))
trim((-.317,0,0), (-1,0,0))
bm.normal_update()
for vertex in bm.verts:
    vertex.co += vertex.normal * .0025
bm.to_mesh(under.data)
bm.free()
under.data.materials.clear()
material = bpy.data.materials.new("Outfit A | Undyed charcoal undercloth")
material.use_nodes = True
shader = material.node_tree.nodes.get("Principled BSDF")
material.diffuse_color = (.062,.061,.070,1)
shader.inputs["Base Color"].default_value = material.diffuse_color
shader.inputs["Roughness"].default_value = .94
under.data.materials.append(material)
for face in under.data.polygons:
    face.material_index = 0
assert len(under.data.polygons) > 100
collection.objects.link(under)
bpy.context.window.view_layer.layer_collection.children["Outfit B"].exclude = True
under.hide_render = False
under.hide_set(False)
bm = bmesh.new()
bm.from_mesh(outfit.data)
bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[bm.verts[i] for i in lining], context="VERTS")
bm.to_mesh(outfit.data)
bm.free()
outfit.data.update()
print("Underlayer faces:",len(under.data.polygons),"removed lining faces:",len(faces))
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)
