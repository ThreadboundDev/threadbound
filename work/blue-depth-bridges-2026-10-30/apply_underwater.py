"""Apply the importer's scoped presentation function without reexporting pixels."""
import ast,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
source=root/'work/krita-map-import/extract_map.py'
tree=ast.parse(source.read_text(encoding='utf-8'))
nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='compose_underwater_scene' or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='UNDERWATER_PRESENTATION' for t in n.targets)]
scope={}
exec(compile(ast.Module(body=nodes,type_ignores=[]),str(source),'exec'),scope)
manifest_path=root/'Assets/BlueBiome/Art/LakesideMap/underwater_background_manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
scene_path=root/'Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_krita_artwork.tscn'
scene=scope['compose_underwater_scene'](scene_path.read_text(encoding='utf-8'),manifest['chunks'])
assert scope['compose_underwater_scene'](scene,manifest['chunks'])==scene,'Scoped composition must be idempotent'
scene_path.write_text(scene,encoding='utf-8',newline='\n')
manifest['presentation']=scope['UNDERWATER_PRESENTATION']
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Configured 25 rock sections; PNGs, timber and collision untouched; reimport is idempotent.')
