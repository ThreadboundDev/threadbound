"""Build the approved villagers and separate workstations in background Blender.

The CC0 MakeHuman hm08 base, matching rig and weights provide human topology.
Clothes, hair, props, stations, painted material detail and animation are authored
here. No existing character, Blender session or production source is changed.
"""
import bpy, math, json, random, hashlib, shutil, sys, os, tempfile
import bmesh
from pathlib import Path
from mathutils import Vector, Matrix
from mathutils.kdtree import KDTree

ROOT = next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
SOURCE = ROOT/'ArtSource/BlueBiome/Villagers'
DEST = ROOT/'Assets/BlueBiome/Villagers'
WORK = ROOT/'work/lakeside-villagers'
CC0 = SOURCE/'CC0_Source'
for folder in [SOURCE, SOURCE/'CC0_Source', DEST/'Models', DEST/'Textures', WORK/'renders']:
    folder.mkdir(parents=True, exist_ok=True)
(WORK/'build-temp').mkdir(exist_ok=True)
tempfile.tempdir=str(WORK/'build-temp')
os.environ['TEMP']=tempfile.tempdir
os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
random.seed(47)
EXPORT_FACTORS={}

def read_obj(path):
    vertices=[];uv=[];faces=[];groups=[];group=''
    for line in path.read_text().splitlines():
        p=line.split()
        if not p:continue
        if p[0]=='v':vertices.append(Vector(tuple(map(float,p[1:4]))))
        elif p[0]=='vt':uv.append(tuple(map(float,p[1:3])))
        elif p[0]=='g':group=' '.join(p[1:])
        elif p[0]=='f':
            face=[];coords=[]
            for token in p[1:]:
                q=token.split('/');face.append(int(q[0])-1);coords.append(uv[int(q[1])-1] if len(q)>1 and q[1] else (0,0))
            faces.append((face,coords));groups.append(group)
    return vertices,faces,groups

BASE,FACES,GROUPS=read_obj(CC0/'base.obj')
RIGDEF=json.loads((CC0/'default.mhskel').read_text())
WEIGHTS=json.loads((CC0/'default_weights.mhw').read_text())['weights']
VERT_WEIGHTS=[{} for v in BASE]
for name,items in WEIGHTS.items():
    for index,weight in items:VERT_WEIGHTS[index][name]=weight

def texture_material(name,color,texture_name=None,normal_name=None,rough_name=None,metal=0.0):
    # Blender's preview multiply node is not represented by its glTF exporter.
    # Preserve the same linear tint explicitly in the runtime packaging step.
    EXPORT_FACTORS[name]=[*color,1]
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    p=mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.82
    p.inputs['Metallic'].default_value=metal
    if texture_name:
        for key,file in [('Base Color',texture_name),('Roughness',rough_name),('Normal',normal_name)]:
            if not file:continue
            node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=bpy.data.images.load(str(file),check_existing=True)
            node.extension='REPEAT'
            if key=='Base Color':
                tint=mat.node_tree.nodes.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1;tint.inputs[2].default_value=(*color,1)
                mat.node_tree.links.new(node.outputs['Color'],tint.inputs[1]);mat.node_tree.links.new(tint.outputs[0],p.inputs[key])
            elif key=='Normal':
                node.image.colorspace_settings.name='Non-Color';normal=mat.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.38
                mat.node_tree.links.new(node.outputs['Color'],normal.inputs['Color']);mat.node_tree.links.new(normal.outputs[0],p.inputs[key])
            else:
                node.image.colorspace_settings.name='Non-Color';mat.node_tree.links.new(node.outputs['Color'],p.inputs[key])
    return mat

PAV=ROOT/'Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2'
TIMBER=ROOT/'Assets/BlueBiome/Art/Lakeside3D/Textures'
MAT={
 'indigo':texture_material('Villager | worn indigo',(.84,.91,1),DEST/'Textures/IndigoWorkwear_BaseColor.png',PAV/'blue_pavilion_indigo_normal.png',PAV/'blue_pavilion_indigo_roughness.png'),
 'flax':texture_material('Villager | flax linen',(.91,.81,.63),PAV/'blue_pavilion_cloth_light.png',PAV/'blue_pavilion_cloth_light_normal.png',PAV/'blue_pavilion_cloth_light_roughness.png'),
 'brown':texture_material('Villager | work apron',(1,1,1),DEST/'Textures/WorkCanvas_BaseColor.png',PAV/'blue_pavilion_cloth_light_normal.png',PAV/'blue_pavilion_cloth_light_roughness.png'),
 'pants':texture_material('Villager | charcoal trouser',(.20,.23,.25),PAV/'blue_pavilion_cloth_light.png',PAV/'blue_pavilion_cloth_light_normal.png',PAV/'blue_pavilion_cloth_light_roughness.png'),
 'wood':texture_material('Villager | village walnut',(1,1,1),TIMBER/'walnut_BaseColor_4K.png',TIMBER/'walnut_NormalGL_4K.png',TIMBER/'walnut_Roughness_4K.png'),
 'cutwood':texture_material('Villager | cut timber',(.62,.39,.18)),
 'hair':texture_material('Villager | dark hair',(.026,.018,.014)),
 'greyhair':texture_material('Villager | salt and pepper',(.065,.055,.042)),
 'iron':texture_material('Villager | iron tool',(.20,.23,.23),metal=.68),
 'rope':texture_material('Villager | hemp cord',(.53,.38,.19)),
 'dark':texture_material('Villager | deep recess',(.012,.009,.007)),
}

