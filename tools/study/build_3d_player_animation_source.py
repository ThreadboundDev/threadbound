"""Keep the existing library run; clean up only its sideways leg spread in 3D.

The original run_1 action is preserved alongside the edited action in the blend.
No new gait, arm motion, pelvis motion, cycle or animation controls are authored.
Production inputs are read-only; only the separate study is exported.
"""
import bpy
import hashlib
import json
import math
from pathlib import Path
from mathutils import Matrix

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/third-person-study-2026-10-28'
REFERENCE=WORK/'source/Threadborne_Pre3D_Reference.glb'
SOURCE=WORK/'source/Threadborne_3D_Demo.blend'
OUT=WORK/'project/assets/player_3d_demo.glb'
LATERAL_FACTOR=.45
LEGS={part+'.'+side for part in ['thigh','shin','foot'] for side in ['L','R']}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene
scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(REFERENCE))
rig=next(o for o in scene.objects if o.type=='ARMATURE')
for track in rig.animation_data.nla_tracks:track.mute=True
track=next(t for t in rig.animation_data.nla_tracks if t.name=='run_1')
original=track.strips[0].action
rig.animation_data.action=original
if original.slots:rig.animation_data.action_slot=original.slots[0]
start,end=original.frame_range

def bags(action):
    return [bag for layer in action.layers for strip in layer.strips for bag in strip.channelbags]

def is_leg(path):
    return any(path.startswith('pose.bones["'+name+'"]') for name in LEGS)

def curve_signature(action):
    return [(c.data_path,c.array_index,[(tuple(k.co),k.interpolation,tuple(k.handle_left),tuple(k.handle_right)) for k in c.keyframe_points])
            for bag in bags(action) for c in bag.fcurves if not is_leg(c.data_path)]

# Include original sample times as well as integer frames, avoiding leftover
# imported fractional keys between newly baked leg corrections.
times=sorted({float(k.co.x) for bag in bags(original) for c in bag.fcurves for k in c.keyframe_points}
             | {float(f) for f in range(math.ceil(start),math.floor(end)+1)})
poses=[]
for frame in times:
    scene.frame_set(math.floor(frame),subframe=frame%1)
    bpy.context.view_layer.update()
    poses.append({p.name:p.matrix.copy() for p in rig.pose.bones})

edited=original.copy()
edited.name='Player_run_1_narrow_leg_cleanup'
edited.use_fake_user=True
unchanged_curves=curve_signature(original)
for bag in bags(edited):
    for curve in list(bag.fcurves):
        if is_leg(curve.data_path):bag.fcurves.remove(curve)
rig.animation_data.action=edited
if edited.slots:rig.animation_data.action_slot=edited.slots[0]
previous={}
samples=[]
max_length_error=0.0
for frame,pose in zip(times,poses):
    cleaned={n:m.copy() for n,m in pose.items()}
    record={'frame':round(frame,5),'feet':{}}
    for side in ['L','R']:
        thigh,shin,foot=[part+'.'+side for part in ['thigh','shin','foot']]
        hip,knee,ankle=[pose[n].translation.copy() for n in [thigh,shin,foot]]
        target=ankle.copy()
        target.x=hip.x+(ankle.x-hip.x)*LATERAL_FACTOR
        a=(knee-hip).length;b=(ankle-knee).length
        delta=target-hip;distance=delta.length;direction=delta.normalized()
        # Preserve the library's knee bend plane, tightening its lateral offset.
        pole=knee-hip;pole.x*=LATERAL_FACTOR
        pole=(pole-direction*pole.dot(direction)).normalized()
        along=(a*a-b*b+distance*distance)/(2*distance)
        assert a+b>distance and distance>abs(a-b), 'Original pose cannot reach narrow target'
        new_knee=hip+direction*along+pole*math.sqrt(max(0,a*a-along*along))
        for name,old_vector,new_vector,origin in [
            (thigh,knee-hip,new_knee-hip,hip),
            (shin,ankle-knee,target-new_knee,new_knee)]:
            change=old_vector.rotation_difference(new_vector)
            matrix=change.to_matrix().to_4x4() @ pose[name]
            matrix.translation=origin
            cleaned[name]=matrix
        cleaned[foot].translation=target
        max_length_error=max(max_length_error,abs((new_knee-hip).length-a),abs((target-new_knee).length-b))
        record['feet'][side]={'original':list(ankle),'cleaned':list(target),'hip_x':hip.x}
    scene.frame_set(math.floor(frame),subframe=frame%1)
    for name in sorted(LEGS):
        pb=rig.pose.bones[name]
        kwargs=dict(parent_matrix=cleaned[pb.parent.name],parent_matrix_local=pb.parent.bone.matrix_local) if pb.parent else {}
        pb.matrix_basis=pb.bone.convert_local_to_pose(cleaned[name],pb.bone.matrix_local,invert=True,**kwargs)
        pb.rotation_mode='QUATERNION'
        q=pb.rotation_quaternion.copy()
        if name in previous and q.dot(previous[name])<0:q.negate()
        pb.rotation_quaternion=q;previous[name]=q
        for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=name)
    samples.append(record)
