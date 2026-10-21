"""Headless, reproducible tower build; creates only a new output asset package."""
import bpy, math, json, random, sys, tempfile, os
from pathlib import Path
from mathutils import Vector

HERE=Path(__file__).resolve()
ROOT=HERE.parents[3] if HERE.parent.name=='source' else HERE.parents[2]
OUT=HERE.parents[1] if HERE.parent.name=='source' else ROOT/'outputs/central-tower-model-v1'
TEMP=OUT/'source/build-temp' if HERE.parent.name=='source' else ROOT/'work/central-tower/blender-temp'
TEMP.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(TEMP)
os.environ['TEMP']=str(TEMP)
os.environ['TMP']=str(TEMP)
TEX=OUT/'textures'
OUT.mkdir(parents=True,exist_ok=True)
random.seed(1401)
PPU=128
TARGET_H=4100/PPU
TARGET_W=1200/PPU
DEPTH=6.0
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
sc=bpy.context.scene
sc.render.engine='CYCLES'
sc.cycles.samples=32
sc.cycles.use_denoising=True
sc.render.image_settings.file_format='PNG'
sc.render.image_settings.color_mode='RGBA'
sc.render.film_transparent=True
sc.view_settings.view_transform='AgX'
sc.world=bpy.data.worlds.new('Neutral studio ambient')
sc.world.use_nodes=True
sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.34,.38,.43,1)
sc.world.node_tree.nodes['Background'].inputs[1].default_value=.65
try:
    prefs=bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type='OPTIX'
    prefs.get_devices()
    found=False
    for d in prefs.devices:
        d.use=d.type!='CPU'; found=found or d.use
    if found: sc.cycles.device='GPU'
except Exception: pass

model=bpy.data.collections.new('CENTRAL_TOWER_MODEL');sc.collection.children.link(model)
root=bpy.data.objects.new('CentralTower_ROOT',None);model.objects.link(root)
root['pixels_per_unit']=PPU
root['height_gameplay_px']=4100
root['maximum_width_gameplay_px']=1200
root['depth_gameplay_px']=DEPTH*PPU
root['depth_is_proposed']=True
root['cutaway_instructions']='Hide collection 02_Facade_Removable; show it for full exterior.'
COLS={}
for key in ['01_Structure','02_Facade_Removable','03_Interior_Platforms','04_Fixed_Blue_Roofs','05_Open_Bottom_Basin']:
    c=bpy.data.collections.new(key);model.children.link(c)
    e=bpy.data.objects.new(key,None);c.objects.link(e);e.parent=root
    COLS[key]=(c,e)

MATS={}
def material(name,base=None,rough=.8):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes; l=m.node_tree.links;p=n.get('Principled BSDF')
    p.inputs['Roughness'].default_value=rough
    if base:
        image=n.new('ShaderNodeTexImage');image.name='BaseColor_4K';image.image=bpy.data.images.load(str(TEX/f'{base}_BaseColor_4K.png'),check_existing=True)
        image.extension='REPEAT';l.new(image.outputs['Color'],p.inputs['Base Color'])
        norm=n.new('ShaderNodeTexImage');norm.image=bpy.data.images.load(str(TEX/f'{base}_NormalGL_4K.png'),check_existing=True);norm.image.colorspace_settings.name='Non-Color'
        normal=n.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.45
        l.new(norm.outputs['Color'],normal.inputs['Color']);l.new(normal.outputs['Normal'],p.inputs['Normal'])
        rr=n.new('ShaderNodeTexImage');rr.image=bpy.data.images.load(str(TEX/f'{base}_Roughness_4K.png'),check_existing=True);rr.image.colorspace_settings.name='Non-Color'
        l.new(rr.outputs['Color'],p.inputs['Roughness'])
    return m
for key in ['walnut','plaster','blue_tiles','slate']:MATS[key]=material(key,base=key)
for key,col,rough in [('rope',(.37,.255,.135,1),.92),('iron',(.07,.065,.055,1),.66),('recess',(.028,.024,.020,1),1)]:
    m=material(key,rough=rough);m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=col;MATS[key]=m