def mesh(name,vertices,faces,material,uv=None):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob)
    ob.data.materials.append(material)
    layer=data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        poly.use_smooth=True
        for i,li in enumerate(poly.loop_indices):
            if uv is not None:layer.data[li].uv=uv[poly.index][i]
            else:
                co=data.vertices[data.loops[li].vertex_index].co
                layer.data[li].uv=(co.x*1.4,co.z*1.4)
    return ob

def remove_unused(ob):
    bm=bmesh.new();bm.from_mesh(ob.data)
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.to_mesh(ob.data);bm.free();ob.data.update()

def bind(ob,rig,weights=None,bone=None,transfer=None):
    ob.parent=rig
    groups={}
    for vertex in ob.data.vertices:
        influences={bone:1.0} if bone else (weights[vertex.index] if weights is not None else transfer(vertex.co))
        total=sum(influences.values()) or 1
        for name,weight in influences.items():
            if weight<.001:continue
            if name not in groups:groups[name]=ob.vertex_groups.new(name=name)
            groups[name].add([vertex.index],weight/total,'REPLACE')
    mod=ob.modifiers.new('Humanoid deformation','ARMATURE');mod.object=rig
    return ob

def sphere(name,center,size,material,rig=None,bone='head',segments=24,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=center)
    ob=bpy.context.object;ob.name=name;ob.scale=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    ob.data.materials.append(material)
    for p in ob.data.polygons:p.use_smooth=True
    if rig:bind(ob,rig,bone=bone)
    return ob

