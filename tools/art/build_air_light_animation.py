"""Air V3: moving jump body and a visibly hinged, side-view sword arm."""
import math
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library'
bpy.ops.wm.open_mainfile(filepath=str(LIB / 'Threadborne_Animation_Library.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
rig.animation_data.use_nla = False
jump = bpy.data.actions['jump_1']
arm_names = {'upper_arm.R', 'forearm.R', 'hand.R'}
# Cache the whole moving jump, not one frozen pose. Keep fingers/equipment grip.
samples = {}
for frame in range(1, 17):
    rig.animation_data.action = jump
    scene.frame_set(frame + 6)
    bpy.context.view_layer.update()
    samples[frame] = {b.name: b.matrix_basis.copy() for b in rig.pose.bones}
rig.animation_data.action = bpy.data.actions['idle_4']
scene.frame_set(1)
bpy.context.view_layer.update()
hand = rig.pose.bones['hand.R']
sword = bpy.data.objects['Threadborne_Sword']
tip = max([sword.matrix_world @ Vector(c) for c in sword.bound_box], key=lambda p: (p-hand.head).length)
grip_axis = hand.matrix.to_3x3().inverted() @ (tip-hand.head).normalized()
action = bpy.data.actions.new('air_light_1')
action.use_fake_user = True
rig.animation_data.action = action

def aim(bone, target):
    bpy.context.view_layer.update()
    m = bone.matrix.copy()
    turn = (bone.tail-bone.head).normalized().rotation_difference((target-bone.head).normalized())
    rotated = turn.to_matrix().to_4x4() @ m
    rotated.translation = m.translation
    bone.matrix = rotated
    bpy.context.view_layer.update()

# Hand offsets from the animated shoulder (Y is gameplay horizontal).
# A close raised hand folds the elbow backwards; reach opens through impact.
keys = [(1, -.12, .13, .35), (3, -.06, .29, 1.0),
        (4, -.08, .30, 1.0), (5, -.33, .26, 1.0),
        (6, -.55, .03, 1.0), (7, -.48, -.25, 1.0),
        (8, -.30, -.43, 1.0), (10, -.21, -.35, .9),
        (13, -.18, -.16, .35), (16, -.12, .13, 0.0)]
for frame in range(1, 17):
    scene.frame_set(frame)
    base = samples[frame]
    for bone in rig.pose.bones:
        bone.matrix_basis = base[bone.name]
    bpy.context.view_layer.update()
    left, right = next((a, b) for a, b in zip(keys, keys[1:]) if a[0] <= frame <= b[0])
    t = (frame-left[0])/(right[0]-left[0])
    t = t*t*(3-2*t)
    y, z, weight = [left[i]*(1-t)+right[i]*t for i in range(1,4)]
    upper = rig.pose.bones['upper_arm.R']
    fore = rig.pose.bones['forearm.R']
    shoulder = upper.head.copy()
    target = shoulder + Vector((-.035,y,z))
    delta = target-shoulder
    distance = min(delta.length, (upper.length+fore.length)*.96)
    axis = delta.normalized()
    target = shoulder+axis*distance
    along = (upper.length**2-fore.length**2+distance**2)/(2*distance)
    # Keep the elbow bend visible in the gameplay plane, not towards the camera.
    pole = Vector((0,1,.4))
    pole = (pole-axis*pole.dot(axis)).normalized()
    elbow = shoulder+axis*along+pole*math.sqrt(max(0,upper.length**2-along**2))
    aim(upper,elbow)
    aim(fore,target)
    m = hand.matrix.copy()
    # Fixed grip relationship to forearm: the wrist does not drive the cut.
    desired = Matrix.Rotation(math.radians(-12),3,'X') @ (hand.head-fore.head).normalized()
    turn = (m.to_3x3() @ grip_axis).normalized().rotation_difference(desired)
    rotated = turn.to_matrix().to_4x4() @ m
    rotated.translation = m.translation
    hand.matrix = rotated
    bpy.context.view_layer.update()
    for name in arm_names:
        bone = rig.pose.bones[name]
        bone.matrix_basis = base[name].lerp(bone.matrix_basis, weight)
    for bone in rig.pose.bones:
        if bone.name not in arm_names:
            assert max(abs(bone.matrix_basis[i][j]-base[bone.name][i][j]) for i in range(4) for j in range(4)) < .0001
        bone.rotation_mode = 'QUATERNION'
        for channel in ('location','rotation_quaternion','scale'):
            bone.keyframe_insert(channel, frame=frame, group=bone.name)
for layer in action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for curve in bag.fcurves:
                for key in curve.keyframe_points:
                    key.interpolation = 'LINEAR'
scene.render.fps = 30
scene.frame_start, scene.frame_end = 1,16
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(LIB / 'Threadborne_Air_Light_v3_final.blend'))
print('AIR_V3_READY: moving jump body, visible elbow windup, fixed forearm grip, 16 frames')


