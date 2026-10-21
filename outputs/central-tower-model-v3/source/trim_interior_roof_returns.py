"""Keep upper roof returns outside the cutaway's inner wall edges.

The visible side roof is trimmed. Its removed inward return is retained in the
removable facade assembly so the complete exterior stays continuous. Tier 1
and all non-roof geometry remain unchanged. The input file is not overwritten.
"""
import bpy,bmesh,json,hashlib,math,os,tempfile
from pathlib import Path
from mathutils import Vector

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
SRC=ROOT/'outputs/central-tower-model-v2/CentralTower_Editable.blend'
OUT=ROOT/'outputs/central-tower-model-v3'
for p in [OUT,OUT/'source',OUT/'source/build-temp',OUT/'previews']:p.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(OUT/'source/build-temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.open_mainfile(filepath=str(SRC))
bpy.context.preferences.filepaths.save_version=0
sc=bpy.context.scene
model=bpy.data.collections['CENTRAL_TOWER_MODEL'];F=bpy.data.collections['02_Facade_Removable']
root=bpy.data.objects['CentralTower_ROOT'];rootinv=root.matrix_world.inverted()
facade_parent=bpy.data.objects['02_Facade_Removable']
scale=json.loads((SRC.parent/'roof_joint_verification.json').read_text())['normalization_scale'][0]
for c in [model,F,bpy.data.collections['04_Fixed_Blue_Roofs']]:c.hide_viewport=False
def meshes():return [o for o in model.all_objects if o is not None and o.type=='MESH']
for ob in model.all_objects:
    if ob is not None:ob.hide_set(False);ob.hide_viewport=False
def digest(ob):
    data=str([tuple(v.co) for v in ob.data.vertices])+str([(tuple(p.vertices),p.material_index) for p in ob.data.polygons])
    return hashlib.sha256(data.encode()).hexdigest()
def bounds(obs):
    p=[rootinv@ob.matrix_world@v.co for ob in obs for v in ob.data.vertices]
    return [min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]
def area(ob):
    ob.data.calc_loop_triangles();verts=ob.data.vertices
    return sum((verts[t.vertices[1]].co-verts[t.vertices[0]].co).cross(verts[t.vertices[2]].co-verts[t.vertices[0]].co).length*.5 for t in ob.data.loop_triangles)

selected={f'Roof_Tier{tier:02d}_{side}_Side_With_Corners' for tier in [2,3,4] for side in ['Left','Right']}
protected={o.name:digest(o) for o in meshes() if o.name not in selected}
beforelo,beforehi=bounds(meshes());checks=[]
def cut(ob,coordinate,sign,keep_outer):
    bm=bmesh.new();bm.from_mesh(ob.data)
    world_co=root.matrix_world@Vector((coordinate,0,0))
    world_no=root.matrix_world.to_3x3().inverted().transposed()@Vector((sign,0,0))
    plane_co=ob.matrix_world.inverted()@world_co
    plane_no=(ob.matrix_world.to_3x3().transposed()@world_no).normalized()
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=plane_co,plane_no=plane_no,use_snap_center=True,clear_inner=keep_outer,clear_outer=not keep_outer)
    bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4])
    bm.to_mesh(ob.data);bm.free();ob.data.update()

