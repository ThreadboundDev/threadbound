"""Author the woven Eave Runner, its deform rig and in-place animation set.

Runs in background Blender. Uses the same CC0 human topology as the villagers
only as a fitting/deformation surface; all visible body material is woven cord.
Existing character assets and the running editor are never replaced.
"""
from pathlib import Path
import bpy, bmesh, json, math, random, os, tempfile, sys
from mathutils import Vector, Matrix, Quaternion
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner'
ASSET=ROOT/'Assets/BlueBiome/Enemies/EaveRunner'
WORK=ROOT/'work/eave-runner'
CC0=ROOT/'ArtSource/BlueBiome/Villagers/CC0_Source'
for p in [SOURCE,ASSET/'Models',ASSET/'Textures',WORK/'renders',WORK/'temp']:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
random.seed(281)
FACTORS={}

def material(name,color,image=None,normal=None,rough=None,metal=0,emission=0):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    node=mat.node_tree.nodes.get('Principled BSDF');node.inputs['Base Color'].default_value=(*color,1)
    node.inputs['Roughness'].default_value=.78;node.inputs['Metallic'].default_value=metal
    if emission:
        node.inputs['Emission Color'].default_value=(*color,1);node.inputs['Emission Strength'].default_value=emission
    FACTORS[name]=[*color,1]
    for channel,path in [('Base Color',image),('Normal',normal),('Roughness',rough)]:
        if not path:continue
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True)
        if channel=='Normal':
            tex.image.colorspace_settings.name='Non-Color';bump=mat.node_tree.nodes.new('ShaderNodeNormalMap');bump.inputs['Strength'].default_value=.32
            mat.node_tree.links.new(tex.outputs['Color'],bump.inputs['Color']);mat.node_tree.links.new(bump.outputs[0],node.inputs['Normal'])
        elif channel=='Base Color':
            mix=mat.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*color,1)
            mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);mat.node_tree.links.new(mix.outputs[0],node.inputs['Base Color'])
        else:
            tex.image.colorspace_settings.name='Non-Color';mat.node_tree.links.new(tex.outputs['Color'],node.inputs[channel])
    return mat

PAV=ROOT/'Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2'
VILL=ROOT/'Assets/BlueBiome/Villagers/Textures'
M={
 'cord':material('Guardian | woven indigo core',(.67,.72,.82),ASSET/'Textures/WovenCord_BaseColor.png',PAV/'blue_pavilion_indigo_normal.png',PAV/'blue_pavilion_indigo_roughness.png'),
 'cloth':material('Guardian | indigo hood and panels',(.09,.17,.29),VILL/'IndigoWorkwear_BaseColor.png',PAV/'blue_pavilion_indigo_normal.png',PAV/'blue_pavilion_indigo_roughness.png'),
 'pants':material('Guardian | charcoal work cloth',(.075,.085,.10),VILL/'IndigoWorkwear_BaseColor.png',PAV/'blue_pavilion_cloth_light_normal.png',PAV/'blue_pavilion_cloth_light_roughness.png'),
 'rope':material('Guardian | worn flax binding',(.56,.40,.23),PAV/'blue_pavilion_cloth_light.png',PAV/'blue_pavilion_cloth_light_normal.png',PAV/'blue_pavilion_cloth_light_roughness.png'),
 'ivory':material('Guardian | aged ivory mask',(.92,.84,.67),ASSET/'Textures/AgedIvory_BaseColor.png',PAV/'blue_pavilion_ceramic_normal.png',PAV/'blue_pavilion_ceramic_roughness.png'),
 'dark':material('Guardian | hollow recess',(.008,.010,.015)),
 'wood':material('Guardian | reed splints',(.34,.19,.075),ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures/walnut_BaseColor_4K.png',ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures/walnut_NormalGL_4K.png',ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures/walnut_Roughness_4K.png'),
 'metal':material('Guardian | darkened iron',(.23,.27,.29),metal=.72),
 'edge':material('Guardian | worn blade bevel',(.48,.52,.53),metal=.82),
 'blue':material('Guardian | blue glaze and inner light',(.025,.20,.30),metal=.12,emission=.25),
}

def mesh(name,points,polys,mat,uv=None,smooth=True):
    data=bpy.data.meshes.new(name);data.from_pydata(points,[],polys);data.update()
    ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);data.materials.append(mat)
    layer=data.uv_layers.new(name='UVMap')
    for p in data.polygons:
        p.use_smooth=smooth
        for i,li in enumerate(p.loop_indices):
            co=data.vertices[data.loops[li].vertex_index].co
            layer.data[li].uv=uv[p.index][i] if uv is not None else (co.x*3+.5,co.z*2)
    return ob

def bind(ob,bone=None,weights=None):
    ob.parent=rig;groups={}
    for v in ob.data.vertices:
        data={bone:1} if bone else (weights[v.index] if weights is not None else transfer(v.co))
        # Trim to the export's four influences before normalization.
        data=dict(sorted(data.items(),key=lambda item:item[1],reverse=True)[:4]);total=sum(data.values()) or 1
        for n,w in data.items():
            if w<.0001:continue
            if n not in groups:groups[n]=ob.vertex_groups.new(name=n)
            groups[n].add([v.index],w/total,'REPLACE')
    mod=ob.modifiers.new('Woven body deformation','ARMATURE');mod.object=rig
    return ob

