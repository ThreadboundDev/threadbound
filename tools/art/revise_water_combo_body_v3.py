"""Use existing sword performances and moving swim idle to revise the combo.

Keeps the v2 hand/blade intent, all-limb IK, fixed fingers, and second grip.
Body animation is sampled from actual reference motions. Sword controllers
retain sparse editable keys. The v2 manual source is never overwritten.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / 'ArtSource/Player/Blender/ManualAttacks'
DEST = FOLDER / 'Threadborne_Water_Combo_v3_IK.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve manual v3 edits.'
bpy.ops.wm.open_mainfile(filepath=str(FOLDER / 'Threadborne_Water_Combo_v2_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
rig.animation_data.use_nla = False
constraints = [c for b in rig.pose.bones for c in b.constraints]
grip = rig.pose.bones['CTRL_LeftHand'].constraints['Second hand follows sword grip']
lengths = [23, 23, 39]
starts = [0, 22, 44]
key_frames = [[1, 5, 8, 11, 12, 13, 14, 18, 23], [1, 5, 8, 11, 12, 13, 14, 15, 19, 23], [1, 5, 8, 11, 14, 18, 22, 26, 31, 35, 39]]

def sample(action, frame):
    rig.animation_data.action = action
    scene.frame_set(int(frame), subframe=frame-int(frame))
    bpy.context.view_layer.update()
    return {
        'basis': {b.name: b.matrix_basis.copy() for b in rig.pose.bones},
        'pose': {b.name: b.matrix.copy() for b in rig.pose.bones},
        'head': {b.name: b.head.copy() for b in rig.pose.bones},
    }

old = {}
for step, last in enumerate(lengths):
    action = bpy.data.actions[f'water_combo_{step+1}']
    for frame in range(1, last+1):
        old[step, frame] = sample(action, frame)
        old[step, frame]['grip'] = grip.influence
    action.name = f'reference_v2_water_combo_{step+1}'

with bpy.data.libraries.load(str(ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'), link=False) as (_, loaded):
    loaded.actions = ['slash_2', 'attack_1', 'water_idle_1']
slash, overhead, swim = loaded.actions
for action, label in [(slash, 'GroundCombo'), (overhead, 'OverheadAttack'), (swim, 'SwimIdle')]:
    action.name = 'BODY_REFERENCE_' + label
for c in constraints:
    c.mute = True
slash_start = sample(slash, 1)
overhead_start = sample(overhead, 1)
swim_start = sample(swim, 1)

def curve(points, frame):
    for (a, x), (b, y) in zip(points, points[1:]):
        if frame <= b:
            t = max(0.0, (frame-a)/(b-a))
            return x+(y-x)*t
    return points[-1][1]

slash_time = [
    [(1, 1), (5, 13), (8, 18), (11, 21), (14, 25), (18, 29), (23, 31)],
    [(1, 31), (5, 29), (8, 25), (11, 21), (15, 17), (19, 14), (23, 13)],
]
overhead_time = [(1, 15), (8, 22), (11, 28), (14, 35), (18, 40), (22, 43), (26, 50), (31, 56), (35, 65), (39, 71)]
arm_angles = [
    [(1, 110), (5, 92), (8, 146), (11, 162), (14, 155), (18, 124), (23, 115)],
    [(1, 115), (5, 104), (8, 162), (11, 160), (15, 146), (19, 125), (23, 118)],
    [(1, 118), (5, 116), (8, 122), (11, 105), (14, 160), (18, 140), (22, 125), (26, 138), (31, 145), (35, 120), (39, 110)],
]

def delta(pose, initial, name):
    return initial['basis'][name].to_quaternion().inverted() @ pose['basis'][name].to_quaternion()

references = {}
for step, last in enumerate(lengths):
    for frame in range(1, last+1):
        idle = sample(swim, 1 + starts[step] + frame-1)
        if step < 2:
            ref = sample(slash, curve(slash_time[step], frame))
            changes = {n: delta(ref, slash_start, n) for n in ref['basis']}
        else:
            ref = sample(overhead, curve(overhead_time, frame))
            start_ref = sample(slash, 13)
            blend = min(1.0, max(0.0, (frame-1)/7.0))
            recovery = min(1.0, max(0.0, (39-frame)/4.0))
            changes = {
                n: Quaternion().slerp(delta(start_ref, slash_start, n).slerp(delta(ref, overhead_start, n), blend), recovery)
                for n in ref['basis']
            }
            # Carry the return swing's elbow plane into the overhead windup.
            ref = {
                'basis': ref['basis'],
                'head': {n: start_ref['head'][n].lerp(ref['head'][n], blend) for n in ref['head']},
                'pose': {n: start_ref['pose'][n].lerp(ref['pose'][n], blend) for n in ref['pose']},
            }
        references[step, frame] = (idle, ref, changes)

def pole(start, joint, end):
    axis = end-start
    projected = start + axis * ((joint-start).dot(axis) / max(1e-8, axis.length_squared))
    bend = joint-projected
    if bend.length < .005:
        bend = axis.cross(Vector((0, 0, 1)))
    return joint + bend.normalized()*.5

def rotate_basis(bone, initial, change, weight):
    loc, rot, scale = initial.decompose()
    bone.matrix_basis = Matrix.LocRotScale(loc, rot @ Quaternion().slerp(change, weight), scale)

body_weights = {'pelvis': .45, 'spine': .75, 'chest': .85, 'neck': .35, 'head': .35, 'clavicle.R': .9, 'clavicle.L': .35}
leg_names = ['thigh.L', 'shin.L', 'foot.L', 'toe.L', 'thigh.R', 'shin.R', 'foot.R', 'toe.R']
left_names = ['upper_arm.L', 'forearm.L', 'hand.L']
fingers = [n for n in old[0, 1]['basis'] if n.startswith(('thumb.', 'index.', 'middle.', 'ring.', 'pinky.'))]
upper_length = rig.data.bones['upper_arm.R'].length
lower_length = rig.data.bones['forearm.R'].length
left_reach = rig.data.bones['upper_arm.L'].length + rig.data.bones['forearm.L'].length
grip_relative = rig.data.bones['CTRL_SwordHand'].matrix_local.inverted() @ rig.data.bones['CTRL_SecondGrip'].matrix_local
desired_joints = {}
desired_other_joints = {}
generated = {}

for step, last in enumerate(lengths):
    for frame in range(1, last+1):
        saved = old[step, frame]
        idle, ref, changes = references[step, frame]
        rig.animation_data.action = None
        for c in constraints:
            c.mute = True
        for name, matrix in saved['basis'].items():
            rig.pose.bones[name].matrix_basis = matrix
        for name, weight in body_weights.items():
            extra = changes[name]
            if name != 'pelvis':
                extra = delta(idle, swim_start, name).slerp(Quaternion(), .65) @ extra
            rotate_basis(rig.pose.bones[name], saved['basis'][name], extra, weight)
        for name in leg_names:
            rotate_basis(rig.pose.bones[name], idle['basis'][name], changes[name], .38 if name.startswith('thigh') else .23)
        for name in left_names:
            rotate_basis(rig.pose.bones[name], idle['basis'][name], changes[name], .2)
        for name in fingers:
            rig.pose.bones[name].matrix_basis = old[0, 1]['basis'][name]
        bpy.context.view_layer.update()
        # Preserve the original gameplay anchor while the torso turns over it.
        pelvis = rig.pose.bones['pelvis'].matrix.copy()
        pelvis.translation = saved['pose']['pelvis'].translation
        rig.pose.bones['pelvis'].matrix = pelvis
        bpy.context.view_layer.update()
        pelvis = rig.pose.bones['pelvis'].matrix.copy()
        inverse_old = saved['pose']['pelvis'].inverted()
        wrist = pelvis @ inverse_old @ saved['pose']['CTRL_SwordHand']
        shoulder = rig.pose.bones['upper_arm.R'].head.copy()
        axis = (wrist.translation-shoulder).normalized()
        elbow_angle = math.radians(curve(arm_angles[step], frame))
        reach = math.sqrt(upper_length**2 + lower_length**2 - 2*upper_length*lower_length*math.cos(elbow_angle))
        wrist.translation = shoulder + axis*reach
        # The second fist must stay reachable while it follows the sword grip.
        if saved['grip'] > .8:
            left_shoulder = rig.pose.bones['upper_arm.L'].head.copy()
            for _ in range(4):
                second = (wrist @ grip_relative).translation
                difference = second-left_shoulder
                if difference.length <= left_reach*.99:
                    break
                wrist.translation -= difference.normalized() * (difference.length-left_reach*.99)
        axis = (wrist.translation-shoulder).normalized()
        distance = (wrist.translation-shoulder).length
        ref_shoulder = ref['head']['upper_arm.R']
        ref_elbow = ref['head']['forearm.R']
        ref_wrist = ref['head']['hand.R']
        ref_axis = (ref_wrist-ref_shoulder).normalized()
        bend = ref_elbow-ref_shoulder
        bend -= ref_axis*bend.dot(ref_axis)
        bend = pelvis.to_quaternion() @ (ref['pose']['pelvis'].to_quaternion().inverted() @ bend)
        bend -= axis*bend.dot(axis)
        bend.normalize()
        along = (upper_length**2-lower_length**2+distance**2)/(2*distance)
        height = math.sqrt(max(0.0, upper_length**2-along**2))
        elbow = shoulder+axis*along+bend*height
        desired_joints[step, frame] = elbow.copy()
        rig.pose.bones['CTRL_SwordHand'].matrix = wrist
        rig.pose.bones['CTRL_SwordElbow'].matrix = Matrix.Translation(elbow+bend*.5)
        # Derive animated IK targets from the reference-driven FK body pose.
        desired_other_joints[step, frame] = {}
        for end, mid, start, control, pole_name in [
            ('hand.L', 'forearm.L', 'upper_arm.L', 'CTRL_LeftHand', 'CTRL_LeftElbow'),
            ('foot.L', 'shin.L', 'thigh.L', 'CTRL_LeftFoot', 'CTRL_LeftKnee'),
            ('foot.R', 'shin.R', 'thigh.R', 'CTRL_RightFoot', 'CTRL_RightKnee'),
        ]:
            desired_other_joints[step, frame][mid] = rig.pose.bones[mid].head.copy()
            rig.pose.bones[control].matrix = rig.pose.bones[end].matrix.copy()
            rig.pose.bones[pole_name].matrix = Matrix.Translation(pole(rig.pose.bones[start].head, rig.pose.bones[mid].head, rig.pose.bones[end].head))
        grip.influence = saved['grip']
        generated[step, frame] = {b.name: b.matrix_basis.copy() for b in rig.pose.bones}

# Calibrate the sword IK pole to the anatomical bend plane measured above.
for name, basis in generated[0, 1].items():
    rig.pose.bones[name].matrix_basis = basis
for c in constraints:
    c.mute = False
grip.influence = 0
ik = rig.pose.bones['forearm.R'].constraints[0]
best = (float('inf'), ik.pole_angle)
for index in range(180):
    ik.pole_angle = -math.pi + math.tau*index/180
    bpy.context.view_layer.update()
    error = (rig.pose.bones['forearm.R'].head-desired_joints[0, 1]).length
    if error < best[0]:
        best = (error, ik.pole_angle)
ik.pole_angle = best[1]
print('ELBOW_POLE_CALIBRATION', best)
for name, target in desired_other_joints[0, 1].items():
    ik = next(c for c in rig.pose.bones[name].constraints if c.type == 'IK')
    best = (float('inf'), ik.pole_angle)
    for index in range(360):
        ik.pole_angle = -math.pi + math.tau*index/360
        bpy.context.view_layer.update()
        error = (rig.pose.bones[name].head-target).length
        if error < best[0]:
            best = (error, ik.pole_angle)
    ik.pole_angle = best[1]
    print('LIMB_POLE_CALIBRATION', name, best)

for step, last in enumerate(lengths):
    action = bpy.data.actions.new(f'water_combo_{step+1}')
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    for frame in range(1, last+1):
        scene.frame_set(frame)
        for name, basis in generated[step, frame].items():
            bone = rig.pose.bones[name]
            bone.matrix_basis = basis
            bone.rotation_mode = 'QUATERNION'
            if name in previous and bone.rotation_quaternion.dot(previous[name]) < 0:
                bone.rotation_quaternion.negate()
            previous[name] = bone.rotation_quaternion.copy()
            # Sample the rotating finisher: world-space interpolation between
            # sparse targets cuts across the torso's circular path and locks IK.
            # The first two swings retain their sparse editable key poses.
            if step < 2 and name in ('CTRL_SwordHand', 'CTRL_SwordElbow') and frame not in key_frames[step]:
                continue
            if name in fingers and frame != 1:
                continue
            for prop in ('location', 'rotation_quaternion', 'scale'):
                bone.keyframe_insert(prop, frame=frame, group=name)
        grip.influence = old[step, frame]['grip']
        grip.keyframe_insert('influence', frame=frame)
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    for key in fc.keyframe_points:
                        key.interpolation = 'BEZIER'
                        key.handle_left_type = 'AUTO_CLAMPED'
                        key.handle_right_type = 'AUTO_CLAMPED'

rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 23
scene.frame_set(1)
scene['water_combo_notes'] = 'v3 body pass: GroundCombo slash_2 torso/shoulder motion, OverheadAttack attack_1 finisher body, continuous SwimIdle water_idle_1 leg motion. Sword elbow opens through contact and follows a moving pole. Hits 1/2 sword IK keys remain sparse; finisher keys sampled to follow rotating torso without IK locking. Fingers stay closed; second grip retained. Prior v2 actions are reference_v2_*.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
print('WATER_COMBO_V3_SAVED', DEST)
