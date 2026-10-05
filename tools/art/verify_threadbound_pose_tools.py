"""Exercise the sidebar operators in a disposable session; never save source."""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
import threadbound_pose_tools as addon

if not hasattr(bpy.types, 'THREADBOUND_PT_pose_tools'):
    addon.register()
assert not bpy.ops.pose.threadbound_reset_sword_arm.poll()
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v3_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
rig.hide_set(False)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
assert not bpy.ops.pose.threadbound_reset_sword_arm.poll()
bpy.ops.object.mode_set(mode='POSE')
assert bpy.ops.pose.threadbound_reset_sword_arm.poll()


def key_data(action):
    return {
        (fc.data_path, fc.array_index): tuple((tuple(k.co), tuple(k.handle_left), tuple(k.handle_right)) for k in fc.keyframe_points)
        for layer in action.layers for strip in layer.strips
        for bag in strip.channelbags for fc in bag.fcurves
    }


def error(a, b):
    return max(abs(a[row][col]-b[row][col]) for row in range(4) for col in range(4))


for step, frames in [(1, [1, 5, 11, 18, 23]), (2, [1, 8, 15, 23]), (3, [1, 8, 14, 22, 26, 31, 39])]:
    action = bpy.data.actions[f'water_combo_{step}']
    rig.animation_data.action = action
    keys = key_data(action)
    for frame in frames:
        bpy.context.scene.frame_set(frame)
        bpy.context.scene.tool_settings.use_keyframe_insert_auto = True
        rig.pose.bones['CTRL_SwordHand'].location += Vector((3, 2, 1))
        rig.pose.bones['CTRL_SwordElbow'].location += Vector((-2, -3, 2))
        rig.pose.bones['forearm.R'].scale = (2, 2, 2)
        rig.pose.bones['upper_arm.R'].rotation_quaternion = (0, 1, 0, 0)
        bpy.context.view_layer.update()
        untouched = {b.name: b.matrix_basis.copy() for b in rig.pose.bones if b.name not in addon.RESET_BONES}
        body = {n: rig.pose.bones[n].matrix.copy() for n in ('pelvis', 'spine', 'chest', 'clavicle.R', 'head')}
        shoulder = rig.pose.bones[addon.ANCHOR].matrix.copy()
        assert bpy.ops.pose.threadbound_reset_sword_arm() == {'FINISHED'}
        assert bpy.context.scene.frame_current == frame
        assert rig.animation_data.action == action
        assert key_data(action) == keys, 'Reset must not modify keys, even with Auto Key enabled'
        assert all(error(rig.pose.bones[n].matrix_basis, mat) < 1e-5 for n, mat in untouched.items()), 'Unrelated transforms changed'
        assert all(error(rig.pose.bones[n].matrix, mat) < 1e-5 for n, mat in body.items()), 'Body moved'
        for name in addon.CONTROLS:
            assert error(rig.pose.bones[name].matrix, addon.ready_control_matrices(rig)[name]) < 1e-5
        gap = (rig.pose.bones['hand.R'].head-rig.pose.bones['CTRL_SwordHand'].head).length
        assert gap < .005, ('IK target unreachable', gap)
        shoulder_pos = rig.pose.bones['upper_arm.R'].head
        elbow = rig.pose.bones['forearm.R'].head
        wrist = rig.pose.bones['hand.R'].head
        angle = math.degrees((shoulder_pos-elbow).angle(wrist-elbow))
        assert 60 < angle < 150, ('Reset arm must have a usable bend', angle)
        pose = {n: rig.pose.bones[n].matrix_basis.copy() for n in addon.RESET_BONES}
        bpy.ops.pose.threadbound_reset_sword_arm()
        assert all(error(rig.pose.bones[n].matrix_basis, mat) < 1e-5 for n, mat in pose.items()), 'Reset must be repeatable'
    print('RESET_POSES_PASS', step, frames, 'elbow', round(angle, 1))

# Explicit keying persists exactly the arm pose, without touching body curves.
action = bpy.data.actions['water_combo_1'].copy()
rig.animation_data.action = action
bpy.context.scene.frame_set(11)
bpy.ops.pose.threadbound_reset_sword_arm()
before = key_data(action)
pose = {n: rig.pose.bones[n].matrix_basis.copy() for n in addon.RESET_BONES}
assert bpy.ops.pose.threadbound_key_sword_arm() == {'FINISHED'}
after = key_data(action)
allowed = tuple('pose.bones["%s"].' % n for n in addon.RESET_BONES)
assert all(after[k] == data for k, data in before.items() if not k[0].startswith(allowed))
bpy.context.scene.frame_set(12)
bpy.context.scene.frame_set(11)
assert all(error(rig.pose.bones[n].matrix_basis, mat) < 1e-5 for n, mat in pose.items()), 'Keyed reset did not persist'
assert 'UNDO' in addon.THREADBOUND_OT_reset_sword_arm.bl_options
assert 'UNDO' in addon.THREADBOUND_OT_key_sword_arm.bl_options
# Exercise undo itself, not just the operator declaration. Explicit undo pushes
# bracket the operation because this test runs from a background Python script.
rig.pose.bones['CTRL_SwordHand'].location += Vector((.2, 0, 0))
bpy.context.view_layer.update()
before_undo = rig.pose.bones['CTRL_SwordHand'].matrix_basis.copy()
bpy.ops.ed.undo_push(message='Before sword arm reset')
bpy.ops.pose.threadbound_reset_sword_arm()
bpy.ops.ed.undo_push(message='Sword arm reset')
assert bpy.ops.ed.undo() == {'FINISHED'}
restored = bpy.data.objects['Threadborne_Rig'].pose.bones['CTRL_SwordHand'].matrix_basis
assert error(restored, before_undo) < 1e-5, 'Undo did not restore the previous arm pose'
print('POSE_TOOLS_UNDO_PASS')
print('THREADBOUND_POSE_TOOLS_PASS: reset, body/finger/key preservation, Auto Key safety, keyed persistence, pose-mode polling')
