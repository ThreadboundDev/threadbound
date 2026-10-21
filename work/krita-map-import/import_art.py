from pathlib import Path
import shutil, sys
ROOT=Path(__file__).resolve().parents[2]
SANDBOX=ROOT/'work/krita-map-import/import_project'
REL=Path('Assets/BlueBiome/Art/LakesideMap')
if sys.argv[-1]=='prepare':
    (SANDBOX/REL).mkdir(parents=True,exist_ok=True)
    for p in (ROOT/REL).glob('*.png'):shutil.copy2(p,SANDBOX/REL/p.name)
    (SANDBOX/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Krita map art import"\nconfig/features=PackedStringArray("4.7", "Forward Plus")\n[threading]\nworker_pool/max_threads=2\n')
elif sys.argv[-1]=='configure':
    for p in (SANDBOX/REL).glob('*.import'):
        s=p.read_text().replace('compress/mode=0','compress/mode=2').replace('mipmaps/generate=false','mipmaps/generate=true')
        p.write_text(s)
elif sys.argv[-1]=='install':
    for p in (SANDBOX/REL).glob('*.import'):shutil.copy2(p,ROOT/REL/p.name)
    for p in (SANDBOX/'.godot/imported').iterdir():
        if p.is_file():shutil.copy2(p,ROOT/'.godot/imported'/p.name)
print('MAP_IMPORT',sys.argv[-1])