def tube(name,points,radius,mat,bone=None,sides=6,weights=True):
    points=[Vector(p) for p in points];verts=[];faces=[];uv=[]
    for i,p in enumerate(points):
        axis=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized();u=axis.cross(Vector((0,0,1)))
        if u.length<.01:u=axis.cross(Vector((0,1,0)))
        u.normalize();v=axis.cross(u)
        for j in range(sides):verts.append(p+radius*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides)))
    for i in range(len(points)-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
            uv.append([(j/sides,i*.2),((j+1)/sides,i*.2),((j+1)/sides,(i+1)*.2),(j/sides,(i+1)*.2)])
    ob=mesh(name,verts,faces,mat,uv)
    if weights:bind(ob,bone)
    return ob

def box(name,center,size,mat,bone=None,bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center);ob=bpy.context.object;ob.name=name;ob.dimensions=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);ob.data.materials.append(mat)
    if bevel:
        mod=ob.modifiers.new('Worn rounded edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
    if bone:bind(ob,bone)
    return ob

def sphere(name,center,scale,mat,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=center);ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);ob.data.materials.append(mat)
    for p in ob.data.polygons:p.use_smooth=True
    return bind(ob,bone)

def read_obj(path):
    vs=[];uvs=[];faces=[];group=''
    for line in path.read_text().splitlines():
        q=line.split()
        if not q:continue
        if q[0]=='v':vs.append(Vector(tuple(map(float,q[1:4]))))
        elif q[0]=='vt':uvs.append(tuple(map(float,q[1:3])))
        elif q[0]=='g':group=' '.join(q[1:])
        elif q[0]=='f':
            f=[];u=[]
            for token in q[1:]:
                a=token.split('/');f.append(int(a[0])-1);u.append(uvs[int(a[1])-1] if len(a)>1 and a[1] else (0,0))
            faces.append((f,u,group))
    return vs,faces

verts,faces=read_obj(CC0/'base.obj')
for line in (CC0/'asian-male-young.target').read_text().splitlines():
    if line and not line.startswith('#'):
        q=line.split();verts[int(q[0])]+=Vector(tuple(map(float,q[1:4])))
body_indices={i for f,u,g in faces if g=='body' for i in f}
ground=min(verts[i].y for i in body_indices);size=1.78/(max(verts[i].y for i in body_indices)-ground)
verts=[Vector((v.x*size,-v.z*size,(v.y-ground)*size+.025)) for v in verts]
oldrig=json.loads((CC0/'default.mhskel').read_text())
def joint(name,tail=False):
    ids=oldrig['joints'][oldrig['bones'][name]['tail' if tail else 'head']]
    return sum((verts[i] for i in ids),Vector())/len(ids)