def tube(name,points,radii,material,rig=None,bone='head',sides=7):
    vertices=[];faces=[];uv=[]
    if isinstance(radii,(int,float)):radii=[radii]*len(points)
    for i,p in enumerate(points):
        p=Vector(p);axis=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized()
        u=axis.cross(Vector((0,0,1)))
        if u.length<.01:u=axis.cross(Vector((0,1,0)))
        u.normalize();v=axis.cross(u).normalized()
        for j in range(sides):
            a=j*math.tau/sides;vertices.append(p+radii[i]*(u*math.cos(a)+v*math.sin(a)))
    for i in range(len(points)-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
            uv.append([(j/sides,i*.4),((j+1)/sides,i*.4),((j+1)/sides,(i+1)*.4),(j/sides,(i+1)*.4)])
    ob=mesh(name,vertices,faces,material,uv)
    if rig:bind(ob,rig,bone=bone)
    return ob

def box(name,center,size,material,rig=None,bone='root',bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    ob=bpy.context.object;ob.name=name;ob.dimensions=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    ob.data.materials.append(material)
    if bevel:
        mod=ob.modifiers.new('Worn edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
        for p in ob.data.polygons:p.use_smooth=False
    if rig:bind(ob,rig,bone=bone)
    return ob

def shaped_vertices(kind):
    v=[p.copy() for p in BASE]
    targets=['asian-female-young.target','universal-female-young-averagemuscle-averageweight.target'] if kind=='NetMender' else ['asian-male-old.target','universal-male-old-averagemuscle-averageweight.target']
    for file in targets:
        for line in (CC0/file).read_text().splitlines():
            if not line or line.startswith('#'):continue
            q=line.split();v[int(q[0])]+=Vector(tuple(map(float,q[1:4])))
    body_indices={i for (face,uv),group in zip(FACES,GROUPS) if group=='body' for i in face}
    ground=min(v[i].y for i in body_indices)
    height=max(v[i].y for i in body_indices)-ground
    scale=(1.65 if kind=='NetMender' else 1.74)/height
    converted=[Vector((p.x*scale,-p.z*scale,(p.y-ground)*scale+.024)) for p in v]
    return converted

def create_rig(kind,vertices):
    arm=bpy.data.armatures.new(kind+'_Humanoid');rig=bpy.data.objects.new(kind+'_Rig',arm);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    def joint(name):return sum((vertices[i] for i in RIGDEF['joints'][name]),Vector())/len(RIGDEF['joints'][name])
    for name,definition in RIGDEF['bones'].items():
        bone=arm.edit_bones.new(name);bone.head=joint(definition['head']);bone.tail=joint(definition['tail'])
        if (bone.tail-bone.head).length<.001:bone.tail=bone.head+Vector((0,0,.01))
    for name,definition in RIGDEF['bones'].items():
        bone=arm.edit_bones[name]
        if definition['parent']:bone.parent=arm.edit_bones[definition['parent']]
        plane=RIGDEF['planes'].get(definition.get('rotation_plane'))
        if plane:
            a,b,c=[joint(j) for j in plane];normal=(b-a).cross(c-a)
            if normal.length>.00001:bone.align_roll(normal.normalized())
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    rig['source']='CC0 MakeHuman hm08 and matching default humanoid weights'
    return rig

def build_body(kind,vertices,rig):
    # Detailed human face, hands, lower calves and feet remain visible. Hidden
    # torso/leg skin is omitted from the exported model under the clothes.
    source_indices=[];coords=[];polys=[];uvs=[];mapping={}
    for (face,uv),group in zip(FACES,GROUPS):
        if group!='body':continue
        center=sum((vertices[i] for i in face),Vector())/len(face)
        arm_weight=sum(sum(w for n,w in VERT_WEIGHTS[i].items() if n.startswith(('lowerarm','wrist','finger','metacarpal'))) for i in face)/len(face)
        if not (center.z>1.28 or center.z<.29 or arm_weight>.55):continue
        poly=[]
        for index in face:
            if index not in mapping:
                mapping[index]=len(coords);coords.append(vertices[index]);source_indices.append(index)
            poly.append(mapping[index])
        polys.append(poly);uvs.append(uv)
    skin=texture_material(kind+' | warm skin',(.66,.39,.235) if kind=='NetMender' else (.61,.355,.205))
    ob=mesh(kind+'_Skin',coords,polys,skin,uvs)
    tint=ob.data.color_attributes.new(name='SkinTint',type='FLOAT_COLOR',domain='POINT')
    eye=vertices[RIGDEF['joints'][RIGDEF['bones']['eye.L']['head']][0]]
    for j,index in enumerate(source_indices):
        co=vertices[index];base=Vector((.43,.235,.13) if kind=='NetMender' else (.37,.19,.09))
        lip=sum(w for n,w in VERT_WEIGHTS[index].items() if n.startswith('oris'))
        blush=math.exp(-((abs(co.x)-.045)/.035)**2-((co.z-(eye.z-.035))/.035)**2)*max(0,min(1,(-co.y-.075)*12))
        noise=random.uniform(-.012,.012)
        base=base.lerp(Vector((.42,.18,.13)),min(.48,lip*.36))
        base+=Vector((.045,-.006,-.008))*blush+Vector((noise,noise,noise))
        tint.data[j].color=(*base,1)
    node=skin.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name='SkinTint'
    skin.node_tree.links.new(node.outputs['Color'],skin.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    skin.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.70
    bind(ob,rig,weights=[VERT_WEIGHTS[i] for i in source_indices])
    return ob

def transfer_function(vertices):
    kd=KDTree(len(vertices))
    for i,p in enumerate(vertices):
        if VERT_WEIGHTS[i]:kd.insert(p,i)
    kd.balance()
    def transfer(point):
        weights={}
        for co,index,distance in kd.find_n(point,4):
            factor=1/max(.0001,distance)**2
            for name,w in VERT_WEIGHTS[index].items():weights[name]=weights.get(name,0)+w*factor
        total=sum(weights.values())
        return {name:w/total for name,w in weights.items()} if total else {'root':1}
    return transfer

def clothing(kind,vertices,rig,transfer):
    helper_faces=[(face,uv) for (face,uv),group in zip(FACES,GROUPS) if group=='helper-tights']
    helper=mesh('Clothing fitting surface',vertices,[face for face,uv in helper_faces],MAT['indigo'])
    normals=[v.normal.copy() for v in helper.data.vertices]
    def garment(name,predicate,material,inflate,loosen):
        mapping={};points=[];polys=[];uvs=[]
        for face,old_uv in helper_faces:
            c=sum((vertices[i] for i in face),Vector())/len(face)
            if not predicate(c,face):continue
            poly=[]
            for index in face:
                if index not in mapping:
                    p=vertices[index]+normals[index]*inflate
                    p=loosen(p)
                    mapping[index]=len(points);points.append(p)
                poly.append(mapping[index])
            polys.append(poly)
            # Stable lengthwise textile UVs; repeats are shared across both NPCs.
            uvs.append([(vertices[i].x*2.2+.5,vertices[i].z*.9) for i in face])
        ob=mesh(name,points,polys,material,uvs)
        smooth=ob.modifiers.new('Soft cloth folds','SMOOTH');smooth.factor=.35;smooth.iterations=3
        bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=smooth.name)
        solid=ob.modifiers.new('Cloth hems thickness','SOLIDIFY');solid.thickness=.006
        bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=solid.name)
        bind(ob,rig,transfer=transfer)
        return ob
    def trouser(p):
        side=1 if p.x>=0 else -1
        if p.z<.85:p.x=side*(.14+(abs(p.x)-.14)*1.28)
        p.y*=1.12
        return p
    garment(kind+'_LooseTrousers',lambda c,f:.24<c.z<1.005 and abs(c.x)<.35,MAT['pants'],.025,trouser)
    def sleeve_weight(face):
        return sum(sum(w for n,w in transfer(vertices[i]).items() if n.startswith(('lowerarm','wrist','finger','metacarpal'))) for i in face)/len(face)
    def coat(p):
        if abs(p.x)<.22:
            p.x*=1.09
            if p.y<0:p.y=min(p.y,-.13+max(0,p.z-1.25)*.11)
        p.x+=math.sin(p.z*48+abs(p.x)*20)*.003
        return p
    garment(kind+'_WorkKimono',lambda c,f:.78<c.z<1.52 and sleeve_weight(f)<.20 and not (abs(c.x)<.085 and c.z>1.46) and not (c.y<-.07 and abs(c.x)<.08 and c.z>1.31+abs(c.x)*1.6),MAT['indigo'],.023,coat)
    bpy.data.objects.remove(helper,do_unlink=True)
    # Linen underlap and the two visible folded edges of the wrap jacket.
    for sign in [-1,1]:
        pts=[(sign*.105,-.125,1.44),(sign*.079,-.165,1.34),(-sign*.035,-.173,1.19),(-sign*.09,-.175,1.035)]
        ribbon=[]
        for x,y,z in pts:ribbon.extend([(x-.017,y-.004,z),(x+.017,y-.004,z)])
        ob=mesh('Folded kimono lapel',ribbon,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(pts)-1)],MAT['indigo'])
        bind(ob,rig,transfer=transfer)
        edge=tube('Kimono fine linen edging',[(x-.018,y-.006,z) for x,y,z in pts],.002,MAT['flax'],sides=5)
        bind(edge,rig,transfer=transfer)
    # Draped waist apron, supported by the pelvis with a loose lower edge.
    points=[];faces=[]
    for row in range(11):
        t=row/10;z=.975-t*.49;half=.195+.025*t
        for column in range(13):
            u=column/12;x=(u*2-1)*half
            y=-.24-.012*math.sin(u*math.tau*2.4+t*.7)-.025*t
            points.append((x,y,z+.008*math.sin(u*7+t)))
    for row in range(10):
        for column in range(12):
            i=row*13+column;faces.append((i,i+1,i+14,i+13))
    apron=mesh(kind+'_CanvasApron',points,faces,MAT['brown'])
    mod=apron.modifiers.new('Apron edge','SOLIDIFY');mod.thickness=.005
    bpy.context.view_layer.objects.active=apron;bpy.ops.object.modifier_apply(modifier=mod.name)
    bind(apron,rig,bone='root')
    # Hemp waist belt with knot and short hanging ends.
    for z in [.978,.988,1.0]:
        pts=[(.22*math.cos(a),.175*math.sin(a)+.01,z) for a in [j*math.tau/48 for j in range(49)]]
        ob=tube('Hemp waist binding',pts,.006,MAT['rope'],sides=6);bind(ob,rig,transfer=transfer)
    for sign in [-1,1]:
        ob=tube('Belt tie loop',[(.12,-.19,.99),(.12+sign*.055,-.21,1.005),(.15+sign*.04,-.215,.962),(.12,-.19,.99)],.006,MAT['rope'],sides=6)
        bind(ob,rig,transfer=transfer)
        ob=tube('Belt short end',[(.12,-.19,.98),(.13+sign*.018,-.205,.89),(.13+sign*.035,-.19,.82)],.006,MAT['rope'],sides=6);bind(ob,rig,transfer=transfer)
    # Cloth repair patches and conspicuous small running stitches.
    for px,pz,w,h,mat in [(-.11,1.20,.075,.065,MAT['indigo']),(.12,1.07,.06,.09,MAT['flax']),(-.10,.64,.085,.11,MAT['brown'])]:
        y=-.282 if pz<1 else -.172
        patch=mesh('Hand-sewn repair',[(px-w/2,y,pz-h/2),(px+w/2,y,pz-h/2),(px+w/2,y,pz+h/2),(px-w/2,y,pz+h/2)],[(0,1,2,3)],mat)
        bind(patch,rig,bone='root') if pz<1 else bind(patch,rig,transfer=transfer)
        for k in range(6):
            x=px-w*.45+w*.9*k/5
            stitch=tube('Visible repair stitch',[(x-.002,y-.003,pz+h*.48-.004),(x+.002,y-.003,pz+h*.48+.004)],.0012,MAT['flax'],sides=4)
            bind(stitch,rig,bone='root') if pz<1 else bind(stitch,rig,transfer=transfer)
    for side in ['L','R']:
        ankle=rig.data.bones['foot.'+side].head_local
        x=ankle.x
        sole=box('Wooden sandal sole',(x,-.075,.024),(.115,.245,.035),MAT['wood'],bevel=.018);bind(sole,rig,bone='foot.'+side)
        for sign in [-1,1]:
            tube('Sandal thong',[(x+sign*.043,-.012,.066),(x+sign*.024,-.10,.083),(x,-.164,.06)],.008,MAT['rope'],rig,'foot.'+side,sides=6)
        for zoff in [-.004,.005]:
            elbow=rig.data.bones['lowerarm01.'+side].head_local
            axis=(rig.data.bones['upperarm02.'+side].tail_local-rig.data.bones['upperarm02.'+side].head_local).normalized()
            u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u)
            c=elbow-axis*.015+axis*zoff
            pts=[c+.068*(u*math.cos(j*math.tau/32)+v*math.sin(j*math.tau/32)) for j in range(33)]
            ob=tube('Rolled linen sleeve cuff',pts,.007,MAT['flax'],sides=6);bind(ob,rig,bone='upperarm02.'+side)

