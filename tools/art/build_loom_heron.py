"""Build the approved cloth-and-reed Loom Heron, rig, clips and packed source."""
from pathlib import Path
import bpy, math, json, os, tempfile, random
from mathutils import Vector, Quaternion
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron'
OUT=ROOT/'Assets/BlueBiome/Enemies/LoomHeron'
WORK=ROOT/'work/loom-heron'
for p in [SRC,OUT/'Models',OUT/'Textures',WORK/'temp',WORK/'renders']:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
random.seed(38)
P=ROOT/'Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2'
E=ROOT/'Assets/BlueBiome/Enemies/EaveRunner/Textures'
V=ROOT/'Assets/BlueBiome/Villagers/Textures'
W=ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures'
FACTORS={}
def mat(name,color,image=None,normal=None,rough=None,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF')
    n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=.78;n.inputs['Metallic'].default_value=metal
    FACTORS[name]=[*color,1]
    for channel,path in [('Base Color',image),('Normal',normal),('Roughness',rough)]:
        if not path:continue
        t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(path),check_existing=True)
        if channel=='Base Color':
            mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*color,1)
            m.node_tree.links.new(t.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],n.inputs[channel])
        elif channel=='Normal':
            t.image.colorspace_settings.name='Non-Color';b=m.node_tree.nodes.new('ShaderNodeNormalMap');b.inputs['Strength'].default_value=.4
            m.node_tree.links.new(t.outputs['Color'],b.inputs['Color']);m.node_tree.links.new(b.outputs[0],n.inputs[channel])
        else:
            t.image.colorspace_settings.name='Non-Color';m.node_tree.links.new(t.outputs[0],n.inputs[channel])
    return m
M={
 'cloth':mat('Heron indigo sail',(.12,.23,.36),V/'IndigoWorkwear_BaseColor.png',P/'blue_pavilion_indigo_normal.png',P/'blue_pavilion_indigo_roughness.png'),
 'patch':mat('Heron repaired flax sail',(.68,.57,.39),P/'blue_pavilion_cloth_light.png',P/'blue_pavilion_cloth_light_normal.png',P/'blue_pavilion_cloth_light_roughness.png'),
 'cord':mat('Heron woven core',(.6,.68,.8),E/'WovenCord_BaseColor.png',P/'blue_pavilion_indigo_normal.png',P/'blue_pavilion_indigo_roughness.png'),
 'rope':mat('Heron flax knots',(.63,.44,.24),P/'blue_pavilion_cloth_light.png',P/'blue_pavilion_cloth_light_normal.png',P/'blue_pavilion_cloth_light_roughness.png'),
 'wood':mat('Heron walnut spars',(.53,.34,.17),W/'walnut_BaseColor_4K.png',W/'walnut_NormalGL_4K.png',W/'walnut_Roughness_4K.png'),
 'ivory':mat('Heron ceramic face',(.92,.85,.69),E/'AgedIvory_BaseColor.png',P/'blue_pavilion_ceramic_normal.png',P/'blue_pavilion_ceramic_roughness.png'),
 'dark':mat('Heron eye recess',(.008,.015,.022)),
 'blue':mat('Heron blue glazed eye',(.06,.43,.58),metal=.25),
}
arm=bpy.data.armatures.new('LoomHeron_DeformSkeleton');rig=bpy.data.objects.new('LoomHeron_Rig',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
def bone(n,h,t,parent=None):
    b=arm.edit_bones.new(n);b.head=h;b.tail=t
    if parent:b.parent=arm.edit_bones[parent]
    b.align_roll(Vector((0,0,1)) if abs((Vector(t)-Vector(h)).normalized().z)<.9 else Vector((0,1,0)))
bone('root',(0,0,0),(0,0,.2))
bone('body',(0,.1,.9),(0,-.1,1.35),'root')
bone('neck',(0,-.12,1.32),(0,-.35,1.64),'body')
bone('head',(0,-.35,1.64),(0,-.67,1.68),'neck')
bone('tail',(0,.25,1.12),(0,.95,.87),'body')
for side,s in [('L',1),('R',-1)]:
    bone('wing_arm.'+side,(s*.12,0,1.35),(s*.78,.06,1.66),'body')
    bone('wing_fan.'+side,(s*.78,.06,1.66),(s*1.73,.05,1.78),'wing_arm.'+side)
    bone('tassel.'+side,(s*1.73,.05,1.78),(s*1.73,.05,1.48),'wing_fan.'+side)
    bone('thigh.'+side,(s*.12,-.02,.95),(s*.18,-.12,.60),'body')
    bone('shin.'+side,(s*.18,-.12,.60),(s*.18,.04,.25),'thigh.'+side)
    bone('foot.'+side,(s*.18,.04,.25),(s*.18,-.20,.21),'shin.'+side)
bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
def mesh(n,vs,fs,m,b,uv=None):
    d=bpy.data.meshes.new(n);d.from_pydata(vs,[],fs);d.update();o=bpy.data.objects.new(n,d);bpy.context.collection.objects.link(o);d.materials.append(M[m])
    layer=d.uv_layers.new(name='UVMap')
    for poly in d.polygons:
        poly.use_smooth=m not in ['cloth','patch','ivory']
        for li in poly.loop_indices:
            co=d.vertices[d.loops[li].vertex_index].co;layer.data[li].uv=(co.x*1.4,co.y*1.4+co.z*.6)
    g=o.vertex_groups.new(name=b);g.add(list(range(len(vs))),1,'REPLACE');o.parent=rig;mod=o.modifiers.new('Deform','ARMATURE');mod.object=rig
    return o
def tube(n,pts,r,m,b,sides=7):
    pts=[Vector(p) for p in pts];vs=[];fs=[]
    for i,p in enumerate(pts):
        axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized();u=axis.cross(Vector((0,0,1)))
        if u.length<.01:u=axis.cross(Vector((0,1,0)))
        u.normalize();v=axis.cross(u)
        for j in range(sides):vs.append(p+r*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides)))
    for i in range(len(pts)-1):
        for j in range(sides):fs.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    return mesh(n,vs,fs,m,b)
