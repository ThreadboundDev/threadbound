"""Author the approved lakeside buildings with the tower's unchanged materials.

Run with Blender 5.2 in background mode. Models are new deliverables only;
no production scene is read or modified. All dimensions are Blender units at
128 gameplay pixels/unit. House sizes are proposed working proportions.
"""
import bpy, bmesh, math, random, json, hashlib, tempfile, os, sys, shutil
from pathlib import Path
from mathutils import Vector

ROOT = next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT = ROOT/'outputs/lakeside-buildings-v1'
SOURCE = ROOT/'outputs/central-tower-model-v3/CentralTower_Editable.blend'
for p in [OUT, OUT/'models', OUT/'previews', OUT/'source', OUT/'references', OUT/'source/build-temp']:
    p.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(OUT/'source/build-temp')
os.environ['TEMP'] = tempfile.tempdir
os.environ['TMP'] = tempfile.tempdir
sys.path.insert(0, str(Path(__file__).parent))
import mesh_helpers as H
random.seed(28)
PPU = 128

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
with bpy.data.libraries.load(str(SOURCE), link=False) as (src, dst):
    dst.materials = [n for n in src.materials if n in ['walnut','plaster','blue_tiles','slate','rope','iron','recess']]
M = {m.name:m for m in bpy.data.materials}
assert len(M) == 7, list(M)
H.MATS = M

def material_signature():
    sig = {}
    for key, mat in M.items():
        maps = []
        for n in mat.node_tree.nodes if mat.use_nodes else []:
            if n.type == 'TEX_IMAGE' and n.image:
                im = n.image
                if not im.packed_file: im.pack()
                maps.append({'image':im.name, 'size':list(im.size), 'sha256':hashlib.sha256(im.packed_file.data).hexdigest()})
        sig[key] = maps
    return sig
MATERIAL_SOURCE_SIGNATURE = material_signature()

ASSETS = {}
def asset(key, title):
    scene = bpy.data.scenes.new(title)
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0
    col = bpy.data.collections.new(key+'_MODEL')
    scene.collection.children.link(col)
    root = bpy.data.objects.new(key+'_ROOT', None)
    col.objects.link(root)
    root.empty_display_type = 'PLAIN_AXES'
    root['pixels_per_unit'] = PPU
    root['front_direction'] = '-Y; vertical +Z; across the gameplay view +X'
    root['material_source'] = str(SOURCE.relative_to(ROOT))
    root['proportions'] = 'Proposed from approved village concepts; placement remains engine-side'
    data = {'key':key, 'scene':scene, 'collection':col, 'root':root, 'groups':{}}
    ASSETS[key] = data
    return data

def group(a, label, removable=False, roof=False):
    name = a['key']+'__'+label
    col = bpy.data.collections.new(name)
    a['collection'].children.link(col)
    parent = bpy.data.objects.new(name, None)
    col.objects.link(parent)
    parent.parent = a['root']
    parent['cutaway_removable'] = removable
    parent['role'] = label
    H.COLS[name] = (col, parent)
    a['groups'][label] = name
    if removable: a['facade_group'] = name
    if roof: a['roof_group'] = name
    return name

box, beam, tube, face = H.box, H.beam, H.tube, H.face

def wrap(g, x, y, z, sx=.23, sy=.23, turns=4):
    for turn in range(turns):
        pts=[]
        for k in range(33):
            a=k*math.tau/32
            pts.append((x+sx*math.copysign(abs(math.cos(a))**.42,math.cos(a)),
                        y+sy*math.copysign(abs(math.sin(a))**.42,math.sin(a)),
                        z+turn*.062+.018*math.sin(a)))
        tube(g,'rope',pts,.023,6)

def crate(g, x,y,z,w=.72):
    # z is the bottom, not center. Individual boards, corner straps and diagonal.
    for k in range(5):
        xx=x+(k-2)*w/5
        box(g,'walnut',(xx,y,z+w*.5),(w/5-.018,w-.03,w-.04))
    for yy in [y-w/2-.014,y+w/2+.014]:
        for zz in [z+.08,z+w-.08]: box(g,'walnut',(x,yy,zz),(w+.04,.07,.13))
        beam(g,'walnut',(x-w*.38,yy-.015,z+.16),(x+w*.38,yy-.015,z+w-.16),.09,.065)
    for xx in [x-w/2,x+w/2]:
        for yy in [y-w/2,y+w/2]: box(g,'iron',(xx,yy,z+w*.5),(.035,.035,w+.02))

