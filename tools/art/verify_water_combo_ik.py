"""Check that restored IK follows control edits and preserves combo poses."""
from pathlib import Path
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parents[2] / 'ArtSource/Player/Blender/ManualAttacks'
clips = [('water_combo_1', 19), ('water_combo_2', 25), ('water_combo_3', 31)]
bpy.ops.wm.open_mainfile(filepath=str(root / 'Threadborne_Water_Combo_v1.blend'))
rig = bpy.data.objects['Threadborne_Rig']
expected = {}
for name, last in clips:
    rig.animation_data.action = bpy.data.actions[name]
    for frame in range(1, last + 1):
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        expected[name, frame] = (rig.pose.bones['hand.R'].matrix.translation.copy(), rig.pose.bones['forearm.R'].matrix.translation.copy())

bpy.ops.wm.open_mainfile(filepath=str(root / 'Threadborne_Water_Combo_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
assert rig.pose.bones['forearm.R'].constraints.get('Sword arm - hand and elbow controls')
assert rig.pose.bones['hand.R'].constraints.get('Sword orientation from hand control')
assert not rig.data.bones['CTRL_SwordHand'].hide
assert not rig.data.bones['CTRL_SwordElbow'].hide
max_hand = 0.0
max_elbow = 0.0
worst_hand = None
worst_elbow = None
for name, last in clips:
    rig.animation_data.action = bpy.data.actions[name]
    for frame in range(1, last + 1):
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        goal_hand, goal_elbow = expected[name, frame]
        hand_error = (rig.pose.bones['hand.R'].matrix.translation - goal_hand).length
        elbow_error = (rig.pose.bones['forearm.R'].matrix.translation - goal_elbow).length
        if hand_error > max_hand:
            max_hand, worst_hand = hand_error, (name, frame)
        if elbow_error > max_elbow:
            max_elbow, worst_elbow = elbow_error, (name, frame)
rig.animation_data.action = bpy.data.actions['water_combo_1']
bpy.context.scene.frame_set(10)
bpy.context.view_layer.update()
before = rig.pose.bones['hand.R'].matrix.translation.copy()
ctrl = rig.pose.bones['CTRL_SwordHand']
ctrl.location += Vector((0.1, 0.25, 0.0))
bpy.context.view_layer.update()
moved = (rig.pose.bones['hand.R'].matrix.translation - before).length
elbow_before = rig.pose.bones['forearm.R'].matrix.translation.copy()
pole = rig.pose.bones['CTRL_SwordElbow']
pole.location += Vector((0.0, 0.0, 0.4))
bpy.context.view_layer.update()
elbow_moved = (rig.pose.bones['forearm.R'].matrix.translation - elbow_before).length
print('IK_ERRORS', max_hand, worst_hand, max_elbow, worst_elbow, 'EDIT_MOVED_HAND', moved, 'ELBOW_MOVED', elbow_moved)
assert moved > 0.05, 'Hand box must drive the hand.'
assert elbow_moved > 0.001, 'Elbow diamond must steer the bend.'
assert max_hand < 0.10 and max_elbow < 0.17, 'The IK pass altered the combo poses too far.'
