"""Render a saved doll GLB in its native study lighting for export review.

Run in background Blender with the native study file loaded, followed by
``--python this_script -- path/to/export.glb path/to/output_directory``.
No changes to the loaded source file are saved.
"""
from pathlib import Path
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
if len(args) != 2:
    raise ValueError('Expected GLB path and output directory after --')
glb, out = Path(args[0]).resolve(), Path(args[1]).resolve()
out.mkdir(parents=True, exist_ok=True)

for obj in list(bpy.data.objects):
    if obj.type == 'ARMATURE' or (obj.type == 'MESH' and obj.name.startswith('Doll |')):
        bpy.data.objects.remove(obj, do_unlink=True)
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(glb))
imported = set(bpy.data.objects) - before
rigs = [obj for obj in imported if obj.type == 'ARMATURE']
meshes = [obj for obj in imported if obj.type == 'MESH'
          and not any(collection.name == 'glTF_not_exported'
                      for collection in obj.users_collection)]
if len(rigs) != 1 or len(meshes) != 1:
    raise RuntimeError(f'Expected one armature and one body mesh, got {len(rigs)} armatures and {len(meshes)} meshes')
rigs[0].data.pose_position = 'REST'
bpy.context.view_layer.update()

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.resolution_x = scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
graph = bpy.context.evaluated_depsgraph_get()
points = []
for obj in meshes:
    evaluated = obj.evaluated_get(graph)
    points.extend(evaluated.matrix_world @ Vector(corner) for corner in evaluated.bound_box)
center = Vector(((min(p[i] for p in points) + max(p[i] for p in points)) / 2
                 for i in range(3)))
camera = scene.camera
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 2.25
for label, direction in [('front', (0, -6, 0)), ('side', (6, 0, 0)),
                         ('back', (0, 6, 0)), ('three_quarter', (3, -6, 1.5))]:
    camera.location = center + Vector(direction)
    camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(out / f'v3_export_{label}.png')
    bpy.ops.render.render(write_still=True)
print('DOLL_EXPORT_REIMPORT_RENDERED', glb, len(meshes), flush=True)