class Batch:
    def __init__(self,group,mat):self.group=group;self.mat=mat;self.v=[];self.f=[];self.uv=[]
    def face(self,verts,uv=None):
        start=len(self.v);self.v.extend(verts);self.f.append(tuple(range(start,start+len(verts))))
        if uv is None:
            v0=Vector(verts[0]);a=(Vector(verts[1])-v0);length=a.length
            if length<1e-8: uv=[(0,0)]*len(verts)
            else:
                a.normalize();normal=a.cross(Vector(verts[-1])-v0)
                if normal.length>1e-8:normal.normalize()
                b=normal.cross(a)
                uv=[((Vector(v)-v0).dot(a)/2.5,(Vector(v)-v0).dot(b)/2.5) for v in verts]
        self.uv.append(uv)
    def build(self):
        me=bpy.data.meshes.new(self.group+'_'+self.mat);me.from_pydata(self.v,[],self.f);me.update()
        ob=bpy.data.objects.new(self.group+'__'+self.mat,me);COLS[self.group][0].objects.link(ob);ob.parent=COLS[self.group][1]
        me.materials.append(MATS[self.mat]);uv=me.uv_layers.new(name='UVMap')
        for poly,coords in zip(me.polygons,self.uv):
            for li,co in zip(poly.loop_indices,coords):uv.data[li].uv=co
        # Low subdivision edge bevels preserve highlights without a high-poly sculpt.
        if self.mat in ['walnut','plaster','slate']:
            mod=ob.modifiers.new('Small silhouette and edge highlights','BEVEL');mod.width=.018 if self.mat!='slate' else .025;mod.segments=1;mod.limit_method='ANGLE'
            mod=ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
        for p in me.polygons:p.use_smooth=self.mat in ['blue_tiles','rope']
        return ob
B={}
def batch(g,m):
    if (g,m) not in B:B[g,m]=Batch(g,m)
    return B[g,m]
S='01_Structure';F='02_Facade_Removable';I='03_Interior_Platforms';R='04_Fixed_Blue_Roofs';A='05_Open_Bottom_Basin'
def face(g,m,vs,uv=None):batch(g,m).face(vs,uv)
def box(g,m,loc,size):
    x,y,z=loc;a,b,c=[s/2 for s in size]
    vs=[(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),(x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)]
    for inds in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
        pts=[vs[j] for j in inds]
        if m=='walnut':
            # Vertical grain follows longest face axis, including horizontal beams.
            p0,p1,p3=map(Vector,[pts[0],pts[1],pts[-1]])
            aa=(p1-p0).length;bb=(p3-p0).length
            off=random.random()*.8
            if aa>bb:uv=[(off+(Vector(p)-p0).dot((p3-p0).normalized())*1.4,(Vector(p)-p0).dot((p1-p0).normalized())/2.3) for p in pts]
            else:uv=[(off+(Vector(p)-p0).dot((p1-p0).normalized())*1.4,(Vector(p)-p0).dot((p3-p0).normalized())/2.3) for p in pts]
            face(g,m,pts,uv)
        elif m=='slate':
            # Sample within one stone face, not an entire brick wall on every block.
            u0=random.choice([.04,.22,.38]);v0=random.choice([.05,.28,.55,.76])
            face(g,m,pts,[(u0,v0),(u0+.10,v0),(u0+.10,v0+.16),(u0,v0+.16)])
        else:face(g,m,pts)
def beam(g,m,p1,p2,width,depth=None):
    a=Vector(p1);b=Vector(p2);d=b-a
    helper=Vector((0,1,0)) if abs(d.normalized().y)<.8 else Vector((1,0,0))
    u=d.normalized().cross(helper).normalized()*width/2
    v=d.normalized().cross(u).normalized()*(depth or width)/2
    vs=[tuple(p+u*su+v*sv) for p in [a,b] for su,sv in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    for inds in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:face(g,m,[vs[j] for j in inds])
def tube(g,m,points,r=.025,sides=6):
    rings=[]
    for j,p in enumerate(points):
        p=Vector(p);t=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(j-1,0)])
        t.normalize();u=t.cross(Vector((0,0,1)))
        if u.length<.01:u=t.cross(Vector((0,1,0)))
        u.normalize();v=t.cross(u).normalized()
        rings.append([tuple(p+r*(u*math.cos(k*math.tau/sides)+v*math.sin(k*math.tau/sides))) for k in range(sides)])
    for j in range(len(rings)-1):
        for k in range(sides):face(g,m,[rings[j][k],rings[j][(k+1)%sides],rings[j+1][(k+1)%sides],rings[j+1][k]],[(k/sides,j*.2),((k+1)/sides,j*.2),((k+1)/sides,(j+1)*.2),(k/sides,(j+1)*.2)])
