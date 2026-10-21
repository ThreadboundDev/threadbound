"""Replace crossing roof strips with side-owned rounded returns and miter joints.

Run Blender headless: --python this_file -- --input FILE.blend --out DIRECTORY
All non-roof meshes are preserved; the input file is never overwritten.
"""
import bpy,bmesh,math,json,hashlib,argparse,sys,tempfile,os
from pathlib import Path
from mathutils import Vector,Matrix

HERE=Path(__file__).resolve()
ROOT=next((p for p in HERE.parents if (p/'project.godot').exists()),HERE.parent)
parser=argparse.ArgumentParser()
parser.add_argument('--input',default=str(ROOT/'outputs/central-tower-model-v1/CentralTower_Editable.blend'))
parser.add_argument('--out',default=str(ROOT/'outputs/central-tower-model-v2'))
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
SRC=Path(args.input);OUT=Path(args.out)
for p in [OUT,OUT/'previews',OUT/'source',OUT/'source/build-temp']:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(OUT/'source/build-temp')
os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.open_mainfile(filepath=str(SRC))
bpy.context.preferences.filepaths.save_version=0
sc=bpy.context.scene
model=bpy.data.collections['CENTRAL_TOWER_MODEL']
R=bpy.data.collections['04_Fixed_Blue_Roofs'];F=bpy.data.collections['02_Facade_Removable']
root=bpy.data.objects['CentralTower_ROOT']
rootinv=root.matrix_world.inverted()
parents={R.name:bpy.data.objects[R.name],F.name:bpy.data.objects[F.name]}
for ob in model.all_objects:
    if ob is not None:ob.hide_set(False);ob.hide_viewport=False
for c in [model,R,F]:c.hide_viewport=False

def vertices(obs):
    return [rootinv@ob.matrix_world@v.co for ob in obs for v in ob.data.vertices]
def bounds(obs):
    p=vertices(obs)
    lo=Vector([min(v[i] for v in p) for i in range(3)])
    hi=Vector([max(v[i] for v in p) for i in range(3)])
    return lo,hi
def digest(ob):
    return hashlib.sha256(bytes(str([(tuple(v.co),) for v in ob.data.vertices])+str([tuple(p.vertices) for p in ob.data.polygons]),'utf8')).hexdigest()
meshes=lambda:[o for o in model.all_objects if o is not None and o.type=='MESH']
beforelo,beforehi=bounds(meshes())
protected={o.name:digest(o) for o in meshes() if o.name not in R.objects and o.name not in F.objects}

# Recover the exact original normalization from the unchanged basin geometry.
basin=[o for o in meshes() if '05_Open_Bottom_Basin' in o.name]
lo,hi=bounds(basin)
sx=(hi.x-lo.x)/(9.375-.012)
sy=(hi.y-lo.y)/(7.0-.012)
sz=(hi.z-lo.z)/.8
raw_min=Vector((-4.6875+.006,-4+.006,.01))
offset=raw_min-Vector((lo.x/sx,lo.y/sy,lo.z/sz))
def local(p):return tuple((p[i]-offset[i])*[sx,sy,sz][i] for i in range(3))
def raw(p):return Vector((p.x/sx+offset.x,p.y/sy+offset.y,p.z/sz+offset.z))

MATS={key:bpy.data.materials[key] for key in ['blue_tiles','walnut']}
def delete_faces(ob,predicate):
    bm=bmesh.new();bm.from_mesh(ob.data)
    rel=rootinv@ob.matrix_world
    faces=[f for f in bm.faces if predicate([raw(rel@v.co) for v in f.verts])]
    bmesh.ops.delete(bm,geom=faces,context='FACES')
    bm.to_mesh(ob.data);bm.free();ob.data.update()
    return len(faces)
deleted={}
for ob in list(R.objects):
    if ob is not None and ob.type=='MESH':
        deleted[ob.name]=delete_faces(ob,lambda vs:max(v.z for v in vs)<30)
        ob.name='Roof_Crown_Caps__'+ob.data.materials[0].name
