"""Package original generation inputs without resizing or retouching images."""
from pathlib import Path
import hashlib
import json
import re
import zipfile
from PIL import Image

HERE = Path(__file__).resolve().parent
UPLOADS = ['01_cowl.png', '02_tunic_sash.png', '03_ragged_breeches.png',
           '04_forearm_wrap_single.png', '05_boot_single.png']
REVIEW = '00_outfit_fit_reference_ragged_v2.png'
manifest = []
for name in [REVIEW] + UPLOADS:
    path = HERE / name
    with Image.open(path) as image:
        width, height = image.size
        mode = image.mode
        assert min(width, height) >= 512, name
        image.verify()
    manifest.append({'file': name, 'width': width, 'height': height, 'mode': mode,
        'role': 'upload one image per job' if name in UPLOADS else 'review only; do not upload as a garment',
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
with zipfile.ZipFile(HERE / 'generation_inputs.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in UPLOADS + ['START_HERE.txt']:
        archive.write(HERE / name, name)
with zipfile.ZipFile(HERE / 'generation_inputs.zip') as archive:
    assert set(archive.namelist()) == set(UPLOADS + ['START_HERE.txt'])
    for name in archive.namelist():
        assert archive.read(name) == (HERE / name).read_bytes(), name
for target in re.findall(r'\]\(([^)]+)\)', (HERE / 'README.md').read_text()):
    if not target.startswith('https:') and target != 'image_manifest.json':
        assert (HERE / target).exists(), target
(HERE / 'image_manifest.json').write_text(json.dumps({
    'images': manifest, 'zip_members': UPLOADS + ['START_HERE.txt'],
    'checks': {'image_integrity': True, 'minimum_512px': True,
               'zip_exact_members': True, 'zip_source_bytes_match': True,
               'readme_links': True},
}, indent=2) + '\n')
print('VERIFIED: six PNGs, five separate upload assets, exact ZIP contents and documentation links')