def hair_and_eyes(kind,vertices,rig):
    hair=MAT['hair'] if kind=='NetMender' else MAT['greyhair']
    eye_center=sum((vertices[i] for i in RIGDEF['joints'][RIGDEF['bones']['eye.L']['head']]),Vector())/len(RIGDEF['joints'][RIGDEF['bones']['eye.L']['head']])
    body_indices={i for (face,uv),group in zip(FACES,GROUPS) if group=='body' for i in face}
    top=max(vertices[i].z for i in body_indices)
    polys=[]
    for (face,uv),group in zip(FACES,GROUPS):
        if group!='body':continue
        c=sum((vertices[i] for i in face),Vector())/len(face)
        if c.z>eye_center.z+.04 or (c.z>eye_center.z-.03 and c.y>-.04):polys.append(face)
    cap=mesh(kind+'_SweptHair',vertices,polys,hair)
    remove_unused(cap)
    for vertex in cap.data.vertices:vertex.co+=vertex.normal*.003
    bind(cap,rig,bone='head')
    # Compact tied bun and visible swept locks give volume from every camera side.
    sphere('Tied hair bun',(0,.07,top-.025),(.053,.052,.046),hair,rig)
    for k in range(13):
        a=k/13*math.tau
        pts=[(.054*math.cos(a)*math.cos(t),.07+.053*math.sin(a)*math.cos(t),top-.025+.047*math.sin(t)) for t in [-1.3+i*2.6/12 for i in range(13)]]
        tube('Hair bun swept strand',pts,.001,MAT['hair'] if k%3 else MAT['greyhair'],rig,'head',sides=4)
    if kind=='NetMender':
        pts=[]
        for k in range(65):
            a=k*math.tau/64;pts.append((.095*math.cos(a),-.015+.13*math.sin(a),eye_center.z+.055+.007*math.sin(a)))
        tube('Indigo hair wrap',pts,.017,MAT['indigo'],rig,'head',sides=9)
        sphere('Head wrap knot',(.025,.143,eye_center.z+.06),(.026,.02,.023),MAT['indigo'],rig)
        for sign in [-1,1]:
            verts=[(.02,.15,eye_center.z+.05),(.05,.15,eye_center.z+.05),(.05+sign*.016,.16,eye_center.z-.025),(.02+sign*.015,.16,eye_center.z-.035)]
            ob=mesh('Short head wrap end',verts,[(0,1,2,3)],MAT['indigo']);bind(ob,rig,bone='head')
    else:
        beard_faces=[]
        for (face,uv),group in zip(FACES,GROUPS):
            if group!='body':continue
            c=sum((vertices[i] for i in face),Vector())/len(face)
            lip=sum(sum(w for n,w in VERT_WEIGHTS[i].items() if n.startswith('oris')) for i in face)/len(face)
            if eye_center.z-.147<c.z<eye_center.z-.065 and c.y<-.035 and abs(c.x)<.075 and lip<.55:beard_faces.append(face)
        beard=mesh('Short salt-and-pepper beard',vertices,beard_faces,hair)
        remove_unused(beard)
        for vertex in beard.data.vertices:vertex.co+=vertex.normal*.004
        bind(beard,rig,bone='head')
    for side in ['L','R']:
        b=rig.data.bones['eye.'+side];center=b.head_local;front=b.tail_local
        sign=1 if side=='L' else -1
        brow=[(center.x+sign*x,front.y+.008,center.z+.018+lift) for x,lift in [(-.018,0),(-.005,.006),(.01,.008),(.022,.002)]]
        tube('Expressive eyebrow '+side,brow,[.0015,.0025,.0023,.0008],hair,rig,'head',sides=6)
    # The eye proxy stores a one-to-one mapping to morphed helper-eye vertices.
    eye_v,eye_f,eye_g=read_obj(CC0/'low-poly.obj')
    lines=(CC0/'low-poly.mhclo').read_text().split('verts 0',1)[1].splitlines()
    mapping=[int(line.strip()) for line in lines if line.strip().isdigit()]
    eye_mat=texture_material('Villager | brown eyes',(1,1,1),CC0/'brown_eye.png')
    eye_mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.30
    eye_mesh=mesh('Brown eyes',[vertices[i] for i in mapping],[face for face,uv in eye_f],eye_mat,[uv for face,uv in eye_f])
    eye_weights=[{'eye.L' if v.co.x>0 else 'eye.R':1} for v in eye_mesh.data.vertices]
    bind(eye_mesh,rig,weights=eye_weights)