arm=bpy.data.armatures.new('EaveRunner_DeformSkeleton');rig=bpy.data.objects.new('EaveRunner_Rig',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
def addbone(name,head,tail,parent=None):
    b=arm.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=arm.edit_bones[parent]
    if (b.tail-b.head).length<.001:b.tail=b.head+Vector((0,0,.015))
    axis=b.tail-b.head;roll=Vector((0,1,0))
    if axis.normalized().dot(roll)>.95:roll=Vector((0,0,1))
    b.align_roll(roll)
addbone('root',(0,0,0),(0,0,.15))
addbone('pelvis',(0,.04,.96),(0,.02,1.09),'root')
addbone('spine',(0,.02,1.09),(0,0,1.30),'pelvis')
addbone('chest',(0,0,1.30),(0,-.005,1.53),'spine')
addbone('neck',(0,-.005,1.53),joint('head'),'chest')
addbone('head',joint('head'),joint('head',True),'neck')
for side in ['L','R']:
    addbone('clavicle.'+side,(0,0,1.46),joint('upperarm01.'+side),'chest')
    for new,a,b,parent in [('upper_arm','upperarm01','lowerarm01','clavicle'),('forearm','lowerarm01','wrist','upper_arm')]:
        addbone(new+'.'+side,joint(a+'.'+side),joint(b+'.'+side),parent+'.'+side)
    addbone('hand.'+side,joint('wrist.'+side),joint('wrist.'+side,True),'forearm.'+side)
    for digit in range(1,6):
        for segment in range(1,4):
            name='finger%d-%d.%s'%(digit,segment,side)
            addbone(name,joint(name),joint(name,True),'hand.'+side if segment==1 else 'finger%d-%d.%s'%(digit,segment-1,side))
    addbone('thigh.'+side,joint('upperleg01.'+side),joint('lowerleg01.'+side),'pelvis')
    addbone('shin.'+side,joint('lowerleg01.'+side),joint('foot.'+side),'thigh.'+side)
    addbone('foot.'+side,joint('foot.'+side),joint('foot.'+side,True),'shin.'+side)
    addbone('toe.'+side,joint('foot.'+side,True),joint('foot.'+side,True)+Vector((0,-.11,-.03)),'foot.'+side)
for side,sign in [('L',1),('R',-1)]:
    for i in range(3):addbone('tail_%s_%d'%(side,i+1),(sign*.10,.13+i*.075,1.46-i*.075),(sign*.10,.205+i*.075,1.385-i*.075),'chest' if i==0 else 'tail_%s_%d'%(side,i))
addbone('blade',joint('wrist.R'),joint('wrist.R',True),'hand.R')
addbone('held_pin',joint('wrist.L'),joint('wrist.L',True),'hand.L')
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
rig['allegiance']='Hermit-aligned woven guardian; exact maker unspecified'
rig['front']='-Y Blender / +Z glTF and Godot'
REST={b.name:b.matrix_local.copy() for b in rig.data.bones}
HEAD={b.name:b.head_local.copy() for b in rig.data.bones};TAIL={b.name:b.tail_local.copy() for b in rig.data.bones}

def mapped(name):
    if name.startswith('finger'):return name
    side='.'+name.rsplit('.',1)[1] if '.' in name else ''
    if name.startswith(('clavicle','shoulder')):return 'clavicle'+side
    if name.startswith('upperarm'):return 'upper_arm'+side
    if name.startswith('lowerarm'):return 'forearm'+side
    if name.startswith(('wrist','metacarpal')):return 'hand'+side
    if name.startswith('upperleg'):return 'thigh'+side
    if name.startswith('lowerleg'):return 'shin'+side
    if name.startswith('foot'):return 'foot'+side
    if name.startswith('toe'):return 'toe'+side
    if name.startswith('neck'):return 'neck'
    if name.startswith('spine'):return 'chest' if joint(name).z>1.28 else 'spine'
    if name.startswith(('root','pelvis')):return 'pelvis'
    if name.startswith('breast'):return 'chest'
    return 'head'
weights=[{} for v in verts]
for name,items in json.loads((CC0/'default_weights.mhw').read_text())['weights'].items():
    n=mapped(name)
    for i,w in items:weights[i][n]=weights[i].get(n,0)+w
kd=KDTree(sum(bool(w) for w in weights))
for i,v in enumerate(verts):
    if weights[i]:kd.insert(v,i)
kd.balance()
def transfer(co):
    result={}
    for p,index,distance in kd.find_n(co,4):
        factor=1/max(.001,distance)**2
        for n,w in weights[index].items():result[n]=result.get(n,0)+w*factor
    total=sum(result.values()) or 1
    return {n:w/total for n,w in result.items()}

# Continuous woven core with an abstract, hollow face beneath the mask.
mapping={};points=[];polys=[];uv=[];source=[]
for f,u,g in faces:
    if g!='body':continue
    c=sum((verts[i] for i in f),Vector())/len(f)
    if c.z>1.55 and c.y<-.05:continue
    poly=[]
    for i in f:
        if i not in mapping:mapping[i]=len(points);points.append(verts[i]);source.append(i)
        poly.append(mapping[i])
    polys.append(poly);uv.append([(a*5,b*5) for a,b in u])
body=mesh('Woven core — no skin',points,polys,M['cord'],uv);bind(body,weights=[weights[i] for i in source])
sphere('Hollow mask interior',(0,-.075,1.665),(.092,.09,.13),M['dark'],'head')

# Fitted garments use the helper topology, then receive real folds and hems.
helper_faces=[(f,u) for f,u,g in faces if g=='helper-tights']
helper=mesh('TEMP cloth fitting surface',verts,[f for f,u in helper_faces],M['cloth'])
normals=[v.normal.copy() for v in helper.data.vertices]
def garment(name,predicate,mat,inflate,deform):
    mapping={};vs=[];ps=[];uv=[]
    for f,unused in helper_faces:
        c=sum((verts[i] for i in f),Vector())/len(f)
        if not predicate(c,f):continue
        poly=[]
        for i in f:
            if i not in mapping:mapping[i]=len(vs);vs.append(deform(verts[i]+normals[i]*inflate))
            poly.append(mapping[i])
        ps.append(poly);uv.append([(verts[i].x*2.1+.5,verts[i].z*1.4) for i in f])
    ob=mesh(name,vs,ps,mat,uv)
    smooth=ob.modifiers.new('Soft textile surface','SMOOTH');smooth.factor=.28;smooth.iterations=2
    bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=smooth.name)
    solid=ob.modifiers.new('Fabric thickness','SOLIDIFY');solid.thickness=.006;bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(ob);return ob
def pants_shape(p):
    sign=1 if p.x>=0 else -1
    p.x=sign*(.145+(abs(p.x)-.145)*1.55);p.y*=1.22
    wave=math.sin(p.z*44+abs(p.x)*26)*.008
    p.y+=wave;p.x+=sign*.004*math.cos(p.z*53)
    return p
garment('Folded charcoal trousers',lambda c,f:.48<c.z<1.0 and abs(c.x)<.34,M['pants'],.024,pants_shape)
def coat_shape(p):
    p.x*=1.10;p.y*=1.16;p.y+=math.sin(p.z*35+p.x*18)*.005
    return p
tunic=garment('Cropped overlapping tunic',lambda c,f:1.005<c.z<1.50 and abs(c.x)<.26,M['cloth'],.026,coat_shape)
tunic_surface=BVHTree.FromPolygons([v.co.copy() for v in tunic.data.vertices],[tuple(p.vertices) for p in tunic.data.polygons])
def on_tunic(x,z,offset=.008):
    hit,normal,face,distance=tunic_surface.ray_cast(Vector((x,-1,z)),Vector((0,1,0)),2)
    return Vector((x,hit.y-offset if hit is not None else -.19,z))
garment('Dark woven tabi uppers',lambda c,f:c.z<.12,M['pants'],.007,lambda p:p)
bpy.data.objects.remove(helper,do_unlink=True)

