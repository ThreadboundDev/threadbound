"""Stage selected retained assets for the independent third-person Godot study."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
PROJECT = WORK / 'project'
LIBRARY = Path.home() / 'Documents/Threadbound Asset Library/archives'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / '.gdignore').write_text('')
    for folder in ['assets', 'assets/licenses', 'scripts', 'scenes', 'tests']:
        (PROJECT / folder).mkdir(parents=True, exist_ok=True)
    source = ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'
    target = WORK / 'temp/threadborne_original.glb'
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    records = [dict(source=str(source.relative_to(ROOT)), sha256=digest(source),
                    license='Existing Threadbound player; unchanged character identity; existing provenance applies')]
    for archive, wanted, destination in [
        ('KayKit_FantasyWeaponsBits_1.0_FREE.zip', ['sword_B.gltf', 'sword_B.bin', 'shield_B.gltf', 'shield_B.bin', 'weapons_bits_texture.png'], WORK / 'temp/weapons'),
        ('kenney_nature-kit_OGA_2.1.zip', ['tree_pineTallA_detailed.obj', 'tree_pineTallA_detailed.mtl', 'tree_detailed.obj', 'tree_detailed.mtl', 'plant_bushLarge.obj', 'plant_bushLarge.mtl', 'rock_largeD.obj', 'rock_largeD.mtl', 'rock_smallFlatA.obj', 'rock_smallFlatA.mtl'], WORK / 'temp/nature'),
    ]:
        path = LIBRARY / archive
        with zipfile.ZipFile(path) as bundle:
            assert bundle.testzip() is None, archive
            licenses = [n for n in bundle.namelist() if Path(n).name.lower() == 'license.txt']
            assert licenses
            license_text = bundle.read(licenses[0]).decode('utf-8-sig')
            assert 'CC0' in license_text or 'Creative Commons Zero' in license_text
            license_path = PROJECT / 'assets/licenses' / (Path(archive).stem + '.txt')
            license_path.write_text(license_text, encoding='utf-8')
            destination.mkdir(parents=True, exist_ok=True)
            members = []
            for member in bundle.namelist():
                matches = [n for n in wanted if Path(n).name == Path(member).name]
                if not matches:
                    continue
                if archive.startswith('kenney_') and not member.startswith('Models/OBJ format/'):
                    continue
                # For named models prefer the glTF/GLB version only.
                out = destination / matches[0]
                out.parent.mkdir(parents=True, exist_ok=True)
                blob = bundle.read(member)
                out.write_bytes(blob)
                members.append(dict(member=member, sha256=digest(out)))
            assert {Path(n).name for n in wanted} <= {Path(n['member']).name for n in members}, archive
        page = 'https://opengameart.org/content/nature-kit' if archive.startswith('kenney_') else 'https://kaylousberg.itch.io/fantasy-weapons-bits'
        records.append(dict(archive=archive, sha256=digest(path), license='CC0', crc='pass', source_page=page, selected=members))
    license_folder = ROOT / 'work/cc0-house-villager-2026-10-28/licenses'
    for path in license_folder.iterdir():
        if path.is_file():
            shutil.copyfile(path, PROJECT / 'assets/licenses' / path.name)
    for path in (PROJECT / 'assets/licenses').glob('*.txt'):
        text = path.read_text(encoding='utf-8-sig')
        path.write_text('\n'.join(line.rstrip() for line in text.splitlines()).strip() + '\n', encoding='utf-8')
    shutil.copyfile(ROOT / 'work/cc0-house-villager-2026-10-28/source_manifest.json', PROJECT / 'assets/workshop_source_manifest.json')
    records.append(dict(source='work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend',
                        sha256=digest(ROOT / 'work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend'),
                        license='Retained CC0 sources plus Threadbound authored assembly and work motion',
                        source_manifest='workshop_source_manifest.json'))
    (PROJECT / 'assets/provenance.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
    print('Staged retained player, two weapon models, five CC0 nature models and source notices.')


if __name__ == '__main__':
    main()