def coil(n,a,b,r,bn,turns=5,strands=2):
    a=Vector(a);b=Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.01:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u)
    for k in range(strands):
        pts=[]
        for i in range(turns*12+1):
            t=i/(turns*12);ang=math.tau*(turns*t+k/strands);pts.append(a.lerp(b,t)+r*(u*math.cos(ang)+v*math.sin(ang)))
        tube(n,pts,.008,'rope',bn,5)
def ellipsoid(n,c,scale,m,b):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=c);o=bpy.context.object;o.name=n;o.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.data.materials.append(M[m]);g=o.vertex_groups.new(name=b);g.add(list(range(len(o.data.vertices))),1,'REPLACE');o.parent=rig;mod=o.modifiers.new('Deform','ARMATURE');mod.object=rig
    for p in o.data.polygons:p.use_smooth=True
    return o
ellipsoid('Woven thorax',(0,.02,1.16),(.23,.36,.40),'cord','body')
ellipsoid('Layered shoulder cloth',(0,.05,1.37),(.27,.30,.17),'cloth','body')
for k in range(12):
    z=.85+k*.045;w=.18*math.sqrt(max(.1,1-((z-1.18)/.4)**2))
    tube('Body winding',[(w*math.cos(i*math.tau/32),.02+.29*math.sin(i*math.tau/32),z+.025*math.sin(i*math.tau/32)) for i in range(33)],.012,'cord','body')
for s in [-1,1]:
    tube('Diagonal harness',[(s*.17,-.24,.94),(s*.22,-.28,1.15),(s*.13,-.28,1.43),(0,-.22,1.49)],.021,'rope','body')
    # Paired loop binding mark, also visible in the human guardian's silhouette.
    tube('Paired guardian knot',[(s*.075+.065*math.cos(i*math.tau/24),-.306,1.27+.07*math.sin(i*math.tau/24)) for i in range(25)],.016,'rope','body')
tube('Curved braided neck',[(0,-.12,1.34),(0,-.26,1.47),(0,-.29,1.62),(0,-.46,1.69)],.085,'cord','neck',12)
coil('Neck tie',(0,-.25,1.47),(0,-.30,1.57),.088,'neck',4)
ellipsoid('Ceramic head',(0,-.46,1.69),(.11,.21,.13),'ivory','head')
# Angular long beak, double-sided hard ceramic shell and dark lower mandible.
mesh('Ceramic spear beak',[(-.09,-.56,1.73),(.09,-.56,1.73),(0,-1.13,1.42),(0,-.60,1.58)],[(0,1,2),(0,2,3),(1,3,2),(0,3,1)],'ivory','head')
tube('Beak dark seam',[(0,-.62,1.61),(0,-1.13,1.42)],.008,'dark','head')
for s in [-1,1]:
    ellipsoid('Eye inset',(s*.101,-.50,1.72),(.018,.046,.031),'dark','head')
    ellipsoid('Blue eye',(s*.118,-.514,1.724),(.006,.011,.012),'blue','head')
    tube('Brow ridge',[(s*.10,-.43,1.76),(s*.105,-.52,1.77),(s*.07,-.61,1.73)],.012,'ivory','head')
    for q in range(3):tube('Crown thread',[(s*.04,-.32,1.76),(s*(.10+q*.03),-.10+q*.05,1.84)],.012,'cord','head')
