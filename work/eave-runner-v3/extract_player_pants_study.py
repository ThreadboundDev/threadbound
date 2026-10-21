from pathlib import Path
import bpy,bmesh,json,math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/eave-runner-v3'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'player_reference_only.blend'))
source=bpy.data.objects['Threadborne_Character'];rig=bpy.data.objects['Threadborne_Rig']
verts=[source.matrix_world@v.co for v in source.data.vertices]
faces=[tuple(p.vertices) for p in source.data.polygons]
surface=BVHTree.FromPolygons(verts,faces)
# The inside-first visibility test prefers the pants surface underneath open coat tails.
selected=set();ray_hits=0
for row in range(301):
    z=.5001+(.6048*row/300)
    for side in [-1,1]:
        hip=Vector((side*.105,0,1.035));knee=Vector((side*.135,-.018,.54))
        center=hip.lerp(knee,(1.035-z)/(.495));center.z=z
        for column in range(360):
            angle=math.tau*column/360;direction=Vector((math.cos(angle),math.sin(angle),0))
            hit,normal,index,distance=surface.ray_cast(center,direction,.33)
            if hit is not None and .4999<hit.z<1.1051:
                selected.add(index);ray_hits+=1

# Retain selected polygons, and their immediately adjacent tiny triangles. The
# source has seam duplicates, so adjacency is built from welded positions.
point_ids={};mapping=[]
for point in verts:
    key=tuple(round(axis*100000) for axis in point)
    if key not in point_ids:point_ids[key]=len(point_ids)
    mapping.append(point_ids[key])
edge_faces={}
for index in selected:
    poly=faces[index]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        key=tuple(sorted((mapping[a],mapping[b])));edge_faces.setdefault(key,[]).append(index)

result={'source':'player_reference_only.blend/Threadborne_Character',
        'method':'first surface reached by outward radial rays from each measured thigh centerline',
        'height_range':[.50,1.105],'ray_count':301*2*360,'ray_hits':ray_hits,
        'polygon_indices':sorted(selected),'selected_polygons':len(selected),
        'warning':'Read-only study. Inspect preview for gaps and tails before production extraction; source is one connected atlas mesh.'}
(OUT/'player_pants_subset.json').write_text(json.dumps(result,indent=2))

# Diagnostic crop meshes only, never saved over the reference/source assets.
for obj in list(bpy.data.objects):
    if obj.type in ['MESH','LIGHT','CAMERA'] and obj!=source:bpy.data.objects.remove(obj,do_unlink=True)
source.hide_render=True
def crop(name,indices):
    chosen=[faces[i] for i in indices];used=sorted({v for f in chosen for v in f});remap={old:new for new,old in enumerate(used)}
    me=bpy.data.meshes.new(name);me.from_pydata([verts[i] for i in used],[],[tuple(remap[i] for i in f) for f in chosen]);me.update()
    bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    for point,normal in [((0,0,.50),(0,0,1)),((0,0,1.105),(0,0,-1))]:
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=point,plane_no=normal,clear_inner=True,dist=.000001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    for p in me.polygons:p.use_smooth=True
    ob=bpy.data.objects.new(name,me);bpy.context.scene.collection.objects.link(ob);return ob
full=crop('All player surfaces in pants height',[p.index for p in source.data.polygons if any(.49<verts[i].z<1.12 for i in p.vertices)])
subset=crop('Inside-first pants surface',selected)
mat=bpy.data.materials.new('Diagnostic neutral clay');mat.use_nodes=True;bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.35,.42,.45,1);bs.inputs['Roughness'].default_value=.75
for ob in [full,subset]:ob.data.materials.append(mat)
sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Diagnostic World');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.14,.18,.22,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.4
def area(name,pos,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);sc.collection.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,.8))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Key',(1.5,-3,3),400,3);area('Fill',(-3,-1,1.5),200,3);area('Rim',(0,3,2.5),350,3)
data=bpy.data.cameras.new('Diagnostic Camera');camera=bpy.data.objects.new('Diagnostic Camera',data);sc.collection.objects.link(camera);sc.camera=camera;camera.location=(1.2,-5,1.25);camera.rotation_euler=(Vector((0,0,.80))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=.85
sc.render.engine='CYCLES';sc.cycles.samples=12;sc.cycles.use_denoising=True;sc.render.resolution_x=900;sc.render.resolution_y=900;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.view_settings.view_transform='AgX'
subset.hide_render=True;full.hide_render=False;sc.render.filepath=str(OUT/'renders/Diagnostic_Player_Pants_All_Crop.png');bpy.ops.render.render(write_still=True)
subset.hide_render=False;full.hide_render=True;sc.render.filepath=str(OUT/'renders/Diagnostic_Player_Pants_Radial_Subset.png');bpy.ops.render.render(write_still=True)
print('PANTS_SUBSET',len(selected),'/',len(faces),flush=True)
