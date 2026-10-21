"""Install caches/metadata only for this task's new model/texture directories."""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[2]
SANDBOX=ROOT/'work/lakeside-godot/sandbox'
new_asset=Path('Assets/BlueBiome/Art/Lakeside3D')
cache=ROOT/'.godot/imported';cache.mkdir(parents=True,exist_ok=True)
copied=[]
for sidecar in (SANDBOX/new_asset).rglob('*.import'):
    rel=sidecar.relative_to(SANDBOX)
    shutil.copy2(sidecar,ROOT/rel)
for source in (SANDBOX/'.godot/imported').iterdir():
    if not source.is_file():continue
    if source.name.startswith('wing_light_falloff'):continue
    assert source.name.startswith(('blue_tiles_','plaster_','slate_','walnut_','central_tower.','covered_boat_slip.','fishers_house.','net_workshop.')),source.name
    shutil.copy2(source,cache/source.name);copied.append(source.name)
print('NEW_ASSET_CACHES_INSTALLED',len(copied))
