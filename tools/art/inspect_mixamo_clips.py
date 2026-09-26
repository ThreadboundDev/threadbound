import bpy,json
from pathlib import Path
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
out.mkdir(exist_ok=True)
report=[]
for label in ['Idle','Run','Jump']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath='C:/Users/chase/Downloads/Sword And Shield '+label+'.fbx')
    item={'clip':label,'fps':bpy.context.scene.render.fps,'objects':[]}
    for o in bpy.context.scene.objects:
        d={'name':o.name,'type':o.type,'scale':list(o.scale)}
        if o.type=='MESH':d.update(vertices=len(o.data.vertices),materials=[m.name for m in o.data.materials if m])
        if o.type=='ARMATURE':
            d['bones']=[{'name':b.name,'head':list(o.matrix_world@b.head_local),'tail':list(o.matrix_world@b.tail_local)} for b in o.data.bones]
            if o.animation_data and o.animation_data.action:d['action']={'name':o.animation_data.action.name,'range':list(o.animation_data.action.frame_range)}
        item['objects'].append(d)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(label+'_import.blend')))
    report.append(item)
(out/'inspection.json').write_text(json.dumps(report,indent=2))
print('CLIP_INSPECTION',json.dumps(report),flush=True)