for ob in list(F.objects):
    if ob is None or ob.type!='MESH':continue
    if ob.data.materials[0].name=='blue_tiles':
        deleted[ob.name]=len(ob.data.polygons)
        bpy.data.objects.remove(ob,do_unlink=True)
    elif ob.data.materials[0].name=='walnut':
        # The old front roof fascia is the only facade timber beyond raw Y=-2.7.
        deleted[ob.name]=delete_faces(ob,lambda vs:max(v.y for v in vs)<-2.7)

class Piece:
    def __init__(self,name,col):self.name=name;self.col=col;self.v=[];self.f=[];self.uv=[];self.mi=[];self.lookup={};self.top=[]
    def add(self,pts,uv=None,mat='blue_tiles',top=False):
        pts=[tuple(p) for p in pts]
        uv=uv or [(p[0]/2,p[1]/2) for p in pts]
        if top and (Vector(pts[1])-Vector(pts[0])).cross(Vector(pts[2])-Vector(pts[0])).z<0:
            pts.reverse();uv=list(reversed(uv))
        ids=[]
        for p in pts:
            key=tuple(round(v,8) for v in p)
            if key not in self.lookup:self.lookup[key]=len(self.v);self.v.append(local(p))
            ids.append(self.lookup[key])
        if len(set(ids))<3:return
        self.f.append(ids);self.uv.append(uv);self.mi.append(0 if mat=='blue_tiles' else 1)
        if top:self.top.append(pts)
    def build(self):
        me=bpy.data.meshes.new(self.name);me.from_pydata(self.v,[],self.f);me.update()
        ob=bpy.data.objects.new(self.name,me);self.col.objects.link(ob);ob.parent=parents[self.col.name]
        for mat in MATS.values():me.materials.append(mat)
        layer=me.uv_layers.new(name='UVMap')
        for face,coords,mi in zip(me.polygons,self.uv,self.mi):
            face.material_index=mi;face.use_smooth=mi==0
            for j,uv in zip(face.loop_indices,coords):layer.data[j].uv=uv
        bm=bmesh.new();bm.from_mesh(me)
        bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4])
        bm.to_mesh(me);bm.free();me.update()
        ob['roof_module']=True
        ob['cutaway_removable']=self.col==F
        ob['corner_ownership']='left/right side pieces retain both curved corners' if 'Side' in self.name else 'short center strip with angled ends'
        return ob

def tube(piece,points,r=.05,sides=8,mat='blue_tiles'):
    rings=[]
    for j,p in enumerate(points):
        p=Vector(p);t=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(j-1,0)])
        t.normalize();u=t.cross(Vector((0,0,1)))
        if u.length<.01:u=t.cross(Vector((0,1,0)))
        u.normalize();v=t.cross(u).normalized()
        rings.append([tuple(p+r*(math.cos(k*math.tau/sides)*u+math.sin(k*math.tau/sides)*v)) for k in range(sides)])
    for j in range(len(rings)-1):
        for k in range(sides):piece.add([rings[j][k],rings[j][(k+1)%sides],rings[j+1][(k+1)%sides],rings[j+1][k]],[(k/sides,j*.2),((k+1)/sides,j*.2),((k+1)/sides,(j+1)*.2),(k/sides,(j+1)*.2)],mat)
    piece.add(list(reversed(rings[0])),mat=mat);piece.add(rings[-1],mat=mat)

def fascia(piece,path):
    rings=[];dist=[0]
    for j,p in enumerate(path):
        p=Vector(p);t=Vector(path[min(j+1,len(path)-1)])-Vector(path[max(j-1,0)])
        n=Vector((t.y,-t.x,0)).normalized()*.06
        p.z-=.12
        rings.append([tuple(p+n+Vector((0,0,.10))),tuple(p-n+Vector((0,0,.10))),tuple(p-n-Vector((0,0,.10))),tuple(p+n-Vector((0,0,.10)))])
        if j:dist.append(dist[-1]+(Vector(path[j])-Vector(path[j-1])).length)
    for j in range(len(rings)-1):
        for k in range(4):piece.add([rings[j][k],rings[j+1][k],rings[j+1][(k+1)%4],rings[j][(k+1)%4]],[(k*.15,dist[j]/2),(k*.15,dist[j+1]/2),((k+1)*.15,dist[j+1]/2),((k+1)*.15,dist[j]/2)],'walnut')
    piece.add(list(reversed(rings[0])),mat='walnut');piece.add(rings[-1],mat='walnut')