def peg(g,x,y,z):
    tube(g,'iron',[(x,y+.02,z),(x,y-.04,z)],.037,8)

# A genuine hollow perimeter ring: there is no face, slab, or mesh across its center.
def stone_run(g,x0,x1,y0,y1,z0,z1,along='x',course=.38):
    rows=max(1,round((z1-z0)/course));rh=(z1-z0)/rows
    for row in range(rows):
        lo,hi=(x0,x1) if along=='x' else (y0,y1)
        span=hi-lo;n=max(1,round(span/.76));step=span/n
        cuts=[lo]+[lo+i*step+(.24*step if row%2 else 0) for i in range(1,n)]+[hi]
        for a,b in zip(cuts,cuts[1:]):
            if along=='x':loc=((a+b)/2,(y0+y1)/2,z0+(row+.5)*rh);sz=(b-a-.022,y1-y0-.012,rh-.02)
            else:loc=((x0+x1)/2,(a+b)/2,z0+(row+.5)*rh);sz=(x1-x0-.012,b-a-.022,rh-.02)
            box(g,'slate',loc,sz)
W=TARGET_W/2
stone_run(A,-W,W,-4,-3.35,0,.82)
stone_run(A,-W,W,2.4,3,0,.82)
stone_run(A,-W,-W+.62,-3.35,2.4,0,.82,'y')
stone_run(A,W-.62,W,-3.35,2.4,0,.82,'y')
for s in [-1,1]:
    for y in [-2.1,2.1]:
        x=s*3.62
        stone_run(S,x-.6,x+.6,y-.52,y+.52,.82,2.55)
        # Splayed pedestal is narrower higher up.
        stone_run(S,x-.48,x+.48,y-.45,y+.45,2.55,4.2)
        box(S,'walnut',(s*3.45,y,4.8),(.48,.48,4.0))

# Continuous stepped side walls and front/back corner timbers.
levels=[(.82,5.9,3.53,1.05),(5.9,24.9,2.95,.82),(24.9,29.65,2.15,.78),(29.65,31.48,2.28,1.05)]
for za,zb,cx,th in levels:
    for s in [-1,1]:
        box(S,'plaster',(s*cx,0,(za+zb)/2),(th,4.25,zb-za))
        for y in [-2.18,2.18]:
            for x in [s*(cx-th/2+.08),s*(cx+th/2-.08)]:
                box(S,'walnut',(x,y,(za+zb)/2),(.27,.31,zb-za+.10))
        # Side panel joinery breaks long flat walls into believable bays.
        for z in [za+.12,zb-.12]:box(S,'walnut',(s*cx,0,z),(th+.14,4.55,.21))
        z=za+2.9
        while z<zb-.5:
            box(S,'walnut',(s*(cx+th/2+.025),0,z),(.15,4.46,.19));z+=3.1
        # Long exterior side mid-post.
        box(S,'walnut',(s*(cx+th/2+.035),0,(za+zb)/2),(.16,.18,zb-za))

# Back wall: central infill remains visible in cutaway.
for za,zb,half in [(.82,5.9,3.50),(5.9,24.9,2.90),(24.9,26.65,2.1)]:
    box(S,'plaster',(0,2.06,(za+zb)/2),(half*2,.19,zb-za))
    for z in [za+.1,zb-.1]:box(S,'walnut',(0,2.2,z),(half*2+.12,.22,.20))
    for x in [-half,0,half]:box(S,'walnut',(x,2.2,(za+zb)/2),(.18,.24,zb-za))

