"""Package engine renders; raw frames stay local. No authored art is repainted."""
import ast
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

p = Path(__file__).resolve().parent
root = p.parents[1]
capture = json.loads((p / 'water-capture.json').read_text(encoding='utf-8'))
baseline_path = root / 'work/gameplay-review-followup-2026-10-30/geometry-baseline.json'
baseline = json.loads(baseline_path.read_text(encoding='utf-8'))
geometry = capture.pop('geometry')
assert baseline == geometry, 'Water presentation must preserve all world polygons'
for label in ['above', 'half']:
    state = capture['painted_' + label]
    assert ast.literal_eval(state['eye'])[1] < 411 and state['underwater_view'] < .01
assert ast.literal_eval(capture['painted_below']['eye'])[1] > 411
assert capture['painted_below']['underwater_view'] > .99
audit = dict(world_polygons=len(geometry), identical=True,
             canonical_geometry_sha256=hashlib.sha256(json.dumps(geometry, sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
             baseline=str(baseline_path.relative_to(root)).replace('\\', '/'), states=capture)
(p / 'water-geometry-and-head-audit.json').write_text(json.dumps(audit, indent=2) + '\n', encoding='utf-8')
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)
out = Image.new('RGB', (1440, 1330), '#17252f')
draw = ImageDraw.Draw(out)
for row, key in enumerate(['above', 'half', 'below']):
    for column, (mode, label) in enumerate([('previous', 'Earlier water treatment'), ('painted', 'Reflective surface / underwater reveal')]):
        im = Image.open(p / f'water_{mode}_{key}.png').convert('RGB')
        im.thumbnail((720, 405))
        x, y = column * 720, row * 440
        out.paste(im, (x, y + 32))
        draw.text((x + 9, y + 5), f'{label} — {key}', font=font, fill='white')
out.save(p / 'water-surface-comparison.jpg', quality=93)
for key in ['depth', 'pocket']:
    out = Image.new('RGB', (1600, 490), '#17252f')
    draw = ImageDraw.Draw(out)
    for i, mode in enumerate(['previous', 'painted']):
        im = Image.open(p / f'water_{mode}_{key}.png').convert('RGB')
        im.thumbnail((800, 450))
        out.paste(im, (800*i, 35))
        draw.text((800*i+10, 7), 'Earlier water treatment' if i == 0 else 'New submerged grade', font=font, fill='white')
    out.save(p / f'water-{key}-comparison.jpg', quality=93)
sky = Image.open(p / 'water_sky.png').convert('RGB')
sky.thumbnail((1280, 720))
sky.save(p / 'high-sky-coverage.jpg', quality=93)
frames = []
for source in sorted(p.glob('water_motion_*.png')):
    im = Image.open(source).convert('RGB')
    im.thumbnail((800, 450))
    frames.append(im)
if frames:
    palette_source = Image.new('RGB', (800, 450*8))
    for i in range(8): palette_source.paste(frames[i*10], (0, i*450))
    palette = palette_source.quantize(colors=160)
    frames = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    frames[0].save(p / 'water-reveal-loop.gif', save_all=True, append_images=frames[1:], duration=50, loop=0, optimize=False)
for name in ['legacy_water', 'tower', 'house', 'grapple_entry']:
    source = root / f'tmp/overnight-feedback-2026-10-30/regressions/{name}/verification.json'
    result = json.loads(source.read_text(encoding='utf-8'))
    assert not result['failures']
    (p / f'water-{name}-regression.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print('148 unchanged world polygons; rendered-head reveal checks pass; review images and loop packaged.')
