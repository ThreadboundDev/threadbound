import bpy,json,math
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/shield_revision'
out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='C:/Users/chase/Downloads/tripo_pbr_model_663e8d12-f981-429b-babe-2406f36f0653_meshopt-v1.glb')
s=bpy.context.scene
meshes=[o for o in s.objects if o.type=='MESH']
points=[o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
lo=Vector([min(p[k] for p in points) for k in range(3)]);hi=Vector([max(p[k] for p in points) for k in range(3)])
center=(lo+hi)/2;extent=max(hi-lo)
report=[{'name':o.name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'bounds':[list(o.matrix_world@Vector(p)) for p in o.bound_box]} for o in meshes]
print('IMPORTED',json.dumps(report),flush=True)
bpy.ops.object.camera_add(location=center+Vector((4*extent,0,0)))
cam=bpy.context.object;s.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=extent*1.2
s.render.engine='CYCLES';s.cycles.samples=12;s.render.resolution_x=s.render.resolution_y=700;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.film_transparent=True
s.world=bpy.data.worlds.new('Inspection world');s.world.use_nodes=True
s.world.node_tree.nodes.get('Background').inputs[0].default_value=(.6,.6,.6,1)
s.world.node_tree.nodes.get('Background').inputs[1].default_value=.9
s.view_settings.view_transform='Standard'
for name,axis in [('plus_x',(1,0,0)),('minus_x',(-1,0,0)),('minus_y',(0,-1,0))]:
    cam.location=center+Vector(axis)*extent*4;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'Shield_Imported_Source.blend'))
(out/'import_report.json').write_text(json.dumps(report,indent=2))
