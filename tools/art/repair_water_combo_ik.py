"""Convert the baked combo workspace to editable sword hand and elbow IK.

Creates a separate .blend so edits in the baked source are preserved.
"""
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
source = ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v1.blend'
dest = ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_IK.blend'
assert not dest.exists(), 'The IK workspace already exists; keep any edits made there.'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
actions = [(name, last) for name, last in [('water_combo_1', 19), ('water_combo_2', 25), ('water_combo_3', 31)]]
hand_offset = Matrix.Translation(Vector((-0.0698958, 0.0409245, 0.0347923)))
pole_offset = Vector((-0.4112252, 0.2538112, 0.3302110))

# The old actions contain every evaluated joint pose. Keep that source and add
# control keys which place the hand target and elbow pole on the same path.
cache = {}
for name, last in actions:
    rig.animation_data.action = bpy.data.actions[name]
    frames = {}
    for frame in range(1, last + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        frames[frame] = {
            'hand': rig.pose.bones['hand.R'].matrix.copy(),
            'elbow': rig.pose.bones['forearm.R'].matrix.copy(),
            'pelvis': rig.pose.bones['pelvis'].matrix.copy(),
        }
    cache[name] = frames

base_pelvis = cache['water_combo_1'][1]['pelvis'].to_quaternion()
for name, frames in cache.items():
    rig.animation_data.action = bpy.data.actions[name]
    for frame, pose in frames.items():
        scene.frame_set(frame)
        hand = rig.pose.bones['CTRL_SwordHand']
        pole = rig.pose.bones['CTRL_SwordElbow']
        hand.matrix = pose['hand'] @ hand_offset
        pole_rotation = pose['pelvis'].to_quaternion() @ base_pelvis.inverted()
        pole_matrix = pole.matrix.copy()
        pole_matrix.translation = pose['elbow'].translation + pole_rotation @ pole_offset
        pole.matrix = pole_matrix
        bpy.context.view_layer.update()
        for ctrl in [hand, pole]:
            ctrl.rotation_mode = 'QUATERNION'
            for prop in ['location', 'rotation_quaternion', 'scale']:
                ctrl.keyframe_insert(prop, frame=frame, group=ctrl.name)

ik = rig.pose.bones['forearm.R'].constraints.new('IK')
ik.name = 'Sword arm - hand and elbow controls'
ik.target = rig
ik.subtarget = 'CTRL_SwordHand'
ik.pole_target = rig
ik.pole_subtarget = 'CTRL_SwordElbow'
ik.chain_count = 2
ik.use_stretch = False
ik.iterations = 100
ik.pole_angle = 0.21816615760326385
rotation = rig.pose.bones['hand.R'].constraints.new('COPY_ROTATION')
rotation.name = 'Sword orientation from hand control'
rotation.target = rig
rotation.subtarget = 'CTRL_SwordHand'
rotation.owner_space = 'POSE'
rotation.target_space = 'POSE'

for collection in rig.data.collections:
    if collection.name.startswith('IK controls'):
        collection.is_visible = True
for bone in rig.data.bones:
    bone.hide = bone.name not in {
        'CTRL_SwordHand', 'CTRL_SwordElbow', 'pelvis', 'spine', 'chest', 'neck', 'head',
        'upper_arm.L', 'forearm.L', 'hand.L', 'thigh.R', 'thigh.L', 'shin.R',
        'shin.L', 'foot.R', 'foot.L',
    }
rig.show_in_front = True
rig.data.display_type = 'STICK'
rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 19
scene.frame_set(1)
bpy.context.view_layer.update()
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
if bpy.context.object and bpy.context.object.mode != 'POSE':
    bpy.ops.object.mode_set(mode='POSE')
scene['water_combo_notes'] = 'Editable sword IK: move/rotate CTRL_SwordHand box; move CTRL_SwordElbow diamond to steer the bend. Three actions water_combo_1/2/3. Other body keys remain editable.'
bpy.ops.wm.save_as_mainfile(filepath=str(dest), compress=True)
print('WATER_COMBO_IK_SAVED', dest)
