"""Add editable IK to the free arm and both legs in a new combo workspace.

Reads the latest saved grip workspace, including the user's sword edits. The
existing sword controls and action keys are retained. Does not overwrite input.
"""
from pathlib import Path
import sys
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parents[2] / 'ArtSource/Player/Blender/ManualAttacks'
source = root / 'Threadborne_Water_Combo_IK_Grip.blend'
dest = root / 'Threadborne_Water_Combo_Full_IK.blend'
assert not dest.exists() or '--replace-generated' in sys.argv, 'Full IK workspace exists; keep edits made there.'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
clips = [('water_combo_1', 19), ('water_combo_2', 25), ('water_combo_3', 31)]
limbs = [
    ('LeftHand', 'upper_arm.L', 'forearm.L', 'hand.L', 'LeftElbow'),
    ('LeftFoot', 'thigh.L', 'shin.L', 'foot.L', 'LeftKnee'),
    ('RightFoot', 'thigh.R', 'shin.R', 'foot.R', 'RightKnee'),
]

def pole_position(start: Vector, joint: Vector, end: Vector) -> Vector:
    axis = end - start
    projection = start + axis * ((joint - start).dot(axis) / max(axis.length_squared, 1e-8))
    bend = joint - projection
    if bend.length < 0.01:
        bend = axis.cross(Vector((0, 1, 0)))
    return joint + bend.normalized() * 0.45

