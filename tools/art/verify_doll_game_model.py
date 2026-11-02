"""Reopen the exported doll and measure actual skinned geometry in Blender."""
from pathlib import Path
import bpy
import json
import math
import struct
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
EXPORT = ROOT/'Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb'
OUT = ROOT/'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll'
checks=[]
def check(name,ok,detail=None):
    checks.append({'name':name,'passed':bool(ok),'detail':detail})
    assert ok,(name,detail)
def glb(path):
    data=path.read_bytes()
    size,kind=struct.unpack_from('<II',data,12)
    assert kind==0x4e4f534a
    return json.loads(data[20:20+size])
doc=glb(EXPORT)
source=glb(ROOT/'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb')
def durations(doc):
    return {a['name']:max(doc['accessors'][s['input']]['max'][0] for s in a['samplers']) for a in doc['animations']}
original=durations(source); exported=durations(doc)
check('all 48 original named clips exported',set(original)==set(exported) and len(exported)==48)
check('clip durations within one source frame',max(abs(original[n]-exported[n]) for n in original)<1/30+.001)
check('62-joint game skin',len(doc['skins'])==1 and len(doc['skins'][0]['joints'])==62)
check('embedded textures',all('bufferView' in image for image in doc['images']))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(EXPORT))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=bpy.data.objects['Threadborne_Doll']
for track in rig.animation_data.nla_tracks: track.mute=True
check('no unweighted exported vertices',all(v.groups for v in body.data.vertices))
check('four or fewer influences',max(len(v.groups) for v in body.data.vertices)<=4)
error=max(abs(sum(g.weight for g in v.groups)-1) for v in body.data.vertices)
check('exported weights normalized',error<1e-5,error)
check('all weight targets exist',all(g.name in rig.data.bones for g in body.vertex_groups))
rigid={v.index:v.groups[0].group for v in body.data.vertices if len(v.groups)==1 and v.groups[0].weight>.99999}
edges=[]
for edge in body.data.edges:
    a,b=edge.vertices
    if a in rigid and b in rigid and rigid[a]==rigid[b]:
        distance=(body.data.vertices[a].co-body.data.vertices[b].co).length
        if distance>.001: edges.append((a,b,distance))
check('substantial rigid shell coverage',len(edges)>10000,len(edges))
samples=['idle_4','run_1','block_idle_1','slash_2','jump_1','roll_1','swimming_1','casting_2']
max_rigid_error=0
for name in samples:
    action=bpy.data.actions[name]
    rig.animation_data.action=action
    rig.animation_data.action_slot=action.slots[0]
    for fraction in [0,.35,.7,1]:
        start,end=action.frame_range
        frame=start+(end-start)*fraction
        bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
        graph=bpy.context.evaluated_depsgraph_get()
        evaluated=body.evaluated_get(graph)
        mesh=evaluated.to_mesh()
        check('finite skinned vertices: %s %.2f'%(name,fraction),all(math.isfinite(c) for v in mesh.vertices for c in v.co))
        error=max(abs((mesh.vertices[a].co-mesh.vertices[b].co).length-distance) for a,b,distance in edges)
        max_rigid_error=max(error,max_rigid_error)
        check('rigid shell edge lengths: %s %.2f'%(name,fraction),error<.0001,error)
        evaluated.to_mesh_clear()
report={'checks':checks,'count':len(checks),'export_vertices':len(body.data.vertices),
        'rigid_edges_checked_per_pose':len(edges),'maximum_rigid_edge_error_m':max_rigid_error,
        'note':'Rigid-shell edges only; blended finger joints intentionally deform. Visual grip and joint review is separate.'}
(OUT/'export_validation.json').write_text(json.dumps(report,indent=2))
print('DOLL_EXPORT_VERIFIED',len(checks),flush=True)
