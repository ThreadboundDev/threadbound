"""Render the supplied model from several directions to plan its prototype rig."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

OUT = Path('C:/Users/chase/Documents/Codex/2026-09-27/i-wanna-write-down-a-few/bellstriker_inspect')
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='C:/Users/chase/Downloads/hitem3d.glb')
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
modifier = mesh.modifiers.new('Preview reduction', 'DECIMATE')
modifier.ratio = .025
bpy.ops.object.modifier_apply(modifier=modifier.name)
print('PREVIEW_TRIANGLES', len(mesh.data.polygons))
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 600
scene.render.resolution_y = 450
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.world = bpy.data.worlds.new('World')
scene.world.color = (.22, .25, .3)
for name, location, power, size in [('Key', (1,-3,4), 800, 5), ('Fill', (-3,2,3), 650, 4)]:
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0,0,.1))-obj.location).to_track_quat('-Z','Y').to_euler()
camera = bpy.data.objects.new('Camera', bpy.data.cameras.new('Camera'))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 2.6
for index, position in enumerate([(3,-4,2), (4,0,1), (0,-4,1), (-4,0,1)]):
    camera.location = position
    camera.rotation_euler = (Vector((0,0,.1))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(OUT / f'view_{index}.png')
    bpy.ops.render.render(write_still=True)
print('BELLSTRIKER_INSPECT_RENDERED', OUT)
