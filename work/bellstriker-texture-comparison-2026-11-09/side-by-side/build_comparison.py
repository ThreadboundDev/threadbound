"""Build a labeled, equally lit comparison of the two delivered texture sets."""
from pathlib import Path
import math,json
import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree

D=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=2400;scene.render.resolution_y=1250;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
scene.world=bpy.data.worlds.new('Shared Neutral Studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.18,.22,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
wn=scene.world.node_tree.nodes;wl=scene.world.node_tree.links
ambient=wn.new('ShaderNodeBackground');ambient.inputs[0].default_value=(.55,.59,.65,1);ambient.inputs[1].default_value=.8
ray=wn.new('ShaderNodeLightPath');mix=wn.new('ShaderNodeMixShader')
wl.new(ray.outputs['Is Camera Ray'],mix.inputs[0]);wl.new(ambient.outputs[0],mix.inputs[1]);wl.new(wn['Background'].outputs[0],mix.inputs[2]);wl.new(mix.outputs[0],wn['World Output'].inputs['Surface'])

report={};roots=[];point_sets=[]
for label,x in [('CODEX',-.65),('TRIPO',.65)]:
    existing=set(bpy.data.objects)
    if label=='CODEX':
        bpy.ops.import_scene.gltf(filepath=str(D.parent/'Bellstriker_Painted_v1.glb'))
    else:
        bpy.ops.import_scene.fbx(filepath=str(D/'tripo_source/fantasy_insect_3d_model.fbx'))
    imported=[o for o in bpy.data.objects if o not in existing]
    meshes=[o for o in imported if o.type=='MESH']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector([min(p[i] for p in points) for i in range(3)])
    hi=Vector([max(p[i] for p in points) for i in range(3)])
    center=(lo+hi)/2;scale=1/(hi.x-lo.x)
    point_sets.append([(p-center)*scale for p in points])
    root=bpy.data.objects.new(label+' - rotate or scrub timeline',None);scene.collection.objects.link(root)
    root.location=(x,0,.37);roots.append(root)
    tri=0
    for ob in meshes:
        world=ob.matrix_world.copy()
        ob.parent=None;ob.matrix_world=world
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        for v in ob.data.vertices:v.co=(v.co-center)*scale
        ob.parent=root;ob.location=(0,0,0)
        ob.name=label+' - Bellstriker'
        ob.data.calc_loop_triangles();tri+=len(ob.data.loop_triangles)
        if label=='TRIPO':
            image=bpy.data.images.load(str(D/'tripo_source/fantasy_insect_3d_model.fbm/fantasy_insect_3d_model_basecolor.jpg'))
        else:
            image=next(n.image for mat in ob.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image)
        image.pack()
        mat=bpy.data.materials.new(label+' - identical comparison material');mat.use_nodes=True
        n=mat.node_tree.nodes;bs=n.get('Principled BSDF');tex=n.new('ShaderNodeTexImage');tex.image=image
        mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
        bs.inputs['Roughness'].default_value=.48;bs.inputs['Metallic'].default_value=0;bs.inputs['Specular IOR Level'].default_value=.28
        ob.data.materials.clear();ob.data.materials.append(mat)
        for poly in ob.data.polygons:poly.material_index=0
    report[label]=dict(triangles=tri,source_dimensions=list(hi-lo),normalization_scale=scale,texture_pixels=list(image.size))

tree=KDTree(len(point_sets[0]))
for i,p in enumerate(point_sets[0]):tree.insert(p,i)
tree.balance()
report['normalized_surface_vertex_distance_max']=max(tree.find(p)[2] for p in point_sets[1])
report['comparison']='Original base-color images; equal world lighting, scale, roughness, metallic, specular, camera and rotation. No recoloring.'

for name,rotation,power in [('Key',(math.radians(25),math.radians(-25),math.radians(-25)),1.5),('Fill',(math.radians(65),math.radians(35),math.radians(140)),.7)]:
    data=bpy.data.lights.new(name,'SUN');data.energy=power;data.angle=.25
    light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.rotation_euler=rotation

textmat=bpy.data.materials.new('Label white');textmat.use_nodes=True
n=textmat.node_tree.nodes;n.clear();em=n.new('ShaderNodeEmission');em.inputs['Color'].default_value=(.8,.85,.95,1)
out=n.new('ShaderNodeOutputMaterial');textmat.node_tree.links.new(em.outputs[0],out.inputs['Surface'])
def caption(name,text,x,z,size):
    font=bpy.data.curves.new(name,'FONT');font.body=text;font.align_x='CENTER';font.size=size
    ob=bpy.data.objects.new(name,font);scene.collection.objects.link(ob);ob.location=(x,-.42,z);ob.rotation_euler=(math.pi/2,0,0);font.materials.append(textmat)
    ob.hide_select=True
caption('Left label','CODEX',-.65,.90,.065)
caption('Right label','TRIPO',.65,.90,.065)
caption('Conditions','SAME SCALE  /  SAME LIGHTING  /  SAME MATERIAL SETTINGS',0,-.16,.025)

camera=bpy.data.objects.new('Comparison Camera',bpy.data.cameras.new('Comparison Camera'));scene.collection.objects.link(camera);scene.camera=camera
camera.location=(0,-6,.37);camera.rotation_euler=(Vector((0,0,.37))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=2.55
scene.frame_start=1;scene.frame_end=120
for frame,name,angle in [(1,'FRONT',0),(40,'ANGLED',-.45),(80,'BACK',math.pi),(120,'SIDE',-math.pi/2)]:
    marker=scene.timeline_markers.new(name,frame=frame)
    for root in roots:
        root.rotation_euler.z=angle;root.keyframe_insert(data_path='rotation_euler',frame=frame)
    scene.frame_set(frame);scene.render.filepath=str(D/('compare_'+name.lower()+'.png'));bpy.ops.render.render(write_still=True)
scene.frame_set(40)
scene.render.engine='CYCLES'
bpy.ops.object.select_all(action='DESELECT')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active;space.shading.type='MATERIAL';space.shading.use_scene_lights=True;space.shading.use_scene_world=True
            space.overlay.show_overlays=False;space.region_3d.view_perspective='CAMERA';space.region_3d.view_camera_zoom=0
            space.region_3d.view_location=(0,0,.37);space.region_3d.view_distance=3
        elif area.type=='DOPESHEET_EDITOR':
            area.spaces.active.show_region_ui=False
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(D/'Bellstriker_Codex_vs_Tripo.blend'),compress=True)
(D/'comparison_report.json').write_text(json.dumps(report,indent=2)+'\n')
print('COMPARISON_READY',json.dumps(report))