for bag in bags(edited):
    for curve in bag.fcurves:
        if is_leg(curve.data_path):
            for key in curve.keyframe_points:key.interpolation='LINEAR'
assert curve_signature(edited)==unchanged_curves,'Non-leg source curves changed'
assert max_length_error<1e-5,'Leg lengths changed'

# Check the evaluated result, including parenting and local-space conversion.
max_forward_height_error=0.0
for frame,pose in zip(times,poses):
    scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
    for side in ['L','R']:
        actual=rig.pose.bones['foot.'+side].head;old=pose['foot.'+side].translation
        max_forward_height_error=max(max_forward_height_error,abs(actual.y-old.y),abs(actual.z-old.z))
assert max_forward_height_error<1e-5, max_forward_height_error
original.name='Original_library_run_1_UNCHANGED'
original.use_fake_user=True
track.strips[0].action=edited
rig.animation_data.action=None
# Reuse the original character library's existing fast left/right strafes and
# heavier hit reaction, mapping rest axes after the GLB round trip.
library=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'
with bpy.data.libraries.load(str(library),link=False) as (available,chosen):
    chosen.objects=['Threadborne_Rig']
    chosen.actions=['strafe_3','strafe_4','impact_2']
donor=chosen.objects[0];scene.collection.objects.link(donor)
donor.animation_data_create()
for t in donor.animation_data.nla_tracks:t.mute=True
aliases={'strafe_3':'combat_strafe_left','strafe_4':'combat_strafe_right','impact_2':'heavy_hit'}
for imported in chosen.actions:
    donor.animation_data.action=imported
    if imported.slots:donor.animation_data.action_slot=imported.slots[0]
    first,last=map(int,imported.frame_range)
    frames=[]
    for frame in range(first,last+1):
        scene.frame_set(frame);bpy.context.view_layer.update()
        frames.append({b.name:rig.matrix_world.inverted() @ donor.matrix_world @ donor.pose.bones[b.name].matrix @ donor.data.bones[b.name].matrix_local.inverted() @ donor.matrix_world.inverted() @ rig.matrix_world @ b.matrix_local for b in rig.data.bones})
    action=bpy.data.actions.new(aliases[imported.name.split('.')[0]])
    rig.animation_data.action=action
    for frame,pose in enumerate(frames,1):
        scene.frame_set(frame)
        for pb in rig.pose.bones:
            kwargs=dict(parent_matrix=pose[pb.parent.name],parent_matrix_local=pb.parent.bone.matrix_local) if pb.parent else {}
            pb.matrix_basis=pb.bone.convert_local_to_pose(pose[pb.name],pb.bone.matrix_local,invert=True,**kwargs)
            pb.rotation_mode='QUATERNION'
            for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=pb.name)
    rig.animation_data.action=None
    new_track=rig.animation_data.nla_tracks.new();new_track.name=action.name
    new_track.strips.new(action.name,1,action);new_track.mute=True
bpy.data.objects.remove(donor,do_unlink=True)
for t in rig.animation_data.nla_tracks:t.mute=False
scene.frame_start=math.floor(start);scene.frame_end=math.ceil(end);scene.frame_set(scene.frame_start)
text=bpy.data.texts.new('READ ME - library run cleanup')
text.write('Existing run_1, with only thigh/shin/foot curves adjusted to reduce lateral spread.\nOriginal_library_run_1_UNCHANGED is retained for comparison.\nArms, torso, pelvis, timing and forward/vertical foot trajectories are unchanged.\nNo procedural replacement gait. All other library clips are preserved. Production sources are read-only.\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE),compress=True)
bpy.ops.object.select_all(action='DESELECT')
for ob in scene.objects:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,
                         export_animation_mode='NLA_TRACKS',export_animations=True,export_apply=False)
width=lambda key:[s['feet']['L'][key][0]-s['feet']['R'][key][0] for s in samples]
report={'source_clip':'run_1','source_reference':str(REFERENCE.relative_to(ROOT)),
        'source_sha256':hashlib.sha256(REFERENCE.read_bytes()).hexdigest(),
        'editable_source':str(SOURCE.relative_to(ROOT)),'runtime':str(OUT.relative_to(ROOT)),
        'fps':scene.render.fps,'cycle_seconds':(end-start)/scene.render.fps,
        'lateral_offset_factor':LATERAL_FACTOR,'changed_bones':sorted(LEGS),
        'non_leg_curves_identical':curve_signature(edited)==unchanged_curves,
        'max_leg_length_error_m':max_length_error,'max_forward_height_error_m':max_forward_height_error,
        'mean_ankle_width_original_m':sum(width('original'))/len(samples),
        'mean_ankle_width_cleaned_m':sum(width('cleaned'))/len(samples),
        'samples':samples[::max(1,len(samples)//8)],'production_files_changed':False,'additional_library_clips':list(aliases.values()),'library_sha256':hashlib.sha256(library.read_bytes()).hexdigest()}
(WORK/'run_cleanup_authoring.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('LIBRARY_RUN_CLEANUP_EXPORTED',json.dumps({k:v for k,v in report.items() if k!='samples'}),flush=True)
