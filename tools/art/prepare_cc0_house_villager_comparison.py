"""Extract only selected CC0 comparison inputs, verifying original ZIP hashes."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import posixpath
from urllib.parse import unquote
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/cc0-house-villager-2026-10-28'
LIBRARY = Path('C:/Users/chase/Documents/Threadbound Asset Library/archives')
SELECTION = {
    'P03': ['Workbench', 'Bucket_Wooden_1', 'Rope_1', 'Crate_Wooden', 'Lantern_Wall'],
    'P07': ['Textiles_Stack_Small', 'Wood_Planks_Stack_Small'],
    'P09': ['Wall_Plaster_Straight', 'Wall_Plaster_Window_Wide_Round',
            'Wall_Plaster_Door_Round', 'DoorFrame_Round_WoodDark', 'Door_1_Round',
            'Floor_WoodDark', 'Roof_RoundTiles_4x6', 'Roof_Front_Brick4',
            'Roof_Support2', 'Prop_Support', 'Window_Wide_Round1'],
    'P10': ['Male_Peasant'],
    'P12': ['UAL1_Standard'],
    'P13': ['Superhero_Male_FullBody', 'Hair_SimpleParted', 'Hair_Beard'],
}


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / '.gdignore').write_text('', encoding='utf-8')
    manifests = json.loads((ROOT / 'docs/assets/download_manifest_2026_10_28.json').read_text())
    report = []
    for pack in manifests:
        if pack['id'] not in SELECTION:
            continue
        archive_path = LIBRARY / pack['archive']
        with archive_path.open('rb') as stream:
            assert hashlib.file_digest(stream, 'sha256').hexdigest() == pack['sha256']
        folder = WORK / 'temp/source' / pack['id']
        with zipfile.ZipFile(archive_path) as archive:
            names = archive.namelist()
            selected = []
            for stem in SELECTION[pack['id']]:
                found = [n for n in names if PurePosixPath(n).stem == stem
                         and PurePosixPath(n).suffix.lower() in ('.gltf', '.glb')]
                if pack['id'] == 'P13' and stem.startswith('Hair_'):
                    found = [n for n in found if 'Rigged to Head Bone' in n]
                assert len(found) == 1, (stem, found)
                selected += found
            needed = set(selected)
            for name in selected:
                if name.endswith('.gltf'):
                    doc = json.loads(archive.read(name))
                    for key in ('buffers', 'images'):
                        for item in doc.get(key, []):
                            uri = item.get('uri', '')
                            if uri and not uri.startswith('data:'):
                                resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), unquote(uri)))
                                if resolved not in names:
                                    # Known P13 upstream normal-map filename errors: fix working JSON only.
                                    alternate = resolved.replace('_Normal_png.png', '_Normal.png')
                                    assert alternate in names, resolved
                                    needed.add(alternate)
                                else:
                                    needed.add(resolved)
            for name in sorted(needed):
                member = PurePosixPath(name)
                assert not member.is_absolute() and '..' not in member.parts and '\\' not in name
                target = folder.joinpath(*member.parts)
                target.parent.mkdir(parents=True, exist_ok=True)
                data = archive.read(name)
                target.write_bytes(data)
                if name in selected and name.endswith('.gltf'):
                    doc = json.loads(data)
                    changed = False
                    for image in doc.get('images', []):
                        if '_Normal_png.png' in image.get('uri', ''):
                            image['uri'] = image['uri'].replace('_Normal_png.png', '_Normal.png')
                            changed = True
                    if changed:
                        target.write_text(json.dumps(doc), encoding='utf-8')
                report.append(dict(pack_id=pack['id'], archive=pack['archive'],
                                   archive_sha256=pack['sha256'], member=name,
                                   source_sha256=hashlib.sha256(data).hexdigest(),
                                   extracted_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
                                   selected_model=name in selected,
                                   local_path=str(target.relative_to(WORK)).replace('\\', '/')))
            for name in names:
                if PurePosixPath(name).name.lower() in ('license.txt', 'license_standard.txt'):
                    data = archive.read(name)
                    assert b'CC0' in data
                    dest = WORK / 'licenses' / (pack['id'] + '_' + PurePosixPath(name).name)
                    dest.parent.mkdir(exist_ok=True)
                    # Preserve the license wording; normalize upstream whitespace for Git.
                    dest.write_bytes(('\n'.join(line.rstrip() for line in data.decode('utf-8-sig').splitlines()).strip() + '\n').encode('utf-8'))
    (WORK / 'source_manifest.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared {sum(x["selected_model"] for x in report)} models and {len(report)} total source members')


if __name__ == '__main__':
    main()
