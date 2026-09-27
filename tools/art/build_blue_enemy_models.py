"""Build approved A and D2 model studies; does not edit gameplay scenes.
Blender --background --factory-startup --threads 8 --python tools/art/build_blue_enemy_models.py
"""
from pathlib import Path
import math, random, json
import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'ArtSource/BlueBiome/Blender/Enemies'
RUNTIME = ROOT/'Assets/BlueBiome/Enemies/Models'
for path in (SOURCE, RUNTIME): path.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
random.seed(19)
TAU = math.tau

def reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'; scene.cycles.samples = 32; scene.cycles.use_denoising = True
    scene.render.resolution_x = 1200; scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.film_transparent = False
    scene.render.fps = 30; scene.frame_start = 1; scene.frame_end = 60
    scene.view_settings.view_transform = 'AgX'
    scene.world.color = (.12,.15,.19)
    return scene

def material(name, color, seed, metallic=0):
    rng = np.random.default_rng(seed)
    n=512; y,x = np.mgrid[0:n,0:n]/n
    # Broad pigment variation, fine fabric grain, and directional brush marks.
    variation = 1 + .12*np.sin(x*19+y*13+seed)*np.sin(y*23-x*4)
    variation += .018*np.sin(y*310+x*22)+.012*np.sin(x*490)
    variation += rng.normal(0,.019,(n,n))
    edge = np.maximum(np.exp(-x*40),np.exp(-(1-x)*40))
    variation += edge*.10
    pixels=np.ones((n,n,4),np.float32)
    for channel in range(3): pixels[:,:,channel]=np.clip(color[channel]*variation,0,1)
    for i in range(70):
        px,py = rng.integers(8,n-8,2); length=int(rng.integers(2,17))
        pixels[py:py+1,px:min(n,px+length),:3] *= float(rng.uniform(.65,1.5))
    im=bpy.data.images.new(name+'_Paint',width=n,height=n)
    im.pixels.foreach_set(pixels.ravel()); im.filepath_raw=str(SOURCE/(name+'_albedo.png'))
    im.file_format='PNG'; im.save(); im.pack()
    m=bpy.data.materials.new(name); m.use_nodes=True; m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Roughness'].default_value=.78 if not metallic else .46
    p.inputs['Metallic'].default_value=metallic
    tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im
    m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    return m

def palette():
    return {
        'navy':material('Indigo_cloth',(.045,.085,.135),1),
        'blue':material('Worn_slate',(.10,.18,.24),2),
        'teal':material('Deep_teal',(.045,.19,.20),3),
        'ivory':material('Aged_porcelain',(.73,.67,.49),4),
        'rope':material('Flax_binding',(.40,.29,.15),5),
        'wood':material('Weathered_walnut',(.20,.105,.045),6),
        'black':material('Dark_recess',(.014,.024,.029),7),
        'steel':material('Blade_steel',(.30,.40,.43),8,.6),
        'gold':material('Worn_brass',(.51,.34,.13),9,.35),
        'coral':material('Coral_scars',(.42,.13,.08),10),
    }

parts=[]
def finish(ob,name,mat,bone):
    ob.name=name; ob.data.materials.append(mat)
    ob['rig_bone']=bone; parts.append(ob)
    if ob.type=='MESH' and not ob.data.uv_layers:
        uv=ob.data.uv_layers.new(name='PaintUV')
        for face in ob.data.polygons:
            axes=sorted(range(3),key=lambda a:abs(face.normal[a]))[:2]
            for li in face.loop_indices:
                co=ob.data.vertices[ob.data.loops[li].vertex_index].co
                uv.data[li].uv=(co[axes[0]]*.7,co[axes[1]]*.7)
    return ob

def mesh(name,verts,faces,mat,bone,solid=0):
    data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
    ob=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(ob)
    finish(ob,name,mat,bone)
    if solid:
        mod=ob.modifiers.new('Cloth thickness','SOLIDIFY'); mod.thickness=solid
    return ob