def barrel(g,x,y,z,r=.3,h=.7):
    # Stave barrel, slightly bowed. Discrete staves preserve the silhouette.
    n=14
    for j in range(n):
        a0=math.tau*(j+.025)/n; a1=math.tau*(j+.975)/n
        for k in range(4):
            t0=k/4;t1=(k+1)/4
            def p(a,t):
                rr=r*(.88+.12*math.sin(math.pi*t))
                return(x+rr*math.cos(a),y+rr*math.sin(a),z+h*t)
            face(g,'walnut',[p(a0,t0),p(a1,t0),p(a1,t1),p(a0,t1)],[(j*.11,t0*h),(j*.11+.1,t0*h),(j*.11+.1,t1*h),(j*.11,t1*h)])
    for t in [.13,.84]:
        rr=r*(.88+.12*math.sin(math.pi*t))+.014
        tube(g,'iron',[(x+rr*math.cos(k*math.tau/40),y+rr*math.sin(k*math.tau/40),z+h*t) for k in range(41)],.025,6)
    # Wooden lid, avoids the appearance of a hollow cylinder.
    pts=[(x+r*.88*math.cos(k*math.tau/n),y+r*.88*math.sin(k*math.tau/n),z+h) for k in range(n)]
    face(g,'walnut',pts)
    for dx in [-.12,0,.12]:beam(g,'walnut',(x+dx,y-r*.73,z+h+.01),(x+dx,y+r*.73,z+h+.01),.025,.02)

def rope_coil(g,x,y,z,r=.24,turns=3):
    pts=[]
    for k in range(turns*45+1):
        t=k/(turns*45);a=t*turns*math.tau
        rr=r*(.55+.45*t)
        pts.append((x+rr*math.cos(a),y+rr*math.sin(a),z+.012*t))
    tube(g,'rope',pts,.027,6)

def net(g,x,y,zt,w=1.9,sag=.95,rows=6,cols=10):
    # Short hanging net whose bottom sags between two high anchors.
    def p(u,v):
        zz=zt-v*(.12+sag*math.sin(math.pi*u)**.7)
        yy=y-.09*math.sin(math.pi*u)*math.sin(math.pi*v)
        return(x+(u-.5)*w,yy,zz)
    tube(g,'rope',[p(k/40,0) for k in range(41)],.024,6)
    tube(g,'rope',[p(k/40,1) for k in range(41)],.024,6)
    for j in range(cols+1):tube(g,'rope',[p(j/cols,k/12) for k in range(13)],.012,5)
    # Diagonals make actual diamond netting rather than a cloth card.
    for sign in [-1,1]:
        for start in range(-rows,cols+1):
            pts=[]
            for k in range(rows*4+1):
                v=k/(rows*4);u=(start+sign*v*rows*.7)/cols
                if 0<=u<=1:pts.append(p(u,v))
            if len(pts)>1:tube(g,'rope',pts,.011,5)

def bench(g,x,y,z,w=1.5):
    for i in range(4):box(g,'walnut',(x,y+(i-1.5)*.14,z+.78),(w,.132,.095))
    for xx in [x-w*.38,x+w*.38]:
        for yy in [y-.21,y+.21]:box(g,'walnut',(xx,yy,z+.38),(.12,.12,.76))
    beam(g,'walnut',(x-w*.38,y,z+.27),(x+w*.38,y,z+.27),.11)

