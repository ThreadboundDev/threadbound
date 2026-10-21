from pathlib import Path
import bpy,json,math
import numpy as np

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/eave-runner-v3'
def summary(points):
    p=np.array([tuple(v) for v in points]);return {'min':p.min(axis=0).tolist(),'max':p.max(axis=0).tolist()}
def quantiles(values):
    return {str(p):float(np.percentile(values,p)) for p in [0,50,90,99,99.9,100]}

bpy.ops.wm.open_mainfile(filepath=str(OUT/'player_reference_only.blend'))
hero=bpy.data.objects['Threadborne_Character'];hr=bpy.data.objects['Threadborne_Rig']
result={'hero_world':{'rig':[list(r) for r in hr.matrix_world],'mesh':[list(r) for r in hero.matrix_world]},'hero_vertex_bounds':summary([hero.matrix_world@v.co for v in hero.data.vertices])}
source_points=[hero.matrix_world@v.co for v in hero.data.vertices]
for n in ['chest','spine','neck','head']:
    result.setdefault('hero_bones',{})[n]={'local_head':list(hr.data.bones[n].head_local),'world_head':list(hr.matrix_world@hr.data.bones[n].head_local)}
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
rig=bpy.data.objects['EaveRunner_Rig'];ob=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('Player-fitted sculpted'))
result['mesh']=ob.name;result['mesh_world']=[list(r) for r in ob.matrix_world]
result['modifiers']=[{'name':m.name,'type':m.type,'object':m.object.name if m.type=='ARMATURE' and m.object else None} for m in ob.modifiers]
rest=np.array([tuple(ob.matrix_world@v.co) for v in ob.data.vertices]);edges=np.array([tuple(e.vertices) for e in ob.data.edges]);rest_lengths=np.linalg.norm(rest[edges[:,1]]-rest[edges[:,0]],axis=1)
result['rest_bounds']=summary(rest);result['rest_edge_lengths']=quantiles(rest_lengths)
rig.data.pose_position='POSE';rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get();ev=ob.evaluated_get(deps);posed=np.array([tuple(ob.matrix_world@v.co) for v in ev.data.vertices]);lengths=np.linalg.norm(posed[edges[:,1]]-posed[edges[:,0]],axis=1);stretch=lengths/np.maximum(1e-9,rest_lengths)
result['idle_bounds']=summary(posed);result['idle_edge_lengths']=quantiles(lengths);result['edge_stretch']=quantiles(stretch);result['edges_over_2x']=int((stretch>2).sum());result['edges_over_5x']=int((stretch>5).sum())
result['worst_edges']=[]
for i in np.argsort(stretch)[-12:]:
    entries=[]
    for vi in edges[i]:
        v=ob.data.vertices[int(vi)];entries.append({'rest':rest[vi].tolist(),'posed':posed[vi].tolist(),'weights':{ob.vertex_groups[g.group].name:g.weight for g in v.groups}})
    result['worst_edges'].append({'stretch':float(stretch[i]),'vertices':entries})
result['invalid_group_names']=sorted({ob.vertex_groups[g.group].name for v in ob.data.vertices for g in v.groups if ob.vertex_groups[g.group].name not in rig.data.bones})
result['invalid_weight_count']=sum(abs(sum(g.weight for g in v.groups)-1)>.0002 for v in ob.data.vertices)
result['deform_bones']={n:{'scale':list(rig.pose.bones[n].scale),'local_head':list(rig.data.bones[n].head_local),'pose_head':list(rig.pose.bones[n].head)} for n in ['pelvis','spine','chest','neck','head','upper_arm.L','upper_arm.R']}
(OUT/'player_tunic_debug.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items() if k!='worst_edges'},indent=2),flush=True)
