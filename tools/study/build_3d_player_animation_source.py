"""Author a separate, editable 3D Ruin locomotion source; production data is read only.

The 20-frame run has alternating planted feet/flight phases, narrow tracking,
forward knee poles and bent, close-to-body arm swing. IK is baked for runtime;
muted constraints and keyed controls remain in the saved Blender source.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
OUT = WORK / 'project/assets/ruin_3d_demo.glb'
SOURCE = WORK / 'source/Threadborne_3D_Demo.blend'
SOURCE.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = 30
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.import_scene.gltf(filepath=str(WORK / 'source/Threadborne_Pre3D_Reference.glb'))
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
rig.animation_data_create()
for track in rig.animation_data.nla_tracks: track.mute = True
base = next(t.strips[0].action for t in rig.animation_data.nla_tracks if t.name == 'run_1')
rig.animation_data.action = base
if base.slots: rig.animation_data.action_slot = base.slots[0]
scene.frame_set(1)
bpy.context.view_layer.update()
rest = {b.name:b.matrix_local.copy() for b in rig.data.bones}
base_pose = {p.name:p.matrix_basis.copy() for p in rig.pose.bones}
# Use the original unarmed wrist attitude; the IK controls own arm positions.
hand_rotations = {side:(rig.matrix_world @ rig.data.bones['hand.'+side].matrix_local).to_quaternion() for side in ['L','R']}
rig.animation_data.action = None
for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()
sword=bpy.data.objects['Study_Sword']
axis=max(range(3),key=lambda i:max(v.co[i] for v in sword.data.vertices)-min(v.co[i] for v in sword.data.vertices))
local_axis=Vector((0,0,0));local_axis[axis]=-1
rest_blade=(sword.matrix_world.to_3x3() @ local_axis).normalized()
hand_rotations['R']=rest_blade.rotation_difference(Vector((0,.40,-.9165)).normalized()) @ hand_rotations['R']

controls = bpy.data.collections.new('3D locomotion controls — unmute IK to edit')
scene.collection.children.link(controls)
helpers = []
constraints = []

def empty(name, position):
    ob = bpy.data.objects.new(name,None)
    controls.objects.link(ob)
    ob.empty_display_type = 'SPHERE'
    ob.empty_display_size = .06
    ob.location = position
    helpers.append(ob)
    return ob


def ik_chain(name, bone, position, pole_position):
    target = empty(name+' target',position)
    pole = empty(name+' pole',pole_position)
    constraint = rig.pose.bones[bone].constraints.new('IK')
    constraint.name = name+' — editable 3D source'
    constraint.target = target
    constraint.pole_target = pole
    constraint.chain_count = 2
    constraint.use_stretch = False
    constraints.append(constraint)
    return target,pole,constraint


legs, arms, rotations = {}, {}, {}
for side,sign in [('L',1),('R',-1)]:
    legs[side] = ik_chain(side+' athletic leg','shin.'+side,(sign*.115,-.25,.13),(sign*.14,-1.2,.55))
    arms[side] = ik_chain(side+' running arm','forearm.'+side,(sign*.28,-.12,1.04),(sign*.62,.14,1.1))
    for bone,rot in [('foot.'+side,rest['foot.'+side].to_quaternion()),('hand.'+side,hand_rotations[side])]:
        target = empty(bone+' orientation',Vector((0,0,0)))
        target.rotation_mode = 'QUATERNION'
        target.rotation_quaternion = rot
        constraint = rig.pose.bones[bone].constraints.new('COPY_ROTATION')
        constraint.target = target
        constraint.target_space = 'WORLD'
        constraint.owner_space = 'WORLD'
        constraints.append(constraint)
        rotations[bone] = target

# Choose pole angles by the evaluated knee/elbow direction, not by rig naming.
for side,sign in [('L',1),('R',-1)]:
    for chain, joint, preferred in [(legs[side],'shin.'+side,Vector((0,-1,0))),
                                     (arms[side],'forearm.'+side,Vector((sign,0.4,0)))]:
        best = (-1e9,0.0)
        for angle in [0,math.pi/2,math.pi,-math.pi/2]:
            chain[2].pole_angle = angle
            bpy.context.view_layer.update()
            score = rig.pose.bones[joint].head.dot(preferred)
            if score>best[0]: best=(score,angle)
        chain[2].pole_angle=best[1]


def frame_pose(phase):
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
        if any(pb.name.startswith(finger+'.') for finger in ['index','middle','ring','pinky']):
            side=pb.name[-1]
            across=(rig.data.bones['index.01.'+side].head_local-rig.data.bones['pinky.01.'+side].head_local).normalized()
            joint=int(pb.name.split('.')[1])-1
            q=Quaternion(-across,[.85,1.15,.85][joint])
            axis=pb.bone.matrix_local.to_quaternion()
            pb.rotation_mode='QUATERNION';pb.rotation_quaternion=axis.inverted() @ q @ axis
        elif pb.name.startswith('thumb.'):
            pb.matrix_basis=base_pose[pb.name]
    pelvis = rig.pose.bones['pelvis']
    # Lower hips at support, lift through flight, without a lateral sway.
    bounce = .035*math.cos(phase*math.tau*2)
    world = rest['pelvis'].copy()
    world.translation += Vector((.005*math.sin(phase*math.tau),0,-.18+bounce))
    world = world @ Quaternion((0,1,0),.025*math.sin(phase*math.tau)).to_matrix().to_4x4()
    pelvis.matrix = world
    for bone in ['spine','chest']:
        pb=rig.pose.bones[bone]
        # Global forward lean, distributed through the torso.
        correction=Quaternion((1,0,0),.065)
        pb.rotation_mode='QUATERNION'
        axis=pb.bone.matrix_local.to_quaternion()
        pb.rotation_quaternion=axis.inverted() @ correction @ axis
    for side,sign,offset in [('L',1,0),('R',-1,.5)]:
        t=(phase+offset)%1
        contact=.35
        if t<contact:
            ratio=t/contact
            forward=.52-1.08*ratio
            lift=.13+.055*ratio**3
            pitch=.20*ratio
        else:
            ratio=(t-contact)/(1-contact)
            forward=-.56+1.08*(ratio*ratio*(3-2*ratio))
            lift=.13+.39*math.sin(math.pi*ratio)**1.15
            pitch=-.32*math.sin(math.pi*ratio)
        legs[side][0].location=(sign*.115,-forward,lift)
        rotations['foot.'+side].rotation_quaternion=Quaternion((1,0,0),pitch) @ rest['foot.'+side].to_quaternion()
        swing=math.cos(t*math.tau)
        arms[side][0].location=(sign*.285,.19*swing,1.045+.10*max(0,-swing))
        rotations['hand.'+side].rotation_quaternion=hand_rotations[side]
    bpy.context.view_layer.update()


samples=[]
poses=[]
for frame in range(1,22):
    phase=(frame-1)/20.0
    scene.frame_set(frame)
    frame_pose(phase)
    evaluated=rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
    poses.append({p.name:p.matrix.copy() for p in evaluated.pose.bones})
    row={'frame':frame,'feet':{},'knees':{}}
    for side in ['L','R']:
        row['feet'][side]=list(evaluated.pose.bones['foot.'+side].head)
        row['knees'][side]=list(evaluated.pose.bones['shin.'+side].head)
    samples.append(row)
    for ob in helpers:
        ob.keyframe_insert('location',frame=frame)
        if ob.rotation_mode=='QUATERNION':ob.keyframe_insert('rotation_quaternion',frame=frame)

for constraint in constraints: constraint.mute=True
action=bpy.data.actions.new('Ruin_3D_Athletic_Run')
rig.animation_data.action=action
for frame,pose in enumerate(poses,1):
    scene.frame_set(frame)
    for pb in rig.pose.bones:
        kwargs=dict(parent_matrix=pose[pb.parent.name],parent_matrix_local=pb.parent.bone.matrix_local) if pb.parent else {}
        pb.matrix_basis=pb.bone.convert_local_to_pose(pose[pb.name],pb.bone.matrix_local,invert=True,**kwargs)
        pb.rotation_mode='QUATERNION'
        for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=pb.name)
action.use_fake_user=True
rig.animation_data.action=None
track=rig.animation_data.nla_tracks.new()
track.name='demo_run'
track.strips.new('demo_run',1,action)
for track in rig.animation_data.nla_tracks:track.mute=False
for ob in helpers: ob.hide_render=True
scene.frame_start=1;scene.frame_end=21;scene.frame_set(1)
text=bpy.data.texts.new('READ ME — 3D Ruin source')
text.write('Dedicated 3D demo source. Production 2D assets are unchanged.\nThe demo_run NLA track is baked from the keyed IK controls.\nMute demo_run and unmute the named IK constraints to edit the controls, then rebake.\nGrounded sword, guard, aerial and water sources remain available on the same rig.\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE),compress=True)
bpy.ops.object.select_all(action='DESELECT')
for ob in scene.objects:
    if ob not in helpers:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,
                         export_animation_mode='NLA_TRACKS',export_animations=True,export_apply=False)
report={'editable_source':str(SOURCE.relative_to(ROOT)),'runtime':str(OUT.relative_to(ROOT)),
        'cycle_seconds':20/30,'fps':30,'samples':samples,'production_files_changed':False}
(WORK/'athletic_run_authoring.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('ATHLETIC_3D_SOURCE_EXPORTED',flush=True)
