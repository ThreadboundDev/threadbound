"""Preserve imported weapon art, separate sword, rebuild the incorrect shield rear."""
import bpy, math, json, numpy as np
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/shield_revision'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Shield_Imported_Source.blend'))
s=bpy.context.scene;source=next(o for o in s.objects if o.type=='MESH');me=source.data
n=len(me.vertices);coords=np.empty(n*3,np.float32);me.vertices.foreach_get('co',coords);coords=coords.reshape(-1,3)
sizes=np.empty(len(me.polygons),np.int32);me.polygons.foreach_get('loop_total',sizes);assert np.all(sizes==3)
indices=np.empty(len(me.loops),np.int32);me.loops.foreach_get('vertex_index',indices);faces=indices.reshape(-1,3)
uv_data=[]
for layer in me.uv_layers:
    arr=np.empty(len(me.loops)*2,np.float32);layer.data.foreach_get('uv',arr);uv_data.append((layer.name,arr.reshape(-1,2)))
centers=coords[faces].mean(axis=1)
def subset(name,mask):
    fi=np.flatnonzero(mask);old=faces[fi];used,new=np.unique(old,return_inverse=True)
    new=new.ravel().astype(np.int32)
    mesh=bpy.data.meshes.new(name);mesh.vertices.add(len(used));mesh.vertices.foreach_set('co',coords[used].ravel())
    mesh.loops.add(len(new));mesh.loops.foreach_set('vertex_index',new)
    mesh.polygons.add(len(fi));mesh.polygons.foreach_set('loop_start',np.arange(len(fi),dtype=np.int32)*3)
    mesh.polygons.foreach_set('loop_total',np.full(len(fi),3,dtype=np.int32));mesh.polygons.foreach_set('use_smooth',np.ones(len(fi),dtype=bool))
    for lname,arr in uv_data:
        layer=mesh.uv_layers.new(name=lname);layer.data.foreach_set('uv',arr.reshape(-1,3,2)[fi].ravel())
    for mat in me.materials:mesh.materials.append(mat)
    mesh.update();ob=bpy.data.objects.new(name,mesh);s.collection.objects.link(ob)
    return ob
sword=subset('Threadborne_Sword',centers[:,1]<-.17)
shield=subset('Shield_Original_Front',(centers[:,1]>=-.17)&(centers[:,0]>=0))
source.name='SOURCE_Original_Combined_Weapons';source.hide_render=True;source.hide_set(True)
archive=bpy.data.collections.new('SOURCE • untouched import');s.collection.children.link(archive)
for c in list(source.users_collection):c.objects.unlink(source)
archive.objects.link(source);archive.hide_viewport=True;archive.hide_render=True
print('FRONT_PRESERVED',len(shield.data.polygons),'faces; SWORD',len(sword.data.polygons),flush=True)

CY=.14;CZ=-.030;R=.284
parts=[shield]
def material(name,low,high,metal=0,scale=(4,95,4)):
    mat=bpy.data.materials.new(name);mat.use_nodes=True;nodes=mat.node_tree.nodes;nodes.clear();links=mat.node_tree.links
    out=nodes.new('ShaderNodeOutputMaterial');p=nodes.new('ShaderNodeBsdfPrincipled');p.inputs['Roughness'].default_value=.74;p.inputs['Metallic'].default_value=metal
    tex=nodes.new('ShaderNodeTexCoord');mapping=nodes.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=scale
    noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3;noise.inputs['Detail'].default_value=3
    ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(*low,1);ramp.color_ramp.elements[1].color=(*high,1)
    bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15;bump.inputs['Distance'].default_value=.001
    links.new(tex.outputs['Generated'],mapping.inputs[0]);links.new(mapping.outputs[0],noise.inputs['Vector']);links.new(noise.outputs['Fac'],ramp.inputs[0])
    links.new(ramp.outputs[0],p.inputs['Base Color']);links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs[0],p.inputs['Normal']);links.new(p.outputs[0],out.inputs[0])
    return mat
