"""Refine approved native models; retain v1, rigs, animation and proportions.

Material-aware subdivision smooths silhouettes, while constrained cloth relief
adds actual folds. Skin paint is baked to UV maps. New heron clips are authored
on the original rig; a beak-tip bone locates the gameplay projectile precisely.
"""
from pathlib import Path
import bpy, bmesh, math, json, os, tempfile, sys
from mathutils import Vector, Quaternion
from mathutils.kdtree import KDTree
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/character-quality-v2';TEX=ROOT/'Assets/BlueBiome/Characters/SharedTexturesV2'
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
REPORT={}

def count(o):return sum(len(p.vertices)-2 for p in o.data.polygons)
def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def split(o):
    active(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.separate(type='MATERIAL');bpy.ops.object.mode_set(mode='OBJECT')
    return [p for p in bpy.context.selected_objects if p.type=='MESH']
def join(parts,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();parts[0].name=name
    return parts[0]
def image(path,noncolor=False):
    im=bpy.data.images.load(str(path),check_existing=True)
    if noncolor:im.colorspace_settings.name='Non-Color'
    return im

def remap_material(mat):
    name=mat.name.lower();family=None
    if any(s in name for s in ['indigo hood','worn indigo','charcoal','indigo sail']):family='IndigoWeave'
    elif any(s in name for s in ['flax','linen']):family='FlaxWeave'
    elif 'work apron' in name:family='WorkCanvas'
    elif 'woven' in name and 'core' in name:family='WovenCord'
    elif 'ivory' in name or 'ceramic face' in name:family='AgedCeramic'
    if not family:return
    for n in mat.node_tree.nodes:
        if n.type!='TEX_IMAGE' or not n.image:continue
        old=n.image.name.lower()
        channel='Normal' if 'normal' in old else 'Roughness' if 'rough' in old else 'BaseColor'
        n.image=image(TEX/(family+'_'+channel+'_4K.png'),channel!='BaseColor')
    mat['surface_detail_version']=2

def boundary_tree(ob):
    bm=bmesh.new();bm.from_mesh(ob.data);points=[]
    for e in bm.edges:
        if e.is_boundary:
            a,b=e.verts[0].co,e.verts[1].co
            for i in range(max(2,math.ceil((a-b).length/.015))):
                points.append(a.lerp(b,i/max(1,math.ceil((a-b).length/.015)-1)))
    bm.free()
    if not points:return None
    tree=KDTree(len(points))
    for i,p in enumerate(points):tree.insert(p,i)
    tree.balance();return tree

def refine(ob,heron=False):
    mat=ob.data.materials[0];n=mat.name.lower();remap_material(mat)
    rig=ob.parent
    for m in list(ob.modifiers):
        if m.type=='ARMATURE':ob.modifiers.remove(m)
    # Preserve sharp authored rims and the pointed beak/blade. Smooth cloth,
    # skin, hair and round cord tubes with Catmull-Clark; retain flat sail edges.
    cloth=any(s in n for s in ['indigo','charcoal','apron','linen'])
    sail=heron and ('sail' in n or 'indigo' in n)
    boundary=boundary_tree(ob) if sail else None
    ceramic='ivory' in n or 'ceramic' in n
    if ceramic:
        bm=bmesh.new();bm.from_mesh(ob.data);bm.normal_update();layer=bm.edges.layers.float.get('crease_edge') or bm.edges.layers.float.new('crease_edge')
        for e in bm.edges:
            if e.is_boundary or (len(e.link_faces)==2 and e.calc_face_angle(0)>.7):e[layer]=.85
        bm.to_mesh(ob.data);bm.free()
    level=2 if sail else 1
    active(ob);mod=ob.modifiers.new('V2 silhouette refinement','SUBSURF');mod.subdivision_type='SIMPLE' if sail or 'blade bevel' in n or 'iron tool' in n else 'CATMULL_CLARK';mod.levels=level;mod.render_levels=level
    mod.uv_smooth='PRESERVE_BOUNDARIES';mod.boundary_smooth='PRESERVE_CORNERS'
    bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.data.update()
    if cloth or sail:
        for v in ob.data.vertices:
            p=v.co
            if sail and boundary:
                _,_,distance=boundary.find(p);fade=min(1,distance/.055)
                displacement=.009*fade*math.sin(p.x*15+p.y*8)*math.sin(p.y*11+p.z*5)
            else:
                # Millimetre-scale cloth folds survive lighting without changing
                # body proportions or pushing the garments through hands.
                displacement=.00085*math.sin(p.z*80+p.x*25)*math.sin(p.y*31+p.z*17)
            v.co+=v.normal*displacement
    for p in ob.data.polygons:p.use_smooth=True
    ob.data.update()
    mod=ob.modifiers.new('Original deform rig','ARMATURE');mod.object=rig
    return ob

def skin_bake(ob,kind):
    mat=ob.data.materials[0];nodes=mat.node_tree.nodes;links=mat.node_tree.links;shader=nodes.get('Principled BSDF');output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
    emit=nodes.new('ShaderNodeEmission');paint=next(n for n in nodes if n.type=='VERTEX_COLOR')
    links.new(paint.outputs['Color'],emit.inputs[0]);links.new(emit.outputs[0],output.inputs[0])
    active(ob);scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=4;scene.render.bake.margin=12
    im=bpy.data.images.new(kind+'_Skin_BaseColor_4K',4096,4096,alpha=False);target=nodes.new('ShaderNodeTexImage');target.image=im;nodes.active=target
    # Geometry can stay in its native rest pose: color paint is UV/vertex based.
    arm=next(m for m in ob.modifiers if m.type=='ARMATURE');arm.show_render=False
    bpy.ops.object.bake(type='EMIT');im.filepath_raw=str(TEX/(kind+'_Skin_BaseColor_4K.png'));im.file_format='PNG';im.save()
    arm.show_render=True;links.new(shader.outputs[0],output.inputs[0]);links.new(target.outputs[0],shader.inputs['Base Color'])
    for old in [paint,emit]:nodes.remove(old)
    uv=nodes.new('ShaderNodeTexCoord');noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=900;noise.inputs['Detail'].default_value=2;links.new(uv.outputs['UV'],noise.inputs[0])
    bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.18;bump.inputs['Distance'].default_value=.00008;links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs[0],shader.inputs['Normal'])
    normal=bpy.data.images.new(kind+'_Skin_Normal_4K',4096,4096,alpha=False);normal.colorspace_settings.name='Non-Color';slot=nodes.new('ShaderNodeTexImage');slot.image=normal;nodes.active=slot
    arm.show_render=False;bpy.ops.object.bake(type='NORMAL',normal_space='TANGENT');arm.show_render=True
    normal.filepath_raw=str(TEX/(kind+'_Skin_Normal_4K.png'));normal.file_format='PNG';normal.save()
    nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.3;links.new(slot.outputs[0],nm.inputs['Color']);links.new(nm.outputs[0],shader.inputs['Normal'])
    shader.inputs['Base Color'].default_value=(1,1,1,1);mat['skin_paint']='4K UV map; vertex colors intentionally omitted from export'

def export(file,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=next(o for o in objects if o.type=='ARMATURE')
    bpy.ops.export_scene.gltf(filepath=str(file),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)

def save_source(path):
    for im in bpy.data.images:
        if im.source=='FILE' or im.name.endswith('_4K'):
            try:im.pack()
            except RuntimeError:pass
    bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)

def heron_clips(rig):
    active(rig);rig.animation_data.action=None;bpy.ops.object.mode_set(mode='EDIT')
    b=rig.data.edit_bones.new('beak_tip');b.head=(0,-1.13,1.42);b.tail=(0,-1.20,1.39);b.parent=rig.data.edit_bones['head']
    bpy.ops.object.mode_set(mode='OBJECT')
    def rot(n,axis,angle):
        p=rig.pose.bones[n];basis=p.bone.matrix_local.to_quaternion();p.rotation_quaternion=basis.inverted()@Quaternion(axis,angle)@basis
    for name,duration in [('needle_aim',.85),('needle_fire',.35),('low_recover',1.1)]:
        action=bpy.data.actions.new(name);action.use_fake_user=True;rig.animation_data.action=action;end=round(duration*30)
        for frame in range(end+1):
            t=frame/end;s=t*t*(3-2*t)
            for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0)
            fold=.13+.46*s if name=='needle_aim' else .59-.20*math.sin(t*math.pi) if name=='needle_fire' else .39*(1-s)
            for side,sign in [('L',1),('R',-1)]:
                rot('wing_fan.'+side,(0,0,1),sign*fold)
                rot('wing_arm.'+side,(0,1,0),sign*(-.13*math.sin(t*math.pi) if name!='low_recover' else -.28*math.sin(t*math.pi)))
                rot('thigh.'+side,(1,0,0),.2 if name!='low_recover' else .2*(1-s))
                rot('shin.'+side,(1,0,0),-.35 if name!='low_recover' else -.35*(1-s))
                rot('tassel.'+side,(1,0,0),.08*math.sin(t*math.pi*2))
            rot('neck',(1,0,0),-.18*s if name=='needle_aim' else -.18+.30*math.sin(t*math.pi) if name=='needle_fire' else .1*(1-s))
            rot('head',(1,0,0),.12*s if name=='needle_aim' else .12-.16*math.sin(t*math.pi) if name=='needle_fire' else -.04*(1-s))
            rot('tail',(1,0,0),.14*math.sin(t*math.pi))
            for p in rig.pose.bones:
                p.keyframe_insert('rotation_quaternion',frame=frame+1,group=p.name);p.keyframe_insert('location',frame=frame+1,group=p.name)
        action['loop']=False
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)