def net_station():
    for x in [-.38,.38]:
        box('Net frame upright',(x,-.39,.80),(.045,.055,1.46),MAT['wood'])
        box('Net frame foot',(x,-.37,.055),(.09,.46,.08),MAT['wood'])
    for z in [.40,1.40]:box('Net frame rail',(0,-.39,z),(.81,.045,.045),MAT['wood'])
    # Diamond mesh is real geometry so warm interior lights reveal its depth.
    for direction in [-1,1]:
        for start in range(-10,15):
            pts=[]
            for j in range(31):
                z=.43+j*.029;x=start*.082+direction*(z-.43)*.50
                if -.35<x<.35:pts.append((x,-.385+.018*math.sin(z*8),z))
            if len(pts)>1:tube('Knotted fishing net',pts,.0017,MAT['rope'],sides=4)
    for i in range(7):
        a=i*math.tau/6
        tube('Spare net cord coil',[(.37+.095*math.cos(t),.03+.08*math.sin(t),.07+i*.003) for t in [k*math.tau/48 for k in range(49)]],.003,MAT['rope'],sides=5)
    bucket('Mender wooden bucket',(.48,-.16,.02),.14,.28)
    for x in [-.22,.0]:
        for y in [.23,.4]:box('Stool leg',(x,y,.14),(.04,.04,.28),MAT['wood'])
    box('Low stool seat',(-.11,.315,.29),(.35,.29,.045),MAT['wood'])

