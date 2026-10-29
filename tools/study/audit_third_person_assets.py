"""Check staged model dependencies, workshop texture sizes and original-input hashes."""
from pathlib import Path
import hashlib
import io
import json
import re
import struct
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
PROJECT = WORK / 'project'
report = {'models': [], 'source_inputs_unchanged': [], 'resource_links_checked': 0}
records = json.loads((PROJECT / 'assets/provenance.json').read_text(encoding='utf-8'))
if (PROJECT / 'assets/combat_provenance.json').exists():
    records += json.loads((PROJECT / 'assets/combat_provenance.json').read_text(encoding='utf-8'))
if (PROJECT / 'assets/eave_runner_provenance.json').exists():
    records.append(json.loads((PROJECT / 'assets/eave_runner_provenance.json').read_text(encoding='utf-8')))
if (PROJECT / 'assets/demo_provenance.json').exists():
    records += json.loads((PROJECT / 'assets/demo_provenance.json').read_text(encoding='utf-8'))
for folder in ['textures', 'weapons']:
    extra = json.loads((PROJECT / 'assets' / folder / 'provenance.json').read_text(encoding='utf-8'))
    records += extra if isinstance(extra,list) else [dict(extra,target='assets/textures/polyhaven_dirt_1k.jpg',target_sha256=extra['sha256'])]
for record in records:
    if 'source' in record and 'sha256' in record:
        path = ROOT / record['source']
        matches = hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256']
        assert matches, path
        report['source_inputs_unchanged'].append(record['source'])
    if 'target_sha256' in record:
        assert hashlib.sha256((PROJECT / record['target']).read_bytes()).hexdigest() == record['target_sha256']
for path in (PROJECT / 'assets').rglob('*.glb'):
    blob = path.read_bytes()
    size = struct.unpack_from('<I', blob, 12)[0]
    data = json.loads(blob[20:20+size])
    binary = blob[28+size:]
    images = []
    for image in data.get('images', []):
        assert 'uri' not in image, (path, image)
        view = data['bufferViews'][image['bufferView']]
        offset = view.get('byteOffset', 0)
        with Image.open(io.BytesIO(binary[offset:offset+view['byteLength']])) as preview:
            images.append({'name': image.get('name'), 'size': list(preview.size)})
            if path.name == 'workshop.glb':
                assert max(preview.size) <= 1024
    report['models'].append({'path': str(path.relative_to(PROJECT)), 'bytes': len(blob),
                             'sha256': hashlib.sha256(blob).hexdigest(), 'images': images,
                             'animations': [a.get('name') for a in data.get('animations', [])]})
for path in list((PROJECT / 'scripts').glob('*.gd')) + list((PROJECT / 'scenes').glob('*.tscn')):
    for resource in re.findall(r'res://[^"\s]+', path.read_text(encoding='utf-8')):
        if resource.startswith(('res://../', 'res://captures')):
            continue
        assert (PROJECT / resource.removeprefix('res://')).exists(), (path, resource)
        report['resource_links_checked'] += 1
report['project_source_bytes'] = sum(p.stat().st_size for p in PROJECT.rglob('*') if p.is_file() and '.godot' not in p.parts)
(WORK / 'asset_validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('PASS', len(report['models']), 'self-contained GLBs;', report['resource_links_checked'], 'resource links;',
      len(report['source_inputs_unchanged']), 'unchanged original inputs; workshop maps <= 1024px')