# Hood shell with an actual open face, doubled rim and stitched edging.
hood_rows=[(1.49,.105,.11),(1.54,.13,.14),(1.60,.15,.155),(1.68,.15,.16),(1.75,.14,.15),(1.81,.115,.125),(1.86,.065,.075),(1.885,.008,.012)]
vs=[];ps=[];uv=[];N=48
for row,(z,rx,ry) in enumerate(hood_rows):
    for k in range(N+1):
        a=k*math.tau/N;fold=.004*math.cos(a*11+row*.6)
        vs.append(((rx+fold)*math.sin(a),.005+(ry+fold)*math.cos(a),z+.003*math.sin(a*7)))
for row in range(len(hood_rows)-1):
    for k in range(N):
        a=(k+.5)*math.tau/N
        if 0<row<5 and abs(a-math.pi)<.78:continue
        i=row*(N+1)+k;ps.append((i,i+1,i+N+2,i+N+1));uv.append([(k/N,row/7),((k+1)/N,row/7),((k+1)/N,(row+1)/7),(k/N,(row+1)/7)])
hood=mesh('Layered indigo hood',vs,ps,M['cloth'],uv)
solid=hood.modifiers.new('Hood folded lining','SOLIDIFY');solid.thickness=.012
bpy.context.view_layer.objects.active=hood;bpy.ops.object.modifier_apply(modifier=solid.name);bind(hood,'head')
for sign in [-1,1]:
    a=math.pi+sign*.78
    edge=[((rx+.002)*math.sin(a),.005+(ry+.002)*math.cos(a),z) for z,rx,ry in hood_rows[1:6]]
    tube('Hood stitched opening rim',edge,.005,M['rope'],'head')
    for i in range(15):
        t=i/14;z=1.56+t*.24;x=sign*(.102-.025*t);y=-.109-.012*math.sin(t*math.pi)
        tube('Hood small running stitch',[(x-.002,y-.004,z-.003),(x+.002,y-.004,z+.003)],.0011,M['rope'],'head',sides=4)

# Ceramic face with narrow slanted open eye cuts and a slightly pointed chin.
mask_rows=[(1.51,.009),(1.55,.055),(1.60,.085),(1.65,.096),(1.663,.093),(1.715,.086),(1.76,.066),(1.795,.025)]
vs=[];ps=[]
for row,(z,half) in enumerate(mask_rows):
    for j in range(17):
        t=j/8-1;x=t*half
        y=-.165+.031*t*t-.024*math.exp(-((z-1.64)/.07)**2)*(1-abs(t))
        vs.append((x,y,z+.010*abs(t) if row in [3,4] else z))
for row in range(len(mask_rows)-1):
    for j in range(16):
        if row==3 and j in [2,3,4,11,12,13]:continue
        i=row*17+j;ps.append((i,i+1,i+18,i+17))
mask=mesh('Ivory ceramic faceplate',vs,ps,M['ivory'],smooth=False)
mod=mask.modifiers.new('Mask ceramic edge','SOLIDIFY');mod.thickness=.008
bpy.context.view_layer.objects.active=mask;bpy.ops.object.modifier_apply(modifier=mod.name)
mod=mask.modifiers.new('Soft ceramic bevels','BEVEL');mod.width=.002;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
bind(mask,'head')
for sign in [-1,1]:
    tube('Narrow blue eye glint',[(sign*.036,-.160,1.654),(sign*.069,-.155,1.661)],.0012,M['blue'],'head',sides=5)
crack=[(.012,-.171,1.759),(.008,-.178,1.721),(.026,-.181,1.687),(.016,-.191,1.649),(.031,-.180,1.606),(.020,-.176,1.564),(.009,-.174,1.530)]
tube('Repaired blue mask fracture',crack,.0024,M['blue'],'head',sides=5)
for p in crack[1:-1]:tube('Mask seam stitch',[(p[0]-.007,p[1]-.001,p[2]-.003),(p[0]+.007,p[1]-.001,p[2]+.003)],.0013,M['rope'],'head',sides=4)

def loop_knot(name,center,radius,bone,mat=None,conform=False):
    x,y,z=center
    for sign in [-1,1]:
        pts=[(x+sign*radius*.55+radius*.72*math.cos(a),y-.006*math.sin(a*2),z+radius*.60*math.sin(a)) for a in [i*math.tau/32 for i in range(33)]]
        if conform:pts=[on_tunic(p[0],p[2],.011) for p in pts]
        tube(name,pts,.0035 if radius<.03 else .005,M['rope'] if mat is None else mat,bone,sides=6)
loop_knot('Forehead paired binding',(0,-.177,1.752),.019,'head',M['metal'])

# Layered shoulder scarf, with no long cape crossing the hands or knees.
for layer in range(3):
    vs=[];ps=[]
    for row in range(4):
        t=row/3
        for k in range(49):
            a=k*math.tau/48;rx=.13+t*.15;ry=.13+t*.075
            vs.append((rx*math.cos(a),ry*math.sin(a)+.015,1.545-t*.15+layer*.016+.008*math.sin(a*4+layer)))
    for row in range(3):
        for k in range(48):
            i=row*49+k;ps.append((i,i+1,i+50,i+49))
    scarf=mesh('Folded shoulder cowl '+str(layer),vs,ps,M['cloth']);bind(scarf)
    tube('Cowl flax stitched hem',vs[-49:],.002,M['rope'])

