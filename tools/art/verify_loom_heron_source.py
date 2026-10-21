"""Sample saved skinned geometry, weights, packed textures and every animation."""
from pathlib import Path
import bpy, json, math
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron'
bpy.ops.wm.open_mainfile(filepath=str(SRC/'LoomHeron_Woven_v1.blend'))
rig=bpy.data.objects['LoomHeron_Rig'];scene=bpy.context.scene
actors=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
report=json.loads((SRC/'build_report.json').read_text());failures=[];checks=0
def check(ok,message):
    global checks
    checks+=1
    if not ok:failures.append(message)
check(len(rig.data.bones)==17,'Seventeen deform bones retained')
check(len(actors)==8,'Eight material surfaces retained')
check(all(v.groups and abs(sum(g.weight for g in v.groups)-1)<.0001 for o in actors for v in o.data.vertices),'Every vertex has normalized skin weights')
check(all(o.vertex_groups[g.group].name in rig.data.bones for o in actors for v in o.data.vertices for g in v.groups),'All weights reference deform bones')
images=[i for i in bpy.data.images if i.source=='FILE']
check(all(i.packed_file for i in images),'Every surface image is packed')
check(all(min(i.size)>=1024 for i in images),'High detail images are at least 1024 square')
check(sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in actors)==report['triangles'],'Triangle report matches source')
clips=[]
for name,duration in report['clips'].items():
    a=bpy.data.actions.get(name);check(a is not None,name+' exists')
    if not a:continue
    rig.animation_data.action=a;start,end=a.frame_range;scene.frame_set(int(start));initial={p.name:p.matrix.copy() for p in rig.pose.bones}
    motion=0
    for fraction in [.25,.5,.75]:
        scene.frame_set(round(start+(end-start)*fraction))
        motion=max(motion,max(max(abs(p.matrix[r][c]-initial[p.name][r][c]) for r in range(4) for c in range(4)) for p in rig.pose.bones))
    check(motion>.001,name+' actually moves bones')
    scene.frame_set(int(end));error=max(max(abs(initial[p.name][r][c]-p.matrix[r][c]) for r in range(4) for c in range(4)) for p in rig.pose.bones)
    if name in ['idle','flight','perch']:check(error<.0002,name+' loop joins exactly')
    for fraction in [0,.25,.5,.75,1]:
        scene.frame_set(round(start+(end-start)*fraction));deps=bpy.context.evaluated_depsgraph_get()
        points=[v.co.copy() for o in actors for v in o.evaluated_get(deps).data.vertices]
        check(all(math.isfinite(q) for p in points for q in p),name+' finite deformed coordinates')
        span=max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
        check(span<4.6,name+' plausible deformed bounds')
    clips.append({'name':name,'seconds':(end-start)/30,'maximum_joint_motion':motion})
result={'passed':not failures,'checks':checks,'failures':failures,'triangles':report['triangles'],'bones':17,'packed_images':len(images),'clips':clips}
(ROOT/'work/loom-heron/source_verification.json').write_text(json.dumps(result,indent=2))
print('LOOM_HERON_SOURCE_VERIFIED',json.dumps(result),flush=True)
if failures:raise RuntimeError('; '.join(failures))