# Interior floors/ledges traced to the selected illustrated cutaway, kept separate.
platforms=[(6.35,'full'),(8.24,'leftshort'),(8.98,'rightshort'),(11.48,'full'),(14.30,'right'),(17.0,'left'),(19.65,'full'),(23.0,'full'),(26.65,'upper')]
for j,(z,kind) in enumerate(platforms):
    if kind=='upper':x0,x1=-1.82,1.82
    elif kind=='full':x0,x1=-2.6,2.6
    elif kind=='left':x0,x1=-2.6,.20
    elif kind=='right':x0,x1=-.25,2.6
    elif kind=='leftshort':x0,x1=-2.6,-.5
    else:x0,x1=.45,2.6
    width=x1-x0
    n=max(2,round(width/.40))
    for k in range(n):box(I,'walnut',(x0+(k+.5)*width/n,0,z-.095),(width/n-.016,4.0,.19))
    for y in [-1.82,1.82]:box(I,'walnut',((x0+x1)/2,y,z-.24),(width+.12,.18,.27))
    for x in [x0+.15,x1-.15]:
        beam(I,'walnut',(x,1.83,z-.8),(x,1.05,z-.2),.12)
    if kind in ['leftshort','rightshort']:
        wallx=-2.35 if kind=='leftshort' else 2.35
        for k in range(5):box(S,'walnut',(wallx,-2.22,z-.28-k*.12),(1.0,.12,.095))

# Exterior facade panels, windows and door are one removable assembly.
def window(g,cx,y,z,width=1.55,height=1.65,side=False):
    def part(xoff,zoff,w,h,mat,dep=.12):
        if not side:box(g,mat,(cx+xoff,y,z+zoff),(w,dep,h))
        else:box(g,mat,(y,cx+xoff,z+zoff),(dep,w,h))
    part(0,0,width,height,'recess',.07)
    for x in [-width/2,width/2]:part(x,0,.15,height+.30,'walnut',.19)
    for zz in [-height/2,height/2]:part(0,zz,width+.30,.16,'walnut',.21)
    for k in range(7):part(-width*.42+k*width*.14,0,.055,height,'walnut',.22)
    for zz in [-height*.23,height*.23]:part(0,zz,width,.06,'walnut',.23)
facade_bays=[(.9,6.35,3.45,3.0,2.6),(6.35,11.48,2.90,9.0,1.65),(11.48,19.65,2.90,15.6,1.8),(19.65,23.0,2.90,21.1,1.4),(23.0,26.65,2.40,24.4,1.4)]
for za,zb,half,wz,wh in facade_bays:
    # Real opening behind the lattice, rather than a black decal on a solid wall.
    opening=1.1 if za<1 else .90
    for s in [-1,1]:
        box(F,'plaster',(s*(half+opening)/2,-2.10,(za+zb)/2),(half-opening,.20,zb-za))
    for aa,bb in [(za,wz-wh/2),(wz+wh/2,zb)]:
        if bb>aa:box(F,'plaster',(0,-2.10,(aa+bb)/2),(opening*2,.20,bb-aa))
    for x in [-half,-opening,opening,half]:box(F,'walnut',(x,-2.25,(za+zb)/2),(.21,.22,zb-za+.1))
    for z in [za+.05,zb-.05]:box(F,'walnut',(0,-2.25,z),(half*2+.13,.23,.19))
    if za<1:
        for k in range(10):box(F,'walnut',(-.99+(k+.5)*.198,-2.27,wz),(.184,.13,wh))
        window(F,0,-2.40,wz+.66,1.85,.85)
        for x in [-.15,.15]:peg(F,x,-2.46,wz-.30)
    else:window(F,0,-2.30,wz,opening*2-.1,wh)

# Side windows and corresponding back windows reinforce a full, coherent model.
for z in [9.0,15.6,21.1]:
    for s in [-1,1]:window(S,0,s*3.40,z,1.55,1.6,side=True)
    window(S,0,2.35,z,1.55,1.65)