cache = {}
for clip, last in clips:
    rig.animation_data.action = bpy.data.actions[clip]
    cache[clip] = {}
    for frame in range(1, last + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        cache[clip][frame] = {
            label: {
                'end': rig.pose.bones[end].matrix.copy(),
                'joint': rig.pose.bones[joint].head.copy(),
                'pole': pole_position(
                    rig.pose.bones[start].head,
                    rig.pose.bones[joint].head,
                    rig.pose.bones[end].head,
                ),
            }
            for label, start, joint, end, _ in limbs
        }

if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for label, start, joint, end, pole_label in limbs:
    end_rest = rig.data.edit_bones[end]
    ctrl = rig.data.edit_bones.new('CTRL_' + label)
    ctrl.matrix = end_rest.matrix.copy()
    ctrl.length = 0.16
    ctrl.use_deform = False
    pole = rig.data.edit_bones.new('CTRL_' + pole_label)
    rest_start = rig.data.edit_bones[start].head
    rest_joint = rig.data.edit_bones[joint].head
    pole.head = pole_position(rest_start, rest_joint, end_rest.head)
    pole.tail = pole.head + Vector((0, 0, 0.14))
    pole.use_deform = False
bpy.ops.object.mode_set(mode='POSE')

collection = rig.data.collections.get('IK controls • optional')
for label, _, _, _, pole_label in limbs:
    for name in ('CTRL_' + label, 'CTRL_' + pole_label):
        rig.data.bones[name].hide = False
        if collection:
            collection.assign(rig.data.bones[name])
if collection:
    collection.is_visible = True
hand_shape = bpy.data.objects.get('CONTROL_SHAPE_hand')
pole_shape = bpy.data.objects.get('CONTROL_SHAPE_elbow')
for label, _, _, _, pole_label in limbs:
    ctrl = rig.pose.bones['CTRL_' + label]
    pole = rig.pose.bones['CTRL_' + pole_label]
    ctrl.custom_shape = hand_shape
    pole.custom_shape = pole_shape
    ctrl.custom_shape_scale_xyz = (0.7, 0.7, 0.7)
    pole.custom_shape_scale_xyz = (0.65, 0.65, 0.65)
    rig.data.bones[ctrl.name].color.palette = 'THEME04' if 'Foot' in label else 'THEME03'
    rig.data.bones[pole.name].color.palette = 'THEME09'

# Set and key the new controllers while those limbs are still unconstrained.
for clip, frames in cache.items():
    rig.animation_data.action = bpy.data.actions[clip]
    previous_rotation = {}
    for frame, targets in frames.items():
        scene.frame_set(frame)
        for label, _, _, _, pole_label in limbs:
            target = targets[label]
            ctrl = rig.pose.bones['CTRL_' + label]
            pole = rig.pose.bones['CTRL_' + pole_label]
            ctrl.rotation_mode = 'QUATERNION'
            pole.rotation_mode = 'QUATERNION'
            ctrl.matrix = target['end']
            pole_matrix = pole.matrix.copy()
            pole_matrix.translation = target['pole']
            pole.matrix = pole_matrix
            bpy.context.view_layer.update()
            for bone in (ctrl, pole):
                if bone.name in previous_rotation and bone.rotation_quaternion.dot(previous_rotation[bone.name]) < 0:
                    bone.rotation_quaternion.negate()
                previous_rotation[bone.name] = bone.rotation_quaternion.copy()
                for prop in ('location', 'rotation_quaternion', 'scale'):
                    bone.keyframe_insert(prop, frame=frame, group=bone.name)

# Fewer, evenly spaced controller beats let edits flow across nearby frames.
# Keep all of the user's existing sword controls and body keys untouched.
new_controls = {
    'CTRL_' + name
    for label, _, _, _, pole_label in limbs
    for name in (label, pole_label)
}
for clip, last in clips:
    action = bpy.data.actions[clip]
    keep = set(range(1, last + 1, 2)) | {last}
    control_curves = [
        curve for layer in action.layers for strip in layer.strips
        for bag in strip.channelbags for curve in bag.fcurves
        if any(f'pose.bones["{name}"]' in curve.data_path for name in new_controls)
    ]
    # Preserve extra poses wherever straight interpolation would visibly
    # alter the orbit of an IK target (especially mid-spin).
    for curve in control_curves:
        values = {round(key.co.x): key.co.y for key in curve.keyframe_points}
        threshold = 0.025 if 'location' in curve.data_path else 0.02
        for frame in range(1, last + 1):
            if frame in keep:
                continue
            left = max(k for k in keep if k < frame)
            right = min(k for k in keep if k > frame)
            predicted = values[left] + (values[right] - values[left]) * (frame - left) / (right - left)
            if abs(values[frame] - predicted) > threshold:
                keep.add(frame)
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    if not any(f'pose.bones["{name}"]' in curve.data_path for name in new_controls):
                        continue
                    for key in list(curve.keyframe_points):
                        if round(key.co.x) not in keep:
                            curve.keyframe_points.remove(key)
                    for key in curve.keyframe_points:
                        key.interpolation = 'LINEAR'
                    curve.update()

for label, _, joint, end, pole_label in limbs:
    ik = rig.pose.bones[joint].constraints.new('IK')
    ik.name = 'Editable ' + label + ' IK'
    ik.target = rig
    ik.subtarget = 'CTRL_' + label
    ik.pole_target = rig
    ik.pole_subtarget = 'CTRL_' + pole_label
    ik.chain_count = 2
    ik.iterations = 100
    ik.use_stretch = False
    # Find the pole twist that best preserves the first saved pose.
    rig.animation_data.action = bpy.data.actions['water_combo_1']
    scene.frame_set(1)
    best = (float('inf'), 0.0)
    import math
    for step in range(72):
        angle = -math.pi + math.tau * step / 72
        ik.pole_angle = angle
        bpy.context.view_layer.update()
        error = (rig.pose.bones[joint].head - cache['water_combo_1'][1][label]['joint']).length
        if error < best[0]:
            best = (error, angle)
    ik.pole_angle = best[1]
    copy = rig.pose.bones[end].constraints.new('COPY_ROTATION')
    copy.name = 'Orientation from ' + label + ' control'
    copy.target = rig
    copy.subtarget = 'CTRL_' + label
    copy.owner_space = 'POSE'
    copy.target_space = 'POSE'

rig.show_in_front = True
rig.data.display_type = 'STICK'
rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 19
scene.frame_set(1)
scene['water_combo_notes'] = 'Full limb IK: sword hand/elbow, free hand/elbow, both feet/knees. Move pelvis for whole-body spin/flip. All three combo actions have keyed controls. Right and left finger poses stay fixed.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(dest), compress=True)
print('WATER_COMBO_FULL_IK_SAVED', dest)
