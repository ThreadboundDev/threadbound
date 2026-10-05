"""Check new limb controls and preservation of the saved sword motion."""
from pathlib import Path
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parents[2] / 'ArtSource/Player/Blender/ManualAttacks'
clips = [('water_combo_1', 19), ('water_combo_2', 25), ('water_combo_3', 31)]
ends = ('hand.R', 'hand.L', 'foot.L', 'foot.R', 'forearm.L', 'shin.L', 'shin.R')
bpy.ops.wm.open_mainfile(filepath=str(root / 'Threadborne_Water_Combo_IK_Grip.blend'))
rig = bpy.data.objects['Threadborne_Rig']
expected = {}
for clip, last in clips:
    rig.animation_data.action = bpy.data.actions[clip]
    for frame in range(1, last + 1):
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        expected[clip, frame] = {name: rig.pose.bones[name].head.copy() for name in ends}

bpy.ops.wm.open_mainfile(filepath=str(root / 'Threadborne_Water_Combo_Full_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
for name in ('CTRL_SwordHand', 'CTRL_SwordElbow', 'CTRL_LeftHand', 'CTRL_LeftElbow',
             'CTRL_LeftFoot', 'CTRL_LeftKnee', 'CTRL_RightFoot', 'CTRL_RightKnee'):
    assert not rig.data.bones[name].hide
    assert rig.pose.bones[name].custom_shape
errors = {name: (0.0, None) for name in ends}
for clip, last in clips:
    rig.animation_data.action = bpy.data.actions[clip]
    for frame in range(1, last + 1):
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        for name in ends:
            error = (rig.pose.bones[name].head - expected[clip, frame][name]).length
            if error > errors[name][0]:
                errors[name] = (error, (clip, frame))
rig.animation_data.action = bpy.data.actions['water_combo_1']
bpy.context.scene.frame_set(10)
for label, end in [('LeftHand', 'hand.L'), ('LeftFoot', 'foot.L'), ('RightFoot', 'foot.R')]:
    ctrl = rig.pose.bones['CTRL_' + label]
    bpy.context.view_layer.update()
    before = rig.pose.bones[end].head.copy()
    ctrl.location += Vector((0.1, 0.1, 0.0))
    bpy.context.view_layer.update()
    moved = (rig.pose.bones[end].head - before).length
    print('CONTROL_MOVED', label, moved)
    assert moved > 0.05, label + ' control does not drive its limb'
    ctrl.location -= Vector((0.1, 0.1, 0.0))
print('POSE_ERRORS', errors)
assert errors['hand.R'][0] < 0.001, 'Saved sword animation changed'
assert max(errors[name][0] for name in ('forearm.L', 'shin.L', 'shin.R')) < 0.15, 'A knee or elbow flips too far from the saved pose'
