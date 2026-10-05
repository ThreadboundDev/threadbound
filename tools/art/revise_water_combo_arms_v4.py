"""Arm-only follow-up: forward elbow plane, long follow-through, neutral wrists.

Preserves every saved v3 body/leg/finger curve. Never regenerates the body pass.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / 'ArtSource/Player/Blender/ManualAttacks'
DEST = FOLDER / 'Threadborne_Water_Combo_v4_IK.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Do not overwrite manual v4 edits.'
bpy.ops.wm.open_mainfile(filepath=str(FOLDER / 'Threadborne_Water_Combo_v3_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
rig.animation_data.use_nla = False
lengths = [23, 23, 39]
snapshots = {}
originals = []
for step, length in enumerate(lengths):
    action = bpy.data.actions[f'water_combo_{step+1}']
    originals.append(action)
    rig.animation_data.action = action
    for frame in range(1, length+1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        snapshots[step, frame] = {
            'pose': {b.name: b.matrix.copy() for b in rig.pose.bones},
            'basis': {b.name: b.matrix_basis.copy() for b in rig.pose.bones},
        }

sword_relative = (rig.pose.bones['hand.R'].matrix.to_quaternion().inverted()
                  @ rig.matrix_world.to_quaternion().inverted()
                  @ bpy.data.objects['Threadborne_Sword'].matrix_world.to_quaternion())
blade_local = sword_relative @ Vector((0, 0, -1))
paths = {}
for step, length in enumerate(lengths):
    rig.animation_data.action = bpy.data.actions[f'reference_v2_water_combo_{step+1}']
    for frame in range(1, length+1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        paths[step, frame] = (rig.pose.bones['pelvis'].matrix.inverted()
                              @ rig.pose.bones['CTRL_SwordHand'].matrix)

def curve(points, frame):
    for (a, x), (b, y) in zip(points, points[1:]):
        if frame <= b:
            t = max(0.0, min(1.0, (frame-a)/(b-a)))
            t = t*t*(3-2*t)
            return x+(y-x)*t
    return points[-1][1]

# Open overhead load, then keep the arm long through the follow-through.
# A tiny bend at full reach avoids an ambiguous IK plane at exactly 180 deg.
angles = [
    [(1, 110), (5, 150), (8, 167), (11, 177), (14, 177), (18, 176), (23, 174)],
    [(1, 174), (5, 174), (8, 177), (11, 177), (15, 165), (19, 155), (23, 155)],
    [(1, 155), (5, 155), (8, 152), (11, 150), (14, 173), (18, 176), (22, 176), (26, 174), (31, 170), (35, 140), (39, 110)],
]

# Sample the wrist's orientation relative to the forearm from the existing
# two-handed overhead attack, not a world-space blade angle during a full flip.
constraints = [c for b in rig.pose.bones for c in b.constraints]
old_mutes = [c.mute for c in constraints]
for c in constraints:
    c.mute = True
ref = bpy.data.actions.get('BODY_REFERENCE_OverheadAttack')
if ref is None:
    with bpy.data.libraries.load(str(ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'), link=False) as (_, loaded):
        loaded.actions = ['attack_1']
    ref = loaded.actions[0]
    ref.name = 'BODY_REFERENCE_OverheadAttack'
ref.use_fake_user = True
rig.animation_data.action = ref
wrist_reference = {}
ref_times = [(1, 15), (8, 22), (11, 28), (14, 36), (18, 40), (22, 43), (26, 50), (31, 56), (35, 65), (39, 71)]
for frame in range(1, 40):
    at = curve(ref_times, frame)
    scene.frame_set(int(at), subframe=at-int(at))
    bpy.context.view_layer.update()
    wrist_reference[frame] = (rig.pose.bones['forearm.R'].matrix.to_quaternion().inverted()
                              @ rig.pose.bones['hand.R'].matrix.to_quaternion())
for c, mute in zip(constraints, old_mutes):
    c.mute = mute

base_pelvis = snapshots[0, 1]['pose']['pelvis'].to_quaternion()
a = rig.data.bones['upper_arm.R'].length
b = rig.data.bones['forearm.R'].length
left_reach = rig.data.bones['upper_arm.L'].length + rig.data.bones['forearm.L'].length
path_keys = [[1, 5, 8, 11, 14, 18, 23], [1, 5, 8, 11, 15, 19, 23], [1, 5, 8, 11, 14, 18, 22, 26, 31, 35, 39]]
directions = {}
for step, keys in enumerate(path_keys):
    for frame in keys:
        saved = snapshots[step, frame]
        pelvis = saved['pose']['pelvis']
        delta = (pelvis @ paths[step, frame]).translation-saved['pose']['upper_arm.R'].translation
        directions[step, frame] = pelvis.to_quaternion().inverted() @ delta.normalized()

def arm_path(step, frame, pelvis):
    # Interpolate the arm's direction on an arc, not a straight hand segment
    # cutting through its own shoulder at the overhead-to-downstroke change.
    keys = path_keys[step]
    for first, last in zip(keys, keys[1:]):
        if frame <= last:
            t = (frame-first)/(last-first)
            qa = paths[step, first].to_quaternion()
            qb = paths[step, last].to_quaternion()
            direction = directions[step, first]
            turn = direction.rotation_difference(directions[step, last])
            axis = Quaternion().slerp(turn, t) @ direction
            return pelvis.to_quaternion() @ qa.slerp(qb, t), pelvis.to_quaternion() @ axis
grip_relative = (rig.data.bones['CTRL_SwordHand'].matrix_local.inverted()
                 @ rig.data.bones['CTRL_SecondGrip'].matrix_local)
grip = rig.pose.bones['CTRL_LeftHand'].constraints['Second hand follows sword grip']
ik = next(c for c in rig.pose.bones['forearm.R'].constraints if c.type == 'IK')

def set_targets(wrist, saved):
    shoulder = rig.pose.bones['upper_arm.R'].head.copy()
    axis = (wrist.translation-shoulder).normalized()
    turn = saved['pose']['pelvis'].to_quaternion() @ base_pelvis.inverted()
    # At overhead: elbow points forward. Through the cut it follows the same
    # sagittal plane instead of sticking out laterally toward the camera.
    lateral = turn @ Vector((1, 0, 0))
    bend = lateral.cross(axis).normalized()
    distance = min(a+b-.000001, (wrist.translation-shoulder).length)
    along = (a*a-b*b+distance*distance)/(2*distance)
    height = math.sqrt(max(0.0, a*a-along*along))
    elbow = shoulder+axis*along+bend*height
    rig.pose.bones['CTRL_SwordHand'].matrix = wrist
    rig.pose.bones['CTRL_SwordElbow'].matrix = Matrix.Translation(elbow+bend*.55)
    bpy.context.view_layer.update()
    return elbow

for step, length in enumerate(lengths):
    original = originals[step]
    original.name = f'reference_v3_water_combo_{step+1}'
    original.use_fake_user = True
    action = original.copy()
    action.name = f'water_combo_{step+1}'
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    previous_roll = 0.0
    for frame in range(1, length+1):
        scene.frame_set(frame)
        saved = snapshots[step, frame]
        # Existing non-arm curves are evaluated and never keyed or replaced.
        bpy.context.view_layer.update()
        shoulder = rig.pose.bones['upper_arm.R'].head.copy()
        # Use the preserved continuous blade path. The saved v3 hand keys have
        # isolated >90-degree rotation jumps; keep that source as a reference,
        # but do not carry those discontinuities into this arm revision.
        authored, axis = arm_path(step, frame, saved['pose']['pelvis'])
        wrist = Matrix.LocRotScale(shoulder, authored, Vector((1, 1, 1)))
        theta = math.radians(curve(angles[step], frame))
        reach = math.sqrt(a*a+b*b-2*a*b*math.cos(theta))
        wrist.translation = shoulder+axis*reach
        wanted_elbow = set_targets(wrist, saved)
        if step == 0 and frame == 1:
            best = (float('inf'), ik.pole_angle)
            for index in range(720):
                ik.pole_angle = -math.pi+math.tau*index/720
                bpy.context.view_layer.update()
                error = (rig.pose.bones['forearm.R'].head-wanted_elbow).length
                if error < best[0]:
                    best = (error, ik.pole_angle)
            ik.pole_angle = best[1]
            bpy.context.view_layer.update()
            print('FORWARD_POLE_CALIBRATION', best)
        if step == 2:
            influence = curve([(1, 0), (8, 1), (31, 1), (39, 0)], frame)
            # Recompute after correcting reach so the left fist stays attached
            # and within its reach without imposing a fixed world wrist roll.
            for _ in range(8):
                set_targets(wrist, saved)
                natural = rig.pose.bones['forearm.R'].matrix.to_quaternion() @ wrist_reference[frame]
                # Keep the blade's authored downstroke. Only borrow axial roll:
                # copying the entire wrist rotation reverses the sword at load.
                relative = authored.inverted() @ natural
                roll = 2*math.atan2(Vector((relative.x, relative.y, relative.z)).dot(blade_local), relative.w)
                roll = (roll+math.pi) % math.tau-math.pi
                roll = max(-math.pi/3, min(math.pi/3, roll))*influence
                # Do not let a reference roll seam become a visible wrist snap.
                roll = previous_roll+max(-math.radians(12), min(math.radians(12), roll-previous_roll))
                rotation = authored @ Quaternion(blade_local, roll)
                wrist = Matrix.LocRotScale(wrist.translation, rotation, Vector((1, 1, 1)))
                if grip.influence > .8:
                    other = (wrist @ grip_relative).translation
                    offset = other-rig.pose.bones['upper_arm.L'].head
                    if offset.length > left_reach*.995:
                        wrist.translation -= offset.normalized()*(offset.length-left_reach*.995)
            previous_roll = roll
        set_targets(wrist, saved)
        for name in ('CTRL_SwordHand', 'CTRL_SwordElbow'):
            bone = rig.pose.bones[name]
            bone.rotation_mode = 'QUATERNION'
            if name in previous and previous[name].dot(bone.rotation_quaternion) < 0:
                bone.rotation_quaternion.negate()
            previous[name] = bone.rotation_quaternion.copy()
            for prop in ('location', 'rotation_quaternion', 'scale'):
                bone.keyframe_insert(prop, frame=frame, group=name)
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    if not any(f'pose.bones["{n}"]' in fc.data_path for n in ('CTRL_SwordHand', 'CTRL_SwordElbow')):
                        continue
                    for key in fc.keyframe_points:
                        key.interpolation = 'BEZIER'
                        key.handle_left_type = 'AUTO_CLAMPED'
                        key.handle_right_type = 'AUTO_CLAMPED'

rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 23
scene.frame_set(1)
scene['water_combo_notes'] = 'v4 arm-only revision from saved v3. Original body, legs, fingers and grip keys unchanged. Elbow bends forward at top; near-full extension held through cut and follow-through. Finisher wrist follows existing overhead attack relative to forearm. Original actions retained as reference_v3_*. All-limb IK and Reset Sword Arm add-on retained.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
print('WATER_COMBO_V4_SAVED', DEST)
