from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "Assets" / "Threadborne" / "Player_Normalized_V1"
CONTACT_DIR = OUT_DIR / "_contact_sheets"
CANVAS_SIZE = 512
ALPHA_THRESHOLD = 8


SOURCES = {
    "Jump_Ascent.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Jump" / "Jump_Ascent.png",
        "target_h": 480,
    },
    "Jump_Apex.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Jump" / "Jump_Apex.png",
        "target_h": 440,
    },
    "Jump_Descent.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Jump" / "Jump_Descent.png",
        "target_h": 480,
    },
    "Jump_Land.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Jump" / "Jump_Land.png",
        "target_h": 405,
    },
    "Wall_Cling.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Jump" / "Wall_Cling.png",
        "target_h": 480,
    },
    "Grapple_Toss_Right.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Grapple" / "Grapple_Toss_Right.png",
        "target_h": 460,
    },
    "Grapple_Toss_Diag_Right.png": {
        "src": ROOT / "Assets" / "Threadborne" / "Grapple" / "Grapple_Toss_Diag_Right.png",
        "target_h": 480,
    },
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
    return mask.getbbox()


def visible_rgb_stats(image: Image.Image) -> tuple[list[float], list[float]]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
    rgb = rgba.convert("RGB")
    stat = ImageStat.Stat(rgb, mask)
    means = [max(1.0, v) for v in stat.mean]
    stddev = [max(1.0, v) for v in stat.stddev]
    return means, stddev


def color_match_to_reference(image: Image.Image, ref_mean: list[float], ref_std: list[float]) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = alpha_bbox(rgba)
    if bbox is None:
        return rgba

    src_mean, src_std = visible_rgb_stats(rgba)
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a <= ALPHA_THRESHOLD:
                continue
            channels = []
            for value, src_m, src_s, ref_m, ref_s in zip((r, g, b), src_mean, src_std, ref_mean, ref_std):
                adjusted = ((value - src_m) / src_s) * ref_s + ref_m
                channels.append(max(0, min(255, int(round(adjusted)))))
            pixels[x, y] = (channels[0], channels[1], channels[2], a)
    return rgba


def normalize_frame(src: Path, target_h: int, ref_mean: list[float], ref_std: list[float]) -> Image.Image:
    image = Image.open(src).convert("RGBA")
    image = color_match_to_reference(image, ref_mean, ref_std)
    bbox = alpha_bbox(image)
    if bbox is None:
        return Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))

    crop = image.crop(bbox)
    crop_w, crop_h = crop.size
    scale = target_h / crop_h
    if crop_w * scale > CANVAS_SIZE - 24:
        scale = (CANVAS_SIZE - 24) / crop_w

    new_size = (max(1, round(crop_w * scale)), max(1, round(crop_h * scale)))
    crop = crop.resize(new_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    x = round((CANVAS_SIZE - new_size[0]) / 2)
    y = round((CANVAS_SIZE - new_size[1]) / 2)
    canvas.alpha_composite(crop, (x, y))
    return canvas


def fit_preview(image: Image.Image, size: int = 220) -> Image.Image:
    preview = Image.new("RGBA", (size, size), (28, 30, 34, 255))
    src = image.convert("RGBA")
    scale = min((size - 20) / src.width, (size - 20) / src.height)
    resized = src.resize((round(src.width * scale), round(src.height * scale)), Image.Resampling.LANCZOS)
    x = (size - resized.width) // 2
    y = (size - resized.height) // 2
    preview.alpha_composite(resized, (x, y))
    return preview


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    draw.text(xy, text, fill=(235, 238, 242), font=font)


def make_contact_sheet(originals: list[tuple[str, Image.Image]], normalized: list[tuple[str, Image.Image]]) -> None:
    cell_w = 240
    cell_h = 270
    sheet = Image.new("RGB", (cell_w * 2, cell_h * len(originals)), (18, 20, 24))
    draw = ImageDraw.Draw(sheet)
    for row, ((name, original), (_, clean)) in enumerate(zip(originals, normalized)):
        y = row * cell_h
        sheet.paste(fit_preview(original).convert("RGB"), (10, y + 34))
        sheet.paste(fit_preview(clean).convert("RGB"), (cell_w + 10, y + 34))
        draw_label(draw, (10, y + 8), f"Original: {name}")
        draw_label(draw, (cell_w + 10, y + 8), "Normalized 512")
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_DIR / "jump_grapple_before_after.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    idle = Image.open(ROOT / "Assets" / "Threadborne" / "Idle" / "Idleright.png").convert("RGBA")
    first_idle = idle.crop((0, 0, 512, 512))
    ref_mean, ref_std = visible_rgb_stats(first_idle)

    originals: list[tuple[str, Image.Image]] = []
    normalized: list[tuple[str, Image.Image]] = []
    for name, spec in SOURCES.items():
        src = spec["src"]
        clean = normalize_frame(src, int(spec["target_h"]), ref_mean, ref_std)
        clean.save(OUT_DIR / name)
        originals.append((name, Image.open(src).convert("RGBA")))
        normalized.append((name, clean))

    make_contact_sheet(originals, normalized)

    print(f"Wrote normalized frames to {OUT_DIR}")
    print(f"Wrote contact sheet to {CONTACT_DIR / 'jump_grapple_before_after.png'}")


if __name__ == "__main__":
    main()
