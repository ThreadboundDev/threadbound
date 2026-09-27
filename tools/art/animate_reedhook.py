"""Bake Reedhook's planted two-hand hook attack and walking gait from the v1 study."""
from pathlib import Path
import math
import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/BlueBiome/Blender/Enemies'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'Reedhook_v1.blend'))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.render.fps = 30
rig = next(ob for ob in scene.objects if ob.type == 'ARMATURE')
parts = [ob for ob in scene.objects if ob.type == 'MESH']
rig.animation_data_clear()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
# The weapon drives both grips, avoiding a cyclic dependency on the right hand.
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
rig.data.edit_bones['hook'].parent = rig.data.edit_bones['root']
bpy.ops.object.mode_set(mode='OBJECT')
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
heads = {b.name: b.head_local.copy() for b in rig.data.bones}
tails = {b.name: b.tail_local.copy() for b in rig.data.bones}
pivot = (heads['hand.R'] + heads['hand.L']) / 2
rig['scope'] = 'Playable first pass: idle, walk, windup, sweep, recover, hurt'

def orient(name, start, end):
    delta = (tails[name] - heads[name]).rotation_difference(end - start)
    rig.pose.bones[name].matrix = Matrix.Translation(start) @ delta.to_matrix().to_4x4() @ rest[name].to_3x3().to_4x4()
    bpy.context.view_layer.update()

def limb(upper, lower, endbone, target, pole, end_rotation=None):
    start = rig.pose.bones[upper].head.copy()
    length_a = (tails[upper] - heads[upper]).length
    length_b = (tails[lower] - heads[lower]).length
    delta = target - start
    distance = min(delta.length, length_a + length_b - .001)
    distance = max(abs(length_a - length_b) + .001, distance)
    axis = delta.normalized()
    along = (length_a**2 - length_b**2 + distance**2) / (2 * distance)
    bend = pole - start
    bend = (bend - axis * bend.dot(axis)).normalized()
    elbow = start + axis * along + bend * math.sqrt(max(0, length_a**2 - along**2))
    target = start + axis * distance
    orient(upper, start, elbow)
    orient(lower, elbow, target)
    rig.pose.bones[endbone].matrix = Matrix.Translation(target) @ (end_rotation or Matrix.Identity(4)) @ rest[endbone].to_3x3().to_4x4()
    bpy.context.view_layer.update()

def smooth(a, b, t):
    return a + (b-a) * (t*t*(3-2*t))

def frame_pose(clip, t):
    for bone in rig.pose.bones:
        bone.rotation_mode = 'QUATERNION'
        bone.matrix_basis = Matrix.Identity(4)
    lean = 0.0
    hook_angle = 0.0
    shift = Vector((0,0,0))
    bob = .012 * math.sin(t * math.tau)
    if clip == 'windup':
        lean = smooth(0,-8,t)
        hook_angle = smooth(0,-23,t)
        shift = Vector((smooth(0,-.12,t),0,smooth(0,.07,t)))
    elif clip == 'sweep':
        lean = smooth(-8,12,t)
        hook_angle = smooth(-23,67,t)
        shift = Vector((smooth(-.12,.16,t),0,smooth(.07,-.08,t)))
    elif clip == 'recover':
        lean = smooth(12,0,t)
        hook_angle = smooth(67,0,t)
        shift = Vector((smooth(.16,0,t),0,smooth(-.08,0,t)))
    elif clip == 'hurt':
        recoil = math.sin(math.pi * min(1,t*1.8)) * (1-t)
        lean = -18 * recoil
        hook_angle = -12 * recoil
        shift.x = -.1 * recoil
    if clip == 'walk':
        bob = .035 * math.cos(t * math.tau * 2)
        hook_angle = 2 * math.sin(t * math.tau)
    rig.pose.bones['pelvis'].location = rest['pelvis'].to_quaternion().inverted() @ Vector((0,0,bob))
    bone = rig.pose.bones['chest']
    q = rest['chest'].to_quaternion()
    bone.rotation_quaternion = q.inverted() @ Quaternion((0,1,0),math.radians(lean)) @ q
    bpy.context.view_layer.update()
    hook_delta = Matrix.Translation(pivot + shift + Vector((0,0,bob))) @ Matrix.Rotation(math.radians(hook_angle),4,'Y') @ Matrix.Translation(-pivot)
    rig.pose.bones['hook'].matrix = hook_delta @ rest['hook']
    bpy.context.view_layer.update()
    for side in ['R','L']:
        target = hook_delta @ heads['hand.'+side]
        pole = Vector((.05, -.9 if side == 'R' else .65, 1.25))
        limb('upper_arm.'+side,'forearm.'+side,'hand.'+side,target,pole,hook_delta.to_3x3().to_4x4())
        foot = heads['foot.'+side].copy()
        if clip == 'walk':
            phase = t*math.tau + (math.pi if side == 'R' else 0)
            foot.x = -.05 + .38*math.cos(phase)
            foot.z = .16 + .15*max(0,-math.sin(phase))
        limb('thigh.'+side,'shin.'+side,'foot.'+side,foot,Vector((1.5,foot.y,.6)))

rig.animation_data_create()
for clip, end in [('idle',61),('walk',33),('windup',19),('sweep',9),('recover',19),('hurt',13)]:
    action = bpy.data.actions.new(clip)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(1,end+1):
        frame_pose(clip,(frame-1)/(end-1))
        for bone in rig.pose.bones:
            for prop in ['location','rotation_quaternion','scale']:
                bone.keyframe_insert(prop,frame=frame,group=bone.name)
rig.animation_data.action = bpy.data.actions['idle']
scene.frame_start = 1
scene.frame_end = 61
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'Reedhook_animated.blend'))
bpy.ops.object.select_all(action='DESELECT')
for ob in parts:
    ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
bpy.context.object.name = 'Reedhook_Mesh'
rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'Assets/BlueBiome/Enemies/Models/Reedhook_animated.glb'),
    export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',
    export_force_sampling=True,export_cameras=False,export_lights=False)
print('REEDHOOK_ANIMATIONS_READY')