def roof(a,g,w,d,eave,rise,cut_limit=None):
    """Continuous hip: surfaces share miter lines; no crossing roof strips.

    The fixed side pieces own all four corners. The center, including the
    inward roof, hides with the facade. Split after triangulation for conserved
    exterior geometry and exact UV interpolation at the cut.
    """
    A=w/2;B=d/2;r=max(.25,(w-d)/2)
    def point(which,u,t):
        along=r+(A-r)*t
        z=eave+rise*(1-t)**1.14+.095*t**8+.21*abs(u)**8*t**4
        # Shallow formed tile channels. Corrugation vanishes at shared hips.
        span=2*(along if which in ['front','back'] else B*t)
        z+=.023*math.cos((u+1)*span/.21*math.pi)*(1-abs(u)**8)*math.sin(math.pi*t/2)
        if which=='front':return(u*along,-B*t,z)
        if which=='back':return(-u*along,B*t,z)
        if which=='right':return(along,u*B*t,z)
        return(-along,-u*B*t,z)
    nu=max(32,round(w/.10));nv=16
    for which in ['front','back','left','right']:
        for j in range(nu):
            for k in range(nv):
                uv=[(-1+2*j/nu,k/nv),(-1+2*(j+1)/nu,k/nv),(-1+2*(j+1)/nu,(k+1)/nv),(-1+2*j/nu,(k+1)/nv)]
                pts=[point(which,u,t) for u,t in uv]
                coords=[];clean=[]
                for p,(u,t) in zip(pts,uv):
                    if clean and (Vector(p)-Vector(clean[-1])).length<1e-7:continue
                    clean.append(p)
                    along=p[0] if which in ['front','back'] else p[1]
                    coords.append((along/2,t*math.sqrt(B*B+rise*rise)/2))
                if len(clean)>2 and (Vector(clean[0])-Vector(clean[-1])).length<1e-7:clean.pop();coords.pop()
                if len(clean)<3:continue
                n=(Vector(clean[1])-Vector(clean[0])).cross(Vector(clean[-1])-Vector(clean[0]))
                if n.z<0:clean.reverse();coords.reverse()
                face(g,'blue_tiles',clean,coords)
    # Four diagonal hip caps cover only the shared seams, once per corner.
    for which in ['front','back']:
        for u in [-1,1]:
            pts=[tuple(Vector(point(which,u,k/24))+Vector((0,0,.045))) for k in range(25)]
            tube(g,'blue_tiles',pts,.065,8)
    tube(g,'blue_tiles',[(-r,0,eave+rise+.04),(r,0,eave+rise+.04)],.105,10)
    for sign in [-1,1]:
        tube(g,'blue_tiles',[(sign*r,0,eave+rise+.04),(sign*(r+.10),0,eave+rise+.11),(sign*(r+.17),0,eave+rise+.26)],.085,8)
    # Rounded tile ends at the front/back eaves, and subtly upturned tips.
    for which in ['front','back']:
        count=round(w/.22)
        for j in range(count):
            u=-1+2*(j+.5)/count
            tube(g,'blue_tiles',[tuple(Vector(point(which,u,t))+Vector((0,0,.023))) for t in [.90,.95,1]],.038,6)
    # Curved wooden rafters follow the underside, visible beneath the shelter.
    for which in ['front','back']:
        for u in [-.84,-.56,-.28,0,.28,.56,.84]:
            pts=[Vector(point(which,u,k/8))-Vector((0,0,.16)) for k in range(9)]
            for p0,p1 in zip(pts,pts[1:]):beam(g,'walnut',p0,p1,.11,.14)
    # One continuous swept fascia, mitered at each corner rather than overlapped.
    outline=[]
    for which in ['front','right','back','left']:
        for j in range(33):
            p=Vector(point(which,-1+2*j/32,1));p.z-=.135
            if outline and (p-outline[-1]).length<1e-6:continue
            outline.append(p)
    if (outline[-1]-outline[0]).length<1e-6:outline.pop()
    rings=[]
    for i,p in enumerate(outline):
        tangent=outline[(i+1)%len(outline)]-outline[(i-1)%len(outline)]
        normal=Vector((tangent.y,-tangent.x,0)).normalized()
        rings.append([tuple(p+normal*s*.07+Vector((0,0,t*.09))) for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]])
    for i in range(len(rings)):
        for k in range(4):face(g,'walnut',[rings[i][k],rings[(i+1)%len(rings)][k],rings[(i+1)%len(rings)][(k+1)%4],rings[i][(k+1)%4]])
    a['roof_spec']={'width':w,'depth':d,'eave_height':eave,'rise':rise,'inner_wall_cut_limit':cut_limit}

def planks(g,x0,x1,y0,y1,z,thickness=.12):
    n=max(1,round((x1-x0)/.28));s=(x1-x0)/n
    for k in range(n):box(g,'walnut',(x0+(k+.5)*s,(y0+y1)/2,z),(s-.015,y1-y0,thickness))

