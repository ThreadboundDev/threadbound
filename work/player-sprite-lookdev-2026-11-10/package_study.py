"""Build comparable review stills and fixed-canvas outlined sprite previews."""
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
REFERENCE = ROOT / "docs/art/concept_art/Idle right first.png"
GAME_SCALE = 0.4
OUTLINE_RADIUS = 3
BG = (36, 49, 54)
INK = (5, 5, 7)


def font(size, bold=False):
    return ImageFont.truetype(f"C:/Windows/Fonts/{'segoeuib' if bold else 'segoeui'}.ttf", size)


def outlined(im, radius=OUTLINE_RADIUS):
    alpha = im.getchannel("A")
    # Circular silhouette growth, including concavities, like Krita's Grow.
    grown = alpha.copy()
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                grown = ImageChops.lighter(grown, ImageChops.offset(alpha, dx, dy))
    backing = Image.new("RGBA", im.size, (*INK, 0))
    backing.putalpha(grown)
    return Image.alpha_composite(backing, im)


def fit_height(im, height):
    bounds = im.getchannel("A").getbbox()
    assert bounds is not None
    im = im.crop(bounds)
    return im.resize((round(im.width * height / im.height), height), Image.Resampling.LANCZOS)


def place(sheet, im, center, bottom):
    sheet.paste(im, (round(center - im.width / 2), bottom - im.height), im)


def text(draw, xy, value, size=19, fill=(217, 224, 223), bold=False):
    draw.text(xy, value, font=font(size, bold), fill=fill)


reference = Image.open(REFERENCE).convert("RGBA")
original = Image.open(OUT / "source_reference_raw.png").convert("RGBA")
study = outlined(Image.open(OUT / "ink_reference_raw.png").convert("RGBA"))
study.save(OUT / "illustrated_reference.png")
fit_height(reference, 180).save(OUT / "reference_for_engine.png")
fit_height(study, 180).save(OUT / "reference_study_for_engine.png")
equipped = outlined(Image.open(OUT / "ink_quarter_raw.png").convert("RGBA"))
equipped.save(OUT / "illustrated_equipped.png")
side = outlined(Image.open(OUT / "ink_side_raw.png").convert("RGBA"))
side.save(OUT / "illustrated_side.png")

sheet = Image.new("RGB", (1440, 1100), BG)
draw = ImageDraw.Draw(sheet)
text(draw, (40, 24), "Threadbound / illustrated character study", 33, bold=True)
text(draw, (40, 75), "Existing detailed Blender mesh. Render treatment and pose only; no shape edits.", 21)
labels = ["OLD 2D REFERENCE", "RETAINED BLENDER MODEL", "ILLUSTRATED RENDER + INK"]
images = [reference, original, study]
centers = [250, 720, 1190]
for center, im, label in zip(centers, images, labels):
    draw.rounded_rectangle((center - 210, 125, center + 210, 745), radius=14, fill=(53, 68, 71))
    text(draw, (center - 190, 145), label, 20, bold=True)
    place(sheet, fit_height(im, 500), center, 710)
draw.line((40, 780, 1400, 780), fill=(92, 108, 110), width=1)
text(draw, (40, 802), "180 px standing-height comparison", 22, bold=True)
text(draw, (40, 840), "Same display height; silhouettes intentionally remain different.", 18)
for center, im in zip(centers, images):
    place(sheet, fit_height(im, 180), center, 1060)
sheet.save(OUT / "comparison.png")

eq_sheet = Image.new("RGB", (1100, 760), BG)
draw = ImageDraw.Draw(eq_sheet)
text(draw, (34, 22), "Existing equipment, rendered together", 30, bold=True)
text(draw, (34, 66), "Side and three-quarter camera tests / one composite exterior outline", 20)
for center, im, label in [(290, side, "TRUE SIDE"), (810, equipped, "THREE-QUARTER")]:
    draw.rounded_rectangle((center - 240, 112, center + 240, 730), radius=14, fill=(53, 68, 71))
    text(draw, (center - 210, 130), label, 19, bold=True)
    place(eq_sheet, fit_height(im, 510), center, 700)
eq_sheet.save(OUT / "equipment_comparison.png")

manifest_path = OUT / "motion_manifest.json"
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text())
    sprites = {}
    for record in manifest:
        im = Image.open(OUT / record["file"]).convert("RGBA")
        bounds = im.getchannel("A").getbbox()
        assert bounds is not None
        assert min(bounds[0], bounds[1], im.width - bounds[2], im.height - bounds[3]) > OUTLINE_RADIUS
        result = outlined(im).resize((240, 320), Image.Resampling.LANCZOS)
        sprites.setdefault(record["clip"], []).append((result, record))
    (OUT / "sprites").mkdir(exist_ok=True)
    all_frames = []
    for clip, frames in sprites.items():
        columns = 8
        rows = math.ceil(len(frames) / columns)
        atlas = Image.new("RGBA", (240 * columns, 320 * rows))
        gif_frames = []
        for index, (im, record) in enumerate(frames):
            atlas.paste(im, (index % columns * 240, index // columns * 320))
            card = Image.new("RGB", (720, 540), BG)
            d = ImageDraw.Draw(card)
            text(d, (28, 20), f"Rendered sprite / {clip}", 26, bold=True)
            text(d, (28, 61), "Existing rig and animation / fixed canvas / black outline", 17)
            place(card, im, 190, 465)
            place(card, im.resize((480, 640), Image.Resampling.NEAREST).crop((0, 150, 480, 640)), 500, 500)
            text(d, (75, 502), "GAME SCALE", 16)
            text(d, (420, 502), "2x DETAIL", 16)
            gif_frames.append(card)
            all_frames.append({**record, "atlas": f"sprites/{clip}.png", "index": index, "region": [index % columns * 240, index // columns * 320, 240, 320]})
        atlas.save(OUT / "sprites" / f"{clip}.png")
        gif_frames[0].save(OUT / f"{clip}_preview.gif", save_all=True, append_images=gif_frames[1:], duration=[r["duration_ms"] for _, r in frames], loop=0, optimize=False, disposal=2)
    (OUT / "sprite_manifest.json").write_text(json.dumps({"cell": [240, 320], "scale_from_render": GAME_SCALE, "outline_source_radius": OUTLINE_RADIUS, "outline_game_radius": OUTLINE_RADIUS * GAME_SCALE, "camera": "level three-quarter orthographic, same for all frames", "frames": all_frames}, indent=2), encoding="utf-8")
    contact = Image.new("RGB", (960, 1080), BG)
    d = ImageDraw.Draw(contact)
    for row, (clip, frames) in enumerate(sprites.items()):
        text(d, (24, row * 360 + 8), f"{clip.upper()} / sampled source poses", 23, bold=True)
        for column, index in enumerate([0, len(frames) // 3, len(frames) * 2 // 3, len(frames) - 1]):
            im, record = frames[index]
            place(contact, im, column * 240 + 120, row * 360 + 340)
            text(d, (column * 240 + 25, row * 360 + 340), f"source frame {record['frame']}", 16)
    contact.save(OUT / "motion_contact.png")
    print("PACKAGED_SPRITES", len(all_frames))
print("PACKAGED_COMPARISON")