# Diagonal woven sash and short overlapping waist panels.
for sign in [-1,1]:
    path=[(sign*.15,-.235,1.43),(sign*.10,-.25,1.30),(-sign*.03,-.25,1.14),(-sign*.15,-.235,1.03)]
    for strand in [-1,0,1]:
        points=[]
        for start,end in zip(path,path[1:]):
            for i in range(0 if not points else 1,9):
                p=Vector(start).lerp(Vector(end),i/8);points.append(on_tunic(p.x+strand*.006,p.z))
        tube('Crossed braided chest binding',points,.0035,M['rope'])
for sector in range(6):
    center=sector*math.tau/6;vs=[];ps=[]
    for row in range(5):
        t=row/4
        for col in range(5):
            a=center+(col/4-.5)*.93
            vs.append(((.22+.035*t)*math.sin(a),(.18+.045*t)*math.cos(a),1.035-.24*t+.012*math.cos(col*3+sector)))
    for row in range(4):
        for col in range(4):i=row*5+col;ps.append((i,i+1,i+6,i+5))
    panel=mesh('Split waist tab '+str(sector),vs,ps,M['cloth']);bind(panel)
    tube('Panel flax hem',vs[-5:],.002,M['rope'])
for z in [1.035,1.049,1.062]:
    points=[]
    for k in range(65):
        a=k*math.tau/64;radial=Vector((math.cos(a),math.sin(a),0));start=radial*.6+Vector((0,0,z))
        hit,normal,face,distance=tunic_surface.ray_cast(start,-radial,1.2)
        points.append(hit+radial*.009 if hit is not None else Vector((.20*math.cos(a),.16*math.sin(a),z)))
    tube('Braided waist binding',points,.006,M['rope'])
loop_knot('Chest paired binding',(0,-.216,1.20),.037,None,conform=True)
loop_knot('Waist binding knot',(0,-.204,1.047),.044,None,conform=True)

# Parallel visible cord fibers and splint bracers make the body visibly woven.
def braid_limb(side,bone,radius,strands=9):
    a=HEAD[bone];b=TAIL[bone];axis=(b-a).normalized();u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u)
    for k in range(strands):
        pts=[]
        for j in range(17):
            t=.05+j*.90/16;angle=k*math.tau/strands+.28*math.sin(t*math.pi*2)
            r=radius*(.96+.08*math.sin(t*math.pi));p=a.lerp(b,t)+r*(u*math.cos(angle)+v*math.sin(angle));pts.append(p)
        tube('Exposed longitudinal cord '+bone,pts,.0032,M['cord'],bone,sides=5)
    for t in [.05,.13,.88,.95]:
        c=a.lerp(b,t);pts=[c+radius*1.10*(u*math.cos(q)+v*math.sin(q)) for q in [j*math.tau/40 for j in range(41)]]
        tube('Tied joint binding '+bone,pts,.004,M['rope'],bone,sides=6)
    return a,b,u,v
for side in ['L','R']:
    for bone,radius in [('forearm.'+side,.047),('shin.'+side,.047),('upper_arm.'+side,.054)]:
        a,b,u,v=braid_limb(side,bone,radius)
        if bone.startswith('forearm'):
            for k in range(6):
                angle=math.pi*.10+k*math.pi*.17
                offset=(u*math.cos(angle)+v*math.sin(angle))*.055
                tube('Weathered reed bracer splint',[a.lerp(b,.18)+offset,a.lerp(b,.49)+offset*1.08,a.lerp(b,.81)+offset*.95],.008,M['wood'],bone,sides=5)
        if bone.startswith('shin'):
            for t in [.14,.84]:
                c=a.lerp(b,t)
                loop_knot('Visible knee and ankle tied knot',(c.x,c.y-.058,c.z),.026,bone)
    foot=HEAD['foot.'+side]
    shoe=box('Woven split-toe sole',(foot.x,-.071,.035),(.115,.25,.035),M['rope'],'foot.'+side,bevel=.015)
    for offset in [-.026,.026]:tube('Tabi binding',[(foot.x+offset,-.015,.12),(foot.x+offset*.8,-.10,.09),(foot.x,-.18,.065)],.009,M['pants'],'foot.'+side,sides=7)

# Two short cloth tails, with three deform bones each and sewn hems.
for side,sign in [('L',1),('R',-1)]:
    vs=[];ps=[];w=[]
    for row in range(13):
        t=row/12;center=Vector((sign*(.10+.015*math.sin(t*3)),.13+t*.225,1.46-t*.225))
        for col in range(5):
            u=col/4-.5;p=center+Vector((u*(.075-.025*t),.008*math.cos(u*7+t*8),.004*math.sin(u*9+t*5)))
            vs.append(p);along=max(0,min(2,t*3-.5));segment=min(1,int(along));blend=along-segment
            w.append({'tail_%s_%d'%(side,segment+1):1-blend,'tail_%s_%d'%(side,segment+2):blend})
    for row in range(12):
        for col in range(4):i=row*5+col;ps.append((i,i+1,i+6,i+5))
    tail=mesh('Short trailing hood cloth '+side,vs,ps,M['cloth']);bind(tail,weights=w)

print('EAVE_RUNNER_MESH_READY',len([o for o in bpy.context.scene.objects if o.type=='MESH']),flush=True)

