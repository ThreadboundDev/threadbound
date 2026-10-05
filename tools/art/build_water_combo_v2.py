"""Author the down/up/two-handed flip combo as sparse, editable IK poses."""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / 'ArtSource/Player/Blender/ManualAttacks'
DEST = FOLDER / 'Threadborne_Water_Combo_v2_IK.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve edits in the v2 workspace.'
bpy.ops.wm.open_mainfile(filepath=str(FOLDER / 'Threadborne_Water_Combo_Full_IK.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
scene.render.fps = 30
rig.animation_data.use_nla = False
rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_set(1)
bpy.context.view_layer.update()
sword = bpy.data.objects['Threadborne_Sword']
sword_relative = rig.pose.bones['hand.R'].matrix.to_quaternion().inverted() @ sword.matrix_world.to_quaternion()
right_grip = {b.name: b.rotation_quaternion.copy() for b in rig.pose.bones if b.name.endswith('.R') and b.name.startswith(('thumb.', 'index.', 'middle.', 'ring.', 'pinky.'))}

# Mirror the closed sword fingers through the armature's rest transforms.
# This works in background mode without depending on viewport selection.
mirror = Matrix.Diagonal(Vector((-1, 1, 1, 1)))
left_grip = {}
for name in right_grip:
    right = rig.pose.bones[name]
    left = rig.pose.bones[name[:-1] + 'L']
    desired = mirror @ right.matrix @ mirror
    desired_parent = mirror @ right.parent.matrix @ mirror
    rest_local = left.parent.bone.matrix_local.inverted() @ left.bone.matrix_local
    left_grip[left.name] = (rest_local.inverted() @ desired_parent.inverted() @ desired).to_quaternion()
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')

# Sample the actual swim idle with IK temporarily muted, then make that the
# held base for the new actions. User-authored actions stay in this file as refs.
for bone in rig.pose.bones:
    for constraint in bone.constraints:
        constraint.mute = True
idle = bpy.data.actions.get('water_idle_1')
if idle is None:
    with bpy.data.libraries.load(str(ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'), link=False) as (_, loaded):
        loaded.actions = ['water_idle_1']
    idle = loaded.actions[0]
rig.animation_data.action = idle
scene.frame_set(1)
bpy.context.view_layer.update()
base_basis = {b.name: b.matrix_basis.copy() for b in rig.pose.bones}
base_pose = {b.name: b.matrix.copy() for b in rig.pose.bones}
pivot = base_pose['pelvis'].translation.copy()
for bone in rig.pose.bones:
    for constraint in bone.constraints:
        constraint.mute = False
for number in range(1, 4):
    bpy.data.actions[f'water_combo_{number}'].name = f'reference_previous_water_combo_{number}'

def blade_rotation(angle):
    rad = math.radians(angle)
    direction = Vector((0, -math.cos(rad), math.sin(rad)))
    z = -direction
    x = Vector((-1, 0, 0))
    y = z.cross(x)
    sword_rotation = Matrix((x, y, z)).transposed().to_quaternion()
    return sword_rotation @ sword_relative.inverted()

def at(position, rotation):
    return Matrix.LocRotScale(Vector(position), rotation, Vector((1, 1, 1)))

# The second fist grips below the sword fist. Derive wrist placement from the
# mirrored finger pose and keep it attached through an editable helper target.
for name, q in {**right_grip, **left_grip}.items():
    rig.pose.bones[name].rotation_quaternion = q
bpy.context.view_layer.update()
right_center = sum((rig.pose.bones[n].head for n in ('index.02.R', 'middle.02.R', 'ring.02.R')), Vector()) / 3
left_center = sum((rig.pose.bones[n].head for n in ('index.02.L', 'middle.02.L', 'ring.02.L')), Vector()) / 3
right_grip_local = rig.pose.bones['hand.R'].matrix.inverted() @ right_center
left_grip_local = rig.pose.bones['hand.L'].matrix.inverted() @ left_center
q_right = blade_rotation(90)
reflect = Matrix.Diagonal(Vector((-1, 1, 1)))
q_left = (reflect @ q_right.to_matrix() @ reflect).to_quaternion()
right_matrix = at((0, 0, 0), q_right)
left_position = q_right @ right_grip_local - Vector((0, 0, 0.10)) - q_left @ left_grip_local
grip_relative = right_matrix.inverted() @ at(left_position, q_left)
bpy.ops.object.mode_set(mode='EDIT')
helper = rig.data.edit_bones.new('CTRL_SecondGrip')
helper.matrix = rig.data.edit_bones['CTRL_SwordHand'].matrix @ grip_relative
helper.length = 0.12
helper.parent = rig.data.edit_bones['CTRL_SwordHand']
helper.use_deform = False
bpy.ops.object.mode_set(mode='POSE')
helper = rig.pose.bones['CTRL_SecondGrip']
helper.custom_shape = bpy.data.objects.get('CONTROL_SHAPE_hand')
helper.custom_shape_scale_xyz = (0.5, 0.5, 0.5)
rig.data.bones[helper.name].color.palette = 'THEME06'
collection = rig.data.collections.get('IK controls • optional')
if collection:
    collection.assign(rig.data.bones[helper.name])
    collection.is_visible = True
grip_constraint = rig.pose.bones['CTRL_LeftHand'].constraints.new('COPY_TRANSFORMS')
grip_constraint.name = 'Second hand follows sword grip'
grip_constraint.target = rig
grip_constraint.subtarget = 'CTRL_SecondGrip'
grip_constraint.owner_space = 'POSE'
grip_constraint.target_space = 'POSE'
grip_constraint.influence = 0.0

def pose(hand, blade, lean=0, chest=0, twist=0, flip=0, tuck=0, grip=0):
    return dict(hand=hand, blade=blade, lean=lean, chest=chest, twist=twist, flip=flip, tuck=tuck, grip=grip)

ready = pose((-.28, -.46, 1.39), 35)
low = pose((-.29, -.23, 1.00), -65, lean=4, chest=3, twist=-5, tuck=.02)
high = pose((-.19, -.27, 1.72), 105, lean=-4, chest=-3, twist=4, tuck=.02)
clips = [
    [(1, ready), (5, pose((-.24, -.24, 1.72), 115, lean=-7, chest=-5, twist=8)),
     (8, pose((-.25, -.49, 1.62), 65, lean=-2, chest=-2, twist=4)),
     (11, pose((-.27, -.70, 1.27), -10, lean=9, chest=7, twist=-6, tuck=.05)),
     (14, pose((-.28, -.45, 1.03), -80, lean=12, chest=8, twist=-10, tuck=.10)),
     (18, low), (23, low)],
    [(1, low), (5, pose((-.29, -.18, .98), -80, lean=7, chest=5, twist=-8, tuck=.03)),
     (8, pose((-.27, -.68, 1.24), -10, lean=4, chest=3, twist=-3, tuck=.05)),
     (11, pose((-.24, -.57, 1.60), 55, lean=-4, chest=-3, twist=4, tuck=.05)),
     (15, pose((-.19, -.24, 1.75), 110, lean=-9, chest=-6, twist=8, tuck=.07)),
     (19, high), (23, high)],
    [(1, high), (5, pose((-.15, -.25, 1.73), 112, lean=-6, chest=-5, tuck=.04, grip=.25)),
     (8, pose((-.08, -.26, 1.72), 120, lean=-8, chest=-6, tuck=.07, grip=1)),
     (11, pose((-.08, -.12, 1.70), 140, lean=-12, chest=-7, tuck=.10, grip=1)),
     (14, pose((-.08, -.62, 1.42), 0, flip=30, chest=9, tuck=.17, grip=1)),
     (18, pose((-.08, -.48, 1.20), -55, flip=100, chest=8, tuck=.24, grip=1)),
     (22, pose((-.08, -.47, 1.20), -55, flip=190, chest=6, tuck=.26, grip=1)),
     (26, pose((-.08, -.50, 1.28), -35, flip=285, chest=4, tuck=.19, grip=1)),
     (31, pose((-.12, -.44, 1.26), -40, flip=360, chest=3, tuck=.08, grip=1)),
     (35, pose((-.25, -.47, 1.35), 15, flip=360, tuck=.02, grip=0)),
     (39, dict(ready, flip=360))],
]

animated = ['pelvis', 'spine', 'chest', 'neck', 'head', 'CTRL_SwordHand', 'CTRL_SwordElbow',
            'CTRL_LeftHand', 'CTRL_LeftElbow', 'CTRL_LeftFoot', 'CTRL_LeftKnee', 'CTRL_RightFoot', 'CTRL_RightKnee']

def set_pose(data):
    for name, basis in base_basis.items():
        rig.pose.bones[name].matrix_basis = basis
    for name, q in {**right_grip, **left_grip}.items():
        rig.pose.bones[name].rotation_mode = 'QUATERNION'
        rig.pose.bones[name].rotation_quaternion = q
    turn = Matrix.Rotation(math.radians(data['flip'] + data['lean']), 4, 'X') @ Matrix.Rotation(math.radians(data['twist']), 4, 'Z')
    world = Matrix.Translation(pivot) @ turn @ Matrix.Translation(-pivot)
    rig.pose.bones['pelvis'].matrix = world @ base_pose['pelvis']
    bpy.context.view_layer.update()
    for name, amount in [('spine', .45), ('chest', .55), ('neck', -.18), ('head', -.12)]:
        bone = rig.pose.bones[name]
        location = bone.matrix.translation.copy()
        rotation = turn @ Matrix.Rotation(math.radians(data['chest'] * amount), 4, 'X') @ turn.inverted()
        bone.matrix = Matrix.Translation(location) @ rotation @ Matrix.Translation(-location) @ bone.matrix
        bpy.context.view_layer.update()
    rig.pose.bones['CTRL_SwordHand'].matrix = world @ at(data['hand'], blade_rotation(data['blade']))
    # Poles steer elbows outside the torso, leaving a clear sword silhouette.
    for name, position in [('CTRL_SwordElbow', (-.68, -.10, 1.35)), ('CTRL_LeftElbow', (.65, -.1, 1.4))]:
        rig.pose.bones[name].matrix = world @ Matrix.Translation(Vector(position))
    shield_hand = base_pose['hand.L'].copy()
    shield_hand.translation = Vector((.25, -.47, 1.32 + .05 * data['grip']))
    rig.pose.bones['CTRL_LeftHand'].matrix = world @ shield_hand
    for side, label in [('L', 'Left'), ('R', 'Right')]:
        foot = base_pose['foot.' + side].copy()
        foot.translation += Vector((0, .18 * data['tuck'], data['tuck']))
        rig.pose.bones['CTRL_' + label + 'Foot'].matrix = world @ foot
        knee = base_pose['shin.' + side].translation + Vector((0, -.45, .03))
        rig.pose.bones['CTRL_' + label + 'Knee'].matrix = world @ Matrix.Translation(knee)
    grip_constraint.influence = data['grip']
    bpy.context.view_layer.update()

for number, poses in enumerate(clips, 1):
    action = bpy.data.actions.new(f'water_combo_{number}')
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    for frame, data in poses:
        scene.frame_set(frame)
        set_pose(data)
        for bone in rig.pose.bones:
            if frame != 1 and bone.name not in animated:
                continue
            bone.rotation_mode = 'QUATERNION'
            if bone.name in previous and bone.rotation_quaternion.dot(previous[bone.name]) < 0:
                bone.rotation_quaternion.negate()
            previous[bone.name] = bone.rotation_quaternion.copy()
            for prop in ('location', 'rotation_quaternion', 'scale'):
                bone.keyframe_insert(prop, frame=frame, group=bone.name)
        grip_constraint.keyframe_insert('influence', frame=frame)
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:
                        key.interpolation = 'BEZIER'
                        key.handle_left_type = 'AUTO_CLAMPED'
                        key.handle_right_type = 'AUTO_CLAMPED'
    print('AUTHORED', action.name, 'frames', poses[-1][0])

rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 23
scene.frame_set(1)
scene.timeline_markers.clear()
for frame, label in [(1, 'READY'), (5, 'RAISE'), (11, 'CUT'), (18, 'RIGHT HIP')]:
    scene.timeline_markers.new(label, frame=frame)
for bone in rig.data.bones:
    bone.hide = not (bone.name.startswith('CTRL_') or bone.name in ('pelvis', 'spine', 'chest', 'neck', 'head'))
    rig.pose.bones[bone.name].select = bone.name == 'CTRL_SwordHand'
rig.data.bones.active = rig.data.bones['CTRL_SwordHand']
scene['water_combo_notes'] = 'v2: 1 downward one-hand cut (1-23), 2 upward return cut (1-23), 3 two-handed downward strike/front flip (1-39). 30 FPS, sparse IK keys. CTRL_SecondGrip is the editable second-hand attachment; its left-hand constraint influence is keyed on hit 3. Earlier manual actions retained as reference_previous_*.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
print('WATER_COMBO_V2_SAVED', DEST)