def charged_thread(rig):
    m=bpy.data.materials.new('Heron | charged thread');m.use_nodes=True;bsdf=m.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.025,.32,.48,1);bsdf.inputs['Emission Color'].default_value=(.04,.5,.8,1);bsdf.inputs['Emission Strength'].default_value=.2
    pts=[Vector(p) for p in [(0,-.30,1.26),(0,-.32,1.40),(0,-.35,1.59),(0,-.49,1.65),(0,-.69,1.56),(0,-.86,1.50)]];vs=[];fs=[]
    for i,p in enumerate(pts):
        for j in range(8):vs.append(p+Vector((math.cos(j*math.tau/8)*.005,0,math.sin(j*math.tau/8)*.005)))
    for i in range(len(pts)-1):
        for j in range(8):fs.append((i*8+j,i*8+(j+1)%8,(i+1)*8+(j+1)%8,(i+1)*8+j))
    d=bpy.data.meshes.new('Drawn thread');d.from_pydata(vs,[],fs);d.materials.append(m);ob=bpy.data.objects.new('Heron_ChargeThread',d);bpy.context.collection.objects.link(ob);ob.parent=rig
    for n in ['body','neck','head']:ob.vertex_groups.new(name=n)
    for i in range(len(vs)):ob.vertex_groups['body' if i//8<1 else 'neck' if i//8<3 else 'head'].add([i],1,'REPLACE')
    mod=ob.modifiers.new('Follow draw and recoil','ARMATURE');mod.object=rig
    for p in d.polygons:p.use_smooth=True
    return ob

mode=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'all'
if mode in ['all','villagers']:
    src=ROOT/'ArtSource/BlueBiome/Villagers';bpy.ops.wm.open_mainfile(filepath=str(src/'LakesideVillagers_v1.blend'))
    for kind in ['NetMender','Boatwright']:
        ob=bpy.data.objects[kind+'_TexturedCharacter'];bpy.context.window.scene=ob.users_scene[0];rig=ob.parent;before=count(ob);name=ob.name;parts=split(ob)
        for part in parts:
            refine(part)
            if 'warm skin' in part.data.materials[0].name:skin_bake(part,kind)
            for attr in list(part.data.color_attributes):part.data.color_attributes.remove(attr)
        actor=join(parts,name);rig.animation_data.action=next(a for a in bpy.data.actions if a.name.startswith('WorkIdle') and (kind=='NetMender' or a.name.endswith('.001')));bpy.context.scene.frame_set(1)
        export(ROOT/f'Assets/BlueBiome/Villagers/Models/{kind}_v2.glb',[actor,rig]);REPORT[kind]={'before_triangles':before,'triangles':count(actor),'vertices':len(actor.data.vertices),'bones':len(rig.data.bones)}
    save_source(src/'LakesideVillagers_v2.blend')
if mode in ['all','eave']:
    src=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner';bpy.ops.wm.open_mainfile(filepath=str(src/'EaveRunner_Woven_v1.blend'));actor=bpy.data.objects['EaveRunner_TexturedMesh'];rig=actor.parent;before=count(actor);name=actor.name
    parts=split(actor)
    for p in parts:refine(p)
    actor=join(parts,name);rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    export(ROOT/'Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v2.glb',[actor,rig]);REPORT['EaveRunner']={'before_triangles':before,'triangles':count(actor),'vertices':len(actor.data.vertices),'bones':len(rig.data.bones)};save_source(src/'EaveRunner_Woven_v2.blend')
if mode in ['all','heron']:
    src=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron';bpy.ops.wm.open_mainfile(filepath=str(src/'LoomHeron_Woven_v1.blend'));rig=bpy.data.objects['LoomHeron_Rig'];obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig];before=sum(count(o) for o in obs)
    for p in obs:refine(p,True)
    heron_clips(rig);obs.append(charged_thread(rig));rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    export(ROOT/'Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v2.glb',obs+[rig]);REPORT['LoomHeron']={'before_triangles':before,'triangles':sum(count(o) for o in obs),'vertices':sum(len(o.data.vertices) for o in obs),'bones':len(rig.data.bones),'new_clips':['needle_aim','needle_fire','low_recover'],'muzzle_bone':'beak_tip'};save_source(src/'LoomHeron_Woven_v2.blend')
file=WORK/('refinement_report_'+mode+'.json');file.write_text(json.dumps(REPORT,indent=2));print('CHARACTER_V2_REFINED',json.dumps(REPORT),flush=True)