for tier,inner_raw in [(2,2.54),(3,2.54),(4,1.76)]:
    # Place the cut a little inside the solid wall thickness, past its inner face.
    limit=(inner_raw+.04)*scale
    for side,sign in [('Left',-1),('Right',1)]:
        ob=bpy.data.objects[f'Roof_Tier{tier:02d}_{side}_Side_With_Corners']
        # Partition planar triangles so a bisected nonplanar roof quad cannot
        # change its diagonal and create a small surface-area discrepancy.
        bm=bmesh.new();bm.from_mesh(ob.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bm.to_mesh(ob.data);bm.free();ob.data.update()
        original_area=area(ob)
        inner=ob.copy();inner.data=ob.data.copy();inner.name=f'Roof_Tier{tier:02d}_{side}_Inner_Return_HideWithFacade'
        F.objects.link(inner);world=ob.matrix_world.copy();inner.parent=facade_parent;inner.matrix_world=world
        cut(ob,sign*limit,sign,True)
        cut(inner,sign*limit,sign,False)
        inner['cutaway_removable']=True;inner['role']='Inward roof return hidden together with the facade'
        ob['interior_wall_clearance_raw_units']=.04
        ob['retains_front_and_back_corners']=True
        positions=[rootinv@ob.matrix_world@v.co for v in ob.data.vertices]
        minimum=min(sign*p.x for p in positions)
        assert minimum>=limit-2e-5,(ob.name,minimum,limit)
        delta=abs(area(ob)+area(inner)-original_area)
        assert delta<1e-3,(ob.name,delta)
        checks.append({'tier':tier,'side':side,'fixed_roof_minimum_abs_x':minimum,'interior_wall_abs_x':inner_raw*scale,'trim_abs_x':limit,'surface_area_difference_full_exterior':delta,'fixed_side':ob.name,'hidden_inner_return':inner.name})
for name,d in protected.items():assert digest(bpy.data.objects[name])==d,name
afterlo,afterhi=bounds(meshes())
assert all(abs(a-b)<2e-5 for a,b in zip(beforelo+beforehi,afterlo+afterhi))
root['roof_revision']='v3: upper three side roofs trimmed beyond inner wall faces; inward returns hide with facade'

def visible(full):
    F.hide_render=not full;F.hide_viewport=False
    for ob in F.objects:
        if ob is not None:ob.hide_render=not full
def export(filename,full):
    visible(True);bpy.ops.object.select_all(action='DESELECT')
    for ob in model.all_objects:
        if ob is None or (not full and ob.name in F.objects):continue
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/filename),export_format='GLB',use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_tangents=True,export_materials='EXPORT',export_image_format='AUTO',export_extras=True,export_cameras=False,export_lights=False)
    bpy.ops.object.select_all(action='DESELECT')

swaps=[];runtime=[]
runtime_dir=ROOT/'outputs/central-tower-model-v1/textures/runtime'
for mat in bpy.data.materials:
    if not mat.use_nodes:continue
    key=mat.name.split('.')[0]
    if key not in ['walnut','plaster','slate','blue_tiles']:continue
    for n in mat.node_tree.nodes:
        if n.type!='TEX_IMAGE' or n.image is None:continue
        old=n.image;name=old.name
        if 'BaseColor' in name:fn=key+'_BaseColor_4K.jpg'
        elif 'NormalGL' in name:fn=key+'_NormalGL_2K.png'
        elif 'Roughness' in name:fn=key+'_Roughness_2K.png'
        else:continue
        image=bpy.data.images.load(str(runtime_dir/fn),check_existing=True)
        if 'BaseColor' not in name:image.colorspace_settings.name='Non-Color'
        swaps.append((n,old));n.image=image;runtime.append(image)
export('CentralTower_Exterior.glb',True);export('CentralTower_Cutaway.glb',False)
for n,old in swaps:n.image=old
for image in set(runtime):
    if image.users==0:bpy.data.images.remove(image)
for image in bpy.data.images:
    if image.source=='FILE' and image.users and not image.packed_file:
        try:image.pack()
        except Exception:pass

report={'version':'v3 interior roof clearance','input':str(SRC),'checks':checks,'bottom_roof_tier_unchanged':all(digest(bpy.data.objects[n])==d for n,d in protected.items() if 'Roof_Tier01' in n),'other_meshes_unchanged':True,'before_dimensions':[b-a for a,b in zip(beforelo,beforehi)],'after_dimensions':[b-a for a,b in zip(afterlo,afterhi)],'hidden_inner_returns':[c['hidden_inner_return'] for c in checks],'checks_passed':True}
(OUT/'roof_clearance_verification.json').write_text(json.dumps(report,indent=2))
cam=sc.camera
def camera(loc,target,ortho):
    cam.data.type='ORTHO';cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=ortho
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True
sc.render.resolution_percentage=100
sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA';sc.render.film_transparent=True
visible(True);camera((40,-70,37),(0,0,15.6),35.8)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))
def render(name,full,loc,target,size,w,h):
    visible(full);camera(loc,target,size);sc.render.resolution_x=w;sc.render.resolution_y=h;sc.render.filepath=str(OUT/'previews'/name)
    bpy.ops.render.render(write_still=True);print('RENDER_READY',name,flush=True)
render('cutaway_front.png',False,(0,-80,16),(0,0,16),34.8,1200,1800)
render('upper_roofs_cutaway_front.png',False,(0,-65,21.2),(0,0,21.2),16,1400,1500)
render('upper_roofs_cutaway_angle.png',False,(11,-30,25),(1,-.3,21),13.6,1500,1200)
render('exterior_three_quarter.png',True,(40,-70,37),(0,0,15.6),35.8,1200,1800)
visible(True);camera((40,-70,37),(0,0,15.6),35.8);sc.render.resolution_x=1200;sc.render.resolution_y=1800
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CentralTower_Editable.blend'))
print('ROOF_CLEARANCE_FIX_COMPLETE',json.dumps(report),flush=True)