wood=material('Shield • dark worn backing',(.011,.012,.012),(.047,.042,.035),scale=(2,70,1))
cloth=material('Shield • charcoal sewn wraps',(.009,.011,.012),(.027,.031,.032),scale=(2,24,35))
leather=material('Shield • brown leather arm straps',(.029,.016,.008),(.105,.061,.027),scale=(5,20,4))
brass=material('Shield • aged brass',(.17,.078,.020),(.43,.245,.089),.65,scale=(6,6,6))
thread=material('Shield • golden stitching',(.22,.12,.038),(.39,.23,.075),.15)
dark=material('Shield • recessed seams',(.003,.003,.003),(.008,.008,.008))
def meshob(name,verts,faces,mat,bevel=0):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new(name,mesh);s.collection.objects.link(ob);mesh.materials.append(mat)
    for p in mesh.polygons:p.use_smooth=True
    if bevel:
        mod=ob.modifiers.new('Soft worn edges','BEVEL');mod.width=bevel;mod.segments=3
        mod=ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    parts.append(ob);return ob
def box(name,center,scale,mat,bevel=.001):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center);ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);ob.data.materials.append(mat)
    if bevel:
        mod=ob.modifiers.new('Rounded worn edges','BEVEL');mod.width=bevel;mod.segments=3
        ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    parts.append(ob);return ob
def curve(name,pts,radius,mat):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius;data.bevel_resolution=2
    sp=data.splines.new('POLY');sp.points.add(len(pts)-1)
    for p,co in zip(sp.points,pts):p.co=(*co,1)
    ob=bpy.data.objects.new(name,data);s.collection.objects.link(ob);data.materials.append(mat);parts.append(ob);return ob
def stud(y,z,x=-.052,size=.003):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=(x,CY+y,CZ+z))
    ob=bpy.context.object;ob.name='Shield_Brass_Rivet';ob.scale=(size*.55,size,size);ob.data.materials.append(brass)
    for p in ob.data.polygons:p.use_smooth=True
    parts.append(ob)

# Circle-trimmed vertical boards close the removed rear shell.
for k in range(11):
    y0=-R+2*R*k/11+.0004;y1=-R+2*R*(k+1)/11-.0004
    arc=[]
    for i in range(17):
        y=y0+(y1-y0)*i/16;arc.append((y,math.sqrt(max(0,R*R-y*y))))
    outline=arc+[(y,-z) for y,z in reversed(arc)]
    verts=[(x,CY+y,CZ+z) for x in [-.018,.001] for y,z in outline];count=len(outline)
    f=[tuple(range(count-1,-1,-1)),tuple(range(count,2*count))]
    f.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
    meshob('Shield_Back_Board_%02d'%k,verts,f,wood,.0008)
# Broad flat rear rim, rather than a rope-like torus.
verts=[];f=[];N=192
for x,r in [(-.028,R-.014),(-.028,R+.004),(.002,R+.004),(.002,R-.014)]:
    verts.extend((x,CY+r*math.sin(i*math.tau/N),CZ+r*math.cos(i*math.tau/N)) for i in range(N))
for band in range(4):
    for i in range(N):f.append((band*N+i,band*N+(i+1)%N,((band+1)%4)*N+(i+1)%N,((band+1)%4)*N+i))
