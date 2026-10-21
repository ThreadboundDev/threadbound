"""Tailored, visibly woven Eave Runner rebuild around the approved animation rig.

This is native mesh authoring, not another blanket subdivision pass. Run in
background Blender; the packed source retains semantic editable components.
"""
from pathlib import Path
import bpy,bmesh,math,json,os,tempfile,random,sys
from mathutils import Vector,Matrix
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/eave-runner-v3';SRC=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner';ASSET=ROOT/'Assets/BlueBiome/Enemies/EaveRunner';TEX=ROOT/'Assets/BlueBiome/Characters/SharedTexturesV2'
for p in [WORK/'temp',WORK/'renders',SRC,ASSET/'Models']:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
random.seed(832)
bpy.ops.wm.open_mainfile(filepath=str(SRC/'EaveRunner_Woven_v2.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];rig.animation_data.action=None
for p in rig.pose.bones:p.location=(0,0,0);p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.scale=(1,1,1)
for o in list(bpy.data.objects):
    if o.type in ['MESH','LIGHT']:bpy.data.objects.remove(o,do_unlink=True)
for coll in [bpy.data.meshes,bpy.data.materials,bpy.data.images]:
    for data in list(coll):
        if not data.users and not data.use_fake_user:coll.remove(data)
sc.frame_set(1);bpy.context.view_layer.update()
H={b.name:b.head_local.copy() for b in rig.data.bones};T={b.name:b.tail_local.copy() for b in rig.data.bones}
OLD_REST={b.name:b.matrix_local.copy() for b in rig.data.bones}

M={};FACTORS={}
def material(key,name,color,family=None,normal=.25,rough=.75,metal=0):
    m=bpy.data.materials.new('Eave V3 | '+name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;bs=n.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    FACTORS[m.name]=[*color,1]
    if family:
        for channel in ['BaseColor','Normal','Roughness']:
            file=TEX/(family+'_'+channel+'_4K.png')
            im=n.new('ShaderNodeTexImage');im.image=bpy.data.images.load(str(file),check_existing=True)
            if channel=='BaseColor':
                mul=n.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[2].default_value=(*color,1);l.new(im.outputs[0],mul.inputs[1]);l.new(mul.outputs[0],bs.inputs['Base Color'])
            elif channel=='Normal':
                im.image.colorspace_settings.name='Non-Color';nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=normal;l.new(im.outputs[0],nm.inputs[1]);l.new(nm.outputs[0],bs.inputs['Normal'])
            else:im.image.colorspace_settings.name='Non-Color';l.new(im.outputs[0],bs.inputs['Roughness'])
    M[key]=m;return m
material('indigo','tailored indigo linen',(.20,.34,.52),'IndigoWeave',normal=.20)
material('faded','weathered indigo linen',(.34,.48,.64),'IndigoWeave',normal=.20)
material('navy','folded navy lining',(.09,.15,.23),'IndigoWeave',normal=.22)
material('charcoal','gathered charcoal hemp',(.08,.10,.13),'IndigoWeave',normal=.24)
material('core','charcoal woven tendons',(.37,.43,.52),'WovenCord',normal=.22)
material('corelight','worn exposed cord',(.53,.54,.52),'WovenCord',normal=.25)
material('rope','aged flax braid',(.55,.40,.24),'FlaxWeave',normal=.42)
material('rope_light','worn flax fibres',(.76,.61,.39),'FlaxWeave',normal=.42)
material('patch','undyded flax repairs',(.73,.71,.61),'FlaxWeave',normal=.22)
material('ivory','carved ivory ceramic',(.97,.96,.88),'AgedCeramic',normal=.11)
material('edge','exposed ceramic cut',(.53,.46,.32),'AgedCeramic',normal=.16)
material('dark','recessed lacquer',(.009,.013,.018),rough=.64)
material('ink','indigo fracture glaze',(.015,.035,.054),rough=.35)
material('metal','worn patinated bronze',(.13,.115,.075),rough=.55,metal=.72)
material('blade','forged iron blade',(.18,.22,.25),rough=.40,metal=.8)
material('blade_edge','honed blade bevel',(.55,.60,.62),rough=.29,metal=.86)
wood=material('wood','split amber bamboo',(.81,.62,.38),rough=.68)
wn=wood.node_tree.nodes;wl=wood.node_tree.links;bs=wn.get('Principled BSDF');woodtex=ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures'
for ch in ['BaseColor','NormalGL','Roughness']:
    im=wn.new('ShaderNodeTexImage');im.image=bpy.data.images.load(str(woodtex/('walnut_'+ch+'_4K.png')),check_existing=True)
    if ch=='BaseColor':
        mul=wn.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[2].default_value=(.81,.62,.38,1);wl.new(im.outputs[0],mul.inputs[1]);wl.new(mul.outputs[0],bs.inputs['Base Color'])
    elif ch=='NormalGL':
        im.image.colorspace_settings.name='Non-Color';nm=wn.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.3;wl.new(im.outputs[0],nm.inputs[1]);wl.new(nm.outputs[0],bs.inputs['Normal'])
    else:im.image.colorspace_settings.name='Non-Color';wl.new(im.outputs[0],bs.inputs['Roughness'])
charge=material('charge','charged thread',(.02,.24,.34),rough=.4)
charge.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value=(.035,.42,.65,1)
charge.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=.18

# Use the established CC0 fitting surface and original skin mapping solely for
# joint continuity. New visible construction is explicitly authored above it.
CC0=ROOT/'ArtSource/BlueBiome/Villagers/CC0_Source'
vv=[];texcoords=[];faces=[];group=''
for line in (CC0/'base.obj').read_text().splitlines():
    q=line.split()
    if not q:continue
    if q[0]=='v':vv.append(Vector(tuple(map(float,q[1:4]))))
    elif q[0]=='vt':texcoords.append(tuple(map(float,q[1:3])))
    elif q[0]=='g':group=' '.join(q[1:])
    elif q[0]=='f':
        ids=[];uv=[]
        for token in q[1:]:
            v=token.split('/');ids.append(int(v[0])-1);uv.append(texcoords[int(v[1])-1] if len(v)>1 and v[1] else (0,0))
        faces.append((ids,uv,group))
for line in (CC0/'asian-male-young.target').read_text().splitlines():
    if line and not line.startswith('#'):
        q=line.split();vv[int(q[0])]+=Vector(tuple(map(float,q[1:4])))
ids={i for f,uv,g in faces if g=='body' for i in f};ground=min(vv[i].y for i in ids);scale=1.78/(max(vv[i].y for i in ids)-ground)
vv=[Vector((v.x*scale,-v.z*scale,(v.y-ground)*scale+.025)) for v in vv]
oldrig=json.loads((CC0/'default.mhskel').read_text())
def oldjoint(name):return sum((vv[i] for i in oldrig['joints'][oldrig['bones'][name]['head']]),Vector())/len(oldrig['joints'][oldrig['bones'][name]['head']])
def mapped(name):
    side='.'+name.rsplit('.',1)[1] if '.' in name else ''
    if name.startswith('finger'):return name
    for prefix,dst in [('upperarm','upper_arm'),('lowerarm','forearm'),('upperleg','thigh'),('lowerleg','shin'),('clavicle','clavicle'),('shoulder','clavicle'),('foot','foot'),('toe','toe')]:
        if name.startswith(prefix):return dst+side
    if name.startswith(('wrist','metacarpal')):return 'hand'+side
    if name.startswith('spine'):return 'chest' if oldjoint(name).z>1.28 else 'spine'
    if name.startswith('neck'):return 'neck'
    if name.startswith(('root','pelvis')):return 'pelvis'
    if name.startswith('breast'):return 'chest'
    return 'head'
W=[{} for v in vv]
for name,items in json.loads((CC0/'default_weights.mhw').read_text())['weights'].items():
    bn=mapped(name)
    for i,w in items:W[i][bn]=W[i].get(bn,0)+w
kd=KDTree(len(ids))
for i in ids:kd.insert(vv[i],i)
kd.balance()
def normweights(w):
    w=dict(sorted(((n,v) for n,v in w.items() if n in H and v>1e-7),key=lambda t:t[1],reverse=True)[:4]);total=sum(w.values()) or 1
    return {n:v/total for n,v in w.items()}
def transfer(co):
    w={}
    for p,i,d in kd.find_n(co,3):
        factor=1/max(.003,d)**2
        for n,v in W[i].items():w[n]=w.get(n,0)+v*factor
    return normweights(w)
def torso_weights(z):
    if z<1.09:return normweights({'pelvis':1,'spine':max(0,(z-1.015)*6)})
    t=max(0,min(1,(z-1.16)/.24));return normweights({'spine':1-t,'chest':t})

B={}
def add(part,mat,verts,faces,bone=None,uv=None,weights=None,smooth=True):
    key=(part,mat,smooth)
    if key not in B:B[key]={'v':[],'f':[],'uv':[],'w':[]}
    q=B[key];off=len(q['v']);verts=[Vector(v) for v in verts]
    q['v']+=verts;q['f']+=[tuple(off+i for i in f) for f in faces]
    q['uv']+=uv if uv is not None else [(v.x*3+.5,v.z*3) for v in verts]
    q['w']+=[normweights(w) for w in weights] if weights is not None else [{bone:1} if bone else transfer(v) for v in verts]
def sample(points,steps=6):
    p=[Vector(v) for v in points];out=[]
    for j in range(len(p)-1):
        a=p[max(0,j-1)];b=p[j];c=p[j+1];d=p[min(j+2,len(p)-1)]
        for i in range(steps):
            t=i/steps;out.append(.5*(2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    return out+[p[-1]]
def frames(ps):
    ps=[Vector(p) for p in ps];out=[];prev=None
    for i,p in enumerate(ps):
        axis=(ps[min(i+1,len(ps)-1)]-ps[max(0,i-1)]).normalized();u=axis.cross(Vector((0,0,1)))
        if u.length<.1:u=axis.cross(Vector((0,1,0)))
        u.normalize()
        if prev is not None and prev.dot(u)<0:u=-u
        prev=u;out.append((u,axis.cross(u).normalized()))
    return out
def tube(part,points,radius,mat,bone=None,sides=10,smooth=0,shading=True):
    ps=sample(points,smooth) if smooth else [Vector(v) for v in points];fr=frames(ps);vs=[];uv=[];fs=[];distance=0
    for i,p in enumerate(ps):
        if i:distance+=(p-ps[i-1]).length
        r=radius(i/(len(ps)-1)) if callable(radius) else radius;u,v=fr[i]
        for k in range(sides+1):
            a=k/sides*math.tau;vs.append(p+r*(u*math.cos(a)+v*math.sin(a)));uv.append((k/sides*.3,distance*3))
    n=sides+1
    for i in range(len(ps)-1):
        for k in range(sides):fs.append((i*n+k,i*n+k+1,(i+1)*n+k+1,(i+1)*n+k))
    fs += [tuple(range(sides-1,-1,-1)),tuple((len(ps)-1)*n+k for k in range(sides))]
    add(part,mat,vs,fs,bone,uv,smooth=shading)
def braid(part,points,radius,mat,bone=None,pitch=.055,strands=3,smooth=6):
    ps=sample(points,smooth) if smooth else [Vector(p) for p in points];d=[0]
    for a,b in zip(ps,ps[1:]):d.append(d[-1]+(b-a).length)
    count=max(9,int(d[-1]/pitch*15));new=[];j=0
    for i in range(count+1):
        dist=d[-1]*i/count
        while j<len(d)-2 and d[j+1]<dist:j+=1
        new.append(ps[j].lerp(ps[j+1],(dist-d[j])/max(1e-8,d[j+1]-d[j])))
    fr=frames(new)
    for k in range(strands):
        path=[]
        for i,p in enumerate(new):
            angle=math.tau*(d[-1]*i/count/pitch+k/strands);u,v=fr[i];path.append(p+radius*.52*(u*math.cos(angle)+v*math.sin(angle)))
        tube(part,path,radius*.48,'rope_light' if mat=='rope' and k==1 else mat,bone,sides=8)
def bindwrap(part,a,b,r,bone,turns=3):
    a=Vector(a);b=Vector(b);ax=(b-a).normalized();u=ax.cross(Vector((0,0,1)))
    if u.length<.1:u=ax.cross(Vector((0,1,0)))
    u.normalize();v=ax.cross(u);ps=[]
    for i in range(turns*16+1):
        t=i/(turns*16);an=t*turns*math.tau;ps.append(a.lerp(b,t)+r*(u*math.cos(an)+v*math.sin(an)))
    tube(part,ps,.0042,'rope',bone,sides=8)
    braid(part,[a+u*r,b+u*r,b-v*r*.8,a-u*r],.0065,'rope',bone,pitch=.038,smooth=5)
def knot(part,center,r,bone):
    c=Vector(center);ps=[]
    for i in range(145):
        a=i/144*math.tau;ps.append(c+Vector((r*math.sin(a),.008*math.sin(3*a),r*.56*math.sin(2*a))))
    braid(part,ps,.009,'rope',bone,pitch=.04,smooth=0)
    for s in [-1,1]:braid(part,[c+Vector((s*.012,0,0)),c+Vector((s*.016,-.003,-.042)),c+Vector((s*.024,.004,-.055))],.005,'rope',bone,pitch=.035)

# Keep the anatomical fitting surface only where it is actually needed: the
# articulated hands and covered neck/skull. Cord limbs have a narrower backing
# below; a full human core otherwise intersects the sculpted tunic and trousers.
vs=[];fs=[];uv=[];ww=[]
for f,tex,g in faces:
    if g!='body':continue
    c=sum((vv[i] for i in f),Vector())/len(f)
    if (c.z>1.55 and c.y<-.05) or c.z<.115:continue
    weights={}
    for i in f:
        for name,value in W[i].items():weights[name]=weights.get(name,0)+value
    dominant=max(weights,key=weights.get) if weights else ''
    if not dominant.startswith(('hand.','finger','head','neck')):continue
    start=len(vs)
    for i,t in zip(f,tex):vs.append(vv[i]);uv.append((t[0]*5,t[1]*5));ww.append(W[i])
    fs.append(tuple(range(start,len(vs))))
add('Continuous woven anatomy and articulated hands','core',vs,fs,weights=ww,uv=uv)

def rx(z):
    r=.175+.055*math.exp(-((z-1.385)/.16)**2);t=max(0,min(1,(z-1.43)/.075))
    return r*(1-t)+.104*t
def ry(z):
    r=.126+.020*math.exp(-((z-1.34)/.19)**2);t=max(0,min(1,(z-1.43)/.075))
    return r*(1-t)+.092*t
def front(x,z,offset=0):return -ry(z)*math.sqrt(max(.08,1-(x/rx(z))**2))-offset
# Tailored dark shirt, narrowed at the waist with no smooth featureless bib.
vs=[];uv=[];fs=[];ww=[];N=56;Q=35
for j in range(Q+1):
    t=j/Q;z=1.035+t*.47
    for i in range(N+1):
        a=i/N*math.tau;radius=1+.015*math.sin(9*a+z*27)
        x=rx(z)*math.sin(a)*radius;y=-ry(z)*math.cos(a)*radius
        vs.append((x,y,z));uv.append((i/N*2.1,t*1.8));ww.append(torso_weights(z))
for j in range(Q):
    for i in range(N):q=j*(N+1)+i;fs.append((q,q+1,q+N+2,q+N+1))
add('Tailored cropped charcoal under-shirt','charcoal',vs,fs,uv=uv,weights=ww)

def wrap_panel(name,corners,mat,depth=.014,fold=.012):
    vs=[];uv=[];fs=[];ww=[];nx=18;ny=35
    for j in range(ny+1):
        t=j/ny
        for i in range(nx+1):
            u=i/nx;a=Vector(corners[0]).lerp(Vector(corners[1]),u);b=Vector(corners[3]).lerp(Vector(corners[2]),u);x,z=a.lerp(b,t)
            y=front(x,z,depth)-fold*math.sin(math.pi*u)*math.sin(t*math.pi)-.006*math.sin(u*math.pi*5+t*4)*math.sin(math.pi*u)
            vs.append((x,y,z));uv.append((u*.7,t*1.5));ww.append(torso_weights(z))
    for j in range(ny):
        for i in range(nx):q=j*(nx+1)+i;fs.append((q,q+1,q+nx+2,q+nx+1))
    add(name,mat,vs,fs,uv=uv,weights=ww)
    for col in [0,nx]:
        edge=[vs[j*(nx+1)+col] for j in range(ny+1)];tube(name+' / rolled cloth lapel',edge,.0028,'navy')
        for j in range(3,ny-1,3):
            p=Vector(edge[j]);tube(name+' / sparse lapel stitching',[p+Vector((.002,-.002,-.003)),p+Vector((-.002,-.002,.003))],.0008,'rope',sides=4)
wrap_panel('Inner diagonal indigo wrap',[(-.205,1.44),(-.080,1.488),(.19,1.155),(.04,1.045)],'indigo',depth=.014,fold=.019)
wrap_panel('Outer crossed indigo wrap',[(.155,1.47),(.227,1.38),(-.035,1.065),(-.185,1.15)],'faded',depth=.023,fold=.017)
# Dark diagonal utilitarian cloth strap, tucked under the cowl and belt.
wrap_panel('Narrow brown charcoal load strap',[(.136,1.47),(.177,1.445),(-.129,1.08),(-.166,1.115)],'charcoal',depth=.032,fold=.003)

# Gathered thigh trousers: large diagonal folds, deep creases and fitted cuffs.
for side,s in [('L',1),('R',-1)]:
    bn='thigh.'+side;a=H[bn];b=T[bn];vs=[];fs=[];uv=[];ww=[];N=56;Q=44
    for j in range(Q+1):
        t=j/Q;center=a.lerp(b,t);center.z+=.035*(1-t)
        r=.068+.035*math.sin(math.pi*t)**.65-.017*t
        for k in range(N+1):
            an=k/N*math.tau
            gather=.0055*math.cos(6*an+t*9.0)*math.sin(math.pi*t)**.8
            diagonal=0
            for band in range(4):
                crease_center=.23+band*.18+.065*math.sin(an+band*.8)
                diagonal+=.007*math.exp(-((t-crease_center)/.033)**2)
                diagonal-=.0035*math.exp(-((t-crease_center-.043)/.024)**2)
            rr=r+gather+diagonal+.003*math.cos(15*an+t*5)*(t**5)
            # Rounded cut volume with shaped cloth folds, not inflated cylinders.
            p=center+Vector((rr*math.cos(an),rr*.93*math.sin(an),.004*math.sin(an*7+t*8)))
            vs.append(p);uv.append((k/N*1.8,t*1.9));pel=max(0,(.20-t)/.20)*.7;ww.append({bn:1-pel,'pelvis':pel})
    for j in range(Q):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    add('Gathered charcoal trouser '+side,'charcoal',vs,fs,uv=uv,weights=ww)
    edge=vs[-(N+1):];tube('Rolled gathered trouser cuff '+side,edge,.0045,'navy',bn,sides=8)

# Three wrapped scarf folds, with curved rolls and an asymmetric front drape.
for layer in range(3):
    vs=[];fs=[];uv=[];ww=[];N=72;Q=12
    for j in range(Q+1):
        t=j/Q
        for k in range(N+1):
            a=k/N*math.tau;fr=max(0,math.cos(a));roll=.014*math.sin(math.pi*t)
            rrx=.116+layer*.014+(t-.5)*.010+roll;rry=.113+layer*.023+(t-.5)*.016+roll
            z=1.545-layer*.030+(.5-t)*.061-.025*fr+.026*math.sin(a)-.012*fr*math.sin(math.pi*t)
            x=rrx*math.sin(a);y=-rry*math.cos(a)-.004*math.sin(a*5+layer)*math.sin(math.pi*t)
            vs.append((x,y,z));uv.append((k/N*2.2,t*.65));ww.append(torso_weights(min(z,1.48)))
    for j in range(Q):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    add('Layered diagonal shoulder cowl '+str(layer),'indigo' if layer==0 else 'faded',vs,fs,uv=uv,weights=ww)
    tube('Soft rolled cowl edge '+str(layer),vs[-(N+1):],.0045,'navy')
wrap_panel('Scarf folded diagonal front end',[(.115,1.49),(.16,1.445),(-.135,1.335),(-.178,1.397)],'indigo',depth=.041,fold=.015)

# Short shoulder/sleeve scales expose deliberate cord construction at the arm.
for side,s in [('L',1),('R',-1)]:
    bn='upper_arm.'+side;a=H[bn];b=T[bn];axis=(b-a).normalized();frontdir=Vector((0,-1,0));cross=axis.cross(frontdir).normalized()
    for layer in range(3):
        vs=[];fs=[];uv=[]
        for j in range(10):
            t=j/9
            for k in range(19):
                an=-1.8+3.6*k/18;r=.064+.005*layer-.007*t
                p=a.lerp(b,.02+layer*.065+t*.24)+r*(frontdir*math.cos(an)+cross*math.sin(an));p+=axis*(.006*math.sin(k*4+layer)*t**4)
                vs.append(p);uv.append((k/18*.8,t*.7))
        for j in range(9):
            for k in range(18):q=j*19+k;fs.append((q,q+1,q+20,q+19))
        add('Short frayed shoulder sleeve '+side+' '+str(layer),'charcoal' if layer!=1 else 'navy',vs,fs,bone=bn,uv=uv)

# Six asymmetric split overskirt tabs, skinned with the adjacent thigh.
for sector in range(7):
    angle=sector*math.tau/7+.18;vs=[];uv=[];fs=[];ww=[];N=12;Q=22
    length=.20+(.075 if sector in [0,6] else .025*(sector%2))
    for j in range(Q+1):
        t=j/Q
        for k in range(N+1):
            u=k/N;an=angle+(u-.5)*.82*(1-.25*t)
            rrx=.198+.035*t;rry=.153+.045*t;x=rrx*math.sin(an);y=-rry*math.cos(an)
            z=1.072-length*t-.020*math.sin(math.pi*u)*t+.006*math.sin(k*5+sector)*t**5
            y-=.012*math.sin(math.pi*u)*math.sin(t*5+sector)
            vs.append((x,y,z));uv.append((u*.65,t*1.1));bn='thigh.L' if x>0 else 'thigh.R';ww.append({'pelvis':1-t*.7,bn:t*.7})
    for j in range(Q):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    add('Layered split waist cloth tab '+str(sector),'faded' if sector in [0,4] else 'indigo',vs,fs,uv=uv,weights=ww)
    tube('Dark stitched waist tab hem '+str(sector),vs[-(N+1):],.0023,'navy')

# Broad textile sash and tight double flax braid, secured with a paired knot.
for layer in range(3):
    vs=[];uv=[];fs=[];N=80;Q=5
    for j in range(Q+1):
        t=j/Q
        for k in range(N+1):
            an=k/N*math.tau;z=1.035+layer*.021+t*.038+.006*math.sin(2*an+layer)
            vs.append(((.199+layer*.003)*math.sin(an),-(.154+layer*.004)*math.cos(an),z));uv.append((k/N*2,t*.3))
    for j in range(Q):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    add('Overlapping woven waist sash '+str(layer),'navy',vs,fs,'pelvis',uv)
for j in range(2):
    ps=[(.207*math.sin(k/100*math.tau),-.167*math.cos(k/100*math.tau),1.058+j*.024+.004*math.sin(k/100*math.tau*2)) for k in range(101)]
    braid('Double braided flax belt',ps,.009,'rope','pelvis',pitch=.065,smooth=0)
knot('Interlaced paired guardian waist knot',(0,-.18,1.070),.049,'pelvis')

# Visible cord bundles are tapered and articulate with the same skin skeleton.
for side,s in [('L',1),('R',-1)]:
    for prefix,rad,count in [('upper_arm',.043,9),('forearm',.034,9),('shin',.035,11)]:
        bn=prefix+'.'+side;a=H[bn];b=T[bn];axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
        if u.length<.1:u=axis.cross(Vector((0,1,0)))
        u.normalize();v=axis.cross(u)
        tube('Recessed dark cord backing '+bn,[a,a.lerp(b,.5),b],
             lambda t:rad*(.56-.10*t),'dark',bn,sides=16)
        for j in range(count):
            ps=[]
            for k in range(31):
                t=k/30;an=j/count*math.tau+.16*math.sin(t*math.pi*2+j)
                r=rad*(.90+.12*math.sin(t*math.pi)-.24*t);ps.append(a.lerp(b,t)+r*(u*math.cos(an)+v*math.sin(an)))
            braid('Organized woven '+bn+' bundle',ps,.0068 if prefix!='shin' else .0074,'corelight' if j%5==0 else 'core',bn,pitch=.067,smooth=0)
        for t in [.07,.90]:
            c=a.lerp(b,t);rr=rad*(.94-.15*t)
            ps=[c+rr*(u*math.cos(k/64*math.tau)+v*math.sin(k/64*math.tau)) for k in range(65)]
            braid('Tied joint braid '+bn,ps,.0075,'rope',bn,pitch=.044,smooth=0)
        if prefix=='shin':
            c=a.lerp(b,.065);knot('Knee tied binding '+side,(c.x,c.y-rad*1.08,c.z),.025,bn)
    # Anatomy-following finger strands and compressed knuckle bindings.
    for digit in range(1,6):
        a=H['hand.'+side];b=H['finger%d-1.%s'%(digit,side)]
        offset=Vector((0,-.006,.003))
        braid('Woven hand metacarpal tendon '+side,[a+offset,a.lerp(b,.5)+offset*1.3,b+offset],.0046,'core','hand.'+side,pitch=.036,smooth=8)
    for digit in range(1,6):
        for seg in range(1,4):
            bn='finger%d-%d.%s'%(digit,seg,side);a=H[bn];b=T[bn]
            radius=.005 if digit!=1 else .006
            braid('Articulated woven finger '+bn,[a,b],radius,'corelight' if seg==3 else 'core',bn,pitch=.027,smooth=7)
            if seg==2:bindwrap('Finger joint tie '+bn,a.lerp(b,.10),a.lerp(b,.26),radius*.95,bn,2)
    # Fitted four-stave bamboo bracer covering the outside, not a pole cage.
    bn='forearm.'+side;a=H[bn];b=T[bn];axis=(b-a).normalized();frontdir=Vector((0,-1,0));frontdir-=axis*frontdir.dot(axis);frontdir.normalize();across=axis.cross(frontdir).normalized()
    for j in range(4):
        an=-.88+j*.58;out=frontdir*math.cos(an)+across*math.sin(an);tangent=axis.cross(out).normalized();vs=[];uv=[];fs=[]
        for k in range(17):
            t=k/16;center=a.lerp(b,.16+t*.64)+out*(.043-.007*t+.004*math.sin(math.pi*t));w=.018*(.65+.35*math.sin(math.pi*t))
            for q,(xx,yy) in enumerate([(-.4,-.002),(.4,-.002),(.5,0),(.5,.0035),(.4,.005),(-.4,.005),(-.5,.0035),(-.5,0)]):
                vs.append(center+tangent*(xx*w*2)+out*yy);uv.append((q/8*.24,t*.9))
        for k in range(16):
            for q in range(8):fs.append((k*8+q,k*8+(q+1)%8,(k+1)*8+(q+1)%8,(k+1)*8+q))
        fs += [tuple(range(7,-1,-1)),tuple(16*8+q for q in range(8))]
        add('Carved bamboo bracer stave '+side+' '+str(j),'wood',vs,fs,bn,uv)
    for t in [.23,.72]:
        c=a.lerp(b,t);rr=.047-.006*t
        ps=[c+rr*(frontdir*math.cos(k/72*math.tau)+across*math.sin(k/72*math.tau)) for k in range(73)]
        braid('Bracer fitted fastening bands '+side,ps,.0075,'rope',bn,pitch=.05,smooth=0)
        # Small patinated fastening stitches through the wooden stave bands.
        for an in [-.75,.75]:
            c2=c+rr*(frontdir*math.cos(an)+across*math.sin(an))
            tube('Bracer bronze fastening '+side,[c2-axis*.009,c2+axis*.009],.0022,'metal',bn,sides=8)

# Woven split-toe sandals and fitted straps around the actual source feet.
for side,s in [('L',1),('R',-1)]:
    x=H['foot.'+side].x;bn='foot.'+side
    # Cloth covers the five anatomical toes as two sewn tabi compartments.
    sections=[(.075,.064,.028,.031),(.035,.075,.040,.054),(-.025,.061,.052,.048),(-.085,.051,.054,.032),(-.132,.047,.051,.026)]
    vs=[];uv=[];fs=[];N=40
    for j,(y,z,w,h) in enumerate(sections):
        for k in range(N+1):
            a=k/N*math.tau;p=(x+w*math.sin(a),y,max(.025,z+h*math.cos(a)))
            vs.append(p);uv.append((k/N*.85,j/(len(sections)-1)*1.1))
    for j in range(len(sections)-1):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    fs.append(tuple(range(N-1,-1,-1)))
    add('Sewn indigo tabi heel and ankle '+side,'navy',vs,fs,bn,uv)
    for toe,offset,w in [('large',-s*.027,.024),('outer',s*.022,.029)]:
        vs=[];uv=[];fs=[];N=32;Q=18
        for j in range(Q+1):
            t=j/Q;y=-.112-.110*t;ww=w*(1-.90*t**4)
            for k in range(N+1):
                a=k/N*math.tau;z=.047+.024*math.cos(a)*(1-.52*t**3)
                vs.append((x+offset+ww*math.sin(a),y,max(.025,z)));uv.append((k/N*.6,t*.8))
        for j in range(Q):
            for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
        fs.append(tuple(Q*(N+1)+k for k in range(N)))
        add('Sewn split tabi toe '+side+' '+toe,'navy',vs,fs,bn,uv)
        tube('Tabi topstitch '+side+' '+toe,[(x+offset,-.119,.072),(x+offset,-.18,.071),(x+offset,-.218,.061)],.0011,'faded',bn,sides=6,smooth=9)
    for layer in range(3):
        ps=[]
        for k in range(101):
            a=k/100*math.tau;ps.append((x+.056*math.sin(a),-.065+.143*math.cos(a),.026+layer*.005))
        braid('Braided split toe sandal sole '+side,ps,.0045,'rope',bn,pitch=.045,smooth=0)
    for j in [-1,1]:
        braid('Crossed indigo sandal strap '+side,[(x+j*.04,.015,.075),(x+j*.019,-.065,.102),(x,-.128,.062)],.009,'navy',bn,pitch=.055)
    c=H['foot.'+side];bindwrap('Tied ankle sandal binding '+side,c+Vector((0,0,.036)),c+Vector((0,0,.014)),.027,bn,3)

# Short rigged scarf tails; all six existing cloth bones retain useful weights.
for side,s in [('L',1),('R',-1)]:
    vs=[];uv=[];fs=[];ww=[];N=10;Q=30
    for j in range(Q+1):
        t=j/Q;c=Vector((s*(.10+.018*math.sin(t*3)),.13+t*.225,1.46-t*.225))
        for k in range(N+1):
            u=k/N-.5;p=c+Vector((u*(.082-.026*t),.010*math.sin(k/10*math.pi*4+t*8),.006*math.sin(k*3)*t**4));vs.append(p);uv.append((k/N*.4,t*1.1))
            pos=max(0,min(2,t*3-.5));seg=min(1,int(pos));blend=pos-seg;ww.append({'tail_%s_%d'%(side,seg+1):1-blend,'tail_%s_%d'%(side,seg+2):blend})
    for j in range(Q):
        for k in range(N):q=j*(N+1)+k;fs.append((q,q+1,q+N+2,q+N+1))
    add('Short articulated scarf tail '+side,'indigo' if s==1 else 'faded',vs,fs,uv=uv,weights=ww)

# Head specialist authors the pierced ceramic and tailored hood using the same
# material and skin buffers. Its construction is editable in the saved file.
sys.path.insert(0,str(ROOT/'tools/art'))
import eave_v3_head
before_head=set(B)
eave_v3_head.build({'add':add,'tube':tube,'braid':braid,'sample':sample})
head_keys=set(B)-before_head

# Weapon is authored in the approved idle grip, then moved back to bind space.
rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1)
# Idle hides the pin by scaling its attachment. Author in the visible bind
# transform before inversion; otherwise the inverse magnifies it 1000 times.
rig.pose.bones['held_pin'].scale=(1,1,1);bpy.context.view_layer.update()
old_idle={n:rig.pose.bones[n].matrix.copy() for n in ['blade','held_pin']}
grip=rig.pose.bones['hand.R'].head.copy()+Vector((.005,-.040,-.035));axis=Vector((0,-.30,-.95)).normalized();cross=Vector((1,0,0));normal=axis.cross(cross).normalized();guard=grip+axis*.075;tip=guard+axis*.34+Vector((.012,-.01,0));back=grip-axis*.09
before={key:len(q['v']) for key,q in B.items()}
tube('Short blade wrapped handle',[back,grip,guard],.0135,'navy','blade',sides=14,smooth=8)
bindwrap('Tight blade grip flax crossing',back,guard,.0148,'blade',9)
tube('Patinated oval blade guard',[guard-normal*.005,guard+normal*.005],.035,'metal','blade',sides=24,shading=False)
vs=[];uv=[]
for c,w in [(guard,.026),(guard.lerp(tip,.12),.028),(guard.lerp(tip,.75),.012),(tip,.0005)]:
    for sign,h in [(-1,0),(-.76,-.003),(.76,-.003),(1,0),(.76,.003),(-.76,.003)]:vs.append(c+cross*w*sign+normal*h);uv.append(((sign+1)/2,(c-guard).length*3))
centerfaces=[];edgefaces=[]
for j in range(3):
    for k in range(6):
        f=(j*6+k,j*6+(k+1)%6,(j+1)*6+(k+1)%6,(j+1)*6+k)
        (centerfaces if k in [1,4] else edgefaces).append(f)
add('Forged dark blade flats','blade',vs,centerfaces,'blade',uv,smooth=False)
add('Honed blade edge bevels','blade_edge',vs,edgefaces,'blade',uv,smooth=False)
for sign in [-1,1]:tube('Dark blade spine fuller',[guard+cross*sign*.009,guard.lerp(tip,.73)+cross*sign*.006],.0015,'blade','blade',sides=6,smooth=12)
pin=rig.pose.bones['hand.L'].head.copy()+Vector((0,-.03,0));pina=pin+Vector((0,0,-.07));pinb=pin+Vector((0,0,.10))
tube('Held pin dark iron shaft',[pina,pinb],.004,'blade','held_pin',sides=10)
tube('Held pin sharpened point',[pinb,pinb+Vector((0,0,.035))],lambda t:.004*(1-.95*t),'blade_edge','held_pin',sides=10)
for key,q in B.items():
    start=before.get(key,0)
    if len(q['v'])==start:continue
    bones={n for w in q['w'][start:] for n in w}
    if bones and bones<={'blade','held_pin'}:
        bn=next(iter(bones));unpose=rig.data.bones[bn].matrix_local@rig.pose.bones[bn].matrix.inverted()
        for i in range(start,len(q['v'])):q['v'][i]=unpose@q['v'][i]
rig.animation_data.action=None
for p in rig.pose.bones:p.location=(0,0,0);p.rotation_quaternion=(1,0,0,0);p.scale=(1,1,1)
bpy.context.view_layer.update()

# The actual playable character is the proportion and cloth-fitting reference.
# Load copies into this background process only; its production assets are read-only.
reference_file=WORK/'player_reference_only.blend'
with bpy.data.libraries.load(str(reference_file),link=False) as (available,loaded):
    loaded.objects=['Threadborne_Character','Threadborne_Rig']
reference_character,reference_rig=loaded.objects
reference_vertices=[reference_character.matrix_world@v.co for v in reference_character.data.vertices]
torso_faces=[]
for poly in reference_character.data.polygons:
    c=sum((reference_vertices[i] for i in poly.vertices),Vector())/len(poly.vertices)
    if 1.085<c.z<1.555 and abs(c.x)<.255:torso_faces.append(tuple(poly.vertices))
torso_surface=BVHTree.FromPolygons(reference_vertices,torso_faces)
reference_weight_kd=KDTree(len(reference_vertices))
for index,point in enumerate(reference_vertices):reference_weight_kd.insert(point,index)
reference_weight_kd.balance()
reference_group_names={group.index:group.name for group in reference_character.vertex_groups}
def fitted_weights(point):
    weights={}
    for coordinate,index,distance in reference_weight_kd.find_n(Vector(point),3):
        influence=1/max(.001,distance)**2
        for group in reference_character.data.vertices[index].groups:
            name=reference_group_names[group.group]
            if name in H:weights[name]=weights.get(name,0)+group.weight*influence
    return normweights(weights) or torso_weights(Vector(point).z)
reference_rest={b.name:b.matrix_local.copy() for b in reference_rig.data.bones}
reference_lengths={b.name:b.length for b in reference_rig.data.bones}
new_specs={}
for name in H:
    if name in reference_rest:
        ref=reference_rig.data.bones[name];old_direction=T[name]-H[name]
        correction=old_direction.rotation_difference(ref.tail_local-ref.head_local)
        basis=Matrix.Translation(ref.head_local)@correction.to_matrix().to_4x4()@OLD_REST[name].to_3x3().to_4x4()
        new_specs[name]=(basis,reference_lengths[name])
    elif name.startswith('finger'):
        side=name.rsplit('.',1)[1];parent='hand.'+side
        transform=new_specs[parent][0]@OLD_REST[parent].inverted()
        ratio=reference_lengths[parent]/(T[parent]-H[parent]).length
        new_specs[name]=(transform@OLD_REST[name],(T[name]-H[name]).length*ratio)
    elif name in ['blade','held_pin']:
        parent='hand.R' if name=='blade' else 'hand.L';new_specs[name]=(new_specs[parent][0],reference_lengths[parent])
    elif name.startswith('tail_'):
        transform=new_specs['chest'][0]@OLD_REST['chest'].inverted();new_specs[name]=(transform@OLD_REST[name],(T[name]-H[name]).length)
    else:new_specs[name]=(OLD_REST[name],(T[name]-H[name]).length)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for name,(matrix,length) in new_specs.items():
    bone=rig.data.edit_bones[name];bone.matrix=matrix;bone.length=length
bpy.ops.object.mode_set(mode='OBJECT')
NEW_REST={b.name:b.matrix_local.copy() for b in rig.data.bones}
NEW_H={b.name:b.head_local.copy() for b in rig.data.bones};NEW_T={b.name:b.tail_local.copy() for b in rig.data.bones}
deform={}
for name in H:
    ratio=(NEW_T[name]-NEW_H[name]).length/(T[name]-H[name]).length if name.startswith(('upper_arm.','forearm.','thigh.','shin.','finger')) else 1
    deform[name]=NEW_REST[name]@Matrix.Diagonal((1,ratio,1,1))@OLD_REST[name].inverted()

def map_z(z):
    anchors=[(0,0),(.525,.54),(.96,1.035),(1.10,1.16),(1.30,1.34),(1.43,1.49),(1.505,1.505),(1.8,1.8)]
    for (a,b),(c,d) in zip(anchors,anchors[1:]):
        if a<=z<=c:return b+(d-b)*(z-a)/(c-a)
    return z
def reference_front(x,z):
    hit,normal,index,distance=torso_surface.ray_cast(Vector((x,-.8,z)),Vector((0,1,0)),1.6)
    return hit
for key,q in B.items():
    name,mat,smoothing=key
    if key in head_keys:continue # Explicit measured head coordinates are already final.
    bone_names={n for w in q['w'] for n in w}
    if bone_names<={'blade','held_pin'}:continue
    for i,p in enumerate(q['v']):
        original=p.copy();w=q['w'][i];p=sum((deform[n]@p*v for n,v in w.items()),Vector())
        if name.startswith(('Gathered charcoal trouser','Rolled gathered trouser')):
            side='L' if original.x>0 else 'R';a=NEW_H['thigh.'+side];b=NEW_T['thigh.'+side];axis=(b-a).normalized();center=a+axis*(p-a).dot(axis);p=center+(p-center)*.86
        if name.startswith(('Overlapping woven waist','Double braided flax belt','Interlaced paired guardian','Layered split waist','Dark stitched waist tab')):
            p=Vector((original.x*.84,original.y*.85,map_z(original.z)))
        if name.startswith(('Layered diagonal shoulder cowl','Soft rolled cowl')):
            p=Vector((original.x*.93,original.y*.93,original.z))
        if name.startswith(('Tailored cropped charcoal','Inner diagonal','Outer crossed','Narrow brown','Scarf folded')):
            p=Vector((original.x*.94,original.y,map_z(original.z)))
            if name.startswith('Scarf folded'):p.z=original.z
            if name.startswith('Tailored cropped'):
                direction=Vector((p.x,p.y,0))
                if direction.length>.01:
                    direction.normalize();hit,normal,index,distance=torso_surface.ray_cast(Vector((0,0,p.z))+direction*.6,-direction,1.2)
                    if hit is not None:p=hit+normal*.004
            else:
                hit=reference_front(p.x,p.z)
                if hit is not None:
                    extra=original.y-front(original.x,original.z)
                    p.y=hit.y+max(-.045,min(-.007,extra))
        if any(word in name for word in ['tabi','sandal']):
            side='L' if original.x>0 else 'R';p=Vector((NEW_H['foot.'+side].x+(original.x-H['foot.'+side].x)*.95,original.y-H['foot.'+side].y,original.z))
        q['v'][i]=p

# Replace the primitive torso wraps with the actual player's sculpted garment
# surface, cropped to a short ninja tunic. This keeps the approved human
# proportions and cloth folds; exposed arms, mask, bracers and belt stay Eave art.
old_torso_prefixes=('Tailored cropped charcoal','Inner diagonal','Outer crossed','Narrow brown','Scarf folded','Layered diagonal shoulder cowl','Soft rolled cowl','Short frayed shoulder')
for key in list(B):
    if key[0].startswith(old_torso_prefixes):del B[key]
bm=bmesh.new();bm.from_mesh(reference_character.data)
bmesh.ops.transform(bm,matrix=reference_character.matrix_world,verts=list(bm.verts))
# Imported glTF UV seams are duplicate vertices, not physical garment edges.
# Weld before clipping so those seams cannot turn into raised hem geometry.
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
for point,normal in [((0,0,1.105),(0,0,1)),((0,0,1.600),(0,0,-1)),((.285,0,0),(-1,0,0)),((-.285,0,0),(1,0,0))]:
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=point,plane_no=normal,clear_inner=True,dist=.000001)
bm.verts.ensure_lookup_table();bm.verts.index_update();layer=bm.verts.layers.deform.active
reference_groups={group.index:group.name for group in reference_character.vertex_groups}
vs=[];uv=[];ww=[]
for v in bm.verts:
    p=v.co.copy();vs.append(p);uv.append((p.x*3.0+.5,p.z*3.0))
    w=normweights({reference_groups[i]:weight for i,weight in v[layer].items() if i in reference_groups}) if layer else {}
    ww.append(w or torso_weights(p.z))
fs=[tuple(v.index for v in f.verts) for f in bm.faces]
add('Player-fitted sculpted indigo short tunic and cowl','indigo',vs,fs,uv=uv,weights=ww)
# Finish the real cut edges instead of leaving a paper-thin crop.
def on_cut_plane(edge):
    points=[v.co for v in edge.verts]
    return any(all(abs(p[axis]-value)<.00001 for p in points)
               for axis,value in [(0,-.285),(0,.285),(2,1.105),(2,1.600)])
boundary_edges=[edge for edge in bm.edges if edge.is_boundary and on_cut_plane(edge)]
adj={}
for edge in boundary_edges:
    a,b=edge.verts;adj.setdefault(a,[]).append(b);adj.setdefault(b,[]).append(a)
unused=set(boundary_edges)
while unused:
    edge=unused.pop();start=edge.verts[0];current=edge.verts[1];previous=start;path=[start.co.copy(),current.co.copy()]
    for _ in range(len(boundary_edges)+1):
        choices=[v for v in adj.get(current,[]) if v!=previous]
        if not choices:break
        nxt=choices[0];found=next((e for e in current.link_edges if nxt in e.verts and e in unused),None)
        if found is None:break
        unused.remove(found);previous,current=current,nxt;path.append(current.co.copy())
        if current==start:break
    if len(path)>3:
        # Copy native interpolated torso/arm weights through nearest surface.
        bone='upper_arm.L' if path[0].x>.27 else 'upper_arm.R' if path[0].x<-.27 else 'chest' if path[0].z>1.45 else 'pelvis'
        tube('Finished tunic and cowl cut hem',path,.0022,'navy',bone,sides=6)
bm.free()
# A single close-fitting diagonal sash supplies the reference's cross-body
# construction without piling disconnected strips over the torso.
vs=[];uv=[];fs=[];ww=[];nx=8;ny=40
for j in range(ny+1):
    t=j/ny;center=Vector((.145,1.485)).lerp(Vector((-.135,1.115)),t)
    for k in range(nx+1):
        u=k/nx-.5;x=center.x+u*.048;z=center.y+u*.035
        hit=reference_front(x,z)
        y=hit.y-.006 if hit is not None else -.13
        vs.append((x,y,z));uv.append((k/nx*.3,t*1.5));ww.append(torso_weights(z))
for j in range(ny):
    for k in range(nx):q=j*(nx+1)+k;fs.append((q,q+1,q+nx+2,q+nx+1))
add('Fitted dark diagonal cloth sash','charcoal',vs,fs,uv=uv,weights=ww)

# The approved Eave Runner has an indigo cross-wrap over the dark garment.
# Fit it onto the actual sculpted torso, retaining its underlying skin weights.
# The silhouette comes from cloth folds and overlapping cut panels, not straps
# suspended in front of a smooth cylindrical chest.
vs=[];uv=[];fs=[];ww=[];nx=20;ny=52
for j in range(ny+1):
    t=j/ny
    for k in range(nx+1):
        u=k/nx
        top=Vector((-.214,1.484)).lerp(Vector((-.085,1.454)),u)
        bottom=Vector((.012,1.121)).lerp(Vector((.176,1.145)),u)
        point=top.lerp(bottom,t);x,z=point
        hit=reference_front(x,z)
        y=(hit.y if hit is not None else front(x,z))-.005
        y-=.004*math.sin(math.pi*u)*math.sin(t*math.pi)
        y-=.002*math.sin(u*math.pi*4+t*6)*math.sin(math.pi*u)
        vs.append((x,y,z));uv.append((u*.65,t*1.65));ww.append(fitted_weights((x,y,z)))
for j in range(ny):
    for k in range(nx):q=j*(nx+1)+k;fs.append((q,q+1,q+nx+2,q+nx+1))
add('Sculpt-fitted diagonal indigo outer wrap','faded',vs,fs,uv=uv,weights=ww)
for column in [0,nx]:
    points=[Vector(vs[j*(nx+1)+column]) for j in range(ny+1)]
    name='Hand finished indigo wrap selvedge '+str(column)
    tube(name,points,.0016,'navy','chest',sides=6)
    for key,part in B.items():
        if key[0]==name:part['w']=[fitted_weights(point) for point in part['v']]
    for j in range(4,ny-2,4):
        point=points[j]+Vector((0,-.0018,0));name='Sparse flax outer wrap stitches %d %d'%(column,j)
        tube(name,[point+Vector((-.0015,0,-.002)),point+Vector((.0015,0,.002))],.0006,'rope','chest',sides=5)
        for key,part in B.items():
            if key[0]==name:part['w']=[fitted_weights(point) for point in part['v']]

# The established in-place actions are solved again on the measured anatomy.
# Names, event timings and 2D gameplay controller remain unchanged.
import eave_pose_authoring_v3
eave_pose_authoring_v3.bake(rig,sc,NEW_H,NEW_T,NEW_REST)
for clip,markers in json.loads((SRC/'animation_events.json').read_text()).items():
    if clip in bpy.data.actions:
        for name,seconds in markers.items():
            marker=bpy.data.actions[clip].pose_markers.new(name);marker.frame=1+round(seconds*30)
rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1);rig.pose.bones['held_pin'].scale=(1,1,1);bpy.context.view_layer.update()
for key,q in B.items():
    bone_names={n for w in q['w'] for n in w}
    if not bone_names or not bone_names<={'blade','held_pin'}:continue
    name=next(iter(bone_names));old_pose=old_idle[name];new_pose=rig.pose.bones[name].matrix.copy()
    translation=Matrix.Translation(new_pose.translation-old_pose.translation)
    correction=NEW_REST[name]@new_pose.inverted()@translation@old_pose@OLD_REST[name].inverted()
    q['v']=[correction@p for p in q['v']]
rig.animation_data.action=None
for p in rig.pose.bones:p.location=(0,0,0);p.rotation_quaternion=(1,0,0,0);p.scale=(1,1,1)
bpy.context.view_layer.update()
for obj in [reference_character,reference_rig]:bpy.data.objects.remove(obj,do_unlink=True)

# Preserve UV seams in corner data but weld geometric duplicates for smooth
# cord lighting. Weights travel through the bmesh deform layer when welding.
actors=[]
for (name,mat,smooth),q in B.items():
    me=bpy.data.meshes.new(name);me.from_pydata(q['v'],[],q['f']);me.update();ob=bpy.data.objects.new(name,me);sc.collection.objects.link(ob);me.materials.append(M[mat])
    uv=me.uv_layers.new(name='UVMap')
    for p in me.polygons:
        p.use_smooth=smooth
        for li in p.loop_indices:uv.data[li].uv=q['uv'][me.loops[li].vertex_index]
    groups={n:ob.vertex_groups.new(name=n) for n in sorted({n for w in q['w'] for n in w})}
    for i,w in enumerate(q['w']):
        for n,v in w.items():groups[n].add([i],v,'REPLACE')
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
    # Normalize after seam welding, and remove zero-valued group entries.
    for vert in me.vertices:
        w=normweights({ob.vertex_groups[g.group].name:g.weight for g in vert.groups})
        for g in list(vert.groups):ob.vertex_groups[g.group].remove([vert.index])
        for n,v in w.items():groups[n].add([vert.index],v,'REPLACE')
    ob.parent=rig;mod=ob.modifiers.new('Retained 60 bone animation rig','ARMATURE');mod.object=rig
    ob['art_component']='hand' if 'finger' in name.lower() else 'core' if 'anatomy' in name.lower() else 'weapon' if 'blade' in name.lower() or 'pin ' in name.lower() else 'crafted garment'
    actors.append(ob)

def tris(o):return sum(len(p.vertices)-2 for p in o.data.polygons)
report={'version':3,'triangles':sum(tris(o) for o in actors),'vertices':sum(len(o.data.vertices) for o in actors),'bones':len(rig.data.bones),'materials':len(M),'components':len(actors),'bounds':[[min(v.co[i] for o in actors for v in o.data.vertices),max(v.co[i] for o in actors for v in o.data.vertices)] for i in range(3)],'clips':{a.name:round((a.frame_range[1]-a.frame_range[0])/30,4) for a in bpy.data.actions},'source':str((SRC/'EaveRunner_Woven_v3.blend').relative_to(ROOT)),'runtime':str((ASSET/'Models/EaveRunner_v3.glb').relative_to(ROOT)),'design':'tailored angular hood, pierced ceramic mask, layered wraps/cowl, gathered trousers, woven tendons, fitted bamboo bracers and articulated fingers'}
for path in [WORK/'manifest.json',SRC/'build_report_v3.json']:path.write_text(json.dumps(report,indent=2))
for path in [WORK/'material_factors.json',SRC/'material_export_factors_v3.json']:path.write_text(json.dumps(FACTORS,indent=2))
rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1)
sc.render.fps=30;sc.frame_start=1;sc.frame_end=73
sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.14,.18,.22,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.42
def light(name,pos,power,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1.0))-o.location).to_track_quat('-Z','Y').to_euler()
light('Warm key',(2,-4,4),430,3,(1,.88,.74));light('Cool fill',(-3,-2,2.5),260,3,(.65,.80,1));light('Soft rim',(1,3,4),600,3,(.73,.85,1))
cam=sc.camera;cam.location=(2.6,-5.8,2.25);target=Vector((0,-.01,.99));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.15
sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.resolution_x=1400;sc.render.resolution_y=1700;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.view_settings.view_transform='AgX'
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'EaveRunner_Woven_v3.blend'),compress=True)
# Export consolidation leaves the editable saved source in semantic pieces.
for mat in M.values():
    obs=[o for o in sc.objects if o.type=='MESH' and o.data.materials[0]==mat]
    if not obs:continue
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=mat.name.replace(' | ','_')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in sc.objects:
    if o.type=='MESH':o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(ASSET/'Models/EaveRunner_v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)
print('EAVE_V3_BUILD',json.dumps(report),flush=True)
sc.render.filepath=str(WORK/'renders/Eave_v3_First.png');bpy.ops.render.render(write_still=True)
