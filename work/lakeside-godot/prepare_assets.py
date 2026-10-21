"""Copy approved model geometry, externalizing identical embedded texture bytes.

No geometry, UV, PBR values or texture pixels are changed. Run in the repository.
"""
import json, struct, hashlib, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Assets/BlueBiome/Art/Lakeside3D'
SCENES=ROOT/'Src/Environment/BlueBiome/Buildings/Lakeside3D'
for p in [OUT/'Models',OUT/'Textures',OUT/'Materials',SCENES]:p.mkdir(parents=True,exist_ok=True)
sources={
 'covered_boat_slip':ROOT/'outputs/lakeside-buildings-v1/models/CoveredBoatSlip.glb',
 'net_workshop':ROOT/'outputs/lakeside-buildings-v1/models/NetWorkshop_Exterior.glb',
 'fishers_house':ROOT/'outputs/lakeside-buildings-v1/models/FishersHouse_Exterior.glb',
 'central_tower':ROOT/'outputs/central-tower-model-v3/CentralTower_Exterior.glb',
}
image_hashes={};report={'models':{},'textures':{}}
canonical=None
for key,path in sources.items():
    raw=path.read_bytes();jlen=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+jlen]);binary=raw[28+jlen:]
    image_views=set()
    for im in doc['images']:
        idx=im['bufferView'];image_views.add(idx);bv=doc['bufferViews'][idx]
        image=binary[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']]
        fn=im['name']+('.jpg' if im['mimeType']=='image/jpeg' else '.png')
        digest=hashlib.sha256(image).hexdigest()
        if fn in image_hashes:assert image_hashes[fn]==digest,(fn,key)
        else:
            image_hashes[fn]=digest;(OUT/'Textures'/fn).write_bytes(image)
            report['textures'][fn]={'sha256':digest,'bytes':len(image)}
        del im['bufferView'];im['uri']='../Textures/'+fn
    new_views=[];remap={};newbin=bytearray()
    for i,bv in enumerate(doc['bufferViews']):
        if i in image_views:continue
        start=bv.get('byteOffset',0);length=bv['byteLength']
        while len(newbin)%4:newbin.append(0)
        remap[i]=len(new_views);newbv=dict(bv);newbv['byteOffset']=len(newbin)
        newbin.extend(binary[start:start+length]);new_views.append(newbv)
    def update_refs(v):
        if isinstance(v,dict):
            for k,x in v.items():
                if k=='bufferView':v[k]=remap[x]
                else:update_refs(x)
        elif isinstance(v,list):
            for x in v:update_refs(x)
    update_refs(doc);doc['bufferViews']=new_views;doc['buffers']=[{'byteLength':len(newbin)}]
    if key=='net_workshop':canonical=json.loads(json.dumps(doc))
    jb=json.dumps(doc,separators=(',',':')).encode();jb+=b' '*((-len(jb))%4)
    newbin+=b'\0'*((-len(newbin))%4)
    final=struct.pack('<4sII',b'glTF',2,28+len(jb)+len(newbin))+struct.pack('<II',len(jb),0x4e4f534a)+jb+struct.pack('<II',len(newbin),0x004e4942)+newbin
    dest=OUT/'Models'/(key+'.glb');dest.write_bytes(final)
    report['models'][key]={'source':str(path.relative_to(ROOT)),'source_bytes':len(raw),'runtime_bytes':len(final),'geometry_uv_material_values_preserved':True}
    label=''.join(s.title() for s in key.split('_'))
    text=f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_building_3d.gd" id="1"]
[ext_resource type="PackedScene" path="res://Assets/BlueBiome/Art/Lakeside3D/Models/{key}.glb" id="2"]

[node name="{label}3D" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]
'''
    (SCENES/(key+'_3d.tscn')).write_text(text)

# Canonical converted PBR material for the test deck and lantern. House GLBs
# keep the original glTF materials, sharing the same external image resources.
for mat in canonical['materials']:
    key=mat['name'];pbr=mat.get('pbrMetallicRoughness',{});res=[];props=[]
    def texture(info,label):
        texture=canonical['textures'][info['index']]
        im=canonical['images'][texture['source']]
        fn=Path(im['uri']).name
        res.append(f'[ext_resource type="Texture2D" path="res://Assets/BlueBiome/Art/Lakeside3D/Textures/{fn}" id="{label}"]')
        return f'ExtResource("{label}")'
    props.append('resource_name = "'+key+'"')
    color=pbr.get('baseColorFactor',[1,1,1,1]);props.append('albedo_color = Color('+', '.join(map(str,color))+')')
    props.append('metallic = '+str(pbr.get('metallicFactor',1)))
    props.append('roughness = '+str(pbr.get('roughnessFactor',1)))
    if 'baseColorTexture' in pbr:props.append('albedo_texture = '+texture(pbr['baseColorTexture'],'color'))
    if 'metallicRoughnessTexture' in pbr:
        props.append('roughness_texture = '+texture(pbr['metallicRoughnessTexture'],'roughness'))
        props.append('roughness_texture_channel = 1')
    if 'normalTexture' in mat:
        props+=['normal_enabled = true','normal_scale = '+str(mat['normalTexture'].get('scale',1)),'normal_texture = '+texture(mat['normalTexture'],'normal')]
    (OUT/'Materials'/(key+'.tres')).write_text('[gd_resource type="StandardMaterial3D" load_steps='+str(len(res)+1)+' format=3]\n\n'+'\n'.join(res)+'\n\n[resource]\n'+'\n'.join(props)+'\n')
report['checks_passed']=True
(OUT/'provenance.json').write_text(json.dumps(report,indent=2))
print('ASSETS_READY',json.dumps({k:v['runtime_bytes'] for k,v in report['models'].items()}),'SHARED_MAPS',len(image_hashes))

# A matching official runtime in scratch; headless commands never open a window.
runtime=ROOT/'work/lakeside-godot/runtime'
if not (runtime/'Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe').exists():
    runtime.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile('C:/Users/chase/Downloads/Godot_v4.7.2-stable_mono_win64.zip') as z:z.extractall(runtime)
print('HEADLESS_RUNTIME_READY')