def signed_area(poly):return sum(p[0]*q[1]-q[0]*p[1] for p,q in zip(poly,poly[1:]+poly[:1]))/2
def ccw(poly):return poly if signed_area(poly)>0 else list(reversed(poly))
def clip_polygon(subject,clip):
    # Independent footprint test: intersection with the convex center-strip trapezoid.
    out=list(subject)
    for a,b in zip(clip,clip[1:]+clip[:1]):
        old=out;out=[]
        if not old:break
        def side(p):return (b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0])
        p=old[-1];sp=side(p)
        for q in old:
            sq=side(q)
            if (sp>=-1e-10)!=(sq>=-1e-10):
                ratio=sp/(sp-sq);out.append((p[0]+ratio*(q[0]-p[0]),p[1]+ratio*(q[1]-p[1])))
            if sq>=-1e-10:out.append(q)
            p,sp=q,sq
    return out

created=[];checks=[];roof_specs=[(6.35,3.45,1.03),(16.65,2.95,1.30),(20.55,2.95,1.24),(25.45,2.15,1.25)]
for tier,(z,cx,rx) in enumerate(roof_specs,1):
    a=cx-.25;bf=2.18;bb=2.25;ry=1.07;rho=.32;ret=.72*rx
    A0=a-ret;A1=A0+rx
    def height(x,y):
        dx=max(0,(abs(x)-a)/rx)
        dy=max(0,(-y-bf)/ry,(y-bb)/ry)
        d=max(dx,dy)
        blend=max(0,min(1,(dx-dy)/.16+.5))
        ripple=.024*((1-blend)*math.cos(x/.23*math.tau)+blend*math.cos(y/.23*math.tau))
        return z+.83*(1-d)+.24*d**7+.24*min(dx,dy)**2+ripple
    def P(x,y):return(x,y,height(x,y))
    def uv(x,y):
        dx=max(0,(abs(x)-a)/rx);dy=max(0,(-y-bf)/ry,(y-bb)/ry)
        return (y/2 if dx>dy else x/2,max(dx,dy)*.75)
    def top(piece,coords):piece.add([P(x,y) for x,y in coords],[uv(x,y) for x,y in coords],top=True)
    def xouter(t):
        if t<=1-rho:return a+rx
        return a+rx*(1-rho+math.sqrt(max(0,rho*rho-(t-1+rho)**2)))
    # Front/back center pieces have angled ends, not crossing rectangles.
    fronts={}
    N=20
    for end in ['Front','Back']:
        piece=Piece(f'Roof_Tier{tier:02d}_{end}_Mitered',F if end=='Front' else R)
        fronts[end]=piece
        s=-1 if end=='Front' else 1;b=bf if s<0 else bb
        nx=max(24,round(2*A1/.15))
        for j in range(N):
            t0=j/N;t1=(j+1)/N
            for k in range(nx):
                u0=-1+2*k/nx;u1=-1+2*(k+1)/nx
                top(piece,[(u0*(A0+rx*t0),s*(b+ry*t0)),(u1*(A0+rx*t0),s*(b+ry*t0)),(u1*(A0+rx*t1),s*(b+ry*t1)),(u0*(A0+rx*t1),s*(b+ry*t1))])
        fascia(piece,[P(-A1+2*A1*k/48,s*(b+ry)) for k in range(49)])
        created.append(piece.build())
    side_footprints={}
    for sign,label in [(-1,'Left'),(1,'Right')]:
        piece=Piece(f'Roof_Tier{tier:02d}_{label}_Side_With_Corners',R)
        # Straight front-to-back side wing.
        ny=36;nv=12
        for j in range(ny):
            y0=-bf+(bf+bb)*j/ny;y1=-bf+(bf+bb)*(j+1)/ny
            for k in range(nv):
                x0=sign*(a+rx*k/nv);x1=sign*(a+rx*(k+1)/nv)
                top(piece,[(x0,y0),(x1,y0),(x1,y1),(x0,y1)])
        # Each side owns both curved corner returns. Their inner boundaries are
        # exactly the matching front/back miter lines, shared by position only.
        maxseam=0
        for end,ys,b in [('Front',-1,bf),('Back',1,bb)]:
            m=20
            for j in range(N):
                t0=j/N;t1=(j+1)/N
                xmin0=A0+rx*t0;xmin1=A0+rx*t1
                xmax0=xouter(t0);xmax1=xouter(t1)
                for k in range(m):
                    u0=k/m;u1=(k+1)/m
                    top(piece,[(sign*(xmin0+(xmax0-xmin0)*u0),ys*(b+ry*t0)),(sign*(xmin0+(xmax0-xmin0)*u1),ys*(b+ry*t0)),(sign*(xmin1+(xmax1-xmin1)*u1),ys*(b+ry*t1)),(sign*(xmin1+(xmax1-xmin1)*u0),ys*(b+ry*t1))])
            # A single diagonal hip ridge belongs to this side, not the facade.
            diag=1-rho+rho/math.sqrt(2)
            tube(piece,[(sign*(a+rx*d),ys*(b+ry*d),height(sign*(a+rx*d),ys*(b+ry*d))+.055) for d in [diag*k/24 for k in range(25)]],.052,8)
        # Continuous fascia follows the rounded outside, not two crossed beams.
        outer=[(A1,-bf-ry),(a+rx*(1-rho),-bf-ry)]
        for k in range(1,17):
            theta=-math.pi/2+k/16*math.pi/2
            outer.append((a+rx*(1-rho+rho*math.cos(theta)),-bf-ry+ry*rho+ry*rho*math.sin(theta)))
        outer.append((a+rx,bb+ry-ry*rho))
        for k in range(1,17):
            theta=k/16*math.pi/2
            outer.append((a+rx*(1-rho+rho*math.cos(theta)),bb+ry-ry*rho+ry*rho*math.sin(theta)))
        outer.append((A1,bb+ry))
        fascia(piece,[P(sign*x,y) for x,y in outer])
        footprint=outer+[(A0,bb),(a,bb),(a,-bf),(A0,-bf)]
        side_footprints[label]=ccw([(sign*x,y) for x,y in footprint])
        ob=piece.build();ob['retains_front_and_back_corners']=True;created.append(ob)
        # Independently read mesh vertices to confirm both seam boundaries exist.
        coords=[Vector(v.co) for v in ob.data.vertices]
        for ys,b in [(-1,bf),(1,bb)]:
            for j in range(N+1):
                t=j/N;p=Vector(local(P(sign*(A0+rx*t),ys*(b+ry*t))))
                maxseam=max(maxseam,min((p-v).length for v in coords))
        assert maxseam<1e-5,maxseam
        checks.append({'tier':tier,'side':label,'seam_vertex_max_error':maxseam})
    fpoly=ccw([(-A0,-bf),(A0,-bf),(A1,-bf-ry),(-A1,-bf-ry)])
    bpoly=ccw([(-A0,bb),(A0,bb),(A1,bb+ry),(-A1,bb+ry)])
    for end,poly in [('Front',fpoly),('Back',bpoly)]:
        for side,subject in side_footprints.items():
            intersection=clip_polygon(subject,poly)
            area=abs(signed_area(intersection)) if len(intersection)>2 else 0
            assert area<1e-7,(tier,end,side,area)
            checks.append({'tier':tier,'end':end,'side':side,'overlapping_roof_footprint_area':area})

