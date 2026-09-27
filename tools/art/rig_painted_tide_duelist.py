"""Build the still-water rig and existing enemy-compatible action set."""
from pathlib import Path
import math
import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / 'ArtSource/BlueBiome/Blender/Enemies/TideDuelist_Painted_v2'
bpy.ops.wm.open_mainfile(filepath=str(D / 'TideDuelist_Painted_v2.blend'))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.render.fps = 30
mesh = next(o for o in scene.objects if o.type == 'MESH')
bpy.ops.object.select_all(action='DESELECT')
data = bpy.data.armatures.new('TideDuelist_Rig')
rig = bpy.data.objects.new('TideDuelist_Rig', data)
scene.collection.objects.link(rig)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
definitions = [('root', 0, None), ('body', -.08, 'root'), ('head', -.22, 'body'),
               ('tail', .22, 'body'), ('tail_mid', .49, 'tail'), ('tail_tip', .73, 'tail_mid')]
for name, y, parent in definitions:
    bone = data.edit_bones.new(name)
    bone.head = (0, y, 0)
    bone.tail = (0, y + .14, 0)
    if parent:
        bone.parent = data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True
mesh.parent = rig
modifier = mesh.modifiers.new('Fish deformation', 'ARMATURE')
modifier.object = rig
modifier.use_deform_preserve_volume = False  # Match glTF linear skinning.
mesh.vertex_groups.clear()
stations = [(-.30, 'head'), (-.06, 'body'), (.32, 'tail'), (.60, 'tail_mid'), (.80, 'tail_tip')]
groups = {name: mesh.vertex_groups.new(name=name) for _, name in stations}
for vertex in mesh.data.vertices:
    y = vertex.co.y
    if y <= stations[0][0]:
        weights = [(stations[0][1], 1)]
    elif y >= stations[-1][0]:
        weights = [(stations[-1][1], 1)]
    else:
        for (a, na), (b, nb) in zip(stations, stations[1:]):
            if a <= y <= b:
                t = (y-a)/(b-a)
                t = t*t*(3-2*t)
                weights = [(na, 1-t), (nb, t)]
                break
    for name, weight in weights:
        if weight > 0:
            groups[name].add([vertex.index], weight, 'REPLACE')

# Small emissive pupils follow the head bone on both sides of the painted eye.
eye_mat = bpy.data.materials.new('TideEyeTell')
eye_mat.diffuse_color = (.95, .65, .18, 1)
eye_mat.use_nodes = True
bs = eye_mat.node_tree.nodes.get('Principled BSDF')
bs.inputs['Base Color'].default_value = (.95, .65, .18, 1)
bs.inputs['Emission Color'].default_value = (1, .32, .04, 1)
bs.inputs['Emission Strength'].default_value = .1
eye_y, eye_z = -.307, .025
near = [v.co for v in mesh.data.vertices if abs(v.co.y-eye_y)<.025 and abs(v.co.z-eye_z)<.025]
eye_x = max(abs(v.x) for v in near)
parts = [mesh]
for side in [-1, 1]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=.009,
                                      location=(side*(eye_x+.002), eye_y, eye_z))
    eye = bpy.context.object
    eye.name = 'EyeTell_Left' if side < 0 else 'EyeTell_Right'
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    eye.data.materials.append(eye_mat)
    eye.parent = rig
    group = eye.vertex_groups.new(name='head')
    group.add(list(range(len(eye.data.vertices))), 1, 'REPLACE')
    eye.modifiers.new('Follow head', 'ARMATURE').object = rig
    parts.append(eye)

curl = {'head': 58, 'body': 4, 'tail': -34, 'tail_mid': -40, 'tail_tip': -27}
clips = {
    'still': [(1, {}), (31, {'tail_mid': 1, 'tail_tip': 1.5}), (61, {})],
    'draw_curl': [(1, {}), (7, {'head': 9, 'tail': -8}), (18, curl), (23, curl)],
    'dash': [(1, curl), (2, {'head': -3, 'tail': 6, 'tail_mid': 5}), (6, {})],
    'recover': [(1, {}), (5, {'head': -4, 'tail': 8, 'tail_mid': 7}), (18, {})],
    'hurt': [(1, {}), (3, {'body': -7, 'head': -12, 'tail': 18, 'tail_mid': 12}),
             (7, {'head': 5, 'tail': -7}), (13, {})]
}
rig.animation_data_create()
for name, keys in clips.items():
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame, angles in keys:
        for bone in rig.pose.bones:
            bone.rotation_mode = 'QUATERNION'
            rest = bone.bone.matrix_local.to_quaternion()
            q = Quaternion((1, 0, 0), math.radians(angles.get(bone.name, 0)))
            bone.rotation_quaternion = rest.inverted() @ q @ rest
            bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)

rig.animation_data.action = bpy.data.actions['still']
scene.frame_start, scene.frame_end = 1, 61
scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.wm.save_as_mainfile(filepath=str(D / 'TideDuelist_Rigged_v2.blend'), compress=True)

# Export facing +X with the existing visual's scale/camera and hitbox footprint.
rig.rotation_euler.z = math.pi/2
rig.scale = (2.2,)*3
bpy.ops.object.select_all(action='DESELECT')
for obj in parts + [rig]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(ROOT / 'Assets/BlueBiome/Enemies/Models/TideDuelist_Rigged_v2.glb'),
    export_format='GLB', use_selection=True, export_animations=True,
    export_animation_mode='ACTIONS', export_force_sampling=True,
    export_cameras=False, export_lights=False)
rig.rotation_euler.z = 0
rig.scale = (1,)*3
scene.camera.location = (4, 0, .10)
scene.camera.rotation_euler = (Vector((0,0,-.12))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale = 2.2
scene.render.resolution_x, scene.render.resolution_y = 960, 600
scene.cycles.samples = 16
for clip, frame in [('still',1), ('draw_curl',23), ('dash',4), ('hurt',3)]:
    rig.animation_data.action = bpy.data.actions[clip]
    scene.frame_set(frame)
    scene.render.filepath = str(D / f'Rig_{clip}.png')
    bpy.ops.render.render(write_still=True)
print('RIGGED_TIDE_READY', list(clips), 'eye surface', eye_x)
