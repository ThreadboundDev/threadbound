"""Add swim, draw/curl, dash, recovery and hurt clips to the approved fish study.
Keeps the v1 source/export untouched. Run with Blender --background --python.
"""
from pathlib import Path
import math
import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/BlueBiome/Blender/Enemies'
EXPORT = ROOT / 'Assets/BlueBiome/Enemies/Models/TideDuelist_animated.glb'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'TideDuelist_v1.blend'))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.render.fps = 30
rig = next(ob for ob in scene.objects if ob.type == 'ARMATURE')
parts = [ob for ob in scene.objects if ob.type == 'MESH']
rig.animation_data_clear()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

# Carry the neck surface with the head, so curling does not expose a rigid seam.
body = next(ob for ob in parts if ob.name == 'Streamlined body')
body.vertex_groups.clear()
groups = {name: body.vertex_groups.new(name=name) for name in ['body', 'head', 'tail']}
for vert in body.data.vertices:
    x = vert.co.x
    tail = max(0.0, min(1.0, (-x - .65) / .75))
    head = max(0.0, min(1.0, (x - .25) / .55))
    for name, weight in [('body', 1 - tail - head), ('head', head), ('tail', tail)]:
        if weight > 0:
            groups[name].add([vert.index], weight, 'REPLACE')

def pose(frame, angles):
    for bone in rig.pose.bones:
        bone.rotation_mode = 'QUATERNION'
        # Angles describe bending in the side-view plane, independent of bone axes.
        rest = bone.bone.matrix_local.to_quaternion()
        q = Quaternion((0, 1, 0), math.radians(angles.get(bone.name, 0)))
        bone.rotation_quaternion = rest.inverted() @ q @ rest
        bone.location = (0, 0, 0)
        bone.scale = (1, 1, 1)
        bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)

clips = {
    'swim': [(1, {}), (16, {'tail': 12, 'tail_tip': 19, 'head': -3, 'fin.L': 9, 'fin.R': -9}),
             (31, {}), (46, {'tail': -12, 'tail_tip': -19, 'head': 3, 'fin.L': -9, 'fin.R': 9}), (61, {})],
    'draw_curl': [(1, {}), (10, {'body': 4, 'head': 35, 'tail': -40, 'tail_tip': -24, 'fin.L': 20, 'fin.R': 20}),
                  (18, {'body': 3, 'head': 100, 'tail': -112, 'tail_tip': -18, 'fin.L': 32, 'fin.R': 32}),
                  (23, {'body': 3, 'head': 100, 'tail': -112, 'tail_tip': -18, 'fin.L': 32, 'fin.R': 32})],
    'dash': [(1, {'body': 3, 'head': 100, 'tail': -112, 'tail_tip': -18, 'fin.L': 32, 'fin.R': 32}),
             (3, {'head': -7, 'tail': 16, 'tail_tip': 24, 'fin.L': -12, 'fin.R': -12}),
             (6, {'head': 0, 'tail': -5, 'tail_tip': -8, 'fin.L': -10, 'fin.R': -10}),
             (11, {'fin.L': -10, 'fin.R': -10})],
    'recover': [(1, {'fin.L': -10, 'fin.R': -10}),
                (6, {'head': -9, 'tail': 24, 'tail_tip': 28, 'fin.L': 22, 'fin.R': 22}), (18, {})],
    'hurt': [(1, {}), (3, {'body': -9, 'head': -23, 'tail': 38, 'tail_tip': 26, 'fin.L': -26, 'fin.R': -26}),
             (7, {'body': 4, 'head': 12, 'tail': -19, 'tail_tip': -12}), (13, {})],
}
rig.animation_data_create()
for name, keys in clips.items():
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame, angles in keys:
        pose(frame, angles)

rig.animation_data.action = bpy.data.actions['swim']
scene.frame_start = 1
scene.frame_end = 61
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'TideDuelist_animated.blend'))
bpy.ops.object.select_all(action='DESELECT')
for ob in parts:
    ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
bpy.context.object.name = 'TideDuelist_Mesh'
rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(EXPORT), export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
    export_cameras=False, export_lights=False)

# Actual geometry review: same camera for the rest pose and curled draw stance.
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.resolution_x = 800
scene.render.resolution_y = 600
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.world.color = (.12, .15, .19)
target = Vector((0, 0, -.25))
bpy.ops.object.camera_add(location=(0, -9, .2))
camera = bpy.context.object
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 5.0
scene.camera = camera
for loc, power in [((2,-4,5),700), ((-3,-2,2),500), ((0,3,3),800)]:
    bpy.ops.object.light_add(type='AREA', location=loc)
    light = bpy.context.object
    light.data.energy = power
    light.data.shape = 'DISK'
    light.data.size = 5
    light.rotation_euler = (target-light.location).to_track_quat('-Z','Y').to_euler()
for name, frame in [('swim',1), ('draw_curl',23), ('dash',3), ('hurt',3)]:
    rig.animation_data.action = bpy.data.actions[name]
    scene.frame_set(frame)
    scene.render.filepath = str(SOURCE / ('TideDuelist_' + name + '.png'))
    bpy.ops.render.render(write_still=True)
print('TIDE_ANIMATIONS_READY', list(clips))
