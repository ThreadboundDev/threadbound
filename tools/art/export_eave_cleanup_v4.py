"""Export only the new candidate, with explicit source PBR factors."""
from pathlib import Path
import bpy,json,struct
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/eave-runner-v4'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v4.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig']
factors={}
for material in bpy.data.materials:
    if not material.use_nodes:continue
    bs=material.node_tree.nodes.get('Principled BSDF')
    if not bs:continue
    color=list(bs.inputs['Base Color'].default_value)
    links=list(bs.inputs['Base Color'].links)
    if links and links[0].from_node.type=='MIX_RGB':
        color=list(links[0].from_node.inputs[2].default_value)
    normal=next((n.inputs['Strength'].default_value for n in material.node_tree.nodes if n.type=='NORMAL_MAP'),1.0)
    factors[material.name]={'baseColorFactor':color,'normal_scale':normal}
# Join only export copies in this background process. The saved native source
# stays in editable semantic components and is never overwritten here.
actors=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
for material in {m for o in actors for m in o.data.materials}:
    objects=[o for o in list(scene.objects) if o.type=='MESH' and o.parent==rig and len(o.data.materials)==1 and o.data.materials[0]==material]
    if len(objects)<2:continue
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in scene.objects:
    if obj.type=='MESH' and obj.parent==rig:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
target=WORK/'EaveRunner_v4.glb'
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,use_active_scene=True,
    export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)
data=target.read_bytes();magic,version,length=struct.unpack_from('<III',data)
assert magic==0x46546c67 and length==len(data)
size,kind=struct.unpack_from('<II',data,12);document=json.loads(data[20:20+size])
offset=20+size;binary_size,binary_kind=struct.unpack_from('<II',data,offset);binary=data[offset+8:offset+8+binary_size]
for material in document['materials']:
    if material.get('name') in factors:
        source=factors[material['name']]
        material.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=source['baseColorFactor']
        if 'normalTexture' in material:material['normalTexture']['scale']=source['normal_scale']
    material['doubleSided']=True
encoded=json.dumps(document,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
binary+=b'\0'*(-len(binary)%4)
rebuilt=struct.pack('<III',magic,version,28+len(encoded)+len(binary))
rebuilt+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(binary),binary_kind)+binary
target.write_bytes(rebuilt)
report={'candidate':True,'model':'work/eave-runner-v4/EaveRunner_v4.glb','bytes':len(rebuilt),
        'triangles':sum(document['accessors'][p['indices']]['count']//3 for m in document['meshes'] for p in m['primitives']),
        'skins':[len(s['joints']) for s in document['skins']], 'meshes':len(document['meshes']),
        'materials':len(document['materials']), 'embedded_images':len(document.get('images',[])),
        'animations':[a['name'] for a in document['animations']], 'active_replacement':False}
(WORK/'export_report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('EAVE_V4_EXPORT',json.dumps(report),flush=True)