# Deterministic two-bone solves keep hands/feet on the intended contacts.
def orient(name,start,end):
    q=(TAIL[name]-HEAD[name]).rotation_difference(end-start)
    rig.pose.bones[name].matrix=Matrix.Translation(start)@q.to_matrix().to_4x4()@REST[name].to_3x3().to_4x4()
    bpy.context.view_layer.update()
def limb(upper,lower,endbone,target,pole,end_angle=0):
    start=rig.pose.bones[upper].head.copy();a=(TAIL[upper]-HEAD[upper]).length;b=(TAIL[lower]-HEAD[lower]).length
    delta=Vector(target)-start;distance=max(abs(a-b)+.0001,min(delta.length,a+b-.0001));axis=delta.normalized()
    along=(a*a-b*b+distance*distance)/(2*distance);bend=Vector(pole)-start;bend-=axis*bend.dot(axis)
    if bend.length<.0001:bend=Vector((0,-1,0))
    bend.normalize();elbow=start+axis*along+bend*math.sqrt(max(0,a*a-along*along));target=start+axis*distance
    orient(upper,start,elbow);orient(lower,elbow,target)
    rotation=Matrix.Rotation(end_angle,4,'X')
    rig.pose.bones[endbone].matrix=Matrix.Translation(target)@rotation@REST[endbone].to_3x3().to_4x4();bpy.context.view_layer.update()
def mix(a,b,t):return Vector(a).lerp(Vector(b),max(0,min(1,t)))
def ease(t):return max(0,min(1,t))**2*(3-2*max(0,min(1,t)))

CLIPS=[('idle',2.4,True),('run',.8,True),('wall_attach',.35,False),('wall_perch',1.6,True),('wall_windup',.45,False),('wall_launch',.30,False),('jump_slash',.65,False),('land_recover',.60,False),('throw_windup',.45,False),('throw_release',.35,False),('hurt',.40,False),('death',1.20,False)]

def pose(clip,t):
    # An earlier action must not re-evaluate over the authored solve while
    # collecting the next action's matrices at the current scene frame.
    if rig.animation_data:rig.animation_data.action=None
    for pb in rig.pose.bones:pb.rotation_mode='QUATERNION';pb.matrix_basis=Matrix.Identity(4)
    phase=t*math.tau;s=ease(t)
    pelvis=Vector((0,0,0));lean=0;twist=0
    feet={side:HEAD['foot.'+side].copy() for side in ['L','R']}
    hands={'L':Vector((.28,-.23,1.14)),'R':Vector((-.30,-.18,1.10))}
    if clip=='idle':pelvis.z=.006*math.sin(phase);lean=.025;hands['L'].z+=.009*math.sin(phase)
    if clip=='run':
        pelvis.z=-.055+.017*math.cos(phase*2);lean=.16
        for side,sign in [('L',1),('R',-1)]:
            q=phase+(0 if sign==1 else math.pi);feet[side].y+=.19*math.cos(q);feet[side].z+=.12*max(0,math.sin(q))
            hands[side]=Vector((sign*.26,-.08+sign*.17*math.cos(phase),1.20+.03*math.sin(q)))
    if clip.startswith('wall_'):
        amount=s if clip=='wall_attach' else 1
        pelvis=mix((0,0,0),(0,.10,-.15),amount);lean=-.08*amount
        hands['L']=mix(hands['L'],(.23,.38,1.39),amount);hands['R']=mix(hands['R'],(-.29,-.04,1.52),amount)
        feet['L']=mix(feet['L'],(.15,.35,.31),amount);feet['R']=mix(feet['R'],(-.17,.35,.69),amount)
        if clip=='wall_perch':pelvis.z+=.005*math.sin(phase)
        if clip=='wall_windup':
            pelvis.z-=.07*s;hands['R']=mix(hands['R'],(-.22,.04,1.59),s)
        if clip=='wall_launch':
            pelvis=mix(pelvis,(0,-.02,.16),s);lean=.4*s
            hands['L']=mix(hands['L'],(.34,-.34,1.34),s)
            feet['L']=mix(feet['L'],(.18,.24,.50),s);feet['R']=mix(feet['R'],(-.22,.40,.68),s)
    if clip=='jump_slash':
        pelvis=Vector((.02*math.sin(math.pi*t),-.02,.15-.10*s));lean=.30;twist=-.35+.72*s
        hands['R']=mix((-.24,-.10,1.60),(.37,-.34,1.08),s)
        hands['L']=mix((.34,-.30,1.36),(.25,.10,1.24),s)
        feet['L']=mix((.16,.23,.49),(.22,.04,.25),s);feet['R']=mix((-.22,.40,.67),(-.19,.25,.49),s)
    if clip=='land_recover':
        amount=1-ease(t);pelvis.z=-.24*amount;lean=.40*amount
        feet['L'].x+=.08*amount;feet['L'].y-=.09*amount;feet['R'].y+=.10*amount
        hands['L']=mix(hands['L'],(.30,-.25,.52),amount);hands['R']=mix(hands['R'],(-.37,-.14,.83),amount)
    if clip in ['throw_windup','throw_release']:
        twist=.25;amount=s if clip=='throw_windup' else 1
        hands['L']=mix(hands['L'],(.25,.03,1.56),amount)
        if clip=='throw_release':hands['L']=mix((.25,.03,1.56),(.12,-.53,1.34),s);twist=.25-.40*s
    if clip=='hurt':
        recoil=math.sin(math.pi*t);pelvis.y=.055*recoil;lean=-.18*recoil;hands['L'].y+=.15*recoil
    if clip=='death':
        pelvis.z=-.50*s;pelvis.y=.15*s;lean=-.48*s
        hands['L']=mix(hands['L'],(.35,.13,.65),s);hands['R']=mix(hands['R'],(-.39,.04,.52),s)
        feet['L'].x+=.09*s;feet['R'].x-=.07*s
    pb=rig.pose.bones['pelvis'];pb.location=REST['pelvis'].to_quaternion().inverted()@pelvis
    for name,angle,axis in [('spine',lean*.45,'X'),('chest',lean*.55,'X'),('chest',twist,'Z')]:
        pb=rig.pose.bones[name];world=Quaternion((1,0,0) if axis=='X' else (0,0,1),angle)
        q=REST[name].to_quaternion();pb.rotation_quaternion=pb.rotation_quaternion@(q.inverted()@world@q)
    bpy.context.view_layer.update()
    blade_angle=0
    if clip in ['wall_attach','wall_perch']:blade_angle=-2.0*(s if clip=='wall_attach' else 1)
    if clip=='wall_windup':blade_angle=-2.0-.7*s
    if clip=='wall_launch':blade_angle=-2.7+.6*s
    if clip=='jump_slash':blade_angle=-2.1+1.95*s
    if clip=='land_recover':blade_angle=-.15*(1-s)
    for side,sign in [('L',1),('R',-1)]:
        limb('thigh.'+side,'shin.'+side,'foot.'+side,feet[side],(sign*.20,-1.3,.7),math.pi/2 if clip.startswith('wall_') else 0)
        limb('upper_arm.'+side,'forearm.'+side,'hand.'+side,hands[side],(sign*.80,-.40,1.10),blade_angle if side=='R' else 0)
        for digit in range(1,6):
            for segment in range(1,4):
                pb=rig.pose.bones['finger%d-%d.%s'%(digit,segment,side)]
                curl=.64 if side=='R' else (.25 if clip not in ['throw_windup','wall_perch','wall_attach','wall_windup'] else .40)
                if side=='L' and clip in ['wall_perch','wall_attach','wall_windup']:curl=.10
                pb.rotation_quaternion=Quaternion((1,0,0),curl if digit>1 else .18)
    for side,sign in [('L',1),('R',-1)]:
        for i in range(3):
            pb=rig.pose.bones['tail_%s_%d'%(side,i+1)]
            sway=.045*math.sin(phase-i*.6+sign*.2) if clip in ['idle','wall_perch','run'] else .12*math.sin(math.pi*t-i*.45)
            trail=(.22 if clip in ['wall_launch','jump_slash','run'] else 0)*(i+1)/3
            pb.rotation_quaternion=Quaternion((1,0,0),sway+trail)@Quaternion((0,0,1),sway*.4)
    if clip!='throw_windup' and not (clip=='throw_release' and t<=.35):
        rig.pose.bones['held_pin'].scale=Vector((.001,.001,.001))
    if clip=='death':
        for side in ['L','R']:
            for i in range(3):rig.pose.bones['tail_%s_%d'%(side,i+1)].scale=Vector((1,1,1+.30*s))
    bpy.context.view_layer.update()