# Dedupe the untouched crown's exactly coincident ridge-cap faces inherited from
# its two pitches; no crown surface shape or position changes.
for ob in R.objects:
    if ob is None or ob.type!='MESH' or not ob.name.startswith('Roof_Crown'):continue
    bm=bmesh.new();bm.from_mesh(ob.data)
    seen=set();duplicate=[]
    for f in bm.faces:
        key=tuple(sorted(tuple(round(c,7) for c in v.co) for v in f.verts))
        if key in seen:duplicate.append(f)
        else:seen.add(key)
    if duplicate:bmesh.ops.delete(bm,geom=duplicate,context='FACES')
    bm.to_mesh(ob.data);bm.free();ob.data.update()

for name,d in protected.items():assert digest(bpy.data.objects[name])==d,name
afterlo,afterhi=bounds(meshes())
before=beforehi-beforelo;after=afterhi-afterlo
assert abs(after.x-before.x)<1e-5 and abs(after.z-before.z)<1e-5
root['roof_revision']='v2: side-owned rounded corners; angled front/back center strips'
root['roof_part_identification']='Roof_Tier##_Left/Right_Side_With_Corners and Roof_Tier##_Front/Back_Mitered'

def visible(full):
    F.hide_render=not full;F.hide_viewport=False
    for ob in F.objects:
        if ob is not None:ob.hide_render=not full