for side,s in [('L',1),('R',-1)]:
    a=(s*.13,0,1.38);hinge=(s*.78,.06,1.66);tip=(s*1.73,.05,1.78)
    bn='wing_arm.'+side;fan='wing_fan.'+side
    tube('Upper double spar',[a,hinge],.034,'wood',bn)
    tube('Lower double spar',[(s*.14,.07,1.32),(s*.78,.13,1.61)],.021,'wood',bn)
    # Root sail follows the shoulder; fan segments follow the folding wrist.
    mesh('Root sail',[a,hinge,(s*.78,.47,1.10),(s*.18,.32,1.05)],[(0,1,2,3)],'cloth',bn)
    ends=[tip,(s*1.70,.43,1.48),(s*1.47,.72,1.12),(s*1.12,.81,.86),(s*.78,.65,.82)]
    for j,end in enumerate(ends):
        tube('Fan radial spar',[hinge,end],.019 if j else .028,'wood',fan)
        endv=Vector(end);hv=Vector(hinge)
        coil('Spar lashing',endv.lerp(hv,.04),endv.lerp(hv,.16),.027,fan,3,1)
        if j==0:continue
        previous=Vector(ends[j-1]);current=Vector(end);vs=[Vector(hinge)]
        for k in range(9):
            t=k/8;v=previous.lerp(current,t);v+=(hv-v)*(.015+(k%2)*.035);vs.append(v)
        mesh('Indigo segmented fan',vs,[(0,i,i+1) for i in range(1,len(vs)-1)],'cloth',fan)
        # Small sewn repair panel at outer edge, uneven edge retained in geometry.
        q0=hv.lerp(previous,.76);q1=hv.lerp(current,.76)
        mesh('Flax sail repair',[q0,q1,current*.98+hv*.02,previous*.98+hv*.02],[(0,1,2,3)],'patch',fan)
        # Pale individual stitches across patch; coherent UVs provide woven microdetail.
        for k in range(1,8):
            v=q0.lerp(q1,k/8);tube('Repair stitch',[v+(hv-v)*.025,v-(hv-v)*.025],.004,'rope',fan,4)
        tube('Sail hem',[previous,current],.009,'rope',fan,5)
    coil('Wing shoulder binding',Vector(a).lerp(Vector(hinge),.78),Vector(a).lerp(Vector(hinge),.98),.046,bn,6)
    coil('Fan wrist binding',Vector(hinge)+Vector((0,-.04,0)),Vector(hinge)+Vector((0,.08,0)),.068,fan,5)
    tube('Tension stay',[(s*.20,.20,1.27),(s*.72,.42,1.04)],.008,'rope',bn,5)
    for j in range(3):
        x=s*(1.72+j*.025);mesh('Wing tassel',[(x,.05,1.73),(x+s*.025,.05,1.73),(x+s*.01,.10,1.40-j*.03)],[(0,1,2)],'cloth','tassel.'+side)
    tube('Braided thigh',[(s*.12,-.02,.95),(s*.18,-.12,.60)],.034,'cord','thigh.'+side)
    tube('Reed shin',[(s*.18,-.12,.60),(s*.18,.04,.25)],.022,'wood','shin.'+side)
    coil('Knee knot',(s*.18,-.13,.63),(s*.18,-.10,.57),.041,'shin.'+side,4)
    coil('Ankle knot',(s*.18,.025,.29),(s*.18,.04,.24),.036,'foot.'+side,3)
    for j in [-1,0,1]:tube('Gripping cord toe',[(s*.18,.04,.25),(s*.18+j*.047,-.10,.20),(s*.18+j*.06,-.24,.19),(s*.18+j*.06,-.26,.16)],.012,'rope','foot.'+side)
    tube('Rear toe',[(s*.18,.04,.25),(s*.18,.15,.18)],.012,'rope','foot.'+side)
for j in range(5):
    x=(j-2)*.068;mesh('Tail pennant',[(x-.05,.27,1.14),(x+.05,.27,1.14),(x+.025,1.03+abs(j-2)*.05,.81),(x-.04,.91,.87)],[(0,1,2,3)],'cloth','tail')
    tube('Tail rib',[(x,.27,1.14),(x,1.02,.84)],.012,'wood','tail',5)