def house(key,title,w,d,base,wallh,rise):
    a=asset(key,title)
    S=group(a,'01_Structure');F=group(a,'02_Facade_Removable',True)
    R=group(a,'03_Roof_Sides_Fixed',roof=True)
    I=group(a,'04_Interior');D=group(a,'05_Exterior_Details')
    t=.20;wx=w/2;dy=d/2;top=base+wallh
    # Low masonry perimeter, with floor planks instead of a monolithic rock block.
    for s in [-1,1]:
        H.stone_run(S,s*wx-.23,s*wx+.23,-dy-.12,dy+.12,.015,base-.07,along='y',course=.30)
    for yy in [-dy,dy]:H.stone_run(S,-wx+.23,wx-.23,yy-.18,yy+.18,.015,base-.07,course=.30)
    planks(I,-wx+.06,wx-.06,-dy+.08,dy-.08,base-.05,.13)
    # Actual side and back plaster surfaces, open front in the cutaway.
    for s in [-1,1]:
        box(S,'plaster',(s*(wx-t/2),0,(base+top)/2),(t,d-t,wallh))
        for yy in [-dy+.09,0,dy-.09]:
            box(S,'walnut',(s*(wx-.03),yy,(base+top)/2),(.23,.22,wallh+.06))
        for zz in [base+.14,top-.17,base+wallh*.55]:
            box(S,'walnut',(s*(wx+.02),0,zz),(.20,d+.12,.18))
    box(S,'plaster',(0,dy-t/2,(base+top)/2),(w-.35,t,wallh))
    for xx in [-wx+.1,0,wx-.1]:box(S,'walnut',(xx,dy-.03,(base+top)/2),(.20,.23,wallh+.04))
    for zz in [base+.14,top-.16]:box(S,'walnut',(0,dy+.02,zz),(w,.21,.19))
    back_window_z=top-.86 if w<=5 else base+wallh*.62
    H.window(S,0,dy+.16,back_window_z,min(1.5,w*.37),1.15)
    for s in [-1,1]:H.window(S,0,s*(wx+.13),base+wallh*.61,1.1,1.1,side=True)
    # Matching interior faces and timber trim: cutaways are finished rooms.
    for xx in [-wx+.17,wx-.17]:
        box(I,'walnut',(xx,dy-t-.035,(base+top)/2),(.16,.10,wallh))
    for zz in [base+.12,top-.14]:
        box(I,'walnut',(0,dy-t-.035,zz),(w-.30,.11,.16))
    H.window(I,0,dy-t-.13,back_window_z,min(1.5,w*.37),1.15)
    for s in [-1,1]:
        for yy2 in [-dy+.13,dy-.13]:
            box(I,'walnut',(s*(wx-t-.025),yy2,(base+top)/2),(.10,.16,wallh))
        for zz in [base+.12,top-.14]:
            box(I,'walnut',(s*(wx-t-.025),0,zz),(.11,d-.25,.16))
        H.window(I,0,s*(wx-t-.13),base+wallh*.61,1.1,1.1,side=True)
    # Front wall, door and lattice windows are one removable collection.
    doorx=-w*.23 if w>5 else 0
    doorw=1.15 if w>5 else 1.24;doorh=2.14
    l=doorx-doorw/2;r=doorx+doorw/2
    yy=-dy+.09
    for lo,hi in [(-wx+.16,l),(r,wx-.16)]:
        if hi>lo:box(F,'plaster',((lo+hi)/2,yy,(base+top)/2),(hi-lo,t,wallh-.03))
    if top>base+doorh:box(F,'plaster',(doorx,yy,(base+doorh+top)/2),(doorw,t,top-base-doorh))
    for xx in [-wx+.08,l-.06,r+.06,wx-.08]:box(F,'walnut',(xx,-dy-.04,(base+top)/2),(.20,.24,wallh+.12))
    for zz in [base+.12,top-.15]:box(F,'walnut',(0,-dy-.08,zz),(w+.12,.24,.19))
    box(F,'recess',(doorx,-dy-.04,base+doorh*.5),(doorw,.11,doorh))
    for k in range(8):box(F,'walnut',(l+(k+.5)*doorw/8,-dy-.16,base+doorh*.5),(doorw/8-.021,.10,doorh-.04))
    for zz in [base+.3,base+doorh-.24]:box(F,'walnut',(doorx,-dy-.24,zz),(doorw+.07,.09,.11))
    H.peg(F,doorx+doorw*.30,-dy-.31,base+1.03)
    box(F,'walnut',(doorx,-dy-.19,base+doorh+.03),(doorw+.34,.28,.17))
    if w>5:
        H.window(F,w*.23,-dy-.18,base+wallh*.60,1.65,1.13)
        net(F,w*.23,-dy-.38,base+1.25,1.7,.72,5,9)
        bench(D,-w*.25,-dy-.61,base-.03,1.65)
        rope_coil(D,-w*.28,-dy-.57,base+.81,.17)
        barrel(D,wx-.37,-dy-.55,base-.1,.27,.68)
        # Interior net repair bench and low shelf; room remains traversable.
        bench(I,-wx+.96,dy-.55,base+.02,1.4)
        rope_coil(I,-wx+.82,dy-.55,base+.83,.20)
        for zz in [base+1.25,base+1.95]:box(I,'walnut',(wx-.72,dy-.28,zz),(1.10,.38,.10))
        crate(I,wx-.62,dy-.6,base+.02,.61)
    else:
        H.window(F,0,-dy-.22,top-.88,1.36,.94)
        box(F,'walnut',(0,-dy-.30,base+2.51),(w+.12,.24,.20))
        for xx in [-wx+.38,wx-.38]:
            box(F,'walnut',(xx,-dy-.20,base+2.48),(.40,.26,.18))
            H.peg(F,xx,-dy-.37,base+2.48)
        # Sparse useful interior: raised sleeping/storage loft at rear only.
        planks(I,-wx+.23,wx-.23,dy-1.20,dy-.20,base+2.43,.10)
        box(I,'walnut',(0,dy-1.18,base+2.35),(w-.35,.18,.18))
        for xx in [-.42,.42]:beam(I,'walnut',(xx,dy-1.2,base+.05),(xx,dy-1.2,base+2.40),.10)
        for z in [base+.3+i*.28 for i in range(8)]:beam(I,'walnut',(-.42,dy-1.22,z),(.42,dy-1.22,z),.075)
        bench(I,-wx+.77,dy-.58,base+.03,1.05)
        crate(I,wx-.62,dy-.60,base+.02,.60)
        barrel(D,wx-.34,-dy-.53,base-.10,.26,.67)
        rope_coil(D,-wx+.38,-dy-.40,base+.02,.24)
    # Porch and step run with open sides; separate from the external facade.
    planks(S,-wx-.15,wx+.15,-dy-.88,-dy+.08,base-.10,.12)
    box(S,'walnut',(0,-dy-.84,base-.22),(w+.50,.18,.23))
    for xx in [-wx-.03,wx+.03]:box(S,'walnut',(xx,-dy-.56,base*.42),(.22,.24,base*.80))
    for k in range(2):box(S,'slate',(doorx,-dy-.99-k*.25,.09+(1-k)*.12),(doorw+.37,.33,.18+(1-k)*.24))
    # Eave brackets sit outside side wall inner faces, staying clear in cutaways.
    for s in [-1,1]:
        xx=s*(wx+.05)
        for y in [-dy+.15,0,dy-.15]:
            beam(S,'walnut',(xx,y,top-.65),(s*(wx+.53),y,top-.04),.12)
            box(S,'walnut',(s*(wx+.23),y,top-.05),(.77,.16,.15))
        for yy2 in [-dy+.05,dy-.05]:wrap(D,s*(wx+.01),yy2,base+.29,.16,.16,3)
    # Short facade-owned rafters over front/back, no fixed center beam overhead.
    for yy2 in [-dy,dy]:
        box(F,'walnut',(0,yy2,top+.03),(w+.28,.20,.18))
        for xx in [-w*.28,0,w*.28]:
            beam(F,'walnut',(xx,yy2,top-.32),(xx,yy2+math.copysign(.50,yy2),top+.05),.12)
    limit=wx-t+.035
    roof(a,R,w+1.28,d+1.18,top+.08,rise,limit)
    a['wall_inner_abs_x']=wx-t
    a['floor_top']=base+.015
    a['design']='B: '+('wide single-story net workshop' if w>5 else 'compact raised fisher house')
    return a