def roof(g,orient,center,span,run,z,cap=False):
    # Corrugated curved tiles are real geometry, not a flat roof texture card.
    # u runs along eave, v down the curved pitch.
    cx,cy=center
    nu=max(12,round(span/.21)*2);nv=8
    tiles=max(6,round(span/.22))
    def point(u,v):
        along=(u-.5)*span
        zz=z+.83*(1-v)+.24*v**7+.25*abs(2*u-1)**8*v*v
        zz+=.026*math.cos(u*tiles*math.tau)
        if orient=='front':return(cx+along,cy-run*v,zz)
        if orient=='back':return(cx-along,cy+run*v,zz)
        if orient=='left':return(cx-run*v,cy+along,zz)
        return(cx+run*v,cy-along,zz)
    for a in range(nu):
        for b in range(nv):
            coords=[(a/nu,b/nv),((a+1)/nu,b/nv),((a+1)/nu,(b+1)/nv),(a/nu,(b+1)/nv)]
            if orient in ['front','back']:coords.reverse()
            face(g,'blue_tiles',[point(u,v) for u,v in coords],[(u*span/2.0,v*.75) for u,v in coords])
    # Heavy front fascia and ridge, plus curved tile-end pipes.
    p0=point(0,1);p1=point(1,1)
    beam(g,'walnut',(p0[0],p0[1],p0[2]-.11),(p1[0],p1[1],p1[2]-.11),.15,.22)
    tube(g,'blue_tiles',[point(k/32,0) for k in range(33)],.075,8)
    for k in range(tiles):
        u=(k+.5)/tiles
        tube(g,'blue_tiles',[point(u,v) for v in [.78,.88,1]],.043,6)
    for u in [0,1]:tube(g,'blue_tiles',[point(u,v) for v in [0,.2,.4,.6,.8,1]],.052,8)

# Roof strips at matching elevations; front center strips belong to removable facade.
roof_specs=[(6.35,3.45,1.03),(16.65,2.95,1.30),(20.55,2.95,1.24),(25.45,2.15,1.25)]
for z,cx,run in roof_specs:
    for s in [-1,1]:
        roof(R,'left' if s<0 else 'right',(s*(cx-.25),0),5.0,run,z)
        # Visible corner wing pieces remain in cutaway.
        roof(R,'front',(s*cx,-1.98),1.35,1.02,z)
        roof(R,'back',(s*cx,1.98),1.35,1.02,z)
        for y in [-1.92,.0,1.92]:
            beam(S,'walnut',(s*(cx-.1),y,z-.90),(s*(cx+run*.75),y,z-.12),.18)
            box(S,'walnut',(s*(cx+run*.18),y,z-.16),(run+.35,.23,.21))
    roof(F,'front',(0,-1.98),cx*2-1.18,1.02,z)
    # Ridge cap must be outside the rear wall, not protruding into the cutaway.
    roof(R,'back',(0,2.25),cx*2-1.18,1.02,z)

# Individual prong roof caps: leave the central crown open.
for s in [-1,1]:
    for orientation,y in [('front',0),('back',0)]:roof(R,orientation,(s*2.28,y),2.05,2.62,31.35,True)
    for y in [-1.8,1.8]:
        beam(S,'walnut',(s*2.28,y,30.55),(s*(2.28+.58),y,31.25),.16)
    # Modest upturned corner finials, anchored to the cap geometry.
    for xx in [s*2.28-1.0,s*2.28+1.0]:
        tube(R,'blue_tiles',[(xx,0,31.87),(xx+s*.08,0,32.03),(xx+s*.16,0,32.18)],.065,8)

# Timber collars, fasteners, and actual wrapped rope loops.
for z in [6.36,8.2,11.5,14.4,19.7,23.0,25.0,29.6]:
    cx=2.95 if z<24.9 else 2.15
    for s in [-1,1]:
        box(S,'walnut',(s*cx,-2.27,z),(.95,.23,.23))
        for dx in [-.32,.32]:peg(S,s*cx+dx,-2.42,z)
for z in [8.0,14.5,22.3]:
    for s in [-1,1]:
        cx=s*2.95
        for yy in [-2.17,2.17]:
            for turn in range(4):
                zz=z+turn*.065
                pts=[]
                for k in range(33):
                    a=k*math.tau/32
                    # Superellipse tightly wraps square post; rounded corners.
                    xx=math.copysign(abs(math.cos(a))**.42,math.cos(a))*.47
                    dy=math.copysign(abs(math.sin(a))**.42,math.sin(a))*.23
                    pts.append((cx+xx,yy+dy,zz+.025*math.sin(a)))
                tube(S,'rope',pts,.027,6)

