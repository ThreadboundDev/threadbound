"""Check the saved, editable Blender asset rather than the builder's assumptions."""
from pathlib import Path
import bpy,json,math
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'EaveRunner_Woven_v1.blend'))
rig=bpy.data.objects['EaveRunner_Rig'];actor=bpy.data.objects['EaveRunner_TexturedMesh'];scene=bpy.context.scene
report=json.loads((SOURCE/'build_report.json').read_text());failures=[];checks=0
def check(ok,message):
    global checks
    checks+=1
    if not ok:failures.append(message)
check(len(rig.data.bones)==60,'Sixty deform bones survive the saved source')
check(sum(b.name.startswith('tail_') for b in rig.data.bones)==6,'Six cloth-tail bones')
check(not any(pb.constraints for pb in rig.pose.bones),'Runtime skeleton has no live authoring IK constraints')
check(all(abs(sum(g.weight for g in v.groups)-1)<.0003 for v in actor.data.vertices),'Every mesh vertex has normalized deform weights')
check(all(0<len(v.groups)<=4 for v in actor.data.vertices),'Four or fewer nonempty weights per vertex')
check(all(actor.vertex_groups[g.group].name in rig.data.bones for v in actor.data.vertices for g in v.groups),'Weights reference real bones')
images=[i for i in bpy.data.images if i.source=='FILE']
check(all(i.packed_file for i in images),'All file textures are packed in the Blender source')
check(all(min(i.size)>=1024 for i in images),'All surface-detail images are at least 1024 square')
check(sum(len(p.vertices)-2 for p in actor.data.polygons)==report['triangles'],'Reported triangle count matches saved geometry')
clip_data=[]
for spec in report['clips']:
    action=bpy.data.actions.get(spec['name']);check(action is not None,spec['name']+' exists')
    if not action:continue
    rig.animation_data.action=action;start,end=action.frame_range;scene.frame_set(round(start))
    initial={b.name:b.matrix.copy() for b in rig.pose.bones}
    scene.frame_set(round(start+(end-start)*.5));middle={b.name:b.matrix.copy() for b in rig.pose.bones}
    movement=max((initial[n].translation-middle[n].translation).length for n in initial)
    check(movement>.001,spec['name']+' moves the deform rig')
    scene.frame_set(round(end));ending={b.name:b.matrix.copy() for b in rig.pose.bones}
    if spec['loop']:
        error=max(max(abs(initial[n][r][c]-ending[n][r][c]) for r in range(4) for c in range(4)) for n in initial)
        check(error<.0002,spec['name']+' has matching loop endpoints')
    bounds=[]
    for fraction in [0,.25,.5,.75,1]:
        scene.frame_set(round(start+(end-start)*fraction));evaluated=actor.evaluated_get(bpy.context.evaluated_depsgraph_get())
        points=[v.co for v in evaluated.data.vertices]
        check(all(math.isfinite(co) for p in points for co in p),spec['name']+' finite skinned coordinates')
        extent=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
        check(max(extent)<3.1,spec['name']+' stays within plausible skinned bounds')
        bounds.append(extent)
    clip_data.append({'name':spec['name'],'frames':[start,end],'max_bone_motion':movement,'bounds':bounds})
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)
result={'passed':not failures,'checks':checks,'failures':failures,'triangles':report['triangles'],'bones':60,
 'packed_images':len(images),'packed_image_bytes':sum(len(i.packed_file.data) for i in images if i.packed_file),
 'source_bytes':(SOURCE/'EaveRunner_Woven_v1.blend').stat().st_size,'clips':clip_data}
(ROOT/'work/eave-runner/source_verification.json').write_text(json.dumps(result,indent=2))
print('EAVE_RUNNER_SOURCE_VERIFIED',json.dumps({k:v for k,v in result.items() if k!='clips'}),flush=True)
if failures:raise RuntimeError('; '.join(failures))
