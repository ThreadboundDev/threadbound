"""Bird-only silhouette and craft rebuild, retaining the approved gameplay rig.

All detail is native, editable mesh work: tailored cambered sail panels, layered
cloth feathers, interwoven basket ribs, three-strand rope and fitted joinery.
Runs in Blender background; never opens or manipulates a desktop window.
"""
from pathlib import Path
from collections import defaultdict
import bpy, bmesh, math, random, json, os, tempfile, sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/loom-heron-v3'
SRC=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron'
MODEL=ROOT/'Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v3.glb'
TEX=ROOT/'Assets/BlueBiome/Characters/SharedTexturesV2'
for p in [WORK/'temp',WORK/'renders',SRC,MODEL.parent]:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
random.seed(108)
bpy.ops.wm.open_mainfile(filepath=str(SRC/'LoomHeron_Woven_v2.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['LoomHeron_Rig']
rig.animation_data.action=None
for p in rig.pose.bones:
    p.location=(0,0,0);p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.scale=(1,1,1)
for o in list(bpy.data.objects):
    if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
for me in list(bpy.data.meshes):
    if not me.users:bpy.data.meshes.remove(me)
for material in list(bpy.data.materials):
    if not material.users:bpy.data.materials.remove(material)
for im in list(bpy.data.images):
    if not im.users:bpy.data.images.remove(im)
sc.frame_set(1);bpy.context.view_layer.update()

M={};FACTORS={}
def material(key,name,color,family=None,roughness=.7,normal=.25,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    nodes=m.node_tree.nodes;links=m.node_tree.links;bs=nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=roughness;bs.inputs['Metallic'].default_value=metal
    FACTORS[name]=[*color,1]
    if family:
        for channel in ['BaseColor','Normal','Roughness']:
            path=TEX/(family+'_'+channel+'_4K.png')
            if not path.exists():continue
            n=nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(path),check_existing=True);n.interpolation='Linear'
            if channel=='BaseColor':
                mul=nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[2].default_value=(*color,1)
                links.new(n.outputs[0],mul.inputs[1]);links.new(mul.outputs[0],bs.inputs['Base Color'])
            elif channel=='Normal':
                n.image.colorspace_settings.name='Non-Color';nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=normal
                links.new(n.outputs[0],nm.inputs[1]);links.new(nm.outputs[0],bs.inputs['Normal'])
            else:
                n.image.colorspace_settings.name='Non-Color';links.new(n.outputs[0],bs.inputs['Roughness'])
    M[key]=m;return m

material('indigo','Heron V3 | deep indigo linen',(.32,.52,.78),'IndigoWeave')
material('faded','Heron V3 | weathered indigo linen',(.57,.76,.94),'IndigoWeave')
material('navy','Heron V3 | shadow indigo linen',(.18,.29,.43),'IndigoWeave')
material('patch','Heron V3 | flax repairs',(.66,.68,.60),'FlaxWeave')
material('rope','Heron V3 | honey flax cord',(.64,.48,.28),'FlaxWeave',normal=.42)
material('rope_light','Heron V3 | worn flax highlights',(.83,.69,.43),'FlaxWeave',normal=.42)
material('core','Heron V3 | dark woven understructure',(.46,.57,.66),'WovenCord',normal=.22)
material('ivory','Heron V3 | carved ivory ceramic',(.97,.97,.90),'AgedCeramic',normal=.12)
material('edge','Heron V3 | ceramic edge wear',(.40,.35,.25),'AgedCeramic',normal=.1)
material('dark','Heron V3 | recessed lacquer',(.012,.019,.025),roughness=.43)
material('bronze','Heron V3 | patinated fasteners',(.075,.085,.066),roughness=.72,metal=.45)
material('blue','Heron V3 | blue glazed iris',(.02,.31,.42),roughness=.24,metal=.3)
material('ink','Heron V3 | indigo ceramic inlay',(.018,.045,.069),roughness=.31)
wood=material('wood','Heron V3 | split walnut spars',(.52,.36,.21),roughness=.66)
wn=wood.node_tree.nodes;wl=wood.node_tree.links;bs=wn.get('Principled BSDF')
woodtex=ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures'
for ch in ['BaseColor','NormalGL','Roughness']:
    path=woodtex/('walnut_'+ch+'_4K.png');n=wn.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(path),check_existing=True)
    if ch=='BaseColor':
        mul=wn.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[2].default_value=(.52,.36,.21,1);wl.new(n.outputs[0],mul.inputs[1]);wl.new(mul.outputs[0],bs.inputs['Base Color'])
    elif ch=='NormalGL':
        n.image.colorspace_settings.name='Non-Color';nm=wn.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.3;wl.new(n.outputs[0],nm.inputs[1]);wl.new(nm.outputs[0],bs.inputs['Normal'])
    else:n.image.colorspace_settings.name='Non-Color';wl.new(n.outputs[0],bs.inputs['Roughness'])
charge=material('charge','Heron | charged thread',(.025,.32,.48),roughness=.38)
charge.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value=(.04,.5,.8,1)
charge.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=.18

# Buffers retain artist-facing component names; export is consolidated per material.
B={}
def add(part,mat,verts,faces,bone,uv=None,weights=None):
    key=(part,mat)
    if key not in B:B[key]={'v':[],'f':[],'uv':[],'w':[]}
    q=B[key];offset=len(q['v']);q['v']+=list(verts);q['f'] += [tuple(offset+i for i in f) for f in faces]
    q['uv']+=uv if uv is not None else [(Vector(v).x*1.5,Vector(v).z*1.5) for v in verts]
    q['w']+=weights if weights is not None else [{bone:1} for v in verts]

def sample(points,steps=6):
    """Catmull-Rom centreline through authored control points."""
    ps=[Vector(p) for p in points];out=[]
    for j in range(len(ps)-1):
        a=ps[max(0,j-1)];b=ps[j];c=ps[j+1];d=ps[min(j+2,len(ps)-1)]
        for i in range(steps):
            t=i/steps;out.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    out.append(ps[-1]);return out

def frames(points):
    ps=[Vector(p) for p in points];result=[];previous=None
    for i,p in enumerate(ps):
        axis=(ps[min(len(ps)-1,i+1)]-ps[max(0,i-1)]).normalized()
        u=axis.cross(Vector((0,0,1)))
        if u.length<.1:u=axis.cross(Vector((0,1,0)))
        u.normalize()
        if previous is not None and u.dot(previous)<0:u=-u
        previous=u;result.append((u,axis.cross(u).normalized()))
    return result

def tube(part,points,radius,mat,bone,sides=8,smooth=0,caps=True,ellipse=1):
    ps=sample(points,smooth) if smooth else [Vector(p) for p in points]
    basis=frames(ps);vs=[];uv=[];faces=[];distance=0
    for i,p in enumerate(ps):
        if i:distance+=(p-ps[i-1]).length
        r=radius(i/(len(ps)-1)) if callable(radius) else radius
        u,v=basis[i]
        for k in range(sides+1):
            a=k*math.tau/sides;vs.append(p+r*(u*math.cos(a)+v*math.sin(a)*ellipse));uv.append((k/sides*.32,distance*2.0))
    n=sides+1
    for i in range(len(ps)-1):
        for k in range(sides):faces.append((i*n+k,i*n+k+1,(i+1)*n+k+1,(i+1)*n+k))
    if caps:faces+=[tuple(range(sides-1,-1,-1)),tuple((len(ps)-1)*n+k for k in range(sides))]
    add(part,mat,vs,faces,bone,uv)

def braid(part,points,radius,mat,bone,pitch=.075,strands=3,wire=None,smooth=7):
    ps=sample(points,smooth);basis=frames(ps);distance=[0]
    for a,b in zip(ps,ps[1:]):distance.append(distance[-1]+(b-a).length)
    # Resample by length for true helical strands even on short bindings.
    n=max(12,int(distance[-1]/pitch*18));new=[];j=0
    for i in range(n+1):
        d=distance[-1]*i/n
        while j<len(distance)-2 and distance[j+1]<d:j+=1
        t=(d-distance[j])/max(1e-8,distance[j+1]-distance[j]);new.append(ps[j].lerp(ps[j+1],t))
    basis=frames(new)
    for k in range(strands):
        points=[]
        for i,p in enumerate(new):
            a=math.tau*(distance[-1]*i/n/pitch+k/strands);u,v=basis[i]
            points.append(p+radius*.52*(u*math.cos(a)+v*math.sin(a)))
        tube(part,points,wire or radius*.48,mat if k!=1 or mat!='rope' else 'rope_light',bone,10)

def binding(part,a,b,r,bone,turns=6):
    a=Vector(a);b=Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized();ps=[]
    for i in range(turns*12+1):
        t=i/(turns*12);ang=t*turns*math.tau;rad=r*(1+.035*math.sin(ang*2.3))
        ps.append(a.lerp(b,t)+rad*(u*math.cos(ang)+v*math.sin(ang)))
    # At this scale a cord's fine twist is carried by its normal map. Keep
    # actual three-strand geometry for the visible large load-bearing braids.
    tube(part,ps,.0054,'rope',bone,7)
    # Cinch across the wrapping rather than enormous detached open rings.
    braid(part,[a+u*r*.94,b+u*r*.94,b-v*r*.75,a-u*r*.94],.008,'rope',bone,pitch=.055,smooth=4)

def shell(part,sections,mat,bone,rings=32,lower=None):
    """Longitudinal shaped shell; each section is y,z,half-width,half-height."""
    vs=[];uv=[];fs=[]
    for j,(y,z,rx,rz) in enumerate(sections):
        for k in range(rings+1):
            a=k/rings*math.tau
            vs.append((rx*math.sin(a),y,z+rz*math.cos(a)));uv.append((k/rings,j/max(1,len(sections)-1)))
    for j in range(len(sections)-1):
        for k in range(rings):fs.append((j*(rings+1)+k,j*(rings+1)+k+1,(j+1)*(rings+1)+k+1,(j+1)*(rings+1)+k))
    fs += [tuple(range(rings-1,-1,-1)),tuple((len(sections)-1)*(rings+1)+k for k in range(rings))]
    add(part,mat,vs,fs,bone,uv)

def leaf(part,root,tip,width,mat,bone,normal=(0,-1,.1),segments=18,seed=0,split=True,repair=False):
    """Sculpted textile feather with a raised centre and irregular tapered hem."""
    root=Vector(root);tip=Vector(tip);axis=(tip-root).normalized();n=Vector(normal).normalized();cross=axis.cross(n).normalized();n=cross.cross(axis).normalized()
    vs=[];uv=[];fs=[]
    for j in range(segments+1):
        t=j/segments
        w=max(.0008,width*(.64+.35*math.sin(math.pi*t))*(1-t**2.7))
        for k in range(7):
            u=k/6*2-1
            tear=(.012*math.sin(j*5.1+seed)*abs(u)**5+.006*math.sin(j*2.4+seed))*t
            p=root.lerp(tip,t)+cross*(u*w*.5)+n*(.018*math.sin(math.pi*t)*(1-u*u)+.005*math.sin(t*19+seed)*u*u)
            if split:p+=axis*tear
            vs.append(p);uv.append((k/6*.32,t*(tip-root).length*2))
    for j in range(segments):
        for k in range(6):fs.append((j*7+k,j*7+k+1,(j+1)*7+k+1,(j+1)*7+k))
    add(part,mat,vs,fs,bone,uv)
    if repair:
        patchverts=[];patchuv=[];patchfaces=[]
        lo=int(segments*.43);hi=int(segments*.73)
        for j in range(lo,hi+1):
            for k in range(1,6):
                p=Vector(vs[j*7+k])+n*.0025
                patchverts.append(p);patchuv.append(uv[j*7+k])
        for j in range(hi-lo):
            for k in range(4):
                q=j*5+k;patchfaces.append((q,q+1,q+6,q+5))
        add(part+' / sewn cloth finger repair','patch',patchverts,patchfaces,bone,patchuv)
        for j in [lo,hi]:
            for k in range(1,6):
                p=Vector(vs[j*7+k])+n*.005
                tube(part+' / cloth finger repair stitches',[p-axis*.008,p+axis*.008],.0018,'rope',bone,4)
    tube(part,[root+n*.003,root.lerp(tip,.45)+n*.024,tip],lambda t:.004*(1-.8*t),'navy' if mat!='navy' else 'faded',bone,5,smooth=7)
    return root,tip

# Lean basket core. Its surface follows individual interlaced reeds, not a
# large rope picture stretched across an ellipsoid.
shell('Body / inner dark basket',[(.42,1.05,.035,.045),(.30,1.13,.13,.16),(.12,1.22,.20,.24),(-.08,1.29,.205,.25),(-.26,1.32,.14,.18),(-.30,1.34,.06,.08)],'core','body',32)
def bodypoint(t,a,offset=0):
    y=.37-.66*t;shape=max(.08,math.sin(math.pi*t))**.63
    rx=.205*shape+offset;rz=.235*shape+offset
    return Vector((rx*math.cos(a),y,1.12+.21*t+rz*math.sin(a)))
for k in range(24):
    a=k/24*math.tau
    ps=[bodypoint(i/70,a+.10*math.sin(i/70*math.pi),.003+.003*math.sin(i/70*math.tau*15+k*math.pi)) for i in range(71)]
    tube('Body / woven basket warp',ps,.009,'core','body',6)
for j in range(28):
    t=.035+j/29*.93
    ps=[bodypoint(t,k/120*math.tau,.005+.003*math.cos(k/120*math.tau*24)) for k in range(121)]
    tube('Body / woven basket weft',ps,.0065,'core','body',6)
# Layered shoulder mantle and breast strips sweep backward with avian flow.
for s in [-1,1]:
    for row in range(3):
        for j in range(5):
            a=-.7+j*.34;y=-.20+row*.14
            root=(s*(.08+.085*j/4),y,1.48-row*.045-.035*j)
            tip=(s*(.17+.07*math.sin(j)),.25+row*.075,1.08+.06*j-row*.035)
            leaf('Body / layered indigo mantle',root,tip,.12,'faded' if (j+row)%4==0 else 'indigo','body',normal=(s*.5,-.8,.45),seed=row*5+j)
    for j in range(5):
        root=(s*(.035+j*.035),-.27,1.43-j*.025)
        tip=(s*(.025+j*.033),-.15,.94+j*.02)
        leaf('Body / overlapping breast feather cloth',root,tip,.075,'indigo' if j%2 else 'navy','body',normal=(s*.4,-1,0),seed=30+j)
    # Braided harness connects shoulder load to the lower keel.
    braid('Body / load bearing chest braid',[(s*.10,-.20,1.48),(s*.17,-.30,1.37),(s*.14,-.323,1.20),(s*.045,-.26,1.10)],.016,'rope','body',pitch=.065)
    braid('Body / shoulder harness',[(s*.09,-.19,1.48),(s*.195,-.01,1.46),(s*.145,.22,1.35),(s*.06,.30,1.16)],.015,'rope','body',pitch=.07)
# Continuous paired interlacing faction knot, alternating front/back passes.
ps=[]
for i in range(201):
    a=i/200*math.tau;ps.append((.115*math.sin(a),-.331+.016*math.sin(3*a),1.31+.067*math.sin(2*a)))
braid('Body / paired interwoven guardian knot',ps,.014,'rope','body',pitch=.048,smooth=1)
for s in [-1,1]:
    braid('Body / secured knot tails',[(s*.02,-.334,1.29),(s*.035,-.34,1.22),(s*.03,-.30,1.17)],.009,'rope','body',pitch=.04)

# Neck is a tensioned reed bundle with independently visible spiral cords.
neckpath=[(0,-.12,1.34),(0,-.29,1.45),(0,-.30,1.60),(0,-.43,1.68)]
tube('Neck / core',neckpath,.059,'core','neck',16,smooth=10)
ps=sample(neckpath,12);basis=frames(ps)
for k in range(7):
    path=[]
    for i,p in enumerate(ps):
        a=k*math.tau/7+i*.11;u,v=basis[i];path.append(p+.054*(u*math.cos(a)+v*math.sin(a)))
    braid('Neck / spiral woven tendons',path,.008,'rope' if k%3==0 else 'core','neck',pitch=.06,smooth=1)
binding('Neck / throat cinch',(0,-.285,1.51),(0,-.31,1.58),.068,'neck',6)

# Continuous tapered skull and bill replace the sphere plus triangle head.
sections=[(-.235,1.72,.022,.031),(-.29,1.735,.058,.070),(-.36,1.735,.088,.09),(-.44,1.719,.103,.096),(-.52,1.69,.090,.082),(-.60,1.665,.072,.063),(-.70,1.625,.051,.047),(-.82,1.57,.034,.030),(-.96,1.50,.017,.016),(-1.13,1.42,.001,.002)]
shell('Head / continuous carved ceramic skull and upper bill',sections,'ivory','head',40)
# Dorsal ridge and long slim lower mandible create a sharp heron profile.
tube('Head / ceramic keel',[(0,-.28,1.79),(0,-.43,1.82),(0,-.58,1.74),(0,-.83,1.606),(0,-1.13,1.423)],lambda t:.011*(1-.94*t),'ivory','head',8,smooth=7,ellipse=.55)
# Glazed dorsal inlay breaks up the large ivory mask and continues the
# indigo crest into a deliberately narrow spear-like bill.
inlay=[(-.285,1.806,.015),(-.36,1.829,.019),(-.43,1.823,.021),(-.52,1.780,.015),(-.61,1.726,.010),(-.73,1.670,.005),(-.90,1.557,.002),(-1.09,1.442,.0005)]
vs=[];uv=[];fs=[]
for j,(y,z,w) in enumerate(inlay):
    for s in [-1,0,1]:vs.append((s*w,y,z+.003*(1-abs(s))));uv.append(((s+1)/2,j/(len(inlay)-1)))
for j in range(len(inlay)-1):
    for k in range(2):fs.append((j*3+k,j*3+k+1,(j+1)*3+k+1,(j+1)*3+k))
add('Head / glazed indigo dorsal inlay','ink',vs,fs,'head',uv)
shell('Head / lacquer lower mandible',[(-.47,1.63,.052,.017),(-.59,1.603,.054,.020),(-.78,1.535,.033,.015),(-.97,1.466,.014,.008),(-1.13,1.415,.001,.001)],'dark','head',20)
for s in [-1,1]:
    tube('Head / bill seam',[(s*.065,-.57,1.635),(s*.041,-.76,1.562),(s*.018,-.96,1.485),(s*.001,-1.125,1.42)],.0025,'edge','head',5,smooth=6)
    # Inlaid almond, narrow brow and tiny iris. No protruding button eyeball.
    c=Vector((s*.103,-.448,1.746));vs=[c+Vector((s*.002,0,0))];uv=[(.5,.5)]
    for i in range(49):
        a=i/48*math.tau;vs.append(c+Vector((-s*.003*abs(math.sin(a)),.044*math.cos(a),.020*math.sin(a)*(abs(math.sin(a))**.3))));uv.append((.5+.5*math.cos(a),.5+.5*math.sin(a)))
    add('Head / recessed almond eye','dark',vs,[(0,i,i+1) for i in range(1,49)],'head',uv)
    tube('Head / sculpted ceramic eyebrow',[(s*.080,-.39,1.768),(s*.101,-.44,1.769),(s*.080,-.512,1.729)],.0055,'ivory','head',8,smooth=9)
    # Iris disc lies against the side of the skull.
    c=Vector((s*.108,-.455,1.747));v=[c];uv=[(.5,.5)]
    for i in range(25):
        a=i/24*math.tau;v.append(c+Vector((s*.001,.006*math.cos(a),.008*math.sin(a))));uv.append((.5+.5*math.cos(a),.5+.5*math.sin(a)))
    add('Head / blue glazed iris','blue',v,[(0,i,i+1) for i in range(1,25)],'head',uv)
    # Thin inlaid sweep carries the blue charge into the bill.
    tube('Head / quiet blue inlay',[(s*.049,-.57,1.70),(s*.031,-.73,1.61),(s*.014,-.94,1.51)],.0022,'charge','head',5,smooth=8)
    for j in range(3):
        leaf('Head / swept crest cloth',(s*.035,-.28,1.77),(s*(.10+j*.035),.10+j*.055,1.91-j*.02),.048,'navy' if j%2 else 'indigo','head',normal=(s*.3,-.4,1),seed=80+j)
binding('Head / nape wrap',(0,-.28,1.705),(0,-.225,1.72),.057,'head',5)

# Broad hand-built fan wings, separate trailing fingers, tucked reinforcement
# patches, longitudinal grain, tension stays and compact crossed lashings.
for side,s in [('L',1),('R',-1)]:
    bn='wing_arm.'+side;fan='wing_fan.'+side;part='Wing '+side
    a=Vector((s*.13,0,1.38));hinge=Vector((s*.78,.06,1.66));tip=Vector((s*1.73,.05,1.78))
    tube(part+' / paired shoulder reeds',[a,a.lerp(hinge,.48)+Vector((0,-.008,.025)),hinge],lambda t:.026*(1-.22*t),'wood',bn,10,smooth=9)
    tube(part+' / paired shoulder reeds',[a+Vector((0,.07,-.03)),hinge+Vector((0,.075,-.025))],.016,'wood',bn,9,smooth=12)
    binding(part+' / shoulder cord',a.lerp(hinge,.07),a.lerp(hinge,.21),.031,bn,6)
    binding(part+' / shoulder cord',a.lerp(hinge,.80),a.lerp(hinge,.96),.030,bn,6)
    # Articulated wrist cap and crossed wrap, fitted to the spar ends.
    tube(part+' / wrist pin',[hinge+Vector((0,-.014,0)),hinge+Vector((0,.085,0))],.034,'bronze',fan,12)
    binding(part+' / wrist crossed lashing',hinge+Vector((0,-.025,0)),hinge+Vector((0,.09,0)),.050,fan,8)
    ends=[tip,Vector((s*1.72,.40,1.48)),Vector((s*1.52,.70,1.12)),Vector((s*1.16,.81,.83)),Vector((s*.80,.66,.80))]
    # Inner sail with shoulder crease, no stretched single quad.
    inner=[a,hinge,Vector((s*.79,.45,1.09)),Vector((s*.19,.29,1.07))]
    vs=[];uv=[];fs=[]
    for j in range(19):
        v=j/18
        for i in range(25):
            u=i/24;p=inner[0].lerp(inner[1],u).lerp(inner[3].lerp(inner[2],u),v)
            p.y+=.028*math.sin(math.pi*u)*math.sin(math.pi*v);p.z+=.009*math.sin(u*24)*math.sin(math.pi*v)
            vs.append(p);uv.append((u*.95,v*.60))
    for j in range(18):
        for i in range(24):fs.append((j*25+i,j*25+i+1,(j+1)*25+i+1,(j+1)*25+i))
    add(part+' / cambered inner sail','navy',vs,fs,bn,uv)
    for j,end in enumerate(ends):
        tube(part+' / radial split reeds',[hinge,hinge.lerp(end,.50)+Vector((0,-.015,.012)),end],lambda t:(.021 if j==0 else .014)*(1-.28*t),'wood',fan,9,smooth=12)
        binding(part+' / rib tip bindings',end.lerp(hinge,.025),end.lerp(hinge,.12),.023 if j==0 else .017,fan,4)
        if not j:continue
        prev=ends[j-1];N=28;Q=24
        def panel(u,v):
            edge=prev.lerp(end,v);d=edge-hinge
            # Distinct split, scooped outer hems and hand-torn cloth fingers.
            rag=.007*math.sin(v*81+j*3)+.004*math.sin(v*193+j)
            scoop=.055*math.sin(math.pi*v)**2
            p=hinge+d*(u*(.995-scoop+rag*u**7))
            p.y+=.045*math.sin(math.pi*v)*math.sin(math.pi*u)
            p.z+=.009*math.sin(v*28+u*9)*math.sin(math.pi*u)*math.sin(math.pi*v)
            p.y-=.012*math.exp(-((u-.87)/.045)**2)*math.sin(math.pi*v)
            return p
        vs=[];uv=[];fs=[]
        for i in range(N+1):
            u=.045+.955*i/N
            for k in range(Q+1):
                v=.018+.964*k/Q;vs.append(panel(u,v));uv.append((v*.48,u*1.4+.12*j))
        for i in range(N):
            for k in range(Q):
                q=i*(Q+1)+k;fs.append((q,q+1,q+Q+2,q+Q+1))
        add(part+' / individually tailored fan panels','faded' if j==2 else 'indigo',vs,fs,fan,uv)
        # Rolled outer seam follows its irregular contour; no closing wood bar.
        edge=[panel(.978,.02+.96*i/45)+Vector((0,-.001,0)) for i in range(46)]
        tube(part+' / rolled indigo hems',edge,.0048,'navy',fan,6)
        for edgev in [.035,.965]:
            tube(part+' / reinforced radial seams',[panel(.10+.88*i/40,edgev)+Vector((0,-.003,0)) for i in range(41)],.0042,'navy',fan,6)
        for k in range(17):
            v=.06+.88*k/16;p=panel(.963,v)
            tube(part+' / hand sewn hems',[p+Vector((0,-.005,.004)),panel(.935,v)+Vector((0,-.005,.004))],.0019,'rope',fan,4)
        # Irregular repaired cloth island, with inset sewn perimeter. Alternate
        # positions intentionally break mirror symmetry across the bird.
        if (j+(0 if s==1 else 1))%2==0:
            u0=.48+.05*(j%2);u1=.80;v0=.17;v1=.76
            vsp=[];uvp=[];fsp=[]
            for i in range(9):
                u=u0+(u1-u0)*i/8
                for k in range(13):
                    v=v0+(v1-v0)*k/12;uu=u+.008*math.sin(k*3+i);vsp.append(panel(uu,v)+Vector((0,-.004,.004)));uvp.append((v*.6,u*.9))
            for i in range(8):
                for k in range(12):
                    q=i*13+k;fsp.append((q,q+1,q+14,q+13))
            add(part+' / fitted flax repairs','patch',vsp,fsp,fan,uvp)
            for k in range(14):
                v=v0+(v1-v0)*k/13
                tube(part+' / repair perimeter stitches',[panel(u0-.008,v)+Vector((0,-.007,.006)),panel(u0+.018,v)+Vector((0,-.007,.006))],.0021,'rope',fan,5)
                tube(part+' / repair perimeter stitches',[panel(u1-.018,v)+Vector((0,-.007,.006)),panel(u1+.008,v)+Vector((0,-.007,.006))],.0021,'rope',fan,5)
        # Layered long pointed cloth fingers extend past the central trailing
        # edge, giving the wing an avian contour rather than a bat membrane.
        if j>=2:
            mid=prev.lerp(end,.58);direction=(mid-hinge).normalized()
            for k in range(3):
                v=.28+k*.22;root=panel(.49,v);endp=panel(.995,v)+direction*(.13+.065*(k%2))
                leaf(part+' / trailing cloth primary fingers',root,endp,.11 if j<4 else .08,'navy' if k==1 else 'indigo',fan,normal=(0,-1,.1),seed=j*10+k+s,repair=(j+k+(1 if s>0 else 0))%3==0)
        # Edge frays are restrained clusters attached to existing hem points.
        for k in range(7):
            v=.08+.84*k/6;p=panel(.985,v);d=(p-hinge).normalized()
            for q in range(2):tube(part+' / hem frays',[p,p+d*(.02+.009*q)+Vector((0,.006*q,-.012))],.0009,'patch' if j%2==0 else 'faded',fan,4)
    # Overlapping small coverts hide the shoulder/sail seam, all anchored.
    for j in range(7):
        root=a.lerp(hinge,.15+.105*j)+Vector((0,-.026,.008))
        leaf(part+' / shoulder covert cloth',root,root+Vector((s*.04,.16,-.20-.018*j)),.12,'faded' if j%3==0 else 'indigo',bn,normal=(0,-1,.4),seed=j)
    braid(part+' / structural tension cord',[a+Vector((0,.12,-.03)),(s*.57,.44,1.08),hinge+Vector((0,.02,-.04))],.008,'rope',bn,pitch=.05)
    # Bound tassel from the actual tip, not floating triangles.
    braid(part+' / tip tassel cord',[tip,tip+Vector((0,.015,-.10))],.008,'rope',fan,pitch=.04)
    for j in range(3):leaf(part+' / tip tassel',tip+Vector((s*(j-1)*.012,.015,-.08)),tip+Vector((s*(j-1)*.018,.025,-.29-.02*j)),.025,'navy' if j%2 else 'indigo','tassel.'+side,normal=(0,-1,0),seed=90+j)

# Articulated reed legs, braided tendons, bound knuckles and curved talons.
for side,s in [('L',1),('R',-1)]:
    hip=Vector((s*.12,-.02,.95));knee=Vector((s*.18,-.12,.60));ankle=Vector((s*.18,.04,.25))
    thigh='thigh.'+side;shin='shin.'+side;foot='foot.'+side;part='Leg '+side
    # Braided hip socket closes the body-to-leg join through every flight pose.
    tube(part+' / hip socket',[hip+Vector((0,0,.11)),hip+Vector((0,0,-.035))],lambda t:.037*(1-.34*t),'core',thigh,12,smooth=8)
    binding(part+' / hip socket binding',hip+Vector((0,0,.035)),hip+Vector((0,0,-.022)),.033,thigh,5)
    for j in range(4):
        leaf(part+' / overlapping hip cloth',(s*(.075+j*.026),-.07,1.13),(s*(.09+j*.029),-.045,.88+.018*j),.072,'indigo' if j%2 else 'navy','body',normal=(s*.3,-1,0),seed=130+j)
    tube(part+' / tapered thigh reed',[hip,hip.lerp(knee,.6)+Vector((0,-.012,0)),knee],lambda t:.024*(1-.28*t),'wood',thigh,10,smooth=10)
    for q in [-1,1]:braid(part+' / thigh tendons',[hip+Vector((q*.016,0,0)),hip.lerp(knee,.6)+Vector((q*.020,-.009,0)),knee+Vector((q*.012,-.005,0))],.008,'core',thigh,pitch=.065)
    binding(part+' / knee binding',knee+Vector((0,-.009,.035)),knee+Vector((0,.009,-.028)),.027,shin,6)
    tube(part+' / tapered shin',[knee,ankle],lambda t:.019*(1-.27*t),'wood',shin,10,smooth=18)
    braid(part+' / shin tendon',[knee+Vector((0,-.018,0)),ankle+Vector((0,-.017,.008))],.006,'core',shin,pitch=.06)
    binding(part+' / ankle binding',ankle+Vector((0,-.008,.028)),ankle+Vector((0,.008,-.023)),.025,foot,5)
    for j in [-1,0,1]:
        ps=[ankle,(s*.18+j*.032,-.05,.208),(s*.18+j*.055,-.155,.19),(s*.18+j*.058,-.205,.135),(s*.18+j*.052,-.185,.105)]
        braid(part+' / braided curved talons',ps,.011,'rope',foot,pitch=.045,smooth=8)
        tube(part+' / glazed talon tips',[ps[-2],ps[-1],(ps[-1][0],-.15,.109)],lambda t:.013*(1-.95*t),'dark',foot,8,smooth=6)
    braid(part+' / rear gripping toe',[ankle,(s*.18,.13,.19),(s*.18,.14,.13),(s*.18,.105,.105)],.010,'rope',foot,pitch=.045)
    tube(part+' / rear claw',[(s*.18,.14,.13),(s*.18,.105,.105)],lambda t:.007*(1-.90*t),'dark',foot,8,smooth=8)

# Multi-layer tail, braided root and narrow cloth streamers.
for j in range(7):
    x=(j-3)*.040
    leaf('Tail / overlapping pennants',(x,.24,1.19),(x*2.0,1.00+.07*(1-abs(j-3)/3),.86-.05*(j%2)),.13,'faded' if j in [1,5] else 'indigo','tail',normal=(0,0,1),seed=100+j)
    if j%2==0:tube('Tail / reed stays',[(x,.24,1.18),(x*1.7,.92,.91)],lambda t:.008*(1-.4*t),'wood','tail',7,smooth=10)
binding('Tail / root binding',(0,.30,1.16),(0,.40,1.12),.071,'tail',6)
# Quiet charge line moves with each neck/head component and becomes bright
# during the existing ranged windup through the unchanged material hook.
tube('Body / charged woven conduit',[(0,-.282,1.20),(0,-.30,1.40)],.0035,'charge','body',6,smooth=8)
tube('Neck / charged woven conduit',[(0,-.302,1.40),(0,-.36,1.52),(0,-.37,1.63)],.0035,'charge','neck',6,smooth=8)

# Build editable components with explicit UVs and clean normalized skin groups.
actors=[]
for (name,mat),q in B.items():
    me=bpy.data.meshes.new(name);me.from_pydata(q['v'],[],q['f']);me.update()
    ob=bpy.data.objects.new(name,me);sc.collection.objects.link(ob);me.materials.append(M[mat])
    uv=me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        poly.use_smooth=mat!='bronze'
        for li in poly.loop_indices:uv.data[li].uv=q['uv'][me.loops[li].vertex_index]
    # Weld cylindrical UV seams in geometry while preserving independent UV
    # corners. Duplicate seam vertices otherwise create a visible lighting
    # crease along every small rope, despite smooth polygon shading.
    bones=sorted({bn for w in q['w'] for bn in w})
    bm=bmesh.new();bm.from_mesh(me)
    if len(bones)==1:bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
    for bn in bones:
        vg=ob.vertex_groups.new(name=bn)
        if len(bones)==1:vg.add(list(range(len(me.vertices))),1,'REPLACE')
        else:
            for i,w in enumerate(q['w']):
                if bn in w:vg.add([i],w[bn],'REPLACE')
    ob.parent=rig;mod=ob.modifiers.new('Original animation skeleton','ARMATURE');mod.object=rig
    ob['construction']='V3 authored component; metric cloth UVs / longitudinal tubular UVs'
    actors.append(ob)

def tris(o):return sum(len(p.vertices)-2 for p in o.data.polygons)
rest_bounds=[[min(v.co[i] for o in actors for v in o.data.vertices),max(v.co[i] for o in actors for v in o.data.vertices)] for i in range(3)]
report={'version':3,'triangles':sum(tris(o) for o in actors),'vertices':sum(len(o.data.vertices) for o in actors),'bones':len(rig.data.bones),'materials':len(M),'components':len(actors),'bounds':rest_bounds,'clips':{a.name:round((a.frame_range[1]-a.frame_range[0])/30,4) for a in bpy.data.actions},'design':'authored tapered ceramic skull; individual cambered indigo fan panels; layered cloth primaries; basket weave; braided load paths; fitted joints; hooked talons','source':'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend','runtime':'Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v3.glb'}
(WORK/'manifest.json').write_text(json.dumps(report,indent=2));(WORK/'material_factors.json').write_text(json.dumps(FACTORS,indent=2))
(SRC/'build_report_v3.json').write_text(json.dumps(report,indent=2));(SRC/'material_export_factors_v3.json').write_text(json.dumps(FACTORS,indent=2))
sc.render.fps=30;rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1)
# Neutral studio setup is saved with the source. Preview never alters textures.
sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.19,.23,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
for o in sc.objects:
    if o.type=='LIGHT':bpy.data.objects.remove(o,do_unlink=True)
def light(name,pos,power,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
    o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
light('Large soft key',(2,-4,5),520,4,(1,.90,.77));light('Cool fill',(-3,-1,3),350,3,(.65,.80,1));light('Rim',(1,3,4),650,3,(.72,.85,1))
cam=sc.camera;cam.location=(3,-5,2.6);target=Vector((0,0,1.12));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=4.1
sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.resolution_x=1600;sc.render.resolution_y=1250;sc.render.resolution_percentage=100
sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'LoomHeron_Woven_v3.blend'),compress=True)
# Consolidate export only, while the packed source retains named parts.
for mat in M.values():
    obs=[o for o in sc.objects if o.type=='MESH' and o.data.materials[0]==mat]
    if not obs:continue
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=mat.name.replace(' | ','_')
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for o in sc.objects:
    if o.type=='MESH':o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(MODEL),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_anim_slide_to_zero=True,export_skins=True,export_cameras=False,export_lights=False)
print('HERON_V3_BUILD',json.dumps(report),flush=True)
sc.render.filepath=str(WORK/'renders/Heron_v3_First.png');bpy.ops.render.render(write_still=True)