def bucket(name,center,radius,height):
    x,y,z=center
    for k in range(12):
        a=k*math.tau/12;da=math.tau/12*.45
        verts=[(x+r*math.cos(t),y+r*math.sin(t),zz) for r,zz in [(radius*.83,z),(radius,z+height)] for t in [a-da,a+da]]
        ob=mesh(name+' stave',verts,[(0,1,3,2)],MAT['wood'])
    for zz in [z+.04,z+height-.035]:
        tube(name+' binding',[(x+radius*math.cos(a),y+radius*math.sin(a),zz) for a in [i*math.tau/40 for i in range(41)]],.007,MAT['iron'],sides=6)
    box(name+' inside bottom',(x,y,z+.01),(radius*1.1,radius*1.1,.02),MAT['wood'])

def boat_station():
    for x in [-.49,.49]:
        for y in [-.56,-.08]:box('Workbench pegged leg',(x,y,.41),(.09,.09,.78),MAT['wood'])
        box('Bench trestle foot',(x,-.32,.10),(.13,.72,.10),MAT['wood'])
    box('Workbench lower stretcher',(0,-.3,.21),(1.08,.07,.08),MAT['wood'])
    for i in range(5):box('Worktop plank',(-.49+i*.245,-.32,.83),(.235,.65,.075),MAT['wood'])
    box('Held timber blank',(0,-.40,.90),(.74,.12,.075),MAT['cutwood'])
    for i in range(6):
        t=i/5
        pts=[(-.40+t*.16,-.56,.886),(-.38+t*.17,-.58,.94),(-.34+t*.17,-.61,.94),(-.32+t*.18,-.61,.90)]
        tube('Curled wood shaving',pts,.004,MAT['cutwood'],sides=5)
    bucket('Workshop tool bucket',(.72,-.13,.02),.13,.29)
    # A short bent boat rib makes the station read as boat work from a distance.
    tube('Curved boat rib offcut',[(-.70,.04,.05),(-.69,.04,.38),(-.62,.04,.73),(-.48,.04,1.04),(-.31,.04,1.22)],.035,MAT['wood'],sides=8)
    for i in range(4):box('Timber peg',(.58,-.06+i*.022,.20+i*.025),(.026,.026,.24),MAT['cutwood'])

