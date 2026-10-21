from pathlib import Path
import bpy,json,os,tempfile
from mathutils.kdtree import KDTree

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/eave-runner-v3'
tempfile.tempdir=str(OUT/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1);bpy.context.view_layer.update()
tunic=next(o for o in sc.objects if o.type=='MESH' and o.name.startswith('Player-fitted sculpted'))
material=tunic.data.materials[0]
objects=[o for o in sc.objects if o.type=='MESH' and o.data.materials[0]==material]
def snapshot():return {p.name:[list(row) for row in p.matrix] for p in rig.pose.bones}
def evaluated(obj):return [obj.matrix_world@v.co for v in obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.vertices]
points=[];posed=[]
for ob in objects:
    points += [ob.matrix_world@v.co for v in ob.data.vertices]
    posed += evaluated(ob)
kd=KDTree(len(points))
for i,p in enumerate(points):kd.insert(p,i)
kd.balance()
def comparison(obj):
    now=evaluated(obj);distances=[]
    for i,v in enumerate(obj.data.vertices):
        co,j,d=kd.find(obj.matrix_world@v.co)
        distances.append((now[i]-posed[j]).length)
    return {'max_pose_vertex_difference':max(distances),'vertices_changed_over_1mm':sum(d>.001 for d in distances)}
result={'before_bones':snapshot(),'objects':len(objects)}
bpy.ops.object.select_all(action='DESELECT')
for ob in objects:ob.select_set(True)
bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();joined=objects[0]
result['after_join']=comparison(joined);result['after_join_bones']=snapshot()
# Export a temporary copy only; production assets remain unchanged.
bpy.ops.object.select_all(action='DESELECT');joined.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/'Debug_Tunic_Export.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)
result['after_export']=comparison(joined);result['after_export_bones']=snapshot();result['action_after_export']=rig.animation_data.action.name if rig.animation_data.action else None
sc.frame_set(1);bpy.context.view_layer.update();result['after_frame_reset']=comparison(joined);result['after_reset_bones']=snapshot()
(OUT/'tunic_join_export_debug.json').write_text(json.dumps(result,indent=2));print('JOIN_EXPORT_RESULT',json.dumps({k:v for k,v in result.items() if 'bones' not in k}),flush=True)
