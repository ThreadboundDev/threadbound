"""Validate saved v2 source geometry, weights, all clips and scale against v1."""
from pathlib import Path
import bpy,json,math
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/character-quality-v2';checks=0;failures=[];rows={}
def check(ok,message):
    global checks
    checks+=1
    if not ok:failures.append(message)
def bonesnap(rig):return {p.name:p.matrix.copy() for p in rig.pose.bones}
for family,file,kinds in [('Villagers','LakesideVillagers_v2.blend',['NetMender','Boatwright']),('Enemies/EaveRunner','EaveRunner_Woven_v2.blend',['EaveRunner']),('Enemies/LoomHeron','LoomHeron_Woven_v2.blend',['LoomHeron'])]:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome'/family/file))
    images=[im for im in bpy.data.images if im.source=='FILE' or im.name.endswith('_4K')]
    check(all(im.packed_file for im in images),family+' file maps are packed')
    for kind in kinds:
        rig=next(o for o in bpy.data.objects if o.type=='ARMATURE' and kind in o.name);scene=rig.users_scene[0];bpy.context.window.scene=scene;meshes=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
        tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
        old={'NetMender':39390,'Boatwright':40146,'EaveRunner':66052,'LoomHeron':24488}[kind]
        check(tris>old*3.7,kind+' has substantially more surface geometry')
        check(all(len(v.groups)>0 and abs(sum(g.weight for g in v.groups)-1)<.0002 for o in meshes for v in o.data.vertices),kind+' normalized deform weights')
        check(all(len(v.groups)<=4 for o in meshes for v in o.data.vertices),kind+' four or fewer skin influences')
        check(all(o.vertex_groups[g.group].name in rig.data.bones for o in meshes for v in o.data.vertices for g in v.groups),kind+' weights reference valid bones')
        expected=163 if kind in ['NetMender','Boatwright'] else 60 if kind=='EaveRunner' else 18
        check(len(rig.data.bones)==expected,kind+' complete rig retained')
        check(all(o.data.uv_layers for o in meshes),kind+' editable UVs retained')
        if kind=='LoomHeron':clips=['idle','flight','perch','needle_aim','needle_fire','low_recover','hurt','death']
        elif kind=='EaveRunner':clips=['idle','run','wall_attach','wall_perch','wall_windup','wall_launch','jump_slash','land_recover','throw_windup','throw_release','hurt','death']
        else:clips=['WorkIdle'+('.001' if kind=='Boatwright' else ''),'TalkIdle'+('.001' if kind=='Boatwright' else '')]
        cliprows=[]
        for name in clips:
            a=bpy.data.actions.get(name);check(a is not None,kind+' '+name+' exists')
            if not a:continue
            rig.animation_data.action=a;start,end=a.frame_range;scene.frame_set(round(start));initial=bonesnap(rig);motion=0;maxspan=0
            for t in [0,.25,.5,.75,1]:
                scene.frame_set(round(start+(end-start)*t));deps=bpy.context.evaluated_depsgraph_get()
                for p in rig.pose.bones:motion=max(motion,max(abs(p.matrix[r][c]-initial[p.name][r][c]) for r in range(4) for c in range(4)))
                points=[v.co.copy() for o in meshes for v in o.evaluated_get(deps).data.vertices]
                check(all(math.isfinite(x) for p in points for x in p),kind+' '+name+' finite skinned geometry')
                span=max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3));maxspan=max(maxspan,span)
                check(span<(4.6 if kind=='LoomHeron' else 3.1),kind+' '+name+' plausible skin deformation bounds')
            check(motion>.001,kind+' '+name+' actual animation motion')
            if name in ['idle','flight','perch','run','wall_perch'] or 'Idle' in name:
                final=bonesnap(rig);error=max(max(abs(final[n][r][c]-initial[n][r][c]) for r in range(4) for c in range(4)) for n in initial)
                check(error<.0003,kind+' '+name+' loop endpoints match')
            cliprows.append({'name':name,'seconds':(end-start)/30,'motion':motion,'maximum_span':maxspan})
        rig.animation_data.action=bpy.data.actions[clips[0]];scene.frame_set(1)
        rows[kind]={'triangles':tris,'previous_triangles':old,'bones':len(rig.data.bones),'clips':cliprows,'packed_images':len(images)}
result={'passed':not failures,'checks':checks,'failures':failures,'characters':rows};(WORK/'source_verification.json').write_text(json.dumps(result,indent=2));print('CHARACTER_V2_SOURCE_CHECKS',checks,'failures=',failures,flush=True)
if failures:raise RuntimeError('; '.join(failures))
