"""Inspect and render the retained character without saving over its source."""
import hashlib
import json
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / "ArtSource/Player/Blender/imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend"
digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
scene.frame_set(38)
report = {
    "source": str(SOURCE.relative_to(ROOT)),
    "sha256": digest,
    "engine": scene.render.engine,
    "camera": {"location": list(scene.camera.location), "rotation": list(scene.camera.rotation_euler), "ortho_scale": scene.camera.data.ortho_scale},
    "view": {"transform": scene.view_settings.view_transform, "look": scene.view_settings.look, "exposure": scene.view_settings.exposure},
    "objects": [],
    "materials": [],
    "images": [],
}
for ob in scene.objects:
    item = {"name": ob.name, "type": ob.type, "hide_render": ob.hide_render, "location": list(ob.location), "dimensions": list(ob.dimensions)}
    if ob.type == "MESH":
        item["vertices"] = len(ob.data.vertices)
        item["materials"] = [slot.material.name if slot.material else None for slot in ob.material_slots]
    if ob.type == "LIGHT":
        item["energy"] = ob.data.energy
        item["color"] = list(ob.data.color)
    report["objects"].append(item)
for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    report["materials"].append({"name": mat.name, "nodes": [{"name": n.name, "type": n.type, "image": n.image.name if n.type == "TEX_IMAGE" and n.image else None} for n in mat.node_tree.nodes], "links": [f"{l.from_node.name}.{l.from_socket.name} -> {l.to_node.name}.{l.to_socket.name}" for l in mat.node_tree.links]})
for im in bpy.data.images:
    report["images"].append({"name": im.name, "path": im.filepath, "packed": bool(im.packed_file), "size": list(im.size)})
(OUT / "source_inspection.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
scene.render.resolution_x = 600
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.cycles.samples = 16
scene.render.filepath = str(OUT / "source_side.png")
bpy.ops.render.render(write_still=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == digest
print("SOURCE_INSPECTION_COMPLETE", flush=True)