slip=asset('CoveredBoatSlip','01 · Covered boat slip')
S=group(slip,'01_Timber_Structure');R=group(slip,'02_Continuous_Blue_Roof',roof=True)
D=group(slip,'03_Ropes_Net_Props');P=group(slip,'04_Stone_Feet_Side_Decks')
for x in [-2.78,2.78]:
    for y in [-1.54,1.54]:
        H.stone_run(P,x-.41,x+.41,y-.42,y+.42,.015,.74,course=.36)
        box(S,'walnut',(x,y,3.38),(.45,.45,5.63))
        box(S,'walnut',(x,y,.91),(.55,.55,.20))
        box(S,'walnut',(x,y,5.59),(.71,.64,.23))
        for z in [1.16,4.56,5.75]:wrap(D,x,y,z,.25,.25,4)
        # Braces to the crossbeam and depth beam, kept near the upper corners.
        sign=1 if x<0 else -1
        beam(S,'walnut',(x,y,4.76),(x+sign*.87,y,5.70),.19)
        signy=1 if y<0 else -1
        beam(S,'walnut',(x,y,4.91),(x,y+signy*.67,5.73),.17)
        for z in [1.01,5.56]:
            box(S,'walnut',(x,y-.27,z),(.71,.10,.15))
            for dx in [-.22,.22]:H.peg(S,x+dx,y-.35,z)
