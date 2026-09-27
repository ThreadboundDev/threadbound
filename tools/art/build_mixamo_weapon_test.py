"""Retarget three supplied Mixamo clips to the detailed rig; attach separate gear."""
import bpy,math,json
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
BASE=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender'
OUT=BASE/'imported_character/mixamo_test';OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(BASE/'imported_character/Threadborne_2D_Shoulder_Refinement.blend'))
s=bpy.context.scene;rig=bpy.data.objects['Threadborne_Rig']
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
source_collection=bpy.data.collections.new('REFERENCE • Mixamo motion sources');s.collection.children.link(source_collection)
mapping={'pelvis':'Hips','spine':'Spine1','chest':'Spine2','neck':'Neck','head':'Head'}
for side,prefix in [('L','Left'),('R','Right')]:
    for dst,src in [('clavicle','Shoulder'),('upper_arm','Arm'),('forearm','ForeArm'),('hand','Hand'),('thigh','UpLeg'),('shin','Leg'),('foot','Foot'),('toe','ToeBase')]:mapping[dst+'.'+side]=prefix+src
sources={};actions={};report={}
def add_mixamo_fingers(source,skin):
    """Use Mixamo finger placement/weights only on hands; retain corrected body weights."""
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    group_map={}
    for side,prefix in [('L','Left'),('R','Right')]:
        group_map['mixamorig:'+prefix+'Hand']='hand.'+side
        for finger in ['Thumb','Index','Middle','Ring','Pinky']:
            for i in [1,2,3]:
                src=prefix+'Hand'+finger+str(i);name=finger.lower()+'.%02d.'%i+side
                sb=source.data.bones['mixamorig:'+src];b=rig.data.edit_bones.new(name)
                b.head=source.matrix_world@sb.head_local;b.tail=source.matrix_world@sb.tail_local
                b.parent=rig.data.edit_bones['hand.'+side if i==1 else finger.lower()+'.%02d.'%(i-1)+side]
                b.use_deform=True;mapping[name]=src;group_map['mixamorig:'+src]=name
            group_map['mixamorig:'+prefix+'Hand'+finger+'4']=finger.lower()+'.03.'+side
    bpy.ops.object.mode_set(mode='OBJECT')
    fingers=rig.data.collections.new('Fingers • Mixamo motion')
    for name in mapping:
        if name.startswith(('thumb.','index.','middle.','ring.','pinky.')):fingers.assign(rig.data.bones[name])
    source.data.pose_position='REST';bpy.context.view_layer.update()
    counts={}
    for ob in [bpy.data.objects['Threadborne_Character'],bpy.data.objects['Threadborne_Posing_Preview']]:
        # The dense mesh is normally hidden by collection; temporarily enable it for transfer.
        visibility=[(c,c.hide_viewport) for c in ob.users_collection]
        for c,_ in visibility:c.hide_viewport=False
        ob.hide_set(False);bpy.context.view_layer.update()
        for name in set(group_map.values()):
            if not ob.vertex_groups.get(name):ob.vertex_groups.new(name=name)
        for g in skin.vertex_groups:
            if not ob.vertex_groups.get(g.name):ob.vertex_groups.new(name=g.name)
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Temporary Mixamo hand weights','DATA_TRANSFER');mod.object=skin
        mod.use_vert_data=True;mod.data_types_verts={'VGROUP_WEIGHTS'};mod.vert_mapping='POLYINTERP_NEAREST';mod.layers_vgroup_select_src='ALL';mod.layers_vgroup_select_dst='NAME'
        bpy.ops.object.modifier_apply(modifier=mod.name)
        names={g.index:g.name for g in ob.vertex_groups};count=0
        for v in ob.data.vertices:
            if abs(v.co.x)<.775 or v.co.z<1.30:continue
            weights={}
            for g in v.groups:
                dst=group_map.get(names[g.group])
                if dst:weights[dst]=weights.get(dst,0)+g.weight
            total=sum(weights.values())
            if total<.01:continue
            for idx in [g.group for g in v.groups if not names[g.group].startswith('mixamorig:')]:ob.vertex_groups[idx].remove([v.index])
            for name,w in weights.items():ob.vertex_groups[name].add([v.index],w/total,'REPLACE')
            count+=1
        for g in list(ob.vertex_groups):
            if g.name.startswith('mixamorig:'):ob.vertex_groups.remove(g)
        for c,hidden in visibility:c.hide_viewport=hidden
        counts[ob.name]=count
    source.data.pose_position='POSE';skin.hide_render=True;skin.hide_set(True)
    print('FINGER_WEIGHTS',json.dumps(counts),flush=True)
