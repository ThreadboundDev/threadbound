"""Lay out existing painted art beside the rendered CC0 proposal; build motion GIFs.

This only composes review boards; source PNGs and production assets are untouched.
Requires Pillow in the bundled Python runtime.
"""
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/cc0-house-villager-2026-10-28'
OUT = WORK / 'renders'
PAINTED = ROOT / 'Assets/BlueBiome/Art/PaintedComparison'
FONT = Path('C:/Windows/Fonts/segoeui.ttf')
BOLD = Path('C:/Windows/Fonts/segoeuib.ttf')


def font(size, bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT), size)


def cover(image, size):
    image = image.copy()
    image.thumbnail(size, Image.Resampling.LANCZOS)
    return image


def paste(canvas, image, xy):
    canvas.paste(image, xy, image if image.mode == 'RGBA' else None)


house = Image.open(PAINTED / 'workshop_v2.png').convert('RGBA').crop((8, 234, 777, 861))
worker = Image.open(PAINTED / 'boatwright.png').convert('RGBA').crop((0, 0, 724, 724))
wide = Image.open(OUT / 'cc0_house_worker.png').convert('RGB')
detail = Image.open(OUT / 'cc0_worker_detail.png').convert('RGB')


def board(right, close=False):
    canvas = Image.new('RGB', (1600, 1000), '#101f2a')
    draw = ImageDraw.Draw(canvas)
    draw.text((38, 24), 'THREADBOUND  /  HOUSE + WORKER', font=font(31, True), fill='#eee6d5')
    draw.text((39, 70), 'Presentation study  |  Current painted art and reusable CC0 models', font=font(20), fill='#aabac5')
    for x, title, subtitle in [(32, 'CURRENT PAINTED 2D', 'Existing artwork; work pose held still'),
                               (816, 'CC0 MODEL PROPOSAL', 'Downloaded rig + clothes; authored planing loop')]:
        draw.rounded_rectangle((x, 118, x+752, 838), radius=14, fill='#1a2e3a')
        draw.text((x+22, 135), title, font=font(24, True), fill='#e9dfcc')
        draw.text((x+22, 173), subtitle, font=font(17), fill='#acbec8')
    if not close:
        display_house = cover(house, (630, 520))
        paste(canvas, display_house, (90, 760-display_house.height))
        display_worker = cover(worker, (194, 194))
        paste(canvas, display_worker, (438, 765-display_worker.height))
        right = cover(right, (742, 626))
        paste(canvas, right, (821+(742-right.width)//2, 204+(626-right.height)//2))
        draw.text((51, 864), 'Existing curved-roof workshop and painted boatwright.', font=font(20), fill='#d8dfdf')
        draw.text((51, 898), 'Source images are unchanged.', font=font(18), fill='#aabac5')
        draw.text((835, 864), 'Modular house, peasant outfit, timber and textiles.', font=font(20), fill='#d8dfdf')
        draw.text((835, 898), 'Same floor plane throughout the four-second work cycle.', font=font(18), fill='#aabac5')
    else:
        display_worker = cover(worker, (400, 400))
        paste(canvas, display_worker, (202, 712-display_worker.height))
        right = cover(right, (626, 626))
        paste(canvas, right, (879, 204))
        draw.text((51, 864), 'Painted work pose for silhouette / material reference.', font=font(20), fill='#d8dfdf')
        draw.text((51, 898), 'This panel is static; it does not show the current 3D NPC.', font=font(18), fill='#aabac5')
        draw.text((835, 864), 'Hands follow the plane; feet remain planted.', font=font(20), fill='#d8dfdf')
        draw.text((835, 898), 'Close view for contact review, enlarged from gameplay scale.', font=font(18), fill='#aabac5')
    draw.text((39, 956), 'Isolated art proposal  /  Different house shapes and lighting  /  No production replacement or performance claim', font=font(17), fill='#8fa5b2')
    return canvas


board(wide).save(OUT / 'house_villager_side_by_side.png')
board(detail, True).save(OUT / 'worker_side_by_side.png')
loops = [] if '--stills-only' in sys.argv else [('wide', 'house_villager_motion.gif', False),
                                              ('detail', 'worker_motion.gif', True)]
for prefix, filename, close in loops:
    paths = [WORK / 'temp' / f'{prefix}_{frame:03}.png' for frame in range(1, 97, 2)]
    assert all(p.is_file() for p in paths), 'Render all 48 loop frames before packaging'
    frames = [board(Image.open(p).convert('RGB'), close).resize((1200, 750), Image.Resampling.LANCZOS) for p in paths]
    palette = frames[0].quantize(colors=248, method=Image.Quantize.MEDIANCUT)
    indexed = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    indexed[0].save(OUT / filename, save_all=True, append_images=indexed[1:],
                    duration=[80, 80, 90]*16, loop=0, optimize=True, disposal=1)
    with Image.open(OUT / filename) as saved:
        assert saved.n_frames == 48
        duration = 0
        for frame in range(saved.n_frames):
            saved.seek(frame)
            duration += saved.info['duration']
        assert duration == 4000
    print(filename, '48 frames / 4 seconds')
artifacts = []
for path in sorted(OUT.iterdir()):
    if path.suffix.lower() in ('.png', '.gif'):
        artifacts.append(dict(file=str(path.relative_to(WORK)).replace('\\', '/'),
                              bytes=path.stat().st_size,
                              sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(WORK / 'preview_manifest.json').write_bytes((json.dumps(artifacts, indent=2)+'\n').encode())
print('CC0_COMPARISON_PACKAGED')