for y in [-1.54,1.54]:
    box(S,'walnut',(0,y,5.83),(6.57,.37,.36))
    box(S,'walnut',(0,y,6.06),(6.83,.23,.17))
for x in [-2.78,2.78]:box(S,'walnut',(x,0,5.87),(.32,3.76,.31))
# Narrow side deck fingers; the center remains entirely open at the bottom.
for x in [-2.85,2.85]:
    planks(P,x-.46,x+.46,-1.90,1.90,.66,.14)
    for yy in [-1.75,1.75]:box(S,'walnut',(x,yy,.43),(.99,.20,.23))
net(D,0,-1.76,5.67,3.35,.83,6,13)
for x in [-2.77,2.77]:
    tube(D,'rope',[(x,-1.84,5.66),(x,-1.84,5.12),(x+.04,-1.85,4.93)],.025,6)
    rope_coil(D,x,1.10,.76,.27,4)
crate(D,2.88,.15,.74,.59)
barrel(D,-2.88,.28,.74,.25,.63)
roof(slip,R,7.94,4.94,6.13,1.20)
slip['design']='C: open covered boat gantry with four posts and narrow side deck fingers'
slip['open_center_width']=5.56-.92

house('NetWorkshop','02 · Net workshop',6.4,4.0,.48,2.90,1.22)
house('FishersHouse','03 · Fisher house',4.4,3.9,.62,4.15,1.38)

objects=[bb.build() for bb in H.B.values()]
print('AUTHORED',len(objects),'batch meshes',flush=True)

# Use the actual smooth/tiled roof surface for splitting, without crossing strips.
def area(ob):
    ob.data.calc_loop_triangles()
    return sum((ob.data.vertices[t.vertices[1]].co-ob.data.vertices[t.vertices[0]].co).cross(ob.data.vertices[t.vertices[2]].co-ob.data.vertices[t.vertices[0]].co).length*.5 for t in ob.data.loop_triangles)

roof_checks=[]
def keep_x(ob,x,sign,outer):
    bm=bmesh.new();bm.from_mesh(ob.data)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(x,0,0),plane_no=(sign,0,0),use_snap_center=True,clear_inner=outer,clear_outer=not outer)
    loose=[v for v in bm.verts if not v.link_faces]
    if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
    bm.to_mesh(ob.data);bm.free();ob.data.update()

for a in ASSETS.values():
    rg=a['roof_group'];rc,rp=H.COLS[rg]
    for ob in list(rc.objects):
        if ob is None or ob.type!='MESH':continue
        # Edge fascia already has a continuous sweep. Applied bevel remains modest.
        bpy.context.window.scene=a['scene']
        bpy.context.view_layer.objects.active=ob;ob.select_set(True)
        for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        ob.select_set(False)
        bm=bmesh.new();bm.from_mesh(ob.data)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-8)
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(ob.data);bm.free();ob.data.update()
        ob['roof_continuous_mitered_hips']=True
        if 'facade_group' not in a:continue
        limit=a['roof_spec']['inner_wall_cut_limit'];original=area(ob)
        source_mesh=ob.data.copy()
        fc,fp=H.COLS[a['facade_group']]
        # Three disjoint regions: left fixed, center removable, right fixed.
        center=ob.copy();center.data=source_mesh.copy();center.name=ob.name+'_Center_HideWithFacade'
        fc.objects.link(center);center.parent=fp;center['cutaway_removable']=True
        keep_x(center,-limit,-1,False);keep_x(center,limit,1,False)
        right=ob.copy();right.data=source_mesh.copy();right.name=ob.name+'_Right_Corners'
        rc.objects.link(right);right.parent=rp;keep_x(right,limit,1,True)
        ob.name=ob.name+'_Left_Corners';keep_x(ob,-limit,-1,True)
        delta=abs(area(ob)+area(right)+area(center)-original)
        assert delta<1e-3,(ob.name,delta)
        for piece,sign in [(ob,-1),(right,1)]:
            assert min(sign*v.co.x for v in piece.data.vertices)>=limit-1e-5
            piece['fixed_roof_min_abs_x']=limit
        roof_checks.append({'asset':a['key'],'material':ob.data.materials[0].name,'fixed_minimum_abs_x':limit,'inner_wall_abs_x':a['wall_inner_abs_x'],'exterior_surface_area_error':delta})
        bpy.data.meshes.remove(source_mesh)