objects=[bb.build() for bb in B.values()]
# Normalize all actual renderable geometry, including eave tips/finials, to exact envelope.
coords=[Vector(v.co) for ob in objects for v in ob.data.vertices]
mn=Vector(tuple(min(c[i] for c in coords) for i in range(3)));mx=Vector(tuple(max(c[i] for c in coords) for i in range(3)))
scale=Vector((TARGET_W/(mx.x-mn.x),DEPTH/(mx.y-mn.y),TARGET_H/(mx.z-mn.z)))
offset=Vector(((mx.x+mn.x)/2,(mx.y+mn.y)/2,mn.z))
for ob in objects:
    for v in ob.data.vertices:
        p=v.co-offset;v.co=(p.x*scale.x,p.y*scale.y,p.z*scale.z)
root['actual_dimensions_blender_units']=[TARGET_W,DEPTH,TARGET_H]
root['reference_file']='central-tower-cutaway-and-exterior-v3.png'

# Non-rendering concept reference boards are packed into the editable .blend.
refs=bpy.data.collections.new('REFERENCES_not_exported');sc.collection.children.link(refs)
for i,fn in enumerate(['central-tower-concept-v2.png','central-tower-cutaway-and-exterior-v3.png','gameplay-shape-reference.png']):
    p=OUT/'references'/fn
    if not p.exists():p=ROOT/'outputs/central-tower-concept'/fn
    im=bpy.data.images.load(str(p),check_existing=True);im.pack()
    ob=bpy.data.objects.new('Reference_'+fn,None);refs.objects.link(ob);ob.empty_display_type='IMAGE';ob.data=im;ob.empty_display_size=20;ob.location=(14+i*11,4,16);ob.rotation_euler=(math.pi/2,0,0);ob.hide_render=True
refs.hide_viewport=True

# Apply modifiers before export so the BLEND and both GLBs have the same geometry.
for ob in objects:
    bpy.context.view_layer.objects.active=ob;ob.select_set(True)
    for mod in list(ob.modifiers):
        try:bpy.ops.object.modifier_apply(modifier=mod.name)
        except Exception as ex:print('MODIFIER_NOTE',ob.name,str(ex),flush=True)
    ob.select_set(False)

def set_facade(show):
    COLS[F][0].hide_render=not show
    for ob in COLS[F][0].objects:ob.hide_render=not show
def export_glb(filename,full):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in model.all_objects:
        if not full and (ob.name in COLS[F][0].objects):continue
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/filename),export_format='GLB',use_selection=True,export_apply=False,export_yup=True,export_texcoords=True,export_normals=True,export_tangents=True,export_materials='EXPORT',export_image_format='AUTO',export_extras=True,export_cameras=False,export_lights=False)
    bpy.ops.object.select_all(action='DESELECT')
# Runtime exports keep 4K color and 2K lossless surface maps. The source BLEND
# retains full 4K PNG maps, avoiding an unnecessarily huge GLB duplication.
swaps=[];runtime_images=[]
for mat in MATS.values():
    for node in mat.node_tree.nodes:
        if node.type!='TEX_IMAGE' or node.image is None:continue
        old=node.image;fn=Path(old.filepath).name
        if '_BaseColor_4K.png' in fn:rt=fn.replace('.png','.jpg')
        elif '_NormalGL_4K.png' in fn:rt=fn.replace('_4K','_2K')
        elif '_Roughness_4K.png' in fn:rt=fn.replace('_4K','_2K')
        else:continue
        im=bpy.data.images.load(str(TEX/'runtime'/rt),check_existing=True)
        if 'BaseColor' not in fn:im.colorspace_settings.name='Non-Color'
        swaps.append((node,old));node.image=im;runtime_images.append(im)
export_glb('CentralTower_Exterior.glb',True)
export_glb('CentralTower_Cutaway.glb',False)
for node,im in swaps:node.image=im
for im in set(runtime_images):
    if im.users==0:bpy.data.images.remove(im)