def ellipsoid(name,center,size,mat,bone,segments=16,rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=center)
    ob=bpy.context.object; ob.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    finish(ob,name,mat,bone)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def tube(name,points,radii,mat,bone,sides=8):
    verts=[]; faces=[]
    for i,co in enumerate(points):
        tangent=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        tangent.normalize(); u=tangent.cross(Vector((0,0,1)))
        if u.length<.01:u=tangent.cross(Vector((0,1,0)))
        u.normalize(); v=tangent.cross(u).normalized()
        for j in range(sides):
            angle=j*TAU/sides
            verts.append(Vector(co)+radii[i]*(math.cos(angle)*u+math.sin(angle)*v))
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))]
    ob=mesh(name,verts,faces,mat,bone)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def band(name,a,b,radius,mat,bone,turns=6,end_radius=None):
    a=Vector(a); b=Vector(b); axis=(b-a).normalized()
    u=axis.cross(Vector((1,0,0)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized()
    end_radius=radius if end_radius is None else end_radius
    pts=[a.lerp(b,i/(turns*12)) + (radius+(end_radius-radius)*i/(turns*12))*(math.cos(i/12*TAU)*u+math.sin(i/12*TAU)*v) for i in range(turns*12+1)]
    tube(name,pts,[.017]*len(pts),mat,bone,5)

def cloth(name,rows,mat,bone):
    verts=[v for row in rows for v in row];width=len(rows[0]);faces=[]
    for r in range(len(rows)-1):
        for c in range(width-1):
            a=r*width+c;faces.append((a,a+1,a+width+1,a+width))
    return mesh(name,verts,faces,mat,bone,.009)

def ring_body(name,rings,mat,bone,sides=16):
    verts=[];faces=[]
    for z,cx,rx,ry in rings:
        for j in range(sides):
            ang=TAU*j/sides
            fold=1+.06*math.cos(j*5)
            verts.append((cx+rx*math.cos(ang)*fold,ry*math.sin(ang)*fold,z))
    for i in range(len(rings)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    faces+=[tuple(reversed(range(sides))),tuple((len(rings)-1)*sides+j for j in range(sides))]
    ob=mesh(name,verts,faces,mat,bone)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def reedhook(m):
    bones=[('root',(0,0,0),(0,0,.3),None),('pelvis',(-.08,0,1.04),(-.02,0,1.35),'root'),
           ('chest',(-.02,0,1.35),(.09,0,1.78),'pelvis'),('head',(.09,0,1.78),(.28,0,2.20),'chest')]
    ring_body('Coat fitted torso',[(1.15,-.09,.20,.23),(1.36,-.04,.19,.22),(1.67,.01,.24,.31),(1.82,.09,.16,.21)],m['navy'],'chest')
    ellipsoid('Hood dark opening',(.19,0,2.03),(.20,.205,.28),m['black'],'head')
    hood=ring_body('Folded indigo hood',[(1.84,.10,.19,.22),(1.94,.10,.23,.25),(2.12,.13,.24,.25),(2.26,.06,.21,.23),(2.33,-.06,.12,.16),(2.35,-.17,.02,.025)],m['navy'],'head',20)
    mod=hood.modifiers.new('Soft cloth folds','SUBSURF');mod.levels=1
    for side in [-1,1]:
        tube('Hood hem '+str(side),[(.33,side*.12,2.27),(.35,side*.18,2.13),(.30,side*.19,1.96),(.19,side*.18,1.85)],[.02]*4,m['blue'],'head',7)
    # Convex single-slit mask, not a human face.
    outline=[(-.115,2.27),(.105,2.27),(.15,2.14),(.10,1.97),(0,1.85),(-.10,1.97),(-.15,2.14)]
    verts=[(.38,y,z) for y,z in outline]+[(.49,0,2.11)]
    mesh('Porcelain face mask',verts,[(i,(i+1)%7,7) for i in range(7)],m['ivory'],'head',.025)
    tube('Single eye slit',[(.485,-.024,2.22),(.507,-.025,2.13),(.487,-.026,2.05)],[.018,.014,.008],m['black'],'head',6)
    tube('Mask hairline crack',[(.418,-.09,2.27),(.453,-.06,2.20),(.446,-.082,2.16)],[.004]*3,m['wood'],'head',4)
    for i in range(10):
        angle=i*TAU/10
        rows=[]
        for row,z in enumerate([1.27,1.03,.79]):
            rr=[.24,.30,.39][row]
            rows.append([(-.10+rr*math.cos(angle+d),rr*math.sin(angle+d),z+(random.uniform(-.09,.06) if row==2 else 0)) for d in [-.24,0,.24]])
        cloth('Split coat panel %02d'%i,rows,m['navy'] if i%3 else m['blue'],'pelvis')
    band('Waist sash',(-.08,0,1.20),(-.05,0,1.30),.255,m['rope'],'pelvis',3)
    for side,y in [('R',-.20),('L',.20)]:
        hip=(-.08,y,1.13)
        knee=(-.34,y-.03,.63) if side=='R' else (.35,y,.63)
        ankle=(-.53,y-.02,.16) if side=='R' else (.52,y,.16)
        thigh='thigh.'+side;shin='shin.'+side;foot='foot.'+side
        bones += [(thigh,hip,knee,'pelvis'),(shin,knee,ankle,thigh),(foot,ankle,(ankle[0]+.22,ankle[1],.08),shin)]
        tube('Trouser thigh '+side,[hip,knee],[.135,.09],m['navy'],thigh,12)
        tube('Wrapped calf '+side,[knee,ankle],[.085,.053],m['wood'],shin,10)
        band('Calf wraps '+side,Vector(knee).lerp(Vector(ankle),.12),Vector(knee).lerp(Vector(ankle),.97),.080,m['rope'],shin,13,.055)
        ellipsoid('Cloth shoe '+side,(ankle[0]+.08,ankle[1],.085),(.19,.083,.085),m['black'],foot)
    staff_a=Vector((-.42,-.40,.70));staff_b=Vector((1.32,-.22,2.18))
    for side,y,t in [('R',-.29,.65),('L',.29,.37)]:
        shoulder=(.055,y,1.72);hand=staff_a.lerp(staff_b,t)
        elbow=(.23,-.46,1.42) if side=='R' else (.19,.31,1.39)
        upper='upper_arm.'+side;fore='forearm.'+side;handbone='hand.'+side
        bones += [(upper,shoulder,elbow,'chest'),(fore,elbow,hand,upper),(handbone,hand,hand+Vector((.10,0,0)),fore)]
        tube('Loose sleeve '+side,[shoulder,elbow],[.14,.12],m['navy'],upper,12)
        tube('Forearm '+side,[elbow,hand],[.084,.06],m['black'],fore,10)
        band('Arm wraps '+side,Vector(elbow).lerp(hand,.12),Vector(elbow).lerp(hand,.8),.082,m['rope'],fore,10,.065)
        ellipsoid('Palm '+side,hand,(.075,.055,.075),m['black'],handbone,12,8)
        axis=(staff_b-staff_a).normalized()
        for digit in range(4):
            center=hand+axis*((digit-1.5)*.025)
            pts=[center+Vector((.025,-.050,.040)),center+Vector((.050,-.028,0)),center+Vector((.035,.030,-.040))]
            tube('Gripping finger '+side+str(digit),pts,[.017]*3,m['rope'],handbone,6)
    bones.append(('hook',staff_a,staff_b,'hand.R'))
    tube('Boat hook walnut shaft',[staff_a,staff_b],[.037,.032],m['wood'],'hook',10)
    end=staff_b
    pts=[end,end+Vector((.10,0,.07)),end+Vector((.24,0,.065)),end+Vector((.30,0,-.03)),end+Vector((.26,0,-.19)),end+Vector((.17,0,-.24))]
    tube('Forged hooked tip',pts,[.041,.045,.047,.043,.033,.008],m['steel'],'hook',8)
    band('Hook socket',staff_a.lerp(staff_b,.90),staff_b,.042,m['rope'],'hook',4)
    cloth('Hook pennant',[[tuple(staff_b+Vector((-.15,-.015,-.04))),tuple(staff_b+Vector((-.05,-.015,-.04)))],[(1.11,-.25,1.83),(1.19,-.23,1.86)],[(1.07,-.28,1.65),(1.16,-.25,1.72)]],m['blue'],'hook')
    for i in range(38):
        side=-1 if i%2 else 1
        start=Vector((-.03,side*random.uniform(.08,.25),1.82+random.uniform(-.015,.055)))
        end=start+Vector((-random.uniform(.14,.35),side*random.uniform(.16,.30),-random.uniform(.10,.25)))
        width=random.uniform(.023,.045)
        mesh('Reed mantle %02d'%i,[start+Vector((0,-width,0)),start+Vector((0,width,0)),end],[(0,1,2)],m['rope'] if i%3 else m['wood'],'chest',.006)
    return bones,(.27,0,1.25),3.25

def tide_duelist(m):
    bones=[('root',(0,0,0),(.25,0,0),None),('body',(-.8,0,0),(.6,0,.1),'root'),
           ('head',(.6,0,.1),(1.05,0,.1),'body'),('tail',(-.8,0,0),(-1.45,0,-.13),'body'),
           ('tail_tip',(-1.45,0,-.13),(-1.9,0,-.1),'tail')]
    rings=[(-1.45,-.13,.08,.10),(-1.0,-.04,.19,.23),(-.5,.07,.31,.41),(0,.12,.35,.46),(.5,.16,.28,.33),(.85,.13,.20,.22),(1.05,.08,.08,.10)]
    verts=[];faces=[];sides=20
    for x,z,ry,rz in rings:
        for j in range(sides):
            a=j*TAU/sides;verts.append((x,ry*math.sin(a),z+rz*math.cos(a)))
    for i in range(len(rings)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    body=mesh('Streamlined body',verts,faces,m['teal'],'body')
    for p in body.data.polygons:p.use_smooth=True
    ellipsoid('Ivory face',(.76,0,.13),(.30,.24,.25),m['ivory'],'head',20,12)
    for side in [-1,1]:
        ellipsoid('Eye socket '+str(side),(.84,side*.218,.20),(.065,.019,.047),m['black'],'head',12,8)
        ellipsoid('Small brass eye '+str(side),(.86,side*.233,.205),(.027,.012,.028),m['gold'],'head',10,6)
        tube('Gill scar '+str(side),[(.59,side*.228,.22),(.56,side*.25,.12),(.60,side*.218,.035)],[.007]*3,m['coral'],'head',5)
    # Curved katana bill: a real tapered diamond section, not a needle cone.
    blade=[];faces=[]
    for i in range(15):
        t=i/14;x=1.0+t*1.15;z=.065-.15*math.sin(t*math.pi)+.13*t*t
        half=.065*(1-t)**.65+.001;thick=.027*(1-t)+.001
        blade.extend([(x,-thick,z),(x,0,z+half),(x,thick,z),(x,0,z-half)])
        if i:
            for j in range(4):faces.append(((i-1)*4+j,(i-1)*4+(j+1)%4,i*4+(j+1)%4,i*4+j))
    mesh('Katana bill steel',blade,faces,m['steel'],'head')
    tube('Katana cutting edge',[(blade[i*4][0],-.008,blade[i*4+3][2]) for i in range(15)],[.009*(1-i/15)+.001 for i in range(15)],m['ivory'],'head',4)
    # Dome and forward brim of the compact kabuto.
    ellipsoid('Kabuto crown',(.58,0,.36),(.38,.275,.18),m['navy'],'head',20,10)
    for side in [-1,1]:
        cloth('Kabuto swept brow '+str(side),[[(.35,side*.28,.40),(.62,side*.29,.43),(.97,side*.19,.35)],[(.35,side*.29,.34),(.66,side*.28,.35),(.97,side*.19,.32)]],m['gold'],'head')
        horn=[(.63,side*.15,.49),(.47,side*.20,.67),(.35,side*.20,.90),(.27,side*.17,1.10)]
        tube('Swept helmet crest '+str(side),horn,[.038,.052,.032,.002],m['gold'],'head',7)
    # Armor follows the body's radial surface, so plates remain outside the skin.
    def surface(x,angle,lift=.035):
        x=max(rings[0][0],min(rings[-1][0],x))
        for a,b in zip(rings,rings[1:]):
            if a[0]<=x<=b[0]:
                t=(x-a[0])/(b[0]-a[0])
                z=a[1]*(1-t)+b[1]*t; ry=a[2]*(1-t)+b[2]*t; rz=a[3]*(1-t)+b[3]*t
                return Vector((x,(ry+lift)*math.sin(angle),z+(rz+lift)*math.cos(angle)))
    for row in range(6):
        x=.38-row*.23
        for side in [-1,1]:
            for tier in range(3):
                angle=side*(.25+tier*.47)
                rows=[]
                for k in range(3):
                    xx=x+.12-k*.15
                    rows.append([surface(xx,angle+side*(j-1)*.245,.055-k*.012) for j in range(3)])
                ob=cloth('Lamellar %d %d %d'%(row,side,tier),rows,m['blue'] if (row+tier)%3 else m['navy'],'body')
                tube('Plate lower rim',rows[-1],[.008]*3,m['gold'],'body',4)
                for point in [rows[0][0],rows[0][-1]]:
                    ellipsoid('Armor fastening',point,(.013,.013,.012),m['gold'],'body',8,5)
                if (row+tier)%3==0:
                    p=rows[-1][0]
                    mesh('Chipped pale enamel',[p,p+Vector((.04,0,.012)),rows[1][0]],[(0,1,2)],m['ivory'],'body')
    # Simple jointed sleeve fins, deliberately fewer layers than concept art.
    for side,name in [(-1,'R'),(1,'L')]:
        root=(.25,side*.24,.02);mid=(-.20,side*.51,-.22);tip=(-.72,side*.77,-.72)
        bone='fin.'+name;bones.append((bone,root,tip,'body'))
        rows=[]
        for i in range(7):
            t=i/6;center=Vector(root).lerp(Vector(tip),t)
            width=.10+.26*math.sin(t*math.pi*.9)
            rows.append([(center.x+width*(2*j/5-1),center.y+.025*math.sin(j*2+t*5),center.z+.05*math.cos(j*2)+(.09*(j%2) if i==6 else 0)) for j in range(6)])
        cloth('Haori sleeve fin '+name,rows,m['navy'],bone)
        for j in [0,2,5]:
            tube('Fin seam '+name+str(j),[rows[i][j] for i in range(7)],[.009]*7,m['blue'],bone,4)
        # Pale crescent insignia follows the fin's surface.
        curve=[]
        for i in range(17):
            a=math.pi*.12+i/16*math.pi*1.55
            curve.append((mid[0]+.13*math.cos(a),mid[1]+side*.015,mid[2]+.13*math.sin(a)-.07))
        tube('Sleeve crescent '+name,curve,[.016]*len(curve),m['ivory'],bone,5)
    cloth('Dorsal indigo fin',[[(-.8,0,.25),(-.42,0,.50),(-.15,0,.53)],[(-1.08,0,.89),(-.55,0,.91),(-.20,0,.54)]],m['navy'],'body')
    for side in [-1,1]:
        rows=[[(-1.39,-.06,-.13),(-1.39,.06,-.13)],[(-1.70,-.035,side*.36-.13),(-1.88,.035,side*.42-.13)],[(-1.81,-.01,side*.72-.13),(-2.05,.01,side*.68-.13)]]
        cloth('Forked tail '+str(side),rows,m['teal'],'tail_tip')
        tube('Tail ivory leading edge '+str(side),[row[0] for row in rows],[.025,.02,.002],m['ivory'],'tail_tip',5)
    band('Tail binding',(-1.37,0,-.13),(-1.51,0,-.13),.092,m['rope'],'tail',4)
    return bones,(.1,0,.10),4.65

def rig_and_export(asset,bones,scene):
    # Apply surface thickness before weighting; retain named pieces in .blend.
    for ob in parts:
        bpy.context.view_layer.objects.active=ob
        for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.select_all(action='DESELECT')
    arm=bpy.data.armatures.new(asset+'_Skeleton');rig=bpy.data.objects.new(asset+'_Rig',arm)
    scene.collection.objects.link(rig);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    for name,head,tail,parent in bones:
        b=arm.edit_bones.new(name);b.head=head;b.tail=tail
        if parent:b.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    for ob in parts:
        bone=ob['rig_bone'];ob.parent=rig
        group=ob.vertex_groups.new(name=bone);group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        if asset=='TideDuelist' and ob.name=='Streamlined body':
            tail=ob.vertex_groups.new(name='tail')
            for vert in ob.data.vertices:
                w=max(0,min(1,(-vert.co.x-.65)/.75))
                if w:group.add([vert.index],1-w,'REPLACE');tail.add([vert.index],w,'REPLACE')
        mod=ob.modifiers.new('Skeleton','ARMATURE');mod.object=rig
    # Small inspection loop demonstrates working joints, not combat behavior.
    rig.animation_data_create()
    action=bpy.data.actions.new('swim_idle' if asset=='TideDuelist' else 'idle_breathe')
    rig.animation_data.action=action
    anim_bones=['tail','tail_tip','fin.R','fin.L'] if asset=='TideDuelist' else ['chest','head']
    for name in anim_bones:
        pb=rig.pose.bones[name];pb.rotation_mode='XYZ'
        for frame,phase in [(1,0),(16,math.pi/2),(31,math.pi),(46,3*math.pi/2),(61,TAU)]:
            amount=.16 if name.startswith('tail') else (.07 if name.startswith('fin') else .018)
            pb.rotation_euler=(math.sin(phase)*amount,0,0)
            pb.keyframe_insert('rotation_euler',frame=frame,group=name)
    scene.frame_end=61;scene.frame_set(1)
    rig['concept']='Approved A Reedhook' if asset=='Reedhook' else 'Approved D2 swordfish samurai, simplified fins'
    rig['scope']='Model study with inspection idle only; no AI or combat clips'
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(asset+'_v1.blend')))
    # Join export meshes for bounded draw calls; the saved source stays separated.
    bpy.ops.object.select_all(action='DESELECT')
    for ob in parts:ob.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join();joined=bpy.context.object;joined.name=asset+'_Mesh'
    rig.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(RUNTIME/(asset+'_v1.glb')),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,
        export_cameras=False,export_lights=False,export_apply=False)
    deps=bpy.context.evaluated_depsgraph_get();evaluated=joined.evaluated_get(deps);me=evaluated.to_mesh();me.calc_loop_triangles()
    report={'triangles':len(me.loop_triangles),'vertices':len(me.vertices),'bones':len(bones),'materials':len(joined.data.materials),'animation':action.name}
    evaluated.to_mesh_clear()
    return report

def studio(scene,focus,size,asset):
    target=Vector(focus)
    bpy.ops.object.camera_add(location=target+Vector((4.0,-7.2,2.5)))
    camera=bpy.context.object;camera.name='REVIEW_Camera';camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=size;scene.camera=camera
    for name,offset,energy,light_size,color in [('Key',(2,-4,6),650,5,(1,.86,.67)),('Fill',(-3,-2,3),400,4,(.62,.80,1)),('Rim',(-1,4,5),850,3,(.79,.89,1))]:
        bpy.ops.object.light_add(type='AREA',location=target+Vector(offset));ob=bpy.context.object;ob.name='REVIEW_'+name
        ob.data.energy=energy;ob.data.shape='DISK';ob.data.size=light_size;ob.data.color=color
        ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
    # Review floor is excluded from GLB by export happening before studio setup.
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,0 if asset=='Reedhook' else -1.13))
    floor=bpy.context.object;floor.name='REVIEW_Floor'
    m=bpy.data.materials.new('Review background');m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.055,.075,.10,1);m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.95;floor.data.materials.append(m)
    scene.render.filepath=str(SOURCE/(asset+'_v1_preview.png'));bpy.ops.render.render(write_still=True)
    camera.location=target+Vector((0,-9,1.4));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(SOURCE/(asset+'_v1_side.png'));bpy.ops.render.render(write_still=True)

reports={}
for asset,builder in [('Reedhook',reedhook),('TideDuelist',tide_duelist)]:
    scene=reset();parts=[];m=palette()
    bones,focus,size=builder(m)
    reports[asset]=rig_and_export(asset,bones,scene)
    studio(scene,focus,size,asset)
(SOURCE/'model_report.json').write_text(json.dumps(reports,indent=2))
print('BLUE_ENEMY_MODELS_READY',json.dumps(reports))