# Apply wood/stone edge modifiers, retain editable meshes and group boundaries.
for a in ASSETS.values():
    bpy.context.window.scene=a['scene']
    for ob in a['collection'].all_objects:
        if ob is None or ob.type!='MESH':continue
        bpy.context.view_layer.objects.active=ob;ob.select_set(True)
        for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        ob.select_set(False)
        bm=bmesh.new();bm.from_mesh(ob.data)
        bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4])
        bm.to_mesh(ob.data);bm.free();ob.data.update()
        ob['pixels_per_unit']=PPU

def meshlist(a,full=True):
    hidden=set()
    if not full and 'facade_group' in a:
        hidden={o.name for o in H.COLS[a['facade_group']][0].all_objects if o is not None}
    return [o for o in a['collection'].all_objects if o is not None and o.type=='MESH' and o.name not in hidden]

def stats(obs):
    points=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    lo=[min(v[i] for v in points) for i in range(3)];hi=[max(v[i] for v in points) for i in range(3)]
    tris=0
    for ob in obs:ob.data.calc_loop_triangles();tris+=len(ob.data.loop_triangles)
    return {'triangles':tris,'mesh_objects':len(obs),'dimensions_blender_units':[hi[i]-lo[i] for i in range(3)],'dimensions_gameplay_px':[round((hi[i]-lo[i])*PPU,2) for i in range(3)],'bounds_min':lo,'bounds_max':hi,'all_meshes_have_uv':all(bool(o.data.uv_layers) for o in obs)}

# Put every root at the horizontal center and the lowest solid foot at Z=0.
for a in ASSETS.values():
    obs=meshlist(a);low=min(v.co.z for ob in obs for v in ob.data.vertices)
    for ob in obs:
        for v in ob.data.vertices:v.co.z-=low

manifest={'pixels_per_unit':PPU,'material_source':str(SOURCE.relative_to(ROOT)),'material_signatures':MATERIAL_SOURCE_SIGNATURE,'assets':{},'roof_clearance_checks':roof_checks}
for a in ASSETS.values():
    st=stats(meshlist(a));cut=stats(meshlist(a,False))
    a['root']['dimensions_blender_units']=st['dimensions_blender_units']
    a['root']['dimensions_gameplay_px']=st['dimensions_gameplay_px']
    a['root']['design_reference']=a['design']
    manifest['assets'][a['key']]={'design':a['design'],'exterior':st,'cutaway':cut if 'facade_group' in a else None,'roof':a['roof_spec']}
    print('MODEL_STATS',a['key'],json.dumps(st),flush=True)

# GLBs embed the tower's same-color runtime maps; source file retains its 4K PNGs.
swaps=[];runtime_images=[]
runtime_dir=ROOT/'outputs/central-tower-model-v1/textures/runtime'
for key,mat in M.items():
    for n in mat.node_tree.nodes if mat.use_nodes else []:
        if n.type!='TEX_IMAGE' or n.image is None:continue
        old=n.image;name=old.name
        if 'BaseColor' in name:fn=key+'_BaseColor_4K.jpg'
        elif 'NormalGL' in name:fn=key+'_NormalGL_2K.png'
        elif 'Roughness' in name:fn=key+'_Roughness_2K.png'
        else:continue
        im=bpy.data.images.load(str(runtime_dir/fn),check_existing=True)
        if 'BaseColor' not in name:im.colorspace_settings.name='Non-Color'
        swaps.append((n,old));n.image=im;runtime_images.append(im)

for a in ASSETS.values():
    bpy.context.window.scene=a['scene']
    versions=[('CoveredBoatSlip.glb',True)] if a['key']=='CoveredBoatSlip' else [(a['key']+'_Exterior.glb',True),(a['key']+'_Cutaway.glb',False)]
    for filename,full in versions:
        bpy.ops.object.select_all(action='DESELECT')
        allowed={o.name for o in meshlist(a,full)}
        hidden=set()
        if not full:hidden={o.name for o in H.COLS[a['facade_group']][0].all_objects if o is not None}
        for ob in a['collection'].all_objects:
            if ob is None or ob.name in hidden:continue
            if ob.type!='MESH' or ob.name in allowed:ob.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(OUT/'models'/filename),export_format='GLB',use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_tangents=True,export_materials='EXPORT',export_image_format='AUTO',export_extras=True,export_cameras=False,export_lights=False)
        print('EXPORT_READY',filename,flush=True)
        bpy.ops.object.select_all(action='DESELECT')