# Merge surfaces to one skinned mesh per material, keeping bone groups intact.
for material in M.values():
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==material]
    if not obs:continue
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=material.name.replace(' ','_')
FPS=30
CLIPS={'idle':2.4,'flight':1.2,'perch':2.0,'dive_windup':.7,'dive':.55,'brake':.85,'hurt':.4,'death':1.2}
def worldrot(n,axis,angle):
    p=rig.pose.bones[n];basis=p.bone.matrix_local.to_quaternion();p.rotation_quaternion=basis.inverted()@Quaternion(axis,angle)@basis
for name,duration in CLIPS.items():
    rig.animation_data_create();action=bpy.data.actions.new(name);rig.animation_data.action=action;action.use_fake_user=True
    end=round(duration*FPS)
    for frame in range(end+1):
        t=frame/end;w=math.sin(t*math.tau);ease=t*t*(3-2*t)
        for p in rig.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=Quaternion();p.location=(0,0,0)
        flap=.16*math.sin(t*math.tau) if name in ['idle','flight'] else 0
        if name=='flight':flap=.55*math.sin(t*math.tau)
        fold=.13
        if name=='perch':fold=1.15+.025*w
        elif name=='dive_windup':fold=.13+.80*ease;flap=.12*math.sin(t*math.pi)
        elif name=='dive':fold=.93
        elif name=='brake':fold=.93*(1-ease);flap=-.45*math.sin(t*math.pi)
        elif name=='hurt':fold=.4;flap=.25*math.sin(t*math.pi*2)
        elif name=='death':fold=1.25*ease;flap=.3*ease
        for side,s in [('L',1),('R',-1)]:
            worldrot('wing_arm.'+side,(0,1,0),s*flap)
            worldrot('wing_fan.'+side,(0,0,1),s*fold)
            worldrot('tassel.'+side,(1,0,0),.15*math.sin(t*math.tau+.7) if name in ['idle','flight','perch'] else .2*math.sin(t*math.pi))
            leg=.4 if name in ['flight','dive','dive_windup'] else 0
            worldrot('thigh.'+side,(1,0,0),leg+.04*w)
            worldrot('shin.'+side,(1,0,0),-.55 if name in ['flight','dive'] else -.04*w)
        worldrot('neck',(1,0,0),-.08*w if name in ['idle','flight','perch'] else (.2*ease if name=='dive_windup' else .1))
        worldrot('tail',(1,0,0),.09*w if name in ['idle','flight','perch'] else -.3*math.sin(t*math.pi))
        if name in ['idle','flight']:rig.pose.bones['root'].location.z=.025*w
        if name=='death':worldrot('body',(0,1,0),1.25*ease);rig.pose.bones['root'].location.z=-.38*ease
        if name=='hurt':worldrot('body',(1,0,0),.3*math.sin(t*math.pi))
        for p in rig.pose.bones:
            p.keyframe_insert('rotation_quaternion',frame=frame+1,group=p.name);p.keyframe_insert('location',frame=frame+1,group=p.name)
    action['loop']=name in ['idle','flight','perch']
rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
sc=bpy.context.scene;sc.render.fps=FPS;sc.frame_end=72
sc.world=bpy.data.worlds.new('Review world');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.18,.23,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.65
def light(n,pos,energy,size):
    d=bpy.data.lights.new(n,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(n,d);sc.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
light('Key',(3,-4,6),650,5);light('Fill',(-4,-2,3),400,4);light('Rim',(1,4,4),800,3)
cam=bpy.data.cameras.new('Review camera');co=bpy.data.objects.new('Review camera',cam);sc.collection.objects.link(co);co.location=(3,-5,3);co.rotation_euler=(Vector((0,0,1.15))-co.location).to_track_quat('-Z','Y').to_euler();cam.type='ORTHO';cam.ortho_scale=4.3;sc.camera=co
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.render.resolution_x=1400;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
actors=[o for o in sc.objects if o==rig or o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in actors:o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'LoomHeron_Woven_v1.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'Models/LoomHeron_v1.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_anim_slide_to_zero=True,export_skins=True,export_yup=True)
report={'bones':len(arm.bones),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in actors if o.type=='MESH'),'vertices':sum(len(o.data.vertices) for o in actors if o.type=='MESH'),'surfaces':len(M),'clips':CLIPS,'direction':'Blender -Y, Godot +Z','scale':'meters; span about 3.5m; body origin at floor'}
(SRC/'build_report.json').write_text(json.dumps(report,indent=2));(SRC/'material_export_factors.json').write_text(json.dumps(FACTORS,indent=2))
sc.render.filepath=str(WORK/'renders/LoomHeron_Model.png');bpy.ops.render.render(write_still=True)
print('LOOM_HERON_BUILD',json.dumps(report))
