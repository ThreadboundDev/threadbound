"""Stage exact downloaded sources for the isolated demo; never run package code.

CC0 inputs and private Fab inputs remain separate. No source archives are changed.
"""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
TEMP = WORK / 'temp/polish'
LIBRARY = Path.home() / 'Documents/Threadbound Asset Library/archives'
DOWNLOADS = Path.home() / 'Downloads'
MANIFEST = []


def extract(archive, predicate, folder):
    with zipfile.ZipFile(archive) as source:
        for name in source.namelist():
            if not predicate(name) or name.endswith('/'):
                continue
            destination = TEMP / folder / name
            if not destination.resolve().is_relative_to(TEMP.resolve()):
                raise ValueError('Unsafe archive member')
            data = source.read(name)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
            MANIFEST.append(dict(archive=archive.name, member=name,
                                 sha256=hashlib.sha256(data).hexdigest(),
                                 local=destination.relative_to(WORK).as_posix()))


def main():
    TEMP.mkdir(parents=True, exist_ok=True)
    for pack, folder in [('Universal Animation Library[Standard].zip', 'ual1'),
                         ('Universal Animation Library 2[Standard].zip', 'ual2')]:
        extract(LIBRARY / pack, lambda n: n.endswith(('UAL1_Standard.glb', 'UAL2_Standard.glb')), folder)
    extract(LIBRARY / 'Modular Character Outfits - Fantasy[Standard].zip',
            lambda n: 'glTF (Godot-Unreal)' in n, 'outfits')
    extract(LIBRARY / 'Fantasy Props MegaKit[Standard].zip', lambda n: 'gltf' in n.lower(), 'props')
    extract(LIBRARY / 'KayKit_FantasyWeaponsBits_1.0_FREE.zip',
            lambda n: n.lower().endswith(('.gltf', '.bin', '.png')) and 'gltf' in n.lower(), 'weapons')
    # The user's explicitly requested Fab boss stays local, never inside a public commit.
    extract(DOWNLOADS / 'mesh.zip', lambda n: n == 'Mesh/StoneGolem.fbx', 'golem')
    clips = {'idle1', 'walkF', 'jogF', 'attack1', 'attack2', 'attack3', 'attack4', 'attack5', 'gethit1', 'death1'}
    extract(DOWNLOADS / 'animations.zip',
            lambda n: n.endswith('.fbx') and Path(n).stem.split('@')[-1] in clips, 'golem')
    extract(DOWNLOADS / 'textures.zip',
            lambda n: n.endswith('.tga') and any(n.endswith('_'+s+'.tga') for s in ['Albedo_Skin1', 'Roughness', 'Metallic']), 'golem')
    # User confirmed website downloads: FreeStylized's website commercial-use terms.
    # Custom redistribution restrictions still keep these derivatives local.
    for pack in ['Ruins1_(AssetPack4).zip', 'Rocks1_(AssetPack2).zip', 'StarterNaturePack_(FoliageKit1).zip']:
        extract(DOWNLOADS / pack, lambda n: '/FBX_Textures/' in n and n.endswith(('.fbx', '.png')), 'stylized')
    for filename in ['threadborne_authored_attacks.glb']:
        destination = WORK / 'project/assets' / filename
        source = ROOT / 'Assets/Threadborne/Player/Equipped3DTest' / filename
        shutil.copyfile(source, destination)
        MANIFEST.append(dict(source=source.relative_to(ROOT).as_posix(), target=destination.relative_to(WORK).as_posix(),
                             sha256=hashlib.sha256(source.read_bytes()).hexdigest()))
    (WORK / 'polish_source_manifest.json').write_text(json.dumps(MANIFEST, indent=2)+'\n', encoding='utf-8')
    print(f'Staged {len(MANIFEST)} selected source members; originals unchanged.')


if __name__ == '__main__':
    main()