# Make the held weapon in its relaxed grip, then move geometry back to bind space.
pose('idle',0)
def held_weapon():
    old=set(bpy.context.scene.objects);grip=rig.pose.bones['hand.R'].head.copy()+Vector((.005,-.040,-.035));axis=Vector((0,-.30,-.95)).normalized();cross=Vector((1,0,0))
    guard=grip+axis*.075;tip=guard+axis*.34+Vector((.012,-.01,0));back=grip-axis*.09
    tube('Wrapped short blade grip',[back,grip,guard],.014,M['pants'],weights=False,sides=9)
    for i in range(9):
        c=back.lerp(guard,i/8)
        tube('Blade grip flax winding',[c+.016*(cross*math.cos(a)+axis.cross(cross)*math.sin(a)) for a in [k*math.tau/12 for k in range(13)]],.0017,M['rope'],weights=False,sides=4)
    box('Oval blade guard',guard,(.10,.035,.017),M['metal'],bevel=.008)
    vs=[guard+cross*.030,guard-cross*.024,tip,guard+Vector((0,-.010,0)),guard+Vector((0,.010,0))]
    blade=mesh('Forged short iron blade',vs,[(0,3,2),(3,1,2),(0,2,4),(1,4,2),(0,4,1,3)],M['edge'],smooth=False)
    for ob in set(bpy.context.scene.objects)-old:
        if ob.type!='MESH':continue
        unpose=REST['blade']@rig.pose.bones['blade'].matrix.inverted()
        for v in ob.data.vertices:v.co=unpose@v.co
        bind(ob,'blade')
held_weapon()
rig.pose.bones['held_pin'].scale=Vector((1,1,1))
bpy.context.view_layer.update()
old=set(bpy.context.scene.objects);grip=rig.pose.bones['hand.L'].head.copy()+Vector((0,-.03,0))
tube('Held throwing pin',[(grip.x,grip.y,grip.z-.07),(grip.x,grip.y,grip.z+.10)],.004,M['metal'],weights=False,sides=6)
for ob in set(bpy.context.scene.objects)-old:
    if ob.type=='MESH':
        unpose=REST['held_pin']@rig.pose.bones['held_pin'].matrix.inverted()
        for v in ob.data.vertices:v.co=unpose@v.co
        bind(ob,'held_pin')

