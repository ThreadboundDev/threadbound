"""Check the requested arm plane/reach and exact preservation of v3 body keys."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v4_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
controls = ('CTRL_SwordHand', 'CTRL_SwordElbow')

def unchanged_curves(action):
    return {
        (fc.data_path, fc.array_index): tuple((tuple(k.co), tuple(k.handle_left), tuple(k.handle_right), k.interpolation) for k in fc.keyframe_points)
        for layer in action.layers for strip in layer.strips for bag in strip.channelbags for fc in bag.fcurves
        if not any(f'pose.bones["{name}"]' in fc.data_path for name in controls)
    }

rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_set(1)
base = rig.pose.bones['pelvis'].matrix.to_quaternion()
for step, last in [(1, 23), (2, 23), (3, 39)]:
    new = bpy.data.actions[f'water_combo_{step}']
    old = bpy.data.actions[f'reference_v3_water_combo_{step}']
    assert unchanged_curves(new) == unchanged_curves(old), 'Body, fingers or grip curves changed'
    rig.animation_data.action = new
    worst_plane = 1.0
    angles = {}
    last_wrist = None
    speeds = []
    for frame in range(1, last+1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        shoulder = rig.pose.bones['upper_arm.R'].head.copy()
        elbow = rig.pose.bones['forearm.R'].head.copy()
        hand = rig.pose.bones['hand.R'].head.copy()
        axis = (hand-shoulder).normalized()
        turn = rig.pose.bones['pelvis'].matrix.to_quaternion() @ base.inverted()
        desired = (turn @ Vector((1, 0, 0))).cross(axis).normalized()
        bend = elbow-shoulder
        bend -= axis*bend.dot(axis)
        worst_plane = min(worst_plane, bend.normalized().dot(desired))
        angle = math.degrees((shoulder-elbow).angle(hand-elbow))
        angles[frame] = angle
        assert 100 < angle < 179.5, ('Arm fold or singular extension', step, frame, angle)
        wrist = (rig.pose.bones['forearm.R'].matrix.to_quaternion().inverted()
                 @ rig.pose.bones['hand.R'].matrix.to_quaternion())
        if last_wrist:
            speeds.append((frame, math.degrees(2*math.acos(min(1, abs(wrist.dot(last_wrist)))))))
        last_wrist = wrist
    assert worst_plane > .97, ('Elbow outside forward swing plane', step, worst_plane)
    assert max(value for _, value in speeds) < 40, ('Wrist rotation snap', step, speeds)
    if step == 1:
        assert 145 < angles[5] < 160
        assert min(angles[f] for f in range(11, 24)) > 172
    if step == 2:
        assert min(angles[f] for f in range(1, 12)) > 172
        assert 150 < angles[23] < 160
    print('ARM_PASS', step, 'worst_plane_dot', worst_plane, 'largest_wrist_steps', sorted(speeds, key=lambda p: p[1])[-3:])
print('WATER_COMBO_V4_PASS: original body curves preserved; forward elbow plane; long follow-through')
