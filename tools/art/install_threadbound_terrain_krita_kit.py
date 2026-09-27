"""Build and install the focused Threadbound terrain-composition kit for Krita."""

from __future__ import annotations

import base64
from collections import deque
import hashlib
import io
import os
from pathlib import Path
import re
import shutil
import zipfile

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, PngImagePlugin


PROJECT = Path(__file__).resolve().parents[2]
GENERATED = Path.home() / ".codex/generated_images/01a03135-c67f-7e62-901c-94cb30e0c202"
KIT = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit"
RAW = KIT / "GeneratedRaw"
EXPORT = KIT / "Presets"
KRITA = Path(os.environ["APPDATA"]) / "krita"
BRUSHES = KRITA / "brushes"
PRESETS = KRITA / "paintoppresets"

ROCK_NAMES = (
    "Rock Single XS", "Rock Single S", "Rock Single M", "Rock Single L",
    "Rock Pair Low", "Rock Pair Tall", "Rock Pair Wide", "Rock Cluster Four",
    "Rock Cluster Three A", "Rock Cluster Three B", "Rock Edge Partial",
    "Rock Surface Broad",
)
GROWTH_NAMES = (
    "Moss Edge Short A", "Moss Edge Short B", "Moss Edge Short C",
    "Moss Edge Trail A", "Moss Edge Trail B", "Grass Short", "Grass Medium",
    "Grass Tall", "Vines A", "Vines B", "Ground Cover A", "Ground Cover B",
)
SIDE_GROWTH_NAMES = (
    "Left Wall Sparse", "Left Wall Medium", "Left Wall Lush", "Left Wall Long",
    "Right Wall Sparse", "Right Wall Medium", "Right Wall Lush", "Right Wall Long",
)
FLOWER_NAMES = (
    "Star Blossom Trio", "Five Petal Pair", "Daisy Cluster", "Hanging Bells",
    "Creeping Blossom Vine", "Flower Rosette", "Tiny Bloom Sprig", "Mixed Blossom Patch",
)

SHEETS = (
    ("exec-07046047-c25c-467e-a3b6-bc907512b3d9.png", "rocks", ROCK_NAMES),
    ("exec-e21dd243-5aa7-4e2c-b98e-cfc3d6d9985b.png", "growth", GROWTH_NAMES),
    ("exec-bc86e2d4-c96d-426c-b886-e1e8f7ed01f4.png", "side_growth", SIDE_GROWTH_NAMES),
    ("exec-a9d6a27e-829c-4373-b84d-7dd6f02a542d.png", "flowers", FLOWER_NAMES),
)

TOOL_TEMPLATES = (
    ("b)_Basic-1_Copy.kpp", "00 Flat Ink"),
    ("b)_Basic-5_Size_default.kpp", "01 Pressure Paint"),
    ("j)_WaterC_Basic_Round-Grain.kpp", "02 Texture Shade"),
    ("a)_Eraser_Circle.kpp", "03 Eraser"),
)


