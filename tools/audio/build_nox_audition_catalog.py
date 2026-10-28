"""Catalog NOX CC0 WAVs and current game SFX for isolated, non-destructive audition."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/nox-sound-audition-2026-10-28'
ARCHIVE = Path('C:/Users/chase/Documents/Threadbound Asset Library/archives/Essentials_Series_NOX_SOUND.zip')


def read_audio(data):
    if data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise ValueError('Expected little-endian RIFF/WAVE')
    position, fmt, raw = 12, None, None
    while position + 8 <= len(data):
        kind, size = struct.unpack_from('<4sI', data, position)
        content = data[position+8:position+8+size]
        if kind == b'fmt ':
            fmt = content
        elif kind == b'data':
            raw = content
        position += 8 + size + size % 2
    if fmt is None or raw is None:
        raise ValueError('Missing WAV format/data chunk')
    encoding, channels, rate, _, align, bits = struct.unpack_from('<HHIIHH', fmt)
    if encoding == 65534:
        encoding = struct.unpack_from('<H', fmt, 24)[0]
    if encoding == 3 and bits in (32, 64):
        samples = np.frombuffer(raw, dtype='<f4' if bits == 32 else '<f8').astype(np.float32)
    elif encoding == 1 and bits == 24:
        triples = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3).astype(np.int32)
        integers = triples[:, 0] | (triples[:, 1] << 8) | (triples[:, 2] << 16)
        samples = ((integers ^ 0x800000) - 0x800000).astype(np.float32) / 8388608
    elif encoding == 1 and bits in (16, 32):
        samples = np.frombuffer(raw, dtype='<i2' if bits == 16 else '<i4').astype(np.float32) / (2 ** (bits-1))
    elif encoding == 1 and bits == 8:
        samples = (np.frombuffer(raw, dtype=np.uint8).astype(np.float32) - 128) / 128
    else:
        raise ValueError(f'Unsupported WAV encoding {encoding}, {bits} bits')
    assert len(raw) % align == 0 and np.isfinite(samples).all()
    if channels > 1:
        samples = samples.reshape(-1, channels)
    return rate, samples


def audio_metadata(data):
    rate, samples = read_audio(data)
    peak = float(np.max(np.abs(samples))) if samples.size else 0
    rms = float(np.sqrt(np.mean(samples.astype(np.float64) ** 2))) if samples.size else 0
    return dict(duration=round(len(samples) / rate, 4), sample_rate=rate,
                channels=1 if samples.ndim == 1 else samples.shape[1],
                peak_db=round(20 * np.log10(max(peak, 1e-6)), 1),
                rms_db=round(20 * np.log10(max(rms, 1e-6)), 1),
                frames=len(samples), sha256=hashlib.sha256(data).hexdigest())


def humanize(value):
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', value.replace('_', ' ')).strip()


def classify(member):
    stem = Path(member).stem
    category, surface, action, purpose, baseline, caution = 'Other', '', '', '', [], ''
    if stem.startswith('Footsteps_'):
        category = 'Footsteps'
        if 'Iceland_' in stem:
            part = re.sub(r'^Footsteps_Iceland_(?:Jump_(?:Land|Start)|Walk|Run)_', '', stem)
            surface = re.sub(r'_Mono_\d+$', '', part)
        else:
            if 'Footsteps_Essentials_NOX_SOUND/' in member:
                surface = member.split('Footsteps_Essentials_NOX_SOUND/')[1].split('/')[0].removeprefix('Footsteps_')
            else:
                surface = re.sub(r'^Footsteps_', '', stem).split('_')[0]
            surface = re.sub(r'V\d+$', '', surface)
        surface = humanize(surface)
        if '_Jump_' in stem:
            if '_Land_' in stem:
                category, action, baseline = 'Landings', 'Landing', ['player_land']
            elif '_Start_' in stem:
                category, action, baseline = 'Jump takeoffs', 'Takeoff', ['player_jump']
            else:
                category, action, baseline = 'Water splashes', 'Splash', ['player_land']
        else:
            action = 'Run' if '_Run_' in stem else 'Walk'
            baseline = ['player_footstep']
        locations = {'Wood': 'dock planks, porch decks and house floors',
                     'Rock': 'cave stone and the tower approach',
                     'Water': 'shallow shoreline wading',
                     'Gravel': 'gravel paths and loose shoreline stones',
                     'Grass': 'grassy village edges', 'Mud': 'wet banks and muddy paths',
                     'Leaves': 'leaf litter', 'Dirty Ground': 'packed-earth paths',
                     'Metal': 'metal platforms or a heavier mechanical footfall',
                     'Sand': 'sandy lake margins', 'Black Pebble': 'pebble shoreline'}
        purpose = f'{action} on {locations.get(surface, surface.lower() + " surfaces")}.'
        if surface == 'Water':
            caution = 'Shallow-water recording; audition before using for a full swim or water-entry splash.'
        if '_Movement_' in stem:
            category, action, baseline = 'Village & nature', 'Foliage brush', []
            purpose = 'Brushing through tall grass; a foliage layer rather than a replacement sole impact.'
    elif stem.startswith(('Ambiance_', 'Atmosphere_')):
        action = 'Ambient loop' if '_Loop_' in stem else 'Ambience'
        if 'Cave' in stem:
            category, purpose = 'Cave ambience', 'Quiet cave/tower-interior bed; drips or low room tone.'
        elif any(x in stem for x in ('Sea', 'Ocean', 'Stream', 'River', 'Waterfall', 'Hot_Spring', 'Old_Mill')):
            category = 'Water ambience'
            purpose = ('Moving-water bed near waterfalls/outlets.' if 'Waterfall' in stem else
                       'Quiet inlet/stream layer near water routes.' if 'Stream' in stem or 'River' in stem else
                       'Shoreline water bed; compare the size and energy to the lake.')
            caution = 'Outdoor recording. Strong sea surf may feel too large for a sheltered lake; not an underwater bed.'
        elif 'Fire' in stem:
            category, purpose = 'Hearth & fire', 'Village hearth, campfire or small workshop fire.'
        elif 'Rain' in stem:
            category, purpose = 'Weather & wind', 'Rain bed for an approved wet outdoor area.'
        elif 'Wind' in stem:
            category, purpose = 'Weather & wind', 'Air movement on exposed ledges, roofs or village exteriors.'
        elif any(x in stem for x in ('Forest', 'Night', 'Cicadas', 'Meadow')):
            category, purpose = 'Village & nature', 'Restrained outdoor life around the village; compare day/night mood.'
        else:
            category, purpose = 'Experimental', 'Optional atmosphere texture for a later art/audio decision.'
            caution = 'May imply technology or a different tone; not a direct environmental replacement.'
    elif 'Cloth_' in stem or 'Backpack_' in stem:
        category, action = 'Cloth & handling', 'Rustle / handling'
        purpose = 'Clothing movement, cloth handling, or a subtle layer under grapple/gear motion.'
        baseline = ['grapple', 'player_damage']
        caution = 'Rustle/handling source, not a ready-made thread snap or cloth-tear impact.'
    elif 'Household_Door_Wood' in stem:
        category, action, surface = 'Doors & objects', 'Wooden door opening', 'Wood'
        purpose = 'Candidate for a village house door opening.'
    elif 'Household_Closet_Key' in stem:
        category, action = 'Doors & objects', 'Key / latch'
        purpose = 'Small key/latch handling source for a matching existing interaction.'
    elif stem.startswith('Voice_'):
        category = 'Character efforts'
        action = next((x for x in ('Attack', 'Hit', 'Pain', 'Jump', 'Land', 'Effort', 'Breath', 'Expression') if x in stem), 'Voice')
        purpose = 'Optional worker/character effort or enemy reaction source; choose a tone deliberately.'
        baseline = ['enemy_hit'] if action in ('Hit', 'Pain') else []
        caution = 'Human vocal recording. Do not assume it suits Threadborne or woven creatures.'
    elif stem.startswith('Vehicle_'):
        category, action = 'Modern / low priority', 'Vehicle source'
        purpose = 'Retained for browsing; not a direct village/wooden-door recommendation.'
        caution = 'Recorded car/truck mechanics may sound modern.'
    elif stem.startswith('Electromagnetic_'):
        category, action = 'Experimental', 'Electronic texture'
        purpose = 'Optional source texture for an approved magic/ambience experiment.'
        caution = 'Recorded electronics; not recommended as ordinary natural environment audio.'
    return dict(category=category, surface=surface, action=action, purpose=purpose,
                compare_events=baseline, caution=caution)


def current_registry():
    text = (ROOT / 'Src/Global/audio_registry.tres').read_text()
    streams = {rid: path.removeprefix('res://') for path, rid in re.findall(
        r'\[ext_resource type="AudioStream"[^\n]*path="([^"]+)" id="([^"]+)"', text)}
    by_path = {}
    keys = {}
    for key, resource in re.findall(r'&"([^"]+)": SubResource\("([^"]+)"\)', text):
        keys.setdefault(resource, []).append(key)
    for resource_id, block in re.findall(r'\[sub_resource type="Resource" id="([^"]+)"\]\n(.*?)(?=\n\[)', text, re.S):
        events = keys.get(resource_id, [resource_id.removeprefix('AudioSound_')])
        for stream_id in re.findall(r'ExtResource\("([^"]+)"\)', block):
            if stream_id in streams:
                by_path.setdefault(streams[stream_id], []).extend(events)
    return by_path


def mark_shortlist(items):
    # Curated uses; first variants are audition starting points, not heard/accepted quality rankings.
    families = Counter()
    surfaces = {'Wood', 'Rock', 'Water', 'Grass', 'Gravel', 'Mud', 'Leaves', 'Metal'}
    for item in items:
        member, category = item['member'], item['category']
        choose = False
        if 'Footsteps_Essentials_' in member and item['surface'] in surfaces:
            family = (category, item['surface'], item['action'])
            cap = 2 if category in ('Footsteps', 'Water splashes') and item['surface'] in ('Wood', 'Rock', 'Water') else 1
            if category in ('Footsteps', 'Landings', 'Water splashes') and families[family] < cap:
                choose = True
                families[family] += 1
        if 'Nature_Essentials_' in member or 'Sample_A_Sound_Effect/' in member and category != 'Experimental':
            choose = True
        if item['action'] == 'Foliage brush' and member.endswith('_01.wav'):
            choose = True
        if 'Iceland_Flows_' in member and any(x in member for x in ('Stream_Light_', 'Sea_Strong_Kirkjufjara_Far_')):
            family = 'Iceland quiet water' if 'Stream_Light_' in member else 'Iceland distant surf'
            if families[family] < 1:
                choose = True
                families[family] += 1
        item['shortlist'] = choose
        item['priority'] = 1 if choose else 3 if category in ('Experimental', 'Modern / low priority') else 2


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / '.gdignore').write_bytes(b'')
    original = next(p for p in json.loads((ROOT/'docs/assets/download_manifest_2026_10_28.json').read_text()) if p['id']=='P02')
    with ARCHIVE.open('rb') as stream:
        assert hashlib.file_digest(stream, 'sha256').hexdigest() == original['sha256']
    items = []
    with zipfile.ZipFile(ARCHIVE) as archive:
        names = sorted(n for n in archive.namelist() if n.lower().endswith('.wav'))
        assert len(names) == 1644
        for number, member in enumerate(names, 1):
            data = archive.read(member)
            item = dict(id='nox-' + hashlib.sha256(member.encode()).hexdigest()[:12],
                        source='NOX CC0', member=member, filename=Path(member).name,
                        title=humanize(Path(member).stem), **classify(member), **audio_metadata(data))
            items.append(item)
            if number % 300 == 0:
                print(f'Analyzed {number}/1644 NOX files', flush=True)
    mark_shortlist(items)
    registry = current_registry()
    for path in sorted((ROOT / 'Assets/Audio/SFX').rglob('*')):
        if path.suffix.lower() not in ('.wav', '.ogg', '.mp3'):
            continue
        relative = path.relative_to(ROOT).as_posix()
        events = registry.get(relative, [])
        file = path.name.lower()
        category = ('Footsteps' if file.startswith('step_') else 'Landings' if file.startswith('land_') else
                    'Jump takeoffs' if file.startswith('jump_') else 'Current combat & movement' if 'Threadborne Sounds' in relative or 'Enemy Sounds' in relative else 'Current UI')
        data = path.read_bytes()
        meta = audio_metadata(data) if path.suffix.lower() == '.wav' else dict(duration=None, sample_rate=None, channels=None, peak_db=None, rms_db=None, sha256=hashlib.sha256(data).hexdigest())
        items.append(dict(id='game-' + hashlib.sha256(relative.encode()).hexdigest()[:12],
                          source='Current game', member=relative, filename=path.name,
                          title=humanize(path.stem), category=category, surface='Current generic' if category in ('Footsteps', 'Landings') else '',
                          action=', '.join(events), purpose='Existing registered source: ' + (', '.join(events) if events else 'no matching central registry entry'),
                          compare_events=[], events=events, caution='Raw source file; in-game pitch, volume offsets and bus mix are not reproduced.',
                          shortlist=False, priority=2, **meta))
    result = dict(date='2026-10-28', archive_name=ARCHIVE.name, archive_sha256=original['sha256'],
                  source_revision='550d62804f27df90b64d7019a557f2663dfc4384',
                  annotation_basis='Source filenames and project registry; intended-use proposals, not listening/acceptance claims.',
                  items=items)
    (WORK / 'catalog.json').write_bytes((json.dumps(result, ensure_ascii=False, separators=(',', ':'))+'\n').encode())
    summary = dict(nox_files=1644, current_files=sum(x['source']=='Current game' for x in items),
                   shortlist_files=sum(x['shortlist'] for x in items),
                   category_counts=dict(Counter(x['category'] for x in items if x['source']=='NOX CC0')),
                   archive_sha256=original['sha256'], total_duration_seconds=round(sum(x['duration'] or 0 for x in items if x['source']=='NOX CC0'), 2))
    (WORK / 'catalog_summary.json').write_bytes((json.dumps(summary, indent=2)+'\n').encode())
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