def export(name,full):
    visible(True);bpy.ops.object.select_all(action='DESELECT')
    for ob in model.all_objects:
        if ob is None:continue
        if not full and ob.name in F.objects:continue
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_tangents=True,export_materials='EXPORT',export_image_format='AUTO',export_extras=True,export_cameras=False,export_lights=False)
    bpy.ops.object.select_all(action='DESELECT')

# Reuse the previously approved material images; no texture content is changed.
swaps=[];runtime_images=[]
for mat in bpy.data.materials:
    if not mat.use_nodes:continue
    key=mat.name.split('.')[0]
    if key not in ['walnut','plaster','blue_tiles','slate']:continue
    for node in mat.node_tree.nodes:
        if node.type!='TEX_IMAGE' or node.image is None:continue
        old=node.image;fn=old.name
        if 'BaseColor' in fn:rt=key+'_BaseColor_4K.jpg'
        elif 'NormalGL' in fn:rt=key+'_NormalGL_2K.png'
        elif 'Roughness' in fn:rt=key+'_Roughness_2K.png'
        else:continue
        path=SRC.parent/'textures/runtime'/rt
        if not path.exists():continue
        im=bpy.data.images.load(str(path),check_existing=True)
        if 'BaseColor' not in fn:im.colorspace_settings.name='Non-Color'
        swaps.append((node,old));node.image=im;runtime_images.append(im)
export('CentralTower_Exterior.glb',True);export('CentralTower_Cutaway.glb',False)
for node,im in swaps:node.image=im
for im in set(runtime_images):
    if im.users==0:bpy.data.images.remove(im)
for im in bpy.data.images:
    if im.source=='FILE' and not im.packed_file and im.users:
        try:im.pack()
        except Exception:pass

def stats(obs):
    n=0
    for ob in obs:ob.data.calc_loop_triangles();n+=len(ob.data.loop_triangles)
    return {'meshes':len(obs),'triangles':n}
report={'input_file':str(SRC),'version':'v2 roof joints','before_dimensions':list(before),'after_dimensions':list(after),'normalization_scale':[sx,sy,sz],'raw_offset':list(offset),'protected_mesh_hashes_unchanged':True,'removed_faces':deleted,'joint_checks':checks,'exterior':stats(meshes()),'cutaway':stats([o for o in meshes() if o.name not in F.objects]),'fixed_side_roof_parts':[o.name for o in created if 'Side_With_Corners' in o.name],'removable_front_roof_parts':[o.name for o in created if 'Front_Mitered' in o.name],'checks_passed':True}
(OUT/'roof_joint_verification.json').write_text(json.dumps(report,indent=2))

cam=sc.camera
def camera(loc,target,ortho):
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=ortho
sc.render.engine='CYCLES';sc.cycles.samples=40;sc.cycles.use_denoising=True
sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA';sc.render.film_transparent=True
sc.render.resolution_percentage=100
def render(name,full,loc,target,ortho,w=1600,h=1200):
    visible(full);camera(loc,target,ortho)
    sc.render.resolution_x=w;sc.render.resolution_y=h;sc.render.filepath=str(OUT/'previews'/name)
    bpy.ops.render.render(write_still=True);print('RENDER_READY',name,flush=True)
visible(True);camera((40,-70,37),(0,0,15.6),35.8)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))
render('roof_corners_exterior.png',True,(13,-21,26),(2.3,-1.6,20.8),8.6)
render('roof_corners_cutaway.png',False,(13,-21,26),(2.3,-1.6,20.8),8.6)
render('exterior_three_quarter.png',True,(40,-70,37),(0,0,15.6),35.8,1200,1800)
render('cutaway_three_quarter.png',False,(32,-80,33),(0,0,15.7),35.4,1200,1800)
visible(True);camera((40,-70,37),(0,0,15.6),35.8)
sc.render.resolution_x=1200;sc.render.resolution_y=1800
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))
print('ROOF_FIX_COMPLETE',json.dumps(report),flush=True)