for n,old in swaps:n.image=old
for im in set(runtime_images):
    if im.users==0:bpy.data.images.remove(im)
assert material_signature()==MATERIAL_SOURCE_SIGNATURE

# Lighting shared between single-asset scenes; cameras never export with models.
def configure(sc):
    sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True
    sc.render.resolution_x=1400;sc.render.resolution_y=1100;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA';sc.render.film_transparent=True
    sc.view_settings.view_transform='AgX'
    world=bpy.data.worlds.new(sc.name+'_World');sc.world=world;world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.32,.39,.50,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.38
    sc.render.threads_mode='FIXED';sc.render.threads=8
    try:
        prefs=bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type='OPTIX';prefs.get_devices();found=False
        for dev in prefs.devices:dev.use=dev.type!='CPU';found|=dev.use
        if found:sc.cycles.device='GPU'
    except Exception as ex:print('CPU_RENDER',str(ex),flush=True)

def light(sc,name,loc,target,energy,size,color):
    data=bpy.data.lights.new(sc.name+'_'+name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;data.color=color
    ob=bpy.data.objects.new(data.name,data);sc.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()

def setup_camera(sc,loc,target,scale):
    if not sc.camera:
        data=bpy.data.cameras.new(sc.name+'_Camera');ob=bpy.data.objects.new(data.name,data);sc.collection.objects.link(ob);sc.camera=ob
    cam=sc.camera;cam.data.type='ORTHO';cam.data.ortho_scale=scale;cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()

for a in ASSETS.values():
    sc=a['scene'];configure(sc)
    h=manifest['assets'][a['key']]['exterior']['dimensions_blender_units'][2]
    target=(0,0,h*.47)
    light(sc,'Warm key',(-6,-9,12),target,1250,7,(1,.88,.73))
    light(sc,'Cool fill',(5,-9,6),target,420,9,(.73,.84,1))
    light(sc,'Rim',(3,6,12),target,950,6,(1,.93,.80))
    setup_camera(sc,(11,-20,12),(0,0,h*.46),max(9,h*1.3))

overview=bpy.data.scenes.new('00 · All three assets')
configure(overview);overview.render.resolution_x=2200;overview.render.resolution_y=1000
for key,x in [('CoveredBoatSlip',-9),('NetWorkshop',0),('FishersHouse',8)]:
    a=ASSETS[key];ob=bpy.data.objects.new(key+'_PreviewInstance',None);overview.collection.objects.link(ob);ob.instance_type='COLLECTION';ob.instance_collection=a['collection'];ob.location=(x,0,0)
light(overview,'Key',(-9,-14,17),(0,0,3),3400,12,(1,.88,.74))
light(overview,'Fill',(12,-12,9),(0,0,3),1450,14,(.72,.84,1))
light(overview,'Rim',(0,8,14),(0,0,3),2400,10,(1,.93,.83))
setup_camera(overview,(13,-42,23),(-.5,0,3.15),28)

# Remove empty factory scene, set a useful edit view in each asset scene.
for sc in list(bpy.data.scenes):
    if sc.name=='Scene' and len(sc.objects)==0:bpy.data.scenes.remove(sc)
bpy.context.window.scene=overview
for screen in bpy.data.screens:
    for ar in screen.areas:
        if ar.type=='VIEW_3D':
            ar.spaces.active.region_3d.view_distance=30
            ar.spaces.active.region_3d.view_location=Vector((0,0,3))
            ar.spaces.active.clip_end=300
            ar.spaces.active.shading.type='MATERIAL'
for im in bpy.data.images:
    if im.source=='FILE' and im.users and not im.packed_file:im.pack()

manifest['checks_passed']=all(d['exterior']['all_meshes_have_uv'] for d in manifest['assets'].values()) and len(roof_checks)==4 and all(c['fixed_minimum_abs_x']>c['inner_wall_abs_x'] and c['exterior_surface_area_error']<1e-3 for c in roof_checks)
assert manifest['checks_passed']
(OUT/'asset_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'LakesideBuildings_Editable.blend'))
print('LAKESIDE_BUILD_COMPLETE',flush=True)
