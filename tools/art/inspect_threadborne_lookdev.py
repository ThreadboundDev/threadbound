import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
s=bpy.context.scene
data={
 'engine':s.render.engine,
 'color_management':{'display':s.display_settings.display_device,'view':s.view_settings.look,'exposure':s.view_settings.exposure,'gamma':s.view_settings.gamma},
 'world':s.world.color[:] if s.world else None,
 'lights':[], 'materials':[]}
for o in s.objects:
 if o.type=='LIGHT':data['lights'].append({'name':o.name,'type':o.data.type,'energy':o.data.energy,'color':o.data.color[:],'location':o.location[:]})
for m in bpy.data.materials:
 if m and m.use_nodes:
  p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
  if p:data['materials'].append({'name':m.name,'base':p.inputs['Base Color'].default_value[:],'roughness':p.inputs['Roughness'].default_value})
out=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_test/lookdev_inspection.json'
out.write_text(json.dumps(data,indent=2,default=list));print(json.dumps(data,indent=2,default=list),flush=True)
