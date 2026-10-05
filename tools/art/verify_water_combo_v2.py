"""Validate pose continuity, constant grips, and two-hand contact in v2."""
from pathlib import Path
import sys
import math
import bpy

root = Path(__file__).resolve().parents[2]
source = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'Threadborne_Water_Combo_v2_IK.blend'
bpy.ops.wm.open_mainfile(filepath=str(root / 'ArtSource/Player/Blender/ManualAttacks' / source))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
fingers = [b.name for b in rig.pose.bones if b.name.startswith(('thumb.', 'index.', 'middle.', 'ring.', 'pinky.'))]
endpoint = {}
reach = {'right': 0.0, 'left': 0.0}
anchor = None
angles = {}
for step, length in [(1, 23), (2, 23), (3, 39)]:
    rig.animation_data.action = bpy.data.actions[f'water_combo_{step}']
    reference = None
    for frame in range(1, length + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        shoulder = rig.pose.bones['upper_arm.R'].head
        elbow = rig.pose.bones['forearm.R'].head
        wrist = rig.pose.bones['hand.R'].head
        angles[step, frame] = math.degrees((shoulder-elbow).angle(wrist-elbow))
        rotations = {name: rig.pose.bones[name].rotation_quaternion.copy() for name in fingers}
        if reference is None:
            reference = rotations
        assert all(abs(rotations[n].dot(reference[n])) > .99999 for n in fingers), 'Fingers must hold their grip'
        if anchor is None:
            anchor = rig.pose.bones['pelvis'].head.copy()
        assert (rig.pose.bones['pelvis'].head - anchor).length < .001, 'Pelvis must remain anchored'
        if step == 3 and 8 <= frame <= 31:
            reach['right'] = max(reach['right'], (rig.pose.bones['hand.R'].head - rig.pose.bones['CTRL_SwordHand'].head).length)
            reach['left'] = max(reach['left'], (rig.pose.bones['hand.L'].head - rig.pose.bones['CTRL_SecondGrip'].head).length)
        if frame in (1, length):
            endpoint[step, frame] = {b.name: b.matrix.copy() for b in rig.pose.bones if b.bone.use_deform}
for left, right in [((1, 23), (2, 1)), ((2, 23), (3, 1))]:
    difference = max((endpoint[left][name].translation - endpoint[right][name].translation).length for name in endpoint[left])
    print('CHAIN_POSITION_ERROR', left, right, difference)
    assert difference < .002, 'Combo transitions must use matching poses'
print('TWO_HAND_REACH_ERROR', reach)
assert max(reach.values()) < .035, 'Both hands must reach the sword during the two-handed section'
for step, length in [(1, 23), (2, 23), (3, 39)]:
    print('ELBOW_INTERIOR_ANGLE', step, [(frame, round(angles[step, frame], 1)) for frame in range(1, length+1, 3)])
if 'v3' in source:
    print('LARGEST_ELBOW_ANGLES', sorted(angles.items(), key=lambda item: item[1])[-5:])
    assert max(angles.values()) < 175, 'Sword elbow must not lock straight between poses'
    for step in (1, 2):
        assert angles[step, 5] < 125, 'Arm must bend to load the strike'
        assert max(angles[step, f] for f in range(8, 15)) > 145, 'Arm must extend through the strike'
print('WATER_COMBO_POSES_PASS', source)
