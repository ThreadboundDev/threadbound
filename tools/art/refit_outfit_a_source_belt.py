"""Refit the source tunic's rear panels and reduce excess ease in Outfit A's shorts."""
import hashlib
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


def smooth(value):
    value = min(1., max(0., value))
    return value * value * (3 - 2 * value)


scene = bpy.context.scene
outfit = bpy.data.objects["A - Original pieces, unified outfit"]
mesh = outfit.data
assert outfit.get("rear_leather_wraps_v1") and not outfit.get("source_rear_fit_v2")
assert bpy.context.mode == "OBJECT"
source = Path(bpy.data.filepath).parents[3] / "Assets/Threadborne/Equipment/Base Gear/Base Chest 3d"
photo = source / "Base_Chest_3d.fbm/Base_Chest_3d_basecolor.jpg"
texture = next(n.image for n in mesh.materials[0].node_tree.nodes if n.type == "TEX_IMAGE")
assert hashlib.sha256(texture.packed_file.data).digest() == hashlib.sha256(photo.read_bytes()).digest()

selected = list(bpy.context.selected_objects)
active = bpy.context.view_layer.objects.active
old_ids = set(bpy.data.user_map())
try:
    bpy.ops.import_scene.fbx(filepath=str(source / "Base_Chest_3d.fbx"))
    src = next(o for o in bpy.context.selected_objects if o.type == "MESH")
    original = src.data
    assert len(original.vertices) == 29872
    assert all(tuple(p.vertices) == tuple(mesh.polygons[p.index].vertices) for p in original.polygons)
    source_points = [src.matrix_world @ v.co for v in original.vertices]
    uvs = [loop.uv.copy() for loop in original.uv_layers.active.data]
finally:
    bpy.data.batch_remove(set(bpy.data.user_map()) - old_ids)
    for obj in selected:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = active

# The previous overlay was appended as four disconnected 51 x 5 ribbons.
bm = bmesh.new()
bm.from_mesh(mesh)
bm.verts.ensure_lookup_table()
start = len(bm.verts) - 4 * 51 * 5
extra = list(bm.verts)[start:]
assert len({f for v in extra for f in v.link_faces}) == 800
assert all(all(v.index >= start for v in f.verts) for v in extra for f in v.link_faces)
bmesh.ops.delete(bm, geom=extra, context="VERTS")
bm.to_mesh(mesh)
bm.free()

# Keep the FBX folds, worn strap edges, stitching, and pouch in register.
# Use a continuous fit over the entire back rather than pushing individual
# leather layers independently against the wooden body.
adjusted = set()
for i, p in enumerate(source_points):
    x = p.x * .86 * 1.04
    y = p.y * .76 * 1.11
    z = .845 + p.z*.765 + max(0., min(1., (abs(p.x)-.10)/.17))*.11
    blend = smooth((y+.012)/.082) * smooth((1.32-z)/.085)
    if blend == 0:
        continue
    skirt = smooth((1.115-z)/.22)
    target = Vector((x, y * (1.025-.275*skirt), z))
    vertex = mesh.vertices[i]
    vertex.co = vertex.co.lerp(target, blend)
    adjusted.add(i)
original_uv = mesh.uv_layers["Attribute"]
for poly in mesh.polygons[:32329]:
    if any(i in adjusted for i in poly.vertices):
        for loop in poly.loop_indices:
            original_uv.data[loop].uv = uvs[loop]

shorts = {i for p in mesh.polygons if p.material_index == 3 for i in p.vertices}
for i in shorts:
    p = mesh.vertices[i].co
    rear = smooth((p.y+.014)/.102)
    seat = smooth((p.z-.73)/.13)
    p.y *= 1. - .38 * rear * seat

mesh.update()
outfit["source_rear_fit_v2"] = True
print("Original tunic fit:",len(adjusted),"source vertices;",len(shorts),"shorts vertices inspected")
