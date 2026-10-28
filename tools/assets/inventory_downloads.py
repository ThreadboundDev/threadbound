"""Read selected asset ZIPs without importing them into Godot or executing content.

Usage: python tools/assets/inventory_downloads.py --source PATH --output PATH
Outputs a hash manifest, complete file catalog, glTF inspection, and local evidence.
PDF text extraction requires pypdf; all other inspection uses the standard library.
"""
import argparse
import collections
import csv
import hashlib
import io
import json
import pathlib
import posixpath
import re
import struct
import zipfile
from urllib.parse import unquote

PACKS = [
    'Bestiary - Dungeon Monsters Kit[Standard].zip',
    'Essentials_Series_NOX_SOUND.zip',
    'Fantasy Props MegaKit[Standard].zip',
    'Fantasy RPG Music Pack.zip',
    'Fantasy RPG Music Vol. 2.zip',
    'KayKit_FantasyWeaponsBits_1.0_FREE.zip',
    'KayKit_ResourceBits_1.0_FREE.zip',
    'kenney_retro-fantasy-kit.zip',
    'Medieval Village MegaKit[Standard].zip',
    'Modular Character Outfits - Fantasy[Standard].zip',
    'Universal Animation Library 2[Standard].zip',
    'Universal Animation Library[Standard].zip',
    'Universal Base Characters[Standard].zip',
]


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inspect_gltf(data, binary):
    if binary:
        magic, version, size, length, kind = struct.unpack_from('<4sIIII', data)
        if magic != b'glTF' or version != 2 or kind != 0x4E4F534A or size != len(data):
            raise ValueError('Invalid GLB header')
        data = data[20:20 + length]
    doc = json.loads(data)
    triangles = 0
    for mesh in doc.get('meshes', []):
        for primitive in mesh['primitives']:
            if primitive.get('mode', 4) == 4:
                index = primitive.get('indices', primitive['attributes'].get('POSITION'))
                triangles += doc['accessors'][index]['count'] // 3
    return dict(
        meshes=len(doc.get('meshes', [])), triangle_count=triangles,
        materials=len(doc.get('materials', [])),
        skin_joint_counts=[len(s['joints']) for s in doc.get('skins', [])],
        joint_names=[[doc['nodes'][j].get('name', str(j)) for j in s['joints']]
                     for s in doc.get('skins', [])],
        animations=[a.get('name', '') for a in doc.get('animations', [])],
        dependencies=[x['uri'] for k in ('buffers', 'images')
                      for x in doc.get(k, []) if 'uri' in x and not x['uri'].startswith('data:')],
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=pathlib.Path, required=True)
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    manifest, catalog, models, evidence = [], [], [], []
    for number, name in enumerate(PACKS, 1):
        path = args.source / name
        pack_id = f'P{number:02}'
        folder = args.output / 'evidence' / pack_id
        folder.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(path) as archive:
            bad = archive.testzip()
            if bad:
                raise ValueError(f'CRC failure: {name}: {bad}')
            files = [e for e in archive.infolist() if not e.is_dir()]
            member_names = {e.filename for e in files}
            counts = collections.Counter(pathlib.PurePosixPath(e.filename).suffix.lower() for e in files)
            manifest.append(dict(id=pack_id, archive=name, bytes=path.stat().st_size,
                                 sha256=digest(path), file_count=len(files),
                                 expanded_bytes=sum(e.file_size for e in files),
                                 extensions=dict(sorted(counts.items())), crc='pass'))
            for entry in files:
                member = pathlib.PurePosixPath(entry.filename)
                ext = member.suffix.lower()
                catalog.append(dict(pack_id=pack_id, archive=name, path=entry.filename,
                                    bytes=entry.file_size, extension=ext))
                if ext in ('.glb', '.gltf'):
                    model = dict(pack_id=pack_id, path=entry.filename,
                                 **inspect_gltf(archive.read(entry), ext == '.glb'))
                    model['missing_dependencies'] = [dep for dep in model['dependencies']
                        if posixpath.normpath(posixpath.join(posixpath.dirname(entry.filename),
                                                           unquote(dep))) not in member_names]
                    models.append(model)
                is_text = ext in ('.txt', '.md', '.url', '.html')
                preview = bool(re.search(r'(preview|overview|contents|sample|setup|importing)', member.name, re.I))
                if ext == '.pdf' or is_text or (preview and ext in ('.png', '.jpg', '.jpeg')):
                    # Keep the member hierarchy; refuse path traversal even in evidence files.
                    if member.is_absolute() or '..' in member.parts or ':' in str(member):
                        raise ValueError(f'Unsafe archive path: {member}')
                    target = folder.joinpath(*member.parts)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    content = archive.read(entry)
                    target.write_bytes(content)
                    if is_text:
                        evidence.append(dict(pack_id=pack_id, path=entry.filename,
                                             text=content.decode('utf-8-sig', errors='replace')))
                    if ext == '.pdf':
                        from pypdf import PdfReader
                        reader = PdfReader(io.BytesIO(content))
                        text = '\n\n'.join(p.extract_text() or '' for p in reader.pages)
                        target.with_suffix('.extracted.txt').write_text(text, encoding='utf-8')
                        evidence.append(dict(pack_id=pack_id, path=entry.filename, text=text))
        print(f'{pack_id}: {len(files)} files; CRC pass; {name}', flush=True)
    for filename, data in [('manifest.json', manifest), ('models.json', models), ('evidence.json', evidence)]:
        (args.output / filename).write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    with (args.output / 'files.csv').open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=['pack_id', 'archive', 'path', 'bytes', 'extension'])
        writer.writeheader()
        writer.writerows(catalog)
    print(f'Total: {len(manifest)} archives, {len(catalog)} files, {len(models)} glTF/GLB files')


if __name__ == '__main__':
    main()
