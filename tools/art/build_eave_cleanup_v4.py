"""New reference-led Eave Runner candidate; never overwrites active v2/v3 assets.

Run in background Blender. Native mesh/cloth authoring retains the existing
60-bone rig and actions. Render the saved model before proposing a live swap.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, shutil
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT/'work/eave-runner-v4'
OUT = WORK/'renders'
SOURCE = ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner'
for folder in (WORK, OUT): folder.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'EaveRunner_Woven_v3.blend'))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
rig = bpy.data.objects['EaveRunner_Rig']
rig.animation_data.action = None
rig.data.pose_position = 'REST'
for p in rig.pose.bones:
    p.location = (0,0,0); p.rotation_mode = 'QUATERNION'
    p.rotation_quaternion = (1,0,0,0); p.scale = (1,1,1)
bpy.context.view_layer.update()
H = {b.name:b.head_local.copy() for b in rig.data.bones}
T = {b.name:b.tail_local.copy() for b in rig.data.bones}
materials = {m.name.split(' | ',1)[-1]:m for m in bpy.data.materials}
M = {'indigo':materials['tailored indigo linen'], 'faded':materials['weathered indigo linen'],
     'navy':materials['folded navy lining'], 'charcoal':materials['gathered charcoal hemp'],
     'rope':materials['aged flax braid']}
removed = []
prefixes = ('Player-fitted sculpted indigo', 'Finished tunic and cowl cut hem',
            'Sculpt-fitted diagonal indigo', 'Fitted dark diagonal cloth sash',
            'Hand finished indigo wrap', 'Sparse flax outer wrap',
            'Gathered charcoal trouser', 'Rolled gathered trouser',
            'Layered split waist cloth tab', 'Dark stitched waist tab')
for obj in list(scene.objects):
    if obj.type == 'MESH' and obj.name.startswith(prefixes):
        removed.append(obj.name); bpy.data.objects.remove(obj, do_unlink=True)

def normalize(weights):
    pairs = sorted(((n,w) for n,w in weights.items() if w > .00001), key=lambda q:-q[1])[:4]
    total = sum(w for n,w in pairs)
    return {n:w/total for n,w in pairs}

def torso_weights(z):
    if z < 1.16:
        t = max(0,min(1,(z-1.06)/.10)); return normalize({'pelvis':1-t,'spine':t})
    t = max(0,min(1,(z-1.22)/.19))
    return normalize({'spine':1-t,'chest':t})

def mesh(name, verts, faces, material, weights, uv=None):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    obj = bpy.data.objects.new(name, me); scene.collection.objects.link(obj)
    me.materials.append(M[material]); layer = me.uv_layers.new(name='UVMap')
    groups = {n:obj.vertex_groups.new(name=n) for n in {n for w in weights for n in w}}
    for i,w in enumerate(weights):
        for n,v in normalize(w).items():groups[n].add([i], v, 'REPLACE')
    for poly in me.polygons:
        poly.use_smooth = True
        for li in poly.loop_indices:
            idx = me.loops[li].vertex_index
            layer.data[li].uv = uv[idx] if uv else (verts[idx][0]*2,verts[idx][2]*2)
    bm=bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.000001)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces)); bm.to_mesh(me); bm.free()
    obj.parent=rig; arm=obj.modifiers.new('Existing Eave skeleton','ARMATURE'); arm.object=rig
    if 'trouser' not in name:
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
        shell=obj.modifiers.new('Real thin cloth cut edge','SOLIDIFY');shell.thickness=.0018;shell.offset=-.5
        bpy.ops.object.modifier_move_up(modifier=shell.name)
        bpy.ops.object.modifier_apply(modifier=shell.name)
    obj['art_component']='reference-led cloth'; return obj

def grid(nx, ny):
    return [(j*(nx+1)+i,j*(nx+1)+i+1,(j+1)*(nx+1)+i+1,(j+1)*(nx+1)+i)
            for j in range(ny) for i in range(nx)]

def turned_edge(name, points, weights, width=.0035):
    """A flat folded-cloth strip, fitted to an existing panel boundary."""
    vs=[]; ws=[]; uv=[]
    for i,p in enumerate(points):
        tangent=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        across=tangent.cross(Vector((0,-1,0))).normalized()*width*.5
        for sign in (-1,1):
            q=Vector(p)+across*sign+Vector((0,-.0016,0))
            vs.append(q);ws.append(weights[i]);uv.append(((sign+1)*.13,i*.06))
    return mesh(name,vs,grid(1,len(points)-1),'navy',ws,uv)

profile=[(1.045,.153,.105),(1.14,.158,.110),(1.24,.177,.121),
         (1.34,.198,.124),(1.42,.212,.113),(1.48,.181,.099),(1.525,.093,.083)]
def section(z):
    for (a,x,y),(b,xx,yy) in zip(profile,profile[1:]):
        if z <= b:
            t=max(0,min(1,(z-a)/(b-a))); return x*(1-t)+xx*t,y*(1-t)+yy*t
    return profile[-1][1:]
def front(x,z,offset=0):
    rx,ry=section(z)
    return -ry*math.sqrt(max(.06,1-(x/rx)**2))-offset

# A coherent dark undershirt with bounded armholes and broad diagonal folds.
vs=[]; ws=[]; uv=[]; nx=64; ny=42
for j in range(ny+1):
    t=j/ny; z=1.045+t*.480; rx,ry=section(z)
    for i in range(nx+1):
        a=i/nx*math.tau
        fold=.0035*math.sin(5*a+z*18)*math.sin(math.pi*t)**2
        vs.append(((rx+fold)*math.sin(a),-(ry+fold)*math.cos(a),z))
        ws.append(torso_weights(z)); uv.append((i/nx*1.6,t*1.6))
fs=[]
for j in range(ny):
    for i in range(nx):
        z=1.045+(j+.5)/ny*.480; a=(i+.5)/nx*math.tau
        if 1.365<z<1.49 and abs(math.sin(a))>.84:continue
        q=j*(nx+1)+i;fs.append((q,q+1,q+nx+2,q+nx+1))
mesh('V4 coherent charcoal under-shirt',vs,fs,'charcoal',ws,uv)

# Broad crossed lapels sit on one known surface, rather than intersecting a
# dense cropped player garment. Subtle folds taper to their sewn boundaries.
def panel(name,corners,mat,offset):
    vs=[];ws=[];uv=[];nx=22;ny=34
    for j in range(ny+1):
        t=j/ny
        for i in range(nx+1):
            u=i/nx; p=Vector(corners[0]).lerp(Vector(corners[1]),u).lerp(
                Vector(corners[3]).lerp(Vector(corners[2]),u),t)
            x,z=p; y=front(x,z,offset)
            y-=.007*math.sin(math.pi*u)*math.sin(math.pi*t)
            y-=.0025*math.sin(3*math.pi*u+t*5)*math.sin(math.pi*u)
            vs.append((x,y,z));ws.append(torso_weights(z));uv.append((u*.7,t*1.5))
    obj=mesh(name,vs,grid(nx,ny),mat,ws,uv)
    for side in (0,nx):
        indices=[j*(nx+1)+side for j in range(ny+1)]
        turned_edge(name+' narrow folded edge '+str(side),[vs[i] for i in indices],[ws[i] for i in indices])
    return obj
panel('V4 inner indigo cross-wrap',[(-.190,1.445),(-.074,1.493),(.166,1.115),(.031,1.083)],'indigo',.010)
panel('V4 outer indigo cross-wrap',[(.135,1.488),(.208,1.405),(-.041,1.081),(-.172,1.136)],'faded',.024)

# Layered scarf folds define the reference's draped neck and asymmetry.
for band in range(3):
    vs=[];ws=[];uv=[];nx=72;ny=10
    for j in range(ny+1):
        t=j/ny
        for i in range(nx+1):
            a=i/nx*math.tau; f=max(0,math.cos(a+.22*band)); roll=.005*math.sin(math.pi*t)
            x=(.117+.013*band+.011*t+roll)*math.sin(a)
            y=-(.112+.017*band+.010*t+roll)*math.cos(a)
            z=1.577-band*.022-t*.067-f*(.025+.023*t)+.036*math.sin(a+.23*band)
            y-=.004*math.sin(a*3+t*3)*math.sin(math.pi*t)
            vs.append((x,y,z));ws.append(torso_weights(min(z,1.46)));uv.append((i/nx*1.7,t*.5))
    mesh('V4 soft folded scarf '+str(band),vs,grid(nx,ny),'indigo' if band==0 else 'faded',ws,uv)
panel('V4 asymmetric scarf front drape',[(.090,1.530),(.170,1.474),(-.100,1.343),(-.190,1.417)],'indigo',.043)

# Short layered sleeves follow the upper-arm articulation and hide the armhole
# join beneath cloth, while leaving the bound woven upper arm visible.
for side in ('L','R'):
    bone='upper_arm.'+side;a=H[bone];b=T[bone];axis=(b-a).normalized()
    u=Vector((0,-1,0));v=axis.cross(u).normalized()
    for band in range(2):
        vs=[];ws=[];uv=[];nx=32;ny=12
        for j in range(ny+1):
            t=j/ny;c=a.lerp(b,-.035+band*.015+t*(.32 if band==0 else .20))
            for i in range(nx+1):
                angle=i/nx*math.tau
                r=.055+.008*math.sin(math.pi*t)-.006*t+.004*band
                r+=.003*math.sin(angle*3+t*2)*math.sin(math.pi*t)
                p=c+r*(u*math.cos(angle)+v*math.sin(angle))
                p+=axis*((.012*math.sin(angle*2+band)+.005*math.sin(angle*5+.8))*t**4)
                # Flatten the top into a draped cloth shoulder rather than a
                # round padded cuff, keeping a thin physical cut edge.
                if p.z>a.z+.020:p.z=a.z+.020+(p.z-a.z-.020)*.42
                vs.append(p);ws.append({bone:1.0});uv.append((i/nx*.7,t*.6))
        mesh('V4 layered cloth shoulder '+side+str(band),vs,grid(nx,ny),'charcoal' if band==0 else 'indigo',ws,uv)

# Fuller thigh volume, gathered knees, and a few broad folds. The underlying
# leg rig stays intact. No thin tubular hems or repeated corrugated ridges.
for side,sign in [('L',1),('R',-1)]:
    bone='thigh.'+side;a=H[bone];b=T[bone];axis=(b-a).normalized()
    u=Vector((1,0,0));u=(u-axis*u.dot(axis)).normalized();v=axis.cross(u).normalized()
    vs=[];ws=[];uv=[];nx=56;ny=40
    for j in range(ny+1):
        t=j/ny;c=a.lerp(b,t);c.z+=.060*(1-t)**3;c.x+=sign*.010*math.sin(math.pi*t)
        r=.071+.050*math.sin(math.pi*t)**.85-.014*t
        for i in range(nx+1):
            angle=i/nx*math.tau
            fold=.006*math.sin(4*angle+t*3+sign*.4)*math.sin(math.pi*t)
            # Unequal diagonal tension from the knee knot, with vertical
            # gathers. No full-circumference horizontal sausage bands.
            center=.54+.20*math.sin(angle+sign*.5)
            localized=.25+.75*max(0,math.cos(angle-sign*.7))
            fold+=localized*(.005*math.exp(-((t-center)/.045)**2)-.003*math.exp(-((t-center+.055)/.04)**2))
            fold+=.006*math.sin(7*angle+.6*math.sin(t*6))*math.exp(-((t-.88)/.17)**2)
            rr=r+fold;p=c+rr*(u*math.cos(angle)+v*math.sin(angle)*.90)
            vs.append(p);ws.append(normalize({bone:1-.28*max(0,1-t/.28),'pelvis':.28*max(0,1-t/.28)}));uv.append((i/nx*1.2,t*1.8))
    fs=grid(nx,ny);fs+=[tuple(range(nx-1,-1,-1)),tuple(ny*(nx+1)+i for i in range(nx))]
    mesh('V4 gathered full charcoal trouser '+side,vs,fs,'charcoal',ws,uv)

# Seven short, irregular waist panels maintain the reference's broken hem.
for n in range(7):
    angle=n*math.tau/7+.10;nx=14;ny=18;vs=[];ws=[];uv=[]
    length=.165+(.075 if n in (0,6) else .018*(n%3))
    for j in range(ny+1):
        t=j/ny
        for i in range(nx+1):
            u=i/nx;a=angle+(u-.5)*.79*(1-.22*t)
            x=(.168+.026*t)*math.sin(a);y=-(.133+.016*t)*math.cos(a)
            notch=.012*math.exp(-((u-(.28 if n%2 else .70))/.065)**2)
            z=1.126-length*t-.015*math.sin(math.pi*u)*t+(.006*math.sin(5*u+n)+notch)*t**8
            y-=.007*math.sin(math.pi*u)*math.sin(t*4+n)
            vs.append((x,y,z)); leg='thigh.L' if x>0 else 'thigh.R'
            ws.append({'pelvis':1-.62*t,leg:.62*t});uv.append((u*.6,t*.9))
    mesh('V4 short asymmetric waist panel '+str(n),vs,grid(nx,ny),'faded' if n in (0,4) else 'indigo',ws,uv)

# Bring belt wrappings against the tailored waist rather than floating rings.
for obj in scene.objects:
    if obj.type!='MESH':continue
    if obj.name.startswith(('Overlapping woven waist','Double braided flax belt','Interlaced paired guardian waist')):
        for vert in obj.data.vertices:
            vert.co.x*=.97;vert.co.y*=.97
            if obj.name.startswith('Interlaced paired guardian waist'):vert.co.y-=.009
    if obj.name.startswith(('Carved bamboo bracer','Bracer fitted fastening','Bracer bronze fastening')):
        side='L' if ' L' in obj.name else 'R';a=H['forearm.'+side];b=T['forearm.'+side]
        axis=(b-a).normalized();center=(a+b)*.5
        for vertex in obj.data.vertices:
            p=vertex.co;along=axis*(p-center).dot(axis)
            vertex.co=center+along*.92+(p-center-along)*.88

# Existing 4K cloth detail supports the broad geometry; reduce overly strong
# tangent bump rather than creating noisy new baked images.
for mat in M.values():
    for node in mat.node_tree.nodes:
        if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.10
    if mat in (M['indigo'],M['faded'],M['rope']):
        factor=.72 if mat==M['rope'] else .70
        for node in mat.node_tree.nodes:
            if node.type=='MIX_RGB' and node.blend_type=='MULTIPLY':
                color=node.inputs[2].default_value
                node.inputs[2].default_value=(color[0]*factor,color[1]*factor,color[2]*factor,1)

helper=ROOT/'tools/art/eave_v4_head.py'
if not helper.is_file():raise FileNotFoundError('Required native hood helper: '+str(helper))
import importlib.util
spec=importlib.util.spec_from_file_location('eave_v4_head',helper);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
hood_report=module.refine(scene,rig)

# Retain shaped woven surfaces with fewer hidden radial faces. UV seams and
# deformation groups are preserved; every export weight is normalized below.
for obj in list(scene.objects):
    if obj.type!='MESH' or obj.name.startswith('V4'):continue
    if any(s in obj.name for s in ('woven','braid','Braided','Woven')) and not any(s in obj.name.lower() for s in ('hands','finger')) and len(obj.data.polygons)>1200:
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
        dec=obj.modifiers.new('V4 bounded cord simplification','DECIMATE');dec.ratio=.50
        bpy.ops.object.modifier_move_up(modifier=dec.name)
        bpy.ops.object.modifier_apply(modifier=dec.name)
for obj in scene.objects:
    if obj.type!='MESH' or obj.parent!=rig:continue
    for vertex in obj.data.vertices:
        weights=normalize({obj.vertex_groups[g.group].name:g.weight for g in vertex.groups})
        for group in list(vertex.groups):obj.vertex_groups[group.group].remove([vertex.index])
        for name,value in weights.items():obj.vertex_groups[name].add([vertex.index],value,'REPLACE')

rig.data.pose_position='POSE';rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)
actors=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
report={'candidate':True,'version':4,'baseline':'current saved v3, not stale renders','bones':len(rig.data.bones),
        'triangles':sum(len(p.vertices)-2 for o in actors for p in o.data.polygons),'components':len(actors),
        'removed_components':removed,'clips':{a.name:round((a.frame_range[1]-a.frame_range[0])/30,4) for a in bpy.data.actions},
        'reference':'outputs/woven-blue-guardians-2026-10-20/EaveRunner_Woven_Concept.png',
        'original_silhouette_reference':'outputs/lakeside-character-concepts-2026-10-19/Indoor_Enemies.png',
        'hood':hood_report,'active_replacement':False}
(WORK/'build_report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=1350;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
cam=scene.camera;cam.data.ortho_scale=2.15;cam.location=(2.6,-5.8,2.25)
cam.rotation_euler=(Vector((0,-.01,.99))-cam.location).to_track_quat('-Z','Y').to_euler()
for image in bpy.data.images:
    if image.source=='FILE' and not image.packed_file:image.pack()
scratch=ROOT/'tmp/eave_cleanup_v4/native_save.blend';scratch.parent.mkdir(parents=True,exist_ok=True)
if scratch.exists():scratch.unlink()
bpy.ops.wm.save_as_mainfile(filepath=str(scratch),compress=True)
shutil.copyfile(scratch,SOURCE/'EaveRunner_Woven_v4.blend')
scene.render.filepath=str(OUT/'Eave_v4_ThreeQuarter.png');bpy.ops.render.render(write_still=True)
print('EAVE_V4_CANDIDATE',json.dumps(report),flush=True)
