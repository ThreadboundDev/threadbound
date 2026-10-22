"""Package the approved v4 using byte-identical existing maps, then import it.

Run package, prepare, Godot --headless --editor --import on the printed sandbox,
then install. Reuses the existing isolated-import plumbing, not v3 packaging.
No scene references, old models, textures or native sources are edited here.
"""
import argparse
import json
import os
from pathlib import Path

import import_eave_quality_v3 as importer

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE = ROOT / 'work/eave-runner-v4/EaveRunner_v4.glb'
MODEL = ROOT / 'Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v4.glb'
REPORT = ROOT / 'work/eave-runner-v4/runtime_verification.json'
SANDBOX = ROOT / 'tmp/eave_cleanup_v4/runtime_import'
TEXTURE_FOLDERS = (
    'Assets/BlueBiome/Characters/SharedTexturesV2',
    'Assets/BlueBiome/Enemies/EaveRunner/Textures',
    'Assets/BlueBiome/Enemies/EaveRunner/TexturesV3',
    'Assets/BlueBiome/Enemies/LoomHeron/Textures',
    'Assets/BlueBiome/Art/Lakeside3D/Textures',
)


def package():
    provenance = json.loads((ROOT / 'work/eave-runner-v4/provenance.json').read_text())
    candidate_hash = importer.digest(CANDIDATE.read_bytes())
    assert candidate_hash == provenance['artifacts'][importer.relative(CANDIDATE)]['sha256']
    known = {}
    for folder in TEXTURE_FOLDERS:
        for file in sorted((ROOT / folder).glob('*.png')):
            known.setdefault(importer.digest(file.read_bytes()), file)
    document, binary = importer.read_glb(CANDIDATE)
    materials_before = json.dumps(document['materials'], sort_keys=True)
    removed, images = set(), []
    for image in document['images']:
        index = image.pop('bufferView')
        view = document['bufferViews'][index]
        start = view.get('byteOffset', 0)
        sha = importer.digest(binary[start:start + view['byteLength']])
        if sha not in known:
            raise RuntimeError('No byte-identical existing texture: ' + image['name'])
        target = known[sha]
        image['uri'] = os.path.relpath(target, MODEL.parent).replace('\\', '/')
        image.pop('mimeType', None)
        removed.add(index)
        images.append(importer.relative(target))
    rebuilt, views, mapping, hashes = bytearray(), [], {}, []
    for index, view in enumerate(document['bufferViews']):
        if index in removed:
            continue
        start = view.get('byteOffset', 0)
        content = binary[start:start + view['byteLength']]
        hashes.append(importer.digest(content))
        rebuilt.extend(b'\0' * (-len(rebuilt) % 4))
        mapping[index] = len(views)
        views.append({**view, 'byteOffset': len(rebuilt)})
        rebuilt.extend(content)

    def remap(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key == 'bufferView':
                    value[key] = mapping[child]
                else:
                    remap(child)
        elif isinstance(value, list):
            for child in value:
                remap(child)

    document['bufferViews'] = views
    remap(document)
    document['buffers'][0]['byteLength'] = len(rebuilt)
    assert hashes == [importer.digest(rebuilt[v['byteOffset']:v['byteOffset'] + v['byteLength']]) for v in views]
    assert materials_before == json.dumps(document['materials'], sort_keys=True)
    importer.write_glb(MODEL, document, bytes(rebuilt))
    normals = {document['textures'][m['normalTexture']['index']]['source'] for m in document['materials'] if 'normalTexture' in m}
    report = {
        'approved_on': '2026-10-22', 'candidate_commit': '4f8c79dd',
        'model': importer.relative(MODEL), 'candidate_sha256': candidate_hash,
        'runtime_sha256': importer.digest(MODEL.read_bytes()), 'bytes': MODEL.stat().st_size,
        'triangles': sum(document['accessors'][p['indices']]['count'] // 3 for mesh in document['meshes'] for p in mesh['primitives']),
        'textures': sorted(set(images)), 'normal_textures': sorted({images[i] for i in normals}),
        'texture_hashes': {p: importer.digest((ROOT / p).read_bytes()) for p in sorted(set(images))},
        'geometry_animation_buffers_verified': len(views), 'material_parameters_unchanged': True,
        'new_texture_files': 0,
    }
    REPORT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('EAVE_V4_PACKAGED', json.dumps(report))


def configure_importer():
    importer.MODEL = MODEL
    importer.SANDBOX = SANDBOX
    importer.MANIFEST = REPORT
    # No new textures are created. Existing dependency sidecars/cache are reused.
    importer.NEW_TEXTURES = ROOT / 'Assets/BlueBiome/Enemies/EaveRunner/TexturesV4'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('package', 'prepare', 'install'))
    mode = parser.parse_args().mode
    configure_importer()
    if mode == 'package':
        package()
    else:
        getattr(importer, mode)()