def area(name,loc,energy,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;d.color=color
    ob=bpy.data.objects.new(name,d);sc.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector((0,0,16))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Large soft key',(-12,-19,29),5500,15,(1,.86,.69))
area('Cool fill',(14,-10,18),3600,13,(.69,.81,1))
area('Rim',(5,10,28),5000,10,(1,.93,.8))
data=bpy.data.cameras.new('Model preview camera');cam=bpy.data.objects.new('Model preview camera',data);sc.collection.objects.link(cam);sc.camera=cam;data.type='ORTHO'
def camera(loc,target,ortho):
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=ortho
camera((40,-70,37),(0,0,15.5),35.8)
sc.render.resolution_x=1200;sc.render.resolution_y=1800;sc.render.resolution_percentage=100
set_facade(True)
# Pack exported source textures too: source blend is portable.
for im in bpy.data.images:
    if im.source=='FILE' and not im.packed_file:
        try:im.pack()
        except Exception:pass
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))

def render(name,show,loc,target,ortho,w=1200,h=1800):
    set_facade(show);camera(loc,target,ortho)
    sc.render.resolution_x=w;sc.render.resolution_y=h
    sc.render.filepath=str(OUT/'previews'/name)
    bpy.ops.render.render(write_still=True)
    print('RENDER_READY',name,flush=True)
render('exterior_three_quarter.png',True,(40,-70,37),(0,0,15.6),35.8)
render('cutaway_front.png',False,(0,-80,16.0),(0,0,16.0),34.8)
render('exterior_front.png',True,(0,-80,16.0),(0,0,16.0),34.8)
render('cutaway_three_quarter.png',False,(32,-80,33),(0,0,15.7),35.4)
render('detail_roof_and_joinery.png',True,(12,-23,24),(0,-.5,21.4),12.5,1600,1200)
render('detail_open_basin.png',False,(13,-22,13),(0,0,2.0),12.0,1600,1200)
set_facade(True);camera((40,-70,37),(0,0,15.6),35.8)
sc.render.resolution_x=1200;sc.render.resolution_y=1800
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))

# Verify true mesh bounds, absent bottom, number of triangles, UVs and material maps.
def stat(obs):
    pts=[ob.matrix_world@v.co for ob in obs for v in ob.data.vertices]
    lo=[min(p[i] for p in pts) for i in range(3)];hi=[max(p[i] for p in pts) for i in range(3)]
    tri=0
    for ob in obs:ob.data.calc_loop_triangles();tri+=len(ob.data.loop_triangles)
    return {'mesh_objects':len(obs),'triangles':tri,'dimensions':[hi[i]-lo[i] for i in range(3)],'bounds_min':lo,'bounds_max':hi,'all_have_uv':all(bool(ob.data.uv_layers) for ob in obs)}
full=stat(objects);cut=stat([o for o in objects if o.name not in COLS[F][0].objects])
from mathutils.bvhtree import BVHTree
basin=[o for o in objects if o.name in COLS[A][0].objects]
blocked=[]
for x in [-2,0,2]:
    for y in [-1,0,1]:
        for ob in basin:
            hit=BVHTree.FromObject(ob,bpy.context.evaluated_depsgraph_get()).ray_cast(Vector((x,y,-1)),Vector((0,0,1)),2.0)
            if hit[0] is not None:blocked.append([x,y,ob.name])
report={'pixels_per_unit':PPU,'target_gameplay_px':{'height':4100,'maximum_width':1200},'proposed_depth_px':DEPTH*PPU,'exterior':full,'cutaway':cut,'open_basin_probe_blockers':blocked,'texture_sizes':{im.name:list(im.size) for im in bpy.data.images if '_4K' in im.name},'source_reference':'central-tower-cutaway-and-exterior-v3.png','notes':['Geometry is newly authored; no game scene or production asset changed.','Both GLBs embed PBR texture images.','Facade is an independent collection/mesh assembly.','No collisions or runtime cutaway script added.']}
report['checks_passed']=abs(full['dimensions'][2]-TARGET_H)<.06 and abs(full['dimensions'][0]-TARGET_W)<.06 and full['all_have_uv'] and not blocked and cut['triangles']<full['triangles']
(OUT/'verification.json').write_text(json.dumps(report,indent=2))
print('BUILD_COMPLETE',json.dumps(report),flush=True)
