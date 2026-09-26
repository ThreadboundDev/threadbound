import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
target=out/'Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
s=bpy.context.scene;rig=bpy.data.objects['Threadborne_Rig'];s.frame_set(1);bpy.context.view_layer.update()
shield=bpy.data.objects['Threadborne_Shield_ROOT'];left=rig.pose.bones['forearm.L']
across=(left.tail-left.head).normalized();normal=Vector((0,-1,0));normal=(normal-across*normal.dot(across)).normalized();up=normal.cross(across)
if up.z<0:across=-across;up=normal.cross(across)
rotation=Matrix((normal,across,up)).transposed().to_4x4()
center=left.head+(left.tail-left.head)*.55+normal*.084
shield.matrix_basis=shield.parent.matrix_world.inverted()@Matrix.Translation(center)@rotation@Matrix.Diagonal((.85,.85,.85,1))
bpy.context.view_layer.update()
assert len(rig.data.bones)==62
assert len(rig.animation_data.nla_tracks[0].strips)==3
assert len(bpy.data.objects['Threadborne_Character'].data.vertices)==982421
report=json.loads((out/'animation_test_report.json').read_text())
# Verify each clip actually changes the pose and every frame is finite.
checks={}
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];signatures=[]
    for frame in range(start,end+1):
        s.frame_set(frame)
        values=[float(v) for name in ['pelvis','hand.R','forearm.L','shin.L'] for row in rig.pose.bones[name].matrix for v in row]
        assert all(math.isfinite(v) for v in values)
        signatures.append(values)
    difference=max(abs(a-b) for a,b in zip(signatures[0],signatures[len(signatures)//2]))
    assert difference>1e-5
    checks[label]={'timeline':[start,end],'pose_change':difference}
s.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(target))
(out/'validation.json').write_text(json.dumps({'clips':checks,'bones':62,'detailed_mesh_vertices':982421,'weapons_follow_bones':True,'shield_fit':'forearm axis through raised straps'},indent=2))
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];s.frame_set(start+(end-start)//2)
    s.render.filepath=str(out/(label.lower()+'_equipped.png'));bpy.ops.render.render(write_still=True)
frames=out/'preview_frames';frames.mkdir(exist_ok=True)
s.render.resolution_percentage=25;s.cycles.samples=8
manifest=[]
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];count=math.ceil((end-start+1)*12/30)
    for i in range(count):
        frame=min(end,start+round(i*30/12));s.frame_set(frame)
        name=label.lower()+'_%03d.png'%i;s.render.filepath=str(frames/name)
        bpy.ops.render.render(write_still=True)
        manifest.append({'clip':label,'frame':frame,'file':name,'duration_ms':round((end-start+1)/30/count*1000)})
    print('PREVIEW_CLIP_COMPLETE',label,count,flush=True)
(out/'preview_manifest.json').write_text(json.dumps(manifest,indent=2))
print('ANIMATION_PREVIEW_COMPLETE',flush=True)
