from pathlib import Path
import bpy,json
R=Path.cwd();bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(R/'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rig.animation_data_clear();rig.data.pose_position='REST'
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
def bounds(pts):return [[min(p[i] for p in pts),max(p[i] for p in pts)] for i in range(3)]
data={'rig':rig.name,'matrix':list(map(list,rig.matrix_world)),'bones':{b.name:[list(rig.matrix_world@b.head_local),list(rig.matrix_world@b.tail_local)] for b in rig.data.bones if b.name in ['head','neck','chest','spine','pelvis','upper_arm.L','upper_arm.R','thigh.L','shin.L','foot.L']},'meshes':[]}
for o in meshes:
    o.modifiers.clear()
    pts=[o.matrix_world@v.co for v in o.data.vertices]
    data['meshes'].append({'name':o.name,'verts':len(pts),'bounds':bounds(pts),'materials':[m.name for m in o.data.materials]})
(R/'work/eave-runner-v3/player_reference_measurements.json').write_text(json.dumps(data,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(R/'work/eave-runner-v3/player_reference_only.blend'),compress=True)
print('PLAYER_REFERENCE_DATA',json.dumps(data),flush=True)