# Bake actual deform-bone transforms; no live IK or authoring constraints export.
scene=bpy.context.scene;scene.name='EaveRunner_Review';scene.render.fps=30
rig.animation_data_create();actions={}
for clip,duration,loop in CLIPS:
    count=round(duration*30)+1;samples=[]
    for frame in range(1,count+1,2):
        t=(frame-1)/(count-1);pose(clip,t)
        matrices={pb.name:pb.matrix.copy() for pb in rig.pose.bones};local={}
        for b in rig.data.bones:
            local[b.name]=b.matrix_local.inverted()@b.parent.matrix_local@matrices[b.parent.name].inverted()@matrices[b.name] if b.parent else b.matrix_local.inverted()@matrices[b.name]
        samples.append((frame,local))
    if samples[-1][0]!=count:
        pose(clip,1);matrices={pb.name:pb.matrix.copy() for pb in rig.pose.bones}
        samples.append((count,{b.name:b.matrix_local.inverted()@b.parent.matrix_local@matrices[b.parent.name].inverted()@matrices[b.name] if b.parent else b.matrix_local.inverted()@matrices[b.name] for b in rig.data.bones}))
    action=bpy.data.actions.new(clip);action.use_fake_user=True;action['loop']=loop;action['duration']=duration;rig.animation_data.action=action
    for frame,local in samples:
        for pb in rig.pose.bones:
            pb.location,pb.rotation_quaternion,pb.scale=local[pb.name].decompose()
            for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=pb.name)
    actions[clip]=action;print('EAVE_RUNNER_CLIP',clip,flush=True)
rig.animation_data.action=actions['idle'];scene.frame_set(1);scene.frame_start=1;scene.frame_end=73
events={'wall_attach':{'contact':.30},'wall_windup':{'aim_lock':.35},'wall_launch':{'detach':.06},
 'jump_slash':{'slash_on':.14,'slash_off':.39},'throw_windup':{'aim_lock':.35},'throw_release':{'release':.13},'land_recover':{'recovered':.55}}
for clip,markers in events.items():
    for name,seconds in markers.items():marker=actions[clip].pose_markers.new(name);marker.frame=1+round(seconds*30)
(SOURCE/'animation_events.json').write_text(json.dumps(events,indent=2))

# One skinned actor, separate editable material slots and the full deform rig.
actor_parts=[o for o in scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for ob in actor_parts:ob.select_set(True)
bpy.context.view_layer.objects.active=actor_parts[0];bpy.ops.object.join();actor=bpy.context.object;actor.name='EaveRunner_TexturedMesh'
triangles=sum(len(p.vertices)-2 for p in actor.data.polygons)
bpy.ops.object.select_all(action='DESELECT');actor.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(ASSET/'Models/EaveRunner_v1.glb'),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)

# Studio review. The wall is a render-only contact reference, not asset geometry.
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Guardian Review World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.27,.32,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45;scene.world=world
floor=box('REVIEW Floor',(0,0,-.022),(200,200,.035),material('REVIEW grey',(.13,.15,.17)),bevel=0)
wall=box('REVIEW Wall',(0,.435,1.2),(1.25,.06,2.4),M['wood']);wall.hide_render=True
target=Vector((0,0,.94))
bpy.ops.object.camera_add(location=(2.6,-5.8,2.45));camera=bpy.context.object;camera.name='REVIEW Camera';camera.data.type='ORTHO';camera.data.ortho_scale=2.30;scene.camera=camera
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
for name,pos,power,size,color in [('Key',(-3,-4,5),580,4,(1,.86,.72)),('Fill',(3,-2,3),380,3,(.66,.82,1)),('Rim',(0,3,4),650,3,(.80,.88,1))]:
    bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.name='REVIEW '+name;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.data.color=color;light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
if '--skip-renders' not in sys.argv:
    for clip,frame in [('idle',1),('wall_perch',1),('jump_slash',12),('land_recover',1),('throw_release',7)]:
        rig.animation_data.action=actions[clip];scene.frame_set(frame);wall.hide_render=clip!='wall_perch'
        scene.render.filepath=str(WORK/'renders'/(clip+'.png'));bpy.ops.render.render(write_still=True)
wall.hide_render=True;rig.animation_data.action=actions['idle'];scene.frame_set(1)
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'EaveRunner_Woven_v1.blend'),compress=True)
report={'triangles':triangles,'vertices':len(actor.data.vertices),'bones':len(rig.data.bones),'materials':len(actor.data.materials),
 'clips':[{'name':n,'duration':d,'loop':l} for n,d,l in CLIPS],'cloth_bones':6,'front':'-Y Blender / +Z Godot',
 'source_base':'CC0 MakeHuman hm08 fitting surface, remapped deform weights; new clothing, cord geometry, props and animation',
 'maker':'Unspecified; visual allegiance is Hermit-aligned','scope':'Rigged animated art asset; no live combat controller or replacement of Reedhook'}
(SOURCE/'build_report.json').write_text(json.dumps(report,indent=2));(SOURCE/'material_export_factors.json').write_text(json.dumps(FACTORS,indent=2))
print('EAVE_RUNNER_BUILT',json.dumps(report),flush=True)
