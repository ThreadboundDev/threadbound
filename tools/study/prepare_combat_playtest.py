"""Stage existing Threadbound enemies and sound plus selected CC0 NOX recordings."""
from pathlib import Path
import hashlib
import importlib.util
import io
import json
import shutil
import wave
import zipfile
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'work/third-person-study-2026-10-28/project'
OUT = PROJECT / 'assets'
manifest = []


def sha(data):
    return hashlib.sha256(data).hexdigest()


for stem, relative in [('reedhook', 'Assets/BlueBiome/Enemies/Models/Reedhook_animated.glb'),
                       ('bellstriker', 'Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v4.glb')]:
    source = ROOT / relative
    target = OUT / 'enemies' / (stem + '.glb')
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    manifest.append({'source': relative, 'target': str(target.relative_to(PROJECT)), 'sha256': sha(source.read_bytes()), 'provenance': 'Existing Threadbound asset; original provenance retained'})

audio = OUT / 'audio'
audio.mkdir(exist_ok=True)
for target, relative in {
    'sword': 'Threadborne Sounds/threadborne_weapon_attack.wav',
    'jump': 'Threadborne Sounds/jump_1.wav',
    'dash': 'Threadborne Sounds/dash.wav',
    'grapple_throw': 'Threadborne Sounds/threadborne_grapple_throw.wav',
    'grapple_connect': 'Threadborne Sounds/threadborne_grapple_connect.wav',
    'hurt': 'Threadborne Sounds/threadborne_take_damage(cloth_rip).wav',
    'enemy_swing': 'Enemy Sounds/enemy_sword_attack.wav',
    'stomp': 'Enemy Sounds/enemy_stomp_attack.wav',
}.items():
    source = ROOT / 'Assets/Audio/SFX' / relative
    shutil.copyfile(source, audio / (target + '.wav'))
    manifest.append({'source': str(source.relative_to(ROOT)), 'target': 'assets/audio/' + target + '.wav', 'sha256': sha(source.read_bytes()), 'provenance': 'Existing registered game SFX'})

spec = importlib.util.spec_from_file_location('nox_reader', ROOT / 'tools/audio/build_nox_audition_catalog.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
archive = Path.home() / 'Documents/Threadbound Asset Library/archives/Essentials_Series_NOX_SOUND.zip'
with zipfile.ZipFile(archive) as bundle:
    for target, suffix in {
        'wind': 'Nature_Essentials_NOX_SOUND/Ambiance_Wind_Forest_Loop_Stereo.wav',
        'river': 'Nature_Essentials_NOX_SOUND/Ambiance_River_Moderate_Loop_Stereo.wav',
        'step_grass_1': 'Footsteps_Grass/Footsteps_Grass_Walk/Footsteps_Walk_Grass_Mono_01.wav',
        'step_grass_2': 'Footsteps_Grass/Footsteps_Grass_Run/Footsteps_Grass_Run_01.wav',
        'step_wood_1': 'Footsteps_Wood/Footsteps_Wood_Walk/Footsteps_Wood_Walk_01.wav',
        'step_wood_2': 'Footsteps_Wood/Footsteps_Wood_Walk/Footsteps_Wood_Walk_02.wav',
        'land': 'Footsteps_Grass/Footsteps_Grass_Jump/Footsteps_Grass_Jump_Land_01.wav',
    }.items():
        member = next(n for n in bundle.namelist() if n.endswith(suffix))
        source = bundle.read(member)
        rate, samples = reader.read_audio(source)
        # PCM16, original level/rate/channels. No peak normalization.
        payload = np.clip(samples * 32767, -32768, 32767).astype('<i2').tobytes()
        with wave.open(str(audio / (target + '.wav')), 'wb') as output:
            output.setnchannels(samples.shape[1] if samples.ndim > 1 else 1)
            output.setsampwidth(2)
            output.setframerate(rate)
            output.writeframes(payload)
        manifest.append({'archive': archive.name, 'member': member, 'sha256': sha(source), 'target': 'assets/audio/' + target + '.wav', 'license': 'CC0; retained NOX notice'})
shutil.copyfile(ROOT / 'work/nox-sound-audition-2026-10-28/LICENSE-NOX.txt', OUT / 'licenses/NOX.txt')
music = Path.home() / 'Documents/Threadbound Asset Library/cathedral_in_the_forest_CC0.ogg'
shutil.copyfile(music, audio / 'forest_ambient.ogg')
manifest.append({'target':'assets/audio/forest_ambient.ogg', 'source_page':'https://opengameart.org/content/cathedral-in-the-forest-ambient-loop', 'creator':'congusbongus', 'license':'CC0', 'sha256':sha(music.read_bytes())})
for entry in manifest:
    entry['target_sha256'] = sha((PROJECT / entry['target']).read_bytes())
(OUT / 'combat_provenance.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print('Staged', len(manifest), 'enemy/audio sources.')
