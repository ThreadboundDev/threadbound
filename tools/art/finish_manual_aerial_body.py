"""Add a supporting body pass to the saved user slash, in a separate Blend.

Run with Blender --background --python. Never modifies the input workspace.
"""
from pathlib import Path
import bpy
import json
import math
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
DIRECTORY = ROOT / 'ArtSource/Player/Blender/ManualAttacks'
SOURCE = DIRECTORY / 'Threadborne_Aerial_Attacks_Workspace.blend'
DEST = DIRECTORY / 'Threadborne_Aerial_Attacks_FullBody.blend'
assert not DEST.exists(), 'Refusing to overwrite an existing body pass'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
rig = bpy.data.objects['Threadborne_Rig']
action = rig.animation_data.action
assert action.name == 'air_attack_forward'

def curves(a):
    return [f for layer in a.layers for strip in layer.strips
            for bag in strip.channelbags for f in bag.fcurves]

def fingerprint(f):
    return (f.data_path, f.array_index, tuple(
        (tuple(k.co), tuple(k.handle_left), tuple(k.handle_right),
         k.interpolation, k.handle_left_type, k.handle_right_type)
        for k in f.keyframe_points))

# Support changes in rig-space degrees: pitch X, yaw Z, roll Y.
frames = [1, 5, 8, 10, 12, 18, 24]
offsets = {
    'pelvis':      [(0,0,0),(-3,-3,0),(6,4,0),(7,5,0),(4,4,0),(-1,-1,0),(0,0,0)],
    'spine':      [(0,0,0),(-6,-5,0),(12,6,0),(13,7,0),(8,5,0),(-2,-2,0),(0,0,0)],
    'chest':      [(0,0,0),(-8,-7,0),(10,7,0),(8,8,0),(5,5,0),(-2,-2,0),(0,0,0)],
    'neck':       [(0,0,0),(5,3,0),(-7,-5,0),(-8,-5,0),(-5,-3,0),(1,1,0),(0,0,0)],
    'head':       [(0,0,0),(3,2,0),(-5,-3,0),(-6,-3,0),(-3,-2,0),(1,0,0),(0,0,0)],
    'clavicle.L': [(0,0,0),(0,3,-3),(0,-5,6),(0,-6,7),(0,-4,4),(0,1,-1),(0,0,0)],
    'upper_arm.L':[(0,0,0),(-4,8,-6),(8,-10,14),(10,-12,16),(6,-7,10),(-2,2,-2),(0,0,0)],
    'forearm.L':  [(0,0,0),(-5,0,0),(8,0,0),(10,0,0),(5,0,0),(-2,0,0),(0,0,0)],
    'hand.L':     [(0,0,0),(2,0,0),(-4,0,0),(-5,0,0),(-3,0,0),(1,0,0),(0,0,0)],
    'thigh.R':    [(0,0,0),(-7,0,0),(-12,0,0),(-15,0,0),(-9,0,0),(3,0,0),(0,0,0)],
    'shin.R':     [(0,0,0),(5,0,0),(8,0,0),(10,0,0),(6,0,0),(-2,0,0),(0,0,0)],
    'foot.R':     [(0,0,0),(-3,0,0),(-5,0,0),(-6,0,0),(-4,0,0),(1,0,0),(0,0,0)],
    'thigh.L':    [(0,0,0),(4,0,0),(-5,0,0),(-8,0,0),(-6,0,0),(2,0,0),(0,0,0)],
    'shin.L':     [(0,0,0),(-4,0,0),(5,0,0),(8,0,0),(6,0,0),(-2,0,0),(0,0,0)],
    'foot.L':     [(0,0,0),(2,0,0),(-4,0,0),(-5,0,0),(-3,0,0),(1,0,0),(0,0,0)],
}
modified_paths = {rig.pose.bones[n].path_from_id('rotation_quaternion') for n in offsets}
protected = [fingerprint(f) for f in curves(action) if f.data_path not in modified_paths]
other_actions = {a.name: [fingerprint(f) for f in curves(a)] for a in bpy.data.actions if a != action}
assert any(len(f.keyframe_points) > 2 for f in curves(action)
           if 'CTRL_SwordHand' in f.data_path), 'User arm keys are missing'
baseline = {}
for frame in frames:
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    baseline[frame] = {n: (rig.pose.bones[n].rotation_quaternion.copy(),
                           rig.pose.bones[n].matrix.to_quaternion().copy()) for n in offsets}

for i, frame in enumerate(frames):
    scene.frame_set(frame)
    for name, samples in offsets.items():
        bone = rig.pose.bones[name]
        q, orientation = baseline[frame][name]
        result = q.copy()
        for axis, degrees in zip([(1,0,0),(0,0,1),(0,1,0)], samples[i]):
            local_axis = orientation.inverted() @ Vector(axis)
            result = result @ Quaternion(local_axis, math.radians(degrees))
        if result.dot(q) < 0:
            result.negate()
        bone.rotation_quaternion = result.normalized()
        bone.keyframe_insert('rotation_quaternion', frame=frame, group=name)
for f in curves(action):
    if f.data_path in modified_paths:
        for k in f.keyframe_points:
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
assert protected == [fingerprint(f) for f in curves(action) if f.data_path not in modified_paths]
assert other_actions == {a.name: [fingerprint(f) for f in curves(a)] for a in bpy.data.actions if a != action}

# Validate the complete action, including subframes and the loop seam.
worst_error = 0
for half in range(2, 49):
    scene.frame_set(half // 2, subframe=(half % 2) * .5)
    bpy.context.view_layer.update()
    worst_error = max(worst_error, (rig.pose.bones['hand.R'].head - rig.pose.bones['CTRL_SwordHand'].head).length)
    assert all(math.isfinite(v) for b in rig.pose.bones for row in b.matrix for v in row)
scene.frame_set(1)
first = {b.name: b.matrix.copy() for b in rig.pose.bones}
scene.frame_set(24)
seam = max(abs(first[b.name][i][j] - b.matrix[i][j]) for b in rig.pose.bones for i in range(4) for j in range(4))
assert seam < .0001, seam
scene.frame_set(8)
scene['body_pass_notes'] = 'User sword-hand/elbow curves preserved exactly. Supporting torso, shield, head and leg motion; original workspace untouched.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
print('FULL_BODY_PASS', json.dumps({'file':str(DEST), 'action':action.name,
      'loop_seam_error':seam, 'max_hand_target_error':worst_error, 'protected_curves':len(protected)}))