meshob('Shield_Back_Brass_Rim',verts,f,brass,.001)
for sign in [-1,1]:
    outline=[(-.029,.260),(-.026,.285),(-.012,.309),(0,.313),(.012,.309),(.026,.285),(.029,.260)]
    vv=[(x,CY+y,CZ+sign*z) for x in [-.004,.009] for y,z in outline];count=len(outline)
    ff=[tuple(range(count-1,-1,-1)),tuple(range(count,2*count))]+[(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
    meshob('Shield_Ornament_Rear_Cap',vv,ff,brass,.001)

def ribbon(name,points,width,mat,width_axis='y',thickness=.003):
    verts=[]
    for x,y,z in points:
        verts.extend([(x,y-width/2,z),(x,y+width/2,z)] if width_axis=='y' else [(x,y,z-width/2),(x,y,z+width/2)])
    ob=meshob(name,verts,[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(points)-1)],mat)
    m=ob.modifiers.new('Leather or cloth thickness','SOLIDIFY');m.thickness=thickness
    m=ob.modifiers.new('Soft edges','BEVEL');m.width=.001;m.segments=3
    return ob
# Cross wraps and the central sewn spine reproduce the rear construction.
for sign in [-1,1]:
    pts=[(-.024,CY+(-.235+.47*i/64),CZ+sign*(-.13+.26*i/64)) for i in range(65)]
    ribbon('Shield_Back_Diagonal_Wrap',pts,.041,cloth,'z')
    for i in range(2,63,3):
        x,y,z=pts[i];curve('Shield_Wrap_Stitch',[(x-.003,y-.002,z-.018),(x-.003,y+.002,z-.015)],.00065,thread)
box('Shield_Back_Vertical_Sewn_Brace',(-.030,CY,CZ),(.012,.052,.55),cloth,.002)
box('Shield_Back_Horizontal_Brace',(-.041,CY,CZ),(.016,.267,.049),cloth,.002)
for z in np.arange(-.225,.236,.034):
    for sign in [-1,1]:curve('Shield_Brace_Cross_Stitch',[(-.038,CY-.009,CZ+z-sign*.007),(-.038,CY+.009,CZ+z+sign*.007)],.0007,thread)
for z in [-.255,.255]:
    box('Shield_Brace_End_Plate',(-.041,CY,CZ+z),(.009,.061,.025),brass,.002)
    for y in [-.020,.020]:stud(y,z,-.048)

# Two real raised leather loops: space behind them for the arm/hand.
for y in [-.102,.102]:
    for z in [-.105,.105]:
        box('Shield_Strap_Anchor_Plate',(-.043,CY+y,CZ+z),(.014,.063,.047),brass,.003)
        box('Shield_Strap_Anchor_Inset',(-.052,CY+y,CZ+z),(.007,.051,.034),leather,.002)
        for dy in [-.024,.024]:
            for dz in [-.016,.016]:stud(y+dy,z+dz,-.054,.0024)
        stud(y,z,-.059,.004)
    pts=[]
    for i in range(65):
        t=i/64;z=.105-.21*t;x=-.058-.066*math.sin(math.pi*t)**.8
        pts.append((x,CY+y,CZ+z))
    ribbon('Shield_Raised_Leather_Arm_Loop',pts,.038,leather,thickness=.005)
    for side in [-1,1]:
        for i in range(2,62,3):
            a=pts[i];b=pts[i+1]
            curve('Shield_Leather_Edge_Stitch',[(a[0]-.003,a[1]+side*.014,a[2]),(b[0]-.003,b[1]+side*.014,b[2])],.0006,thread)
for k in range(12):
    a=k*math.tau/12;stud((R-.006)*math.sin(a),(R-.006)*math.cos(a),-.032,.0026)

# Independent placement roots make the sword and shield useful as separate gear.
def root(name,location,children):
    ob=bpy.data.objects.new(name,None);s.collection.objects.link(ob);ob.location=location;ob.empty_display_size=.05
    bpy.context.view_layer.update()
    for child in children:
        matrix=child.matrix_world.copy();child.parent=ob;child.matrix_world=matrix
    return ob
shield_root=root('Threadborne_Shield_ROOT',(0,CY,CZ),parts)
shield_root['attachment_note']='Separate shield assembly. Raised arm loops are modeled; align to character forearm during equipment fitting.'
sword_root=root('Threadborne_Sword_ROOT',(0,-.315,.31),[sword])
sword_root['attachment_note']='Approximate handle pivot; final grip placement requires hand fitting.'
for mat in sword.data.materials:
    if mat:mat.name='Threadborne_Imported_Weapon_Artwork'
cam=s.camera;cam.name='Weapon_Review_Camera';cam.data.ortho_scale=.77
s.render.resolution_x=s.render.resolution_y=900;s.cycles.samples=20
def view(name,axis,all_weapons=False):
    center=Vector((0,0,0)) if all_weapons else Vector((0,CY,CZ))
    cam.data.ortho_scale=1.18 if all_weapons else .77
    cam.location=center+Vector(axis)*4;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
view('corrected_front',(1,0,0),True)
view('corrected_back',(-1,0,0))
view('corrected_back_three_quarter',(-1,-.6,.20))
view('corrected_side',(-.25,-1,.10))
bpy.ops.object.select_all(action='DESELECT');shield_root.select_set(True);bpy.context.view_layer.objects.active=shield_root
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL';area.spaces.active.region_3d.view_location=Vector((0,CY,CZ));area.spaces.active.region_3d.view_distance=1.25
            area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Threadborne_Sword_Shield_Rear_Fix.blend'))
(OUT/'repair_report.json').write_text(json.dumps({'source_vertices':n,'sword_faces_preserved':len(sword.data.polygons),'shield_front_faces_preserved':len(shield.data.polygons),'rear_parts':len(parts)-1,'separate_weapon_roots':True,'live_scene_changed':False},indent=2))
print('SHIELD_BACK_COMPLETE',flush=True)