for label in ['Idle','Run','Jump']:
    with bpy.data.libraries.load(str(OUT/(label+'_import.blend')),link=False) as (data,loaded):loaded.objects=['Armature','Threadborne_Mixamo_Upload'] if label=='Idle' else ['Armature']
    source=loaded.objects[0];source_collection.objects.link(source);source.name='Mixamo_Source_'+label;sources[label]=source
    source.hide_render=True;source.display_type='WIRE'
    bpy.context.view_layer.update()
    if label=='Idle':
        skin=loaded.objects[1];source_collection.objects.link(skin);skin.name='Mixamo_Source_Skin'
        bpy.context.view_layer.update();add_mixamo_fingers(source,skin)
    action=source.animation_data.action;action.name='SOURCE_Mixamo_'+label;action.use_fake_user=True
    first,last=[int(x) for x in action.frame_range];count=last-first+1
    # Source skeletons can have different rest axes. Use each clip's own rest transforms.
    rest_source={name:(source.matrix_world@source.data.bones['mixamorig:'+src].matrix_local).to_quaternion() for name,src in mapping.items()}
    rest_target={b.name:b.matrix_local.to_quaternion() for b in rig.data.bones}
    src_hip_rest=source.matrix_world@source.data.bones['mixamorig:Hips'].head_local
    rig.animation_data_create();rig.animation_data.action=None
    for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4);p.rotation_mode='QUATERNION'
    target_action=bpy.data.actions.new('Threadborne_SwordShield_'+label);target_action.use_fake_user=True
    rig.animation_data.action=target_action
    hips=[];previous={}
    for frame in range(first,last+1):
        s.frame_set(frame)
        actual=source.evaluated_get(bpy.context.evaluated_depsgraph_get())
        hip_world=actual.matrix_world@actual.pose.bones['mixamorig:Hips'].head
        delta=hip_world-src_hip_rest;hips.append(list(delta))
        desired={name:(actual.matrix_world@actual.pose.bones['mixamorig:'+src].matrix).to_quaternion()@rest_source[name].inverted()@rest_target[name] for name,src in mapping.items()}
        global_rot={}
        for bone in rig.data.bones:
            pb=rig.pose.bones[bone.name]
            parent_q=global_rot[bone.parent.name] if bone.parent else Quaternion()
            relative_rest=(rest_target[bone.parent.name].inverted()@rest_target[bone.name]) if bone.parent else rest_target[bone.name]
            if bone.name in desired:
                q=relative_rest.inverted()@parent_q.inverted()@desired[bone.name];q.normalize()
                if bone.name in previous and previous[bone.name].dot(q)<0:q.negate()
                previous[bone.name]=q.copy();pb.rotation_quaternion=q
                pb.keyframe_insert(data_path='rotation_quaternion',frame=frame-first+1,group=bone.name)
                global_rot[bone.name]=desired[bone.name]
            else:
                pb.rotation_quaternion=Quaternion();global_rot[bone.name]=parent_q@relative_rest
        # In-place horizontal motion for sprite playback; preserve vertical jump/bounce.
        local_delta=rest_target['pelvis'].inverted()@Vector((0,0,delta.z))
        rig.pose.bones['pelvis'].location=local_delta
        rig.pose.bones['pelvis'].keyframe_insert(data_path='location',frame=frame-first+1,group='pelvis')
    target_action.use_frame_range=True;target_action.frame_start=1;target_action.frame_end=count
    actions[label]=target_action
    report[label]={'frames':count,'fps':30,'original_hip_displacement':hips,'horizontal_motion':'removed from target only; source retained','vertical_range':[min(p[2] for p in hips),max(p[2] for p in hips)]}
    print('RETARGETED',label,count,report[label]['vertical_range'],flush=True)
rig.animation_data.action=None
source_collection.hide_viewport=True;source_collection.hide_render=True

# Three named clips laid sequentially on one NLA track for simple Spacebar playback.
track=rig.animation_data.nla_tracks.new();track.name='TEST REEL • Idle / Run / Jump'
cursor=1
for label in ['Idle','Run','Jump']:
    strip=track.strips.new(label,cursor,actions[label]);strip.action_frame_start=1;strip.action_frame_end=report[label]['frames'];strip.extrapolation='NOTHING';strip.blend_type='REPLACE'
    report[label]['timeline']=[cursor,cursor+report[label]['frames']-1]
    s.timeline_markers.new(label,frame=cursor)
    cursor+=report[label]['frames']
s.frame_start=1;s.frame_end=cursor-1;s.render.fps=30
s.frame_set(1);bpy.context.view_layer.update()