def component_boxes(image: Image.Image, expected: int) -> list[tuple[int, int, int, int]]:
    rgb = np.asarray(image.convert("RGB"))
    ink = (rgb.min(axis=2) < 125).astype(np.uint8) * 255
    expanded = Image.fromarray(ink).filter(ImageFilter.MaxFilter(31))
    mask = np.asarray(expanded) > 0
    height, width = mask.shape
    visited = np.zeros(mask.shape, dtype=np.bool_)
    boxes: list[tuple[int, int, int, int, int]] = []
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y, x] = True
            xs: list[int] = []
            ys: list[int] = []
            while queue:
                px, py = queue.popleft()
                xs.append(px)
                ys.append(py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and mask[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True
                        queue.append((nx, ny))
            if len(xs) > 1000:
                boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1, len(xs)))
    if len(boxes) != expected:
        raise RuntimeError(f"Expected {expected} separated stamps, found {len(boxes)}")
    boxes.sort(key=lambda box: (((box[1] + box[3]) // 2) // 180, box[0]))
    return [(a, b, c, d) for a, b, c, d, _ in boxes]


def extract_stamp(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    padding = 22
    left, top, right, bottom = box
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(sheet.width, right + padding)
    bottom = min(sheet.height, bottom + padding)
    crop = sheet.crop((left, top, right, bottom)).convert("RGB")
    gray = np.asarray(crop.convert("L"), dtype=np.int16)
    alpha = np.clip((225 - gray) * 5, 0, 255).astype(np.uint8)
    result = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    result.putalpha(Image.fromarray(alpha, "L"))
    visible = result.getbbox()
    if visible is None:
        raise RuntimeError("Extracted an empty stamp")
    result = result.crop(visible)
    canvas = Image.new("RGBA", (result.width + 32, result.height + 32), (0, 0, 0, 0))
    canvas.alpha_composite(result, (16, 16))
    return canvas


def renamed_preset(source: Path, display_name: str) -> Image.Image:
    image = Image.open(source)
    xml = image.info["preset"]
    xml = re.sub(r'name="[^"]*"', f'name="{display_name}"', xml, count=1)
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("preset", xml, zip=True)
    metadata.add_text("version", image.info.get("version", "5.0"))
    output = image.copy()
    output.info["_tb_metadata"] = metadata
    return output


def stamp_preset(template_path: Path, stamp: Image.Image, display_name: str, brush_name: str) -> tuple[Image.Image, PngImagePlugin.PngInfo]:
    template = Image.open(template_path)
    xml = template.info["preset"]
    buffer = io.BytesIO()
    stamp.save(buffer, "PNG")
    payload = buffer.getvalue()
    encoded = base64.b64encode(payload).decode("ascii")
    digest = hashlib.md5(payload).hexdigest()
    resource_name = Path(brush_name).stem

    xml = re.sub(r'name="[^"]*"', f'name="{display_name}"', xml, count=1)
    xml = re.sub(
        r'<resources>.*?</resources>',
        f'<resources> <resource filename="{brush_name}" md5sum="{digest}" name="{resource_name}" type="brushes"><![CDATA[{encoded}]]></resource> </resources>',
        xml,
        count=1,
        flags=re.DOTALL,
    )
    xml = re.sub(
        r'<param name="brush_definition" type="string"><!\[CDATA\[.*?\]\]></param>',
        '<param name="brush_definition" type="string"><![CDATA['
        f'<Brush scale="1" spacing="0.1" ContrastAdjustment="0" brushApplication="0" '
        f'BrushVersion="2" angle="0" AdjustmentMidPoint="127" filename="{brush_name}" '
        f'AutoAdjustMidPoint="1" BrightnessAdjustment="0" md5sum="{digest}" useAutoSpacing="0" '
        'ColorAsMask="1" type="png_brush" autoSpacingCoeff="1" AdjustmentVersion="2"/> '
        ']]></param>',
        xml,
        count=1,
        flags=re.DOTALL,
    )

    preview = Image.new("RGBA", (200, 200), (235, 238, 238, 255))
    icon = stamp.copy()
    icon.thumbnail((176, 176), Image.Resampling.LANCZOS)
    preview.alpha_composite(icon, ((200 - icon.width) // 2, (200 - icon.height) // 2))
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("preset", xml, zip=True)
    metadata.add_text("version", template.info.get("version", "5.0"))
    return preview, metadata


def make_working_document() -> Path:
    width, height, grid = 4096, 2560, 512
    transparent = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    background = Image.new("RGBA", (width, height), (232, 238, 239, 255))
    grid_layer = transparent.copy()
    draw = ImageDraw.Draw(grid_layer)
    for x in range(0, width + 1, grid):
        draw.line((x, 0, x, height), fill=(36, 168, 205, 125), width=3)
    for y in range(0, height + 1, grid):
        draw.line((0, y, width, y), fill=(36, 168, 205, 125), width=3)

    layers = [
        ("08 GUIDE - 512px Grid (toggle)", grid_layer),
        ("07 Highlights", transparent),
        ("06 Shading", transparent),
        ("05 Flat Colors", transparent),
        ("04 Grass and Moss Line Art", transparent),
        ("03 Rock Line Art", transparent),
        ("02 Terrain Silhouette - fill navy", transparent),
        ("01 Background (toggle)", background),
    ]
    ora = KIT / "blue_biome_terrain_section_512_grid.ora"
    preview = background.copy()
    preview.alpha_composite(grid_layer)
    stack = ['<?xml version="1.0" encoding="UTF-8"?>', f'<image version="0.0.1" w="{width}" h="{height}" name="Blue Biome Terrain Section">', ' <stack>']
    with zipfile.ZipFile(ora, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        for index, (name, layer) in enumerate(layers):
            path = f"data/layer_{index:02d}.png"
            data = io.BytesIO()
            layer.save(data, "PNG", optimize=True)
            archive.writestr(path, data.getvalue())
            locked = ' edit-locked="true"' if "GUIDE" in name or "Background" in name else ""
            stack.append(f'  <layer name="{name}" src="{path}" visibility="visible"{locked}/>')
        stack.extend([" </stack>", "</image>"])
        archive.writestr("stack.xml", "\n".join(stack))
        merged = io.BytesIO(); preview.save(merged, "PNG", optimize=True)
        thumb = preview.copy(); thumb.thumbnail((256, 256), Image.Resampling.LANCZOS)
        thumb_data = io.BytesIO(); thumb.save(thumb_data, "PNG")
        archive.writestr("mergedimage.png", merged.getvalue())
        archive.writestr("Thumbnails/thumbnail.png", thumb_data.getvalue())
    return ora


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)
    BRUSHES.mkdir(parents=True, exist_ok=True)
    PRESETS.mkdir(parents=True, exist_ok=True)

    template = PRESETS / "Line.kpp"
    if not template.exists():
        raise FileNotFoundError(f"Known-working Krita stamp template is missing: {template}")

    for old in PRESETS.glob("TB_Blue_Biome_*.kpp"):
        old.unlink()
    for old in BRUSHES.glob("threadbound_blue_biome_stamp_*.png"):
        old.unlink()
    for old in PRESETS.glob("TB_TERRAIN_*.kpp"):
        old.unlink()
    for old in BRUSHES.glob("tb_terrain_*.png"):
        old.unlink()
    for old in EXPORT.glob("*"):
        if old.is_file():
            old.unlink()

    count = 0
    for filename, kind, names in SHEETS:
        source = GENERATED / filename
        if not source.exists():
            raise FileNotFoundError(source)
        shutil.copy2(source, RAW / f"{kind}_line_art_sheet_raw.png")
        sheet = Image.open(source).convert("RGB")
        boxes = component_boxes(sheet, len(names))
        for index, (box, name) in enumerate(zip(boxes, names), start=1):
            stamp = extract_stamp(sheet, box)
            brush_name = f"tb_terrain_{kind}_{index:02d}.png"
            preset_name = f"TB_TERRAIN_{kind.upper()}_{index:02d}.kpp"
            display = f"TB TERRAIN | {kind.title()} {index:02d} - {name}"
            stamp.save(BRUSHES / brush_name, optimize=True)
            stamp.save(EXPORT / brush_name, optimize=True)
            preview, metadata = stamp_preset(template, stamp, display, brush_name)
            preview.save(PRESETS / preset_name, "PNG", pnginfo=metadata)
            preview.save(EXPORT / preset_name, "PNG", pnginfo=metadata)
            count += 1

    for index, (filename, label) in enumerate(TOOL_TEMPLATES):
        source = PRESETS / filename
        if not source.exists():
            continue
        image = Image.open(source)
        xml = re.sub(r'name="[^"]*"', f'name="TB TERRAIN | {label}"', image.info["preset"], count=1)
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text("preset", xml, zip=True)
        metadata.add_text("version", image.info.get("version", "5.0"))
        destination = f"TB_TERRAIN_TOOL_{index:02d}.kpp"
        image.save(PRESETS / destination, "PNG", pnginfo=metadata)
        image.save(EXPORT / destination, "PNG", pnginfo=metadata)

    ora = make_working_document()
    print(f"Installed {count} embedded terrain stamps and {len(TOOL_TEMPLATES)} focused tools")
    print(f"Working document: {ora}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