def animation_samples(kind,rig):
    targets={};constraints=[]
    for side in ['L','R']:
        target=bpy.data.objects.new('TEMP_IK_'+side,None);bpy.context.collection.objects.link(target);targets[side]=target
        ik=rig.pose.bones['lowerarm02.'+side].constraints.new('IK');ik.target=target;ik.chain_count=4;ik.use_stretch=False
        constraints.append(ik)
    def pose(clip,phase):
        rig.animation_data_clear()
        for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
        talk=clip=='TalkIdle'
        for side,sign in [('L',1),('R',-1)]:
            if talk:
                targets[side].location=(sign*.31,-.12,.94+.015*math.sin(phase+sign*.8))
            elif kind=='NetMender':
                targets[side].location=(sign*.12+(.025*math.sin(phase) if side=='R' else 0),-.34-.022*math.sin(phase),1.08+.022*math.cos(phase+sign))
            else:
                targets[side].location=(sign*.11,-.34-.07*math.sin(phase),1.005+.008*math.cos(phase))
            for digit in range(1,6):
                for joint in range(1,4):
                    name='finger%d-%d.%s'%(digit,joint,side)
                    if name in rig.pose.bones:
                        pb=rig.pose.bones[name];pb.rotation_mode='XYZ';pb.rotation_euler.x=(.20 if talk else .52) if digit>1 else .18
        for name,angles in [('spine03',(.012*math.sin(phase),0,.006*math.cos(phase))),('spine01',(.012 if not talk else -.012,0,0)),('head',(.04+.014*math.cos(phase) if not talk else -.018+.025*math.sin(phase),.02*math.sin(phase*.5),.015*math.sin(phase)))]:
            pb=rig.pose.bones[name];pb.rotation_mode='XYZ';pb.rotation_euler=angles
        bpy.context.view_layer.update()
    clips={}
    for clip in ['WorkIdle','TalkIdle']:
        samples=[]
        for frame in range(1,122,4):
            phase=(frame-1)/120*math.tau
            pose(clip,phase)
            evaluated=rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
            matrices={pb.name:pb.matrix.copy() for pb in evaluated.pose.bones}
            local={}
            for bone in rig.data.bones:
                if bone.parent:
                    local[bone.name]=bone.matrix_local.inverted() @ bone.parent.matrix_local @ matrices[bone.parent.name].inverted() @ matrices[bone.name]
                else:local[bone.name]=bone.matrix_local.inverted() @ matrices[bone.name]
            samples.append((frame,local))
        clips[clip]=samples
    pose('WorkIdle',0)
    work_matrices={pb.name:pb.matrix.copy() for pb in rig.evaluated_get(bpy.context.evaluated_depsgraph_get()).pose.bones}
    for pb in rig.pose.bones:
        for constraint in list(pb.constraints):pb.constraints.remove(constraint)
    for target in targets.values():bpy.data.objects.remove(target,do_unlink=True)
    for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    rig.animation_data_create();actions=[]
    for clip,samples in clips.items():
        action=bpy.data.actions.new(clip);action.use_fake_user=True;rig.animation_data.action=action
        for frame,local in samples:
            for pb in rig.pose.bones:
                pb.rotation_mode='QUATERNION';pb.location,pb.rotation_quaternion,pb.scale=local[pb.name].decompose()
                pb.keyframe_insert('location',frame=frame,group=pb.name)
                pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
                pb.keyframe_insert('scale',frame=frame,group=pb.name)
        # The clips are four-second seamless loops; the last pose equals first.
        action['loop']=True
        actions.append(action)
    rig.animation_data.action=actions[0]
    bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=121;bpy.context.scene.render.fps=30
    bpy.context.scene.frame_set(1)
    return actions,work_matrices

def held_tools(kind,rig,posed):
    old=set(bpy.context.scene.objects)
    if kind=='NetMender':
        center=Vector((-.12,-.37,1.08))
        # Split-prong wooden netting shuttle, rather than a solid weapon shape.
        for dx in [-.013,.013]:
            tube('Netting shuttle prong',[center+Vector((dx,0,-.055)),center+Vector((dx,-.007,.045)),center+Vector((0,-.007,.065))],.004,MAT['wood'],sides=6)
        for i in range(8):
            tube('Shuttle wound thread',[center+Vector((-.014,-.009,i*.004-.015)),center+Vector((.014,-.009,i*.004-.015))],.0015,MAT['rope'],sides=4)
    else:
        box('Wooden hand plane',(-.04,-.35,.98),(.22,.085,.065),MAT['wood'])
        box('Plane iron blade',(-.02,-.35,1.018),(.042,.073,.009),MAT['iron'],bevel=.002)
        tube('Plane rounded handle',[(-.13,-.35,1.0),(-.12,-.35,1.06),(-.07,-.35,1.065),(-.06,-.35,1.01)],.012,MAT['wood'],sides=8)
    # Place against the posed grip, then bring geometry into bind/rest space.
    bone='wrist.R';unpose=rig.data.bones[bone].matrix_local @ posed[bone].inverted()
    for ob in set(bpy.context.scene.objects)-old:
        if ob.type!='MESH':continue
        for vertex in ob.data.vertices:vertex.co=unpose @ vertex.co
        bind(ob,rig,bone=bone)

