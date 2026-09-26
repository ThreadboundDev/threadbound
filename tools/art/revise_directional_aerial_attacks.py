"""Author up/down IK attacks in a new file; retain the approved forward clip."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
DIR = ROOT / 'ArtSource/Player/Blender/ManualAttacks'
DEST = DIR / 'Threadborne_Aerial_Attacks_Directional_v2.blend'
assert not DEST.exists(), 'Refusing to overwrite an existing directional workspace'
bpy.ops.wm.open_mainfile(filepath=str(DIR / 'Threadborne_Aerial_Attacks_FullBody.blend'))
r = bpy.data.objects['Threadborne_Rig']
s = bpy.context.scene
forward = bpy.data.actions['air_attack_forward']
r.animation_data.action = forward

def curves(a):
    return [f for l in a.layers for st in l.strips for bag in st.channelbags for f in bag.fcurves]

def fingerprint(a):
    return [(f.data_path, f.array_index, [(tuple(k.co), tuple(k.handle_left), tuple(k.handle_right), k.interpolation) for k in f.keyframe_points]) for f in curves(a)]

approved = fingerprint(forward)
s.frame_set(1)
base = {b.name: b.matrix_basis.copy() for b in r.pose.bones}
world_rot = {b.name: b.matrix.to_quaternion().copy() for b in r.pose.bones}
ready_hand = r.pose.bones['CTRL_SwordHand'].matrix.copy()
ready_pole = r.pose.bones['CTRL_SwordElbow'].matrix.copy()
# Use the actual sword geometry to determine the blade axis in hand space.
s.frame_set(8)
sword = bpy.data.objects['Threadborne_Sword']
hand = r.pose.bones['hand.R']
grip = r.matrix_world @ hand.head
tip = max(sword.data.vertices, key=lambda v: ((sword.matrix_world @ v.co)-grip).length)
blade_axis = hand.matrix.to_quaternion().inverted() @ (sword.matrix_world @ tip.co-grip).normalized()
reference_rotation = r.pose.bones['CTRL_SwordHand'].matrix.to_quaternion().copy()
frames = [1,5,8,10,12,18,24]
configs = {
 'up': {
  'reach': [None,(-.12,-.20,.02),(-.10,-.20,.54),(-.10,-.20,.54),(-.12,-.20,.30),None,None],
  'blade': [None,(0,0,1),(0,0,1),(0,0,1),(0,0,1),None,None],
  'pitch': [0,4,-10,-10,-5,1,0],
  'twist': [0,-3,2,2,1,0,0],
 },
 'down': {
  'reach': [None,(-.16,-.27,.19),(-.10,-.12,-.575),(-.10,-.12,-.575),(-.15,-.20,-.43),None,None],
  'blade': [None,(0,-.45,-.89),(0,-.06,-1),(0,-.06,-1),(0,-.25,-.97),None,None],
  'pitch': [0,-8,20,20,12,-2,0],
  'twist': [0,-5,5,6,3,-1,0],
 }
}
reports = {}
for direction, cfg in configs.items():
    name = 'air_attack_' + direction
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    a = bpy.data.actions.new(name)
    a.use_fake_user = True
    r.animation_data.action = a
    previous = {}
    for i, frame in enumerate(frames):
        s.frame_set(frame)
        for b in r.pose.bones:
            b.matrix_basis = base[b.name]
        pitch, twist = cfg['pitch'][i], cfg['twist'][i]
        strength = [0,.65,1,1,.65,.10,0][i]
        rotations = {
            'pelvis': (pitch*.15,twist*.2,0),
            'spine': (pitch*.4,twist*.35,0),
            'chest': (pitch*.45,twist*.45,0),
            'neck': (-pitch*.15,-twist*.2,0),
            'head': ((-6 if direction=='up' else 5)*strength,-twist*.15,0),
            'upper_arm.L': (4*strength,-8*strength,12*strength),
            'forearm.L': (5*strength,0,0),
            'thigh.R': ((-7 if direction=='up' else -55)*strength,0,0),
            'shin.R': ((7 if direction=='up' else 65)*strength,0,0),
            'thigh.L': ((5 if direction=='up' else -9)*strength,0,0),
            'shin.L': ((6 if direction=='up' else 28)*strength,0,0),
            'foot.R': (-4*strength,0,0),
            'foot.L': (-3*strength,0,0),
        }
        for bone, angles in rotations.items():
            b = r.pose.bones[bone]
            q = b.rotation_quaternion.copy()
            for axis, angle in zip([(1,0,0),(0,0,1),(0,1,0)], angles):
                q = q @ Quaternion(world_rot[bone].inverted() @ Vector(axis), math.radians(angle))
            b.rotation_quaternion = q
        bpy.context.view_layer.update()
        if cfg['reach'][i] is not None:
            shoulder = r.pose.bones['upper_arm.R'].head.copy()
            control = r.pose.bones['CTRL_SwordHand']
            desired = Vector(cfg['blade'][i]).normalized()
            q = (reference_rotation @ blade_axis).rotation_difference(desired) @ reference_rotation
            matrix = q.to_matrix().to_4x4()
            matrix.translation = shoulder + Vector(cfg['reach'][i])
            control.matrix = matrix
            pole = ready_pole.copy()
            pole.translation = shoulder + Vector((-.65,.05,-.30) if direction=='up' else (-.75,-.03,.10))
            r.pose.bones['CTRL_SwordElbow'].matrix = pole
        else:
            r.pose.bones['CTRL_SwordHand'].matrix = ready_hand
            r.pose.bones['CTRL_SwordElbow'].matrix = ready_pole
        for b in r.pose.bones:
            q = b.rotation_quaternion.copy()
            if b.name in previous and q.dot(previous[b.name]) < 0:
                q.negate()
                b.rotation_quaternion = q
            previous[b.name] = q.copy()
            for prop in ['location','rotation_quaternion','scale']:
                b.keyframe_insert(prop,frame=frame,group=b.name)
    for f in curves(a):
        for k in f.keyframe_points:
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
    maximum_error = 0
    for half in range(2,49):
        s.frame_set(half//2,subframe=(half%2)*.5)
        bpy.context.view_layer.update()
        maximum_error = max(maximum_error,(r.pose.bones['hand.R'].head-r.pose.bones['CTRL_SwordHand'].head).length)
        assert all(math.isfinite(v) for b in r.pose.bones for row in b.matrix for v in row)
    s.frame_set(1)
    start = {b.name:b.matrix.copy() for b in r.pose.bones}
    s.frame_set(24)
    seam = max(abs(start[b.name][i][j]-b.matrix[i][j]) for b in r.pose.bones for i in range(4) for j in range(4))
    assert seam < .0001, (direction,seam)
    assert maximum_error < .035, (direction,maximum_error)
    reports[direction] = {'max_ik_error':maximum_error,'loop_seam':seam}
assert approved == fingerprint(forward), 'Approved forward action changed'
r.animation_data.action = bpy.data.actions['air_attack_up']
s.frame_set(8)
s['directional_attack_notes'] = 'Approved forward action unchanged. Up: chambered vertical thrust. Down: extended stab with tucked legs. 30fps, frames1-24. Not yet exported to Godot.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST),compress=True)
print('DIRECTIONAL_ATTACKS',json.dumps(reports))

