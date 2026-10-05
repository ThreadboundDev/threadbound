"""Save an IK combo copy with one fixed sword grip for every strike."""
from pathlib import Path
import sys
import bpy

root = Path(__file__).resolve().parents[2] / 'ArtSource/Player/Blender/ManualAttacks'
source = root / 'Threadborne_Water_Combo_IK.blend'
dest = root / 'Threadborne_Water_Combo_IK_Grip.blend'
assert not dest.exists() or '--replace-generated' in sys.argv, 'Grip workspace already exists; preserve edits in it.'

bpy.ops.wm.open_mainfile(filepath=str(root / 'Threadborne_Water_Attacks_Workspace.blend'))
rig = bpy.data.objects['Threadborne_Rig']
rig.animation_data.action = bpy.data.actions['water_attack_idle']
bpy.context.scene.frame_set(8)
bpy.context.view_layer.update()
fingers = {
    bone.name: bone.rotation_quaternion.copy()
    for bone in rig.pose.bones
    if bone.name.endswith(('.R', '.L'))
    and any(bone.name.startswith(prefix) for prefix in ('thumb.', 'index.', 'middle.', 'ring.', 'pinky.'))
}
assert len(fingers) == 30

bpy.ops.wm.open_mainfile(filepath=str(source))
rig = bpy.data.objects['Threadborne_Rig']
for name in ('water_combo_1', 'water_combo_2', 'water_combo_3'):
    action = bpy.data.actions[name]
    rig.animation_data.action = action
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in list(bag.fcurves):
                    if any(f'pose.bones["{bone_name}"]' in curve.data_path for bone_name in fingers):
                        bag.fcurves.remove(curve)
    bpy.context.scene.frame_set(1)
    for bone_name, grip in fingers.items():
        bone = rig.pose.bones[bone_name]
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = grip
        bone.keyframe_insert('rotation_quaternion', frame=1, group=bone_name)
    bpy.context.view_layer.update()

rig.animation_data.action = bpy.data.actions['water_combo_1']
bpy.context.scene.frame_set(1)
bpy.context.scene['water_combo_notes'] = 'Fixed sword grip: both hands hold the source slash frame-8 finger poses throughout all three actions. Animate arm with the hand box and elbow diamond; finger motion is intentionally absent.'
bpy.ops.wm.save_as_mainfile(filepath=str(dest), compress=True)
print('WATER_COMBO_GRIP_SAVED', dest)
