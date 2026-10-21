"""Use the exact packed 4K Blender source maps with the approved GLB geometry."""
from pathlib import Path
import hashlib,json,re,shutil,struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ASSET=ROOT/'Assets/BlueBiome/Art/Lakeside3D'
SOURCE=ROOT/'outputs/central-tower-model-v1/textures'
provenance=json.loads((ASSET/'provenance.json').read_text())
remap={}
for material in ['walnut','plaster','blue_tiles','slate']:
    for channel in ['BaseColor','NormalGL','Roughness']:
        name=f'{material}_{channel}_4K.png'
        source=SOURCE/name
        assert Image.open(source).size==(4096,4096),name
        shutil.copy2(source,ASSET/'Textures'/name)
        old=f'{material}_{channel}_'+('4K.jpg' if channel=='BaseColor' else '2K.png')
        remap[old]=name
        provenance['textures'][name]={'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'bytes':source.stat().st_size,'source':str(source.relative_to(ROOT)),'dimensions':[4096,4096]}
for model in (ASSET/'Models').glob('*.glb'):
    raw=model.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+size]);tail=raw[20+size:]
    before_geometry=hashlib.sha256(tail).hexdigest()
    for im in doc['images']:
        old=Path(im['uri']).name
        im['uri']='../Textures/'+remap.get(old,old)
        im['name']=Path(im['uri']).stem
    encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    result=struct.pack('<4sII',b'glTF',2,20+len(encoded)+len(tail))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+tail
    assert hashlib.sha256(result[20+len(encoded):]).hexdigest()==before_geometry
    model.write_bytes(result)
    provenance['models'][model.stem]['runtime_bytes']=len(result)
    provenance['models'][model.stem]['geometry_binary_sha256']=before_geometry
for path in (ASSET/'Materials').glob('*.tres'):
    text=path.read_text()
    for old,new in remap.items():text=text.replace(old,new)
    path.write_text(text)
provenance['render_quality']={'maps':'Original 4096px Blender PNG color, normal and roughness maps, unchanged pixels','vram_compression':'high quality BC7/BPTC where supported','shared_by_all_buildings':True,'retained_legacy_files':'Old 2K runtime maps and JPEGs remain available but are not referenced by the building models'}
(ASSET/'provenance.json').write_text(json.dumps(provenance,indent=2))
print('ORIGINAL_BLENDER_4K_MAPS_RESTORED',len(remap),'GEOMETRY_UNCHANGED')
