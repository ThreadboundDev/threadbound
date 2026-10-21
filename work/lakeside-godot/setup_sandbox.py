"""Import only new art in an isolated, plugin-free headless Godot project.

The production editor and its unsaved scenes are never opened or saved.
"""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[2]
SANDBOX=ROOT/'work/lakeside-godot/sandbox'
folders=['Assets/BlueBiome/Art/Lakeside3D','Src/Environment/BlueBiome/Buildings/Lakeside3D']
for rel in folders:
    src=ROOT/rel;dst=SANDBOX/rel
    dst.mkdir(parents=True,exist_ok=True)
    for file in src.rglob('*'):
        if not file.is_file() or file.suffix in ['.import','.uid']:continue
        out=dst/file.relative_to(src);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,out)
rel=Path('Src/Environment/WingLighting/wing_light_falloff.png')
(SANDBOX/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,SANDBOX/rel)
(SANDBOX/'project.godot').write_text('''config_version=5
[application]
config/name="Lakeside headless asset validation"
config/features=PackedStringArray("4.7", "Forward Plus")
[threading]
worker_pool/max_threads=2
''')
(SANDBOX/'api_probe.gd').write_text('''extends SceneTree
func _initialize() -> void:
 print("AMBIENT_COLOR=", Environment.AMBIENT_SOURCE_COLOR, " REFLECTION_DISABLED=", Environment.REFLECTED_SOURCE_DISABLED)
 print("HEADLESS=", DisplayServer.get_name(), " AUDIO=", AudioServer.get_driver_name())
 quit()
''')
print('SANDBOX_READY',SANDBOX)
