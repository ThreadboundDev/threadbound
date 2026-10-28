"""Export an independent, self-contained 1K-map Eave Runner copy for the study."""
from pathlib import Path
import bpy
import json
import hashlib

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
SOURCE = ROOT / 'Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v4.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
for index, image in enumerate(bpy.data.images):
    if image.source == 'FILE':
        pixel = image.pixels[0]
        if max(image.size) > 1024:
            factor = 1024 / max(image.size)
            image.scale(round(image.size[0] * factor), round(image.size[1] * factor))
            image.filepath_raw = str(WORK / 'temp' / ('eave_map_' + str(index) + '.png'))
            image.file_format = 'PNG'
            image.save()
            if image.packed_file:
                image.unpack(method='REMOVE')
        image.pack()
for ob in list(bpy.context.scene.objects):
    if ob.name == 'Icosphere':
        bpy.data.objects.remove(ob, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(WORK / 'project/assets/enemies/eave_runner.glb'),
                          export_format='GLB', export_animation_mode='NLA_TRACKS')
(WORK / 'project/assets/eave_runner_provenance.json').write_text(json.dumps({
    'source': str(SOURCE.relative_to(ROOT)), 'sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'adaptation': 'Existing Threadbound model/rig/animations; working-copy maps reduced to 1K and embedded',
}, indent=2), encoding='utf-8')
