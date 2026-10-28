"""Focused catalog/PCM/HTTP checks for the local audition tool (not gameplay tests)."""
import io
import json
import struct
from urllib.error import HTTPError
from urllib.request import Request, urlopen
import wave
import numpy as np
from build_nox_audition_catalog import ROOT, WORK, read_audio, classify

BASE = 'http://127.0.0.1:8876'
checks = []


def check(condition, name):
    assert condition, name
    checks.append(name)


def fetch(path, headers=None):
    with urlopen(Request(BASE + path, headers=headers or {}), timeout=15) as response:
        return response.status, response.headers, response.read()


def expect_error(path, status, headers=None):
    try:
        fetch(path, headers)
        raise AssertionError('Expected HTTP error')
    except HTTPError as error:
        check(error.code == status, f'HTTP {status}: {path}')


def main():
    catalog = json.loads((WORK / 'catalog.json').read_bytes())
    items = catalog['items']
    nox = [x for x in items if x['source']=='NOX CC0']
    current = [x for x in items if x['source']=='Current game']
    check(len(nox)==1644 and len(current)==27, '1644 NOX + 27 current source entries')
    check(sum(x['shortlist'] for x in items)==60, '60 starter candidates')
    check(len({x['id'] for x in items})==len(items), 'Unique stable IDs')
    check(all(x['duration'] > 0 and x['frames'] > 0 for x in nox), 'All NOX files fully decoded with positive durations')
    check(all(len(x['sha256'])==64 for x in items), 'Every source has SHA-256 provenance')
    check(all(x['surface'] not in ('Walk','Jump') for x in items), 'Surface classification excludes action tokens')
    cloth = next(x for x in nox if x['filename']=='Cloth_Coat_PickUp_Stereo.wav')
    check('grapple' in cloth['compare_events'], 'Cloth source maps to actual grapple registry key')
    check(any('grapple' in x['events'] for x in current), 'Current grapple comparison exists')
    check(classify('Footsteps_Essentials_NOX_SOUND/Footsteps_Grass/Footsteps_Walk_Grass_Mono_01.wav')['surface']=='Grass', 'Alternate grass filename order')
    check(classify('Footsteps_Essentials_NOX_SOUND/Footsteps_Grass/Footsteps_Grass_Tall_Movement_01.wav')['action']=='Foliage brush', 'Foliage movement is not mislabeled as a sole impact')
    raw = bytes([0,0,128, 0,0,0, 255,255,127])
    fmt = struct.pack('<HHIIHH',1,1,48000,144000,3,24)
    chunks = b'fmt '+struct.pack('<I',16)+fmt+b'data'+struct.pack('<I',len(raw))+raw+b'\0'
    wav = b'RIFF'+struct.pack('<I',len(chunks)+4)+b'WAVE'+chunks
    rate, pcm = read_audio(wav)
    check(rate==48000 and np.allclose(pcm,[-1,0,8388607/8388608]), 'PCM24 sign extension and original-level conversion')
    status, _, payload = fetch('/api/catalog')
    check(status==200 and json.loads(payload)==catalog, 'Live catalog matches saved catalog')
    checked_media = []
    representatives = [next(x for x in nox if x['shortlist'] and x['category']==category)
                       for category in ('Footsteps','Water splashes','Water ambience','Cave ambience','Doors & objects','Cloth & handling')]
    representatives += [next(x for x in nox if x['sample_rate']==96000), next(x for x in current if x['filename']=='step_1.wav')]
    for item in representatives:
        status, headers, data = fetch('/audio/'+item['id'])
        with wave.open(io.BytesIO(data)) as preview:
            check(status==200 and preview.getnframes()==item['frames'] and preview.getframerate()==item['sample_rate']
                  and preview.getnchannels()==item['channels'] and preview.getsampwidth()==2, 'Complete playable PCM16 preview: '+item['filename'])
        _, ranged_headers, ranged = fetch('/audio/'+item['id'], {'Range':'bytes=0-43'})
        check(ranged==data[:44] and ranged_headers.get('Content-Range')==f'bytes 0-43/{len(data)}', 'Byte-range seek: '+item['filename'])
        checked_media.append(item['filename'])
    item=representatives[0]
    expect_error('/audio/'+item['id'],416,{'Range':'bytes=999999999-9999999999'})
    expect_error('/audio/'+item['id'],416,{'Range':'bytes=bad'})
    expect_error('/audio/unknown',404)
    expect_error('/../../AGENTS.md',404)
    expect_error('/api/save',404)
    for path in ('/','/audition.js','/audition.css'):
        check(fetch(path)[0]==200,'Static UI available: '+path)
    report=dict(result='PASS',checks=len(checks),passed=checks,
                media_examples=checked_media,
                limitations='Browser interaction separately checked; listening/appearance acceptance and game integration are not implied.')
    (WORK/'verification.json').write_bytes((json.dumps(report,indent=2)+'\n').encode())
    print(f'PASS: {len(checks)} catalog/PCM/HTTP checks')


if __name__=='__main__':
    main()