def join_meshes(objects,name):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
    ob=bpy.context.object;ob.name=name
    return ob

def export_selection(path,objects,animations=False):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_animations=animations,export_animation_mode='ACTIONS',export_force_sampling=True,
        export_cameras=False,export_lights=False,export_apply=False,export_image_format='AUTO',export_skins=True)

def studio(scene,kind,rig,actor,station,talk_action):
    scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
    scene.render.resolution_x=1100;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
    scene.view_settings.view_transform='AgX'
    world=bpy.data.worlds.new(kind+' Review World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.20,.25,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45;scene.world=world
    floor_mat=texture_material('Review | warm grey',(.17,.19,.20))
    box('REVIEW_Floor',(0,0,-.035),(200,200,.05),floor_mat,bevel=0)
    target=Vector((0,-.18,.91))
    bpy.ops.object.camera_add(location=(2.4,-5.4,2.45))
    camera=bpy.context.object;camera.name='REVIEW_Camera';camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=2.18;scene.camera=camera
    for label,position,power,size,color in [('Key',(-2,-4,5),520,4,(1,.84,.68)),('Fill',(3,-2,3),300,3,(.68,.80,1)),('Rim',(0,3,4),500,3,(.82,.88,1))]:
        bpy.ops.object.light_add(type='AREA',location=position);light=bpy.context.object;light.name='REVIEW_'+label;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.data.color=color;light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
    scene.frame_set(1)
    scene.render.filepath=str(WORK/'renders'/(kind+'_work.png'));bpy.ops.render.render(write_still=True)
    for ob in [station]:ob.hide_render=True
    target=Vector((0,0,.90));camera.location=(2.3,-5.5,2.1);camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=1.95
    rig.animation_data.action=talk_action
    scene.frame_set(1)
    scene.render.filepath=str(WORK/'renders'/(kind+'_talk.png'));bpy.ops.render.render(write_still=True)
    station.hide_render=False

reports={}
for kind in ['NetMender','Boatwright']:
    scene=bpy.data.scenes.new(kind+'_WorkshopReview');bpy.context.window.scene=scene
    vertices=shaped_vertices(kind)
    rig=create_rig(kind,vertices);transfer=transfer_function(vertices)
    body=build_body(kind,vertices,rig)
    clothing(kind,vertices,rig,transfer)
    hair_and_eyes(kind,vertices,rig)
    actions,posed=animation_samples(kind,rig)
    held_tools(kind,rig,posed)
    actor_objects=[ob for ob in scene.objects if ob.type=='MESH']
    # Keep material slots and vertex groups editable on the joined actor.
    actor=join_meshes(actor_objects,kind+'_TexturedCharacter')
    rig.animation_data.action=actions[0];scene.frame_set(1)
    export_selection(DEST/'Models'/(kind+'.glb'),[rig,actor],True)
    before=set(scene.objects)
    if kind=='NetMender':net_station()
    else:boat_station()
    station_objects=[ob for ob in set(scene.objects)-before if ob.type=='MESH']
    station=join_meshes(station_objects,kind+'_Workstation')
    export_selection(DEST/'Models'/(kind+'_Workstation.glb'),[station],False)
    scene.frame_set(1)
    triangles=sum(len(p.vertices)-2 for p in actor.data.polygons)
    reports[kind]={'triangles':triangles,'station_triangles':sum(len(p.vertices)-2 for p in station.data.polygons),'bones':len(rig.data.bones),'animations':[a.name for a in actions],'height_m':1.65 if kind=='NetMender' else 1.74,'base':'CC0 MakeHuman hm08','front':'-Y in Blender, +Z in glTF/Godot'}
    studio(scene,kind,rig,actor,station,actions[1])
    rig.animation_data.action=actions[0];scene.frame_set(1)

for image in bpy.data.images:
    if image.source=='FILE':
        image.pack()
bpy.context.window.scene=bpy.data.scenes['NetMender_WorkshopReview']
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'LakesideVillagers_v1.blend'),compress=True)
(SOURCE/'build_report.json').write_text(json.dumps(reports,indent=2))
(SOURCE/'material_export_factors.json').write_text(json.dumps(EXPORT_FACTORS,indent=2))
print('LAKESIDE_VILLAGERS_BUILT',json.dumps(reports),flush=True)