# Append the repaired weapon assemblies without their original hidden source mesh.
with bpy.data.libraries.load(str(BASE/'shield_revision/Threadborne_Sword_Shield_Rear_Fix.blend'),link=False) as (data,loaded):
    loaded.objects=[name for name in data.objects if name.startswith(('Shield_','Threadborne_Sword','Threadborne_Shield'))]
gear_collection=bpy.data.collections.new('GEAR • sword and sliding forearm shield');s.collection.children.link(gear_collection)
for ob in loaded.objects:
    if ob:gear_collection.objects.link(ob)
sword=bpy.data.objects['Threadborne_Sword_ROOT'];shield=bpy.data.objects['Threadborne_Shield_ROOT']
def attach(root,bone_name,position,rotation,scale):
    # A bone-follow empty avoids Blender bone-parent tail-offset ambiguity.
    follow=bpy.data.objects.new(root.name+'_FOLLOW',None);gear_collection.objects.link(follow);follow.empty_display_size=.035
    con=follow.constraints.new('COPY_TRANSFORMS');con.target=rig;con.subtarget=bone_name
    bpy.context.view_layer.update()
    target=Matrix.Translation(position)@rotation.to_matrix().to_4x4()@Matrix.Diagonal((scale,scale,scale,1))
    root.parent=follow;root.matrix_parent_inverse=Matrix.Identity(4);root.matrix_basis=follow.matrix_world.inverted()@target
    return follow
right=rig.pose.bones['hand.R'];grip=rig.matrix_world@(right.head+(right.tail-right.head)*.48)
sword_follow=attach(sword,'hand.R',grip,Quaternion((0,0,1),-math.pi/2),.92)
left=rig.pose.bones['forearm.L'];forearm_center=rig.matrix_world@(left.head+(left.tail-left.head)*.55)
# Front of source shield is +X; face it toward the character's forward -Y.
across=(left.tail-left.head).normalized();normal=Vector((0,-1,0));normal=(normal-across*normal.dot(across)).normalized()
up=normal.cross(across)
if up.z<0:across=-across;up=normal.cross(across)
shield_rotation=Matrix((normal,across,up)).transposed().to_quaternion()
shield_follow=attach(shield,'forearm.L',forearm_center+normal*.084,shield_rotation,.85)
shield['slide_note']='Separate child offset under forearm follow. Slide locally for grapple clearance; no grapple animation authored yet.'
for name in ['Threadborne_Sword','Shield_Original_Front']:
    ob=bpy.data.objects[name]
    dec=ob.modifiers.new('Lightweight viewport only','DECIMATE');dec.ratio=.12;dec.show_render=False

# Portrait canvas keeps the same 400 source pixels/metre while allowing jump height.
cam=s.camera
s.render.resolution_x=900;s.render.resolution_y=1200;s.render.resolution_percentage=100
cam.data.ortho_scale=3.0
corners=cam.data.view_frame(scene=s);vertical=max(p.y for p in corners)-min(p.y for p in corners)
cam.data.ortho_scale*=3.0/vertical
def camera(angle=-35):
    a=math.radians(angle);center=Vector((0,0,1.275));cam.location=center+Vector((6*math.sin(a),-6*math.cos(a),0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
camera()
s.render.engine='CYCLES';s.cycles.samples=16
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.film_transparent=True
s['animation_test_note']='Three retargeted clips including finger motion. Horizontal root travel removed; vertical motion retained. Grip alignment needs review; skirt is not simulated.'
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];frame=start+(end-start)//2
    s.frame_set(frame);bpy.context.view_layer.update()
    s.render.filepath=str(OUT/(label.lower()+'_equipped.png'));bpy.ops.render.render(write_still=True)
camera(0);s.frame_set(1);s.render.filepath=str(OUT/'idle_equipped_front.png');bpy.ops.render.render(write_still=True)
camera();s.frame_set(1)
bpy.ops.object.select_all(action='DESELECT');rig.hide_set(False);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='POSE')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_location=Vector((0,0,1.0));area.spaces.active.region_3d.view_distance=3.1
            area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
report['setup']={'detailed_mesh_vertices':len(bpy.data.objects['Threadborne_Character'].data.vertices),'target_bones':len(rig.data.bones),'weapon_attachment':['hand.R','forearm.L'],'canvas':[900,1200],'standing_source_height':720,'game_height':180,'cloth_simulated':False,'fingers_animated':True}
(OUT/'animation_test_report.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Threadborne_Equipped_Animation_Test.blend'))
print('EQUIPPED_TEST_SAVED',flush=True)
