"""Continue the grey woven tunic beneath Outfit A's overlapping waist wraps."""
import bpy

outfit = bpy.data.objects["A - Original pieces, unified outfit"]
mesh = outfit.data
lining = list(mesh.materials).index(bpy.data.materials["Base tunic | dark sash backing"])
cloth = next(i for i, mat in enumerate(mesh.materials) if mat.node_tree and any(
    node.type == "TEX_IMAGE" and node.image and node.image.name.lower() == "base_chest_3d_basecolor"
    for node in mat.node_tree.nodes))
faces = [face for face in mesh.polygons if face.material_index == lining]
assert len(faces) == 224 and all(len(face.vertices) == 4 for face in faces)
first = min(i for face in faces for i in face.vertices)
# Mirror a clean woven region from the tunic atlas across the lining grid.
# All rows meet on matching texels, including the wrap around the back.
for face in faces:
    for loop in face.loop_indices:
        index = mesh.loops[loop].vertex_index - first
        row, column = divmod(index, 56)
        u = (60 + 35 * (1 - abs(column % 4 - 2) / 2)) / 560
        v = 1 - (509 + 30 * (row % 2)) / 560
        for layer in mesh.uv_layers:
            layer.data[loop].uv = (u, v)
    face.material_index = cloth
mesh.update()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)
print("Mapped", len(faces), "lining faces to", mesh.materials[cloth].name)
