"""Install Threadbound blue-biome line-art stamps as personal Krita presets."""

from __future__ import annotations

import os
import re
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, PngImagePlugin


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_SHEET = (
    PROJECT_ROOT
    / "ArtSource/BlueBiome/ChamberExitRooftops/LineArtGuide/blue_biome_environment_ink_stamp_sheet_01.png"
)
KRITA_ROOT = Path(os.environ["APPDATA"]) / "krita"
BRUSH_DIR = KRITA_ROOT / "brushes"
PRESET_DIR = KRITA_ROOT / "paintoppresets"
TEMPLATE_PRESET = PRESET_DIR / "a)_Eraser_Circle.kpp"
PROJECT_EXPORT_DIR = (
    PROJECT_ROOT / "ArtSource/BlueBiome/ChamberExitRooftops/LineArtGuide/KritaStampPresets"
)
PREFIX = "threadbound_blue_biome_stamp_"

# Fixed source-sheet regions. These are intentionally hand-authored instead of
# inferred from alpha connectivity, because nearby ink fragments belong to the
# same visual stamp and automatic component splitting produced clipped presets.
MANUAL_STAMPS = [
    ("Rock Cluster A", (0, 0, 245, 200)),
    ("Rock Cluster B", (245, 0, 490, 200)),
    ("Rock Cluster C", (490, 0, 735, 200)),
    ("Rock Cluster D", (735, 0, 980, 200)),
    ("Moss Edge A", (0, 390, 245, 530)),
    ("Moss Edge B", (490, 390, 735, 530)),
    ("Moss Edge C", (975, 390, 1222, 530)),
    ("Root Cluster A", (0, 530, 230, 795)),
    ("Root Cluster B", (490, 530, 720, 795)),
    ("Root Cluster C", (985, 530, 1222, 795)),
    ("Corner Growth A", (0, 1000, 225, 1275)),
    ("Corner Growth B", (510, 1000, 685, 1275)),
    ("Flower Accents", (920, 1000, 1222, 1275)),
]


def component_boxes(image: Image.Image) -> list[tuple[int, int, int, int]]:
    alpha = image.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(17))
    small = expanded.resize((expanded.width // 2, expanded.height // 2), Image.Resampling.NEAREST)
    mask = np.asarray(small) > 20
    visited = np.zeros(mask.shape, dtype=bool)
    height, width = mask.shape
    boxes: list[tuple[int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y, x] = True
            min_x = max_x = x
            min_y = max_y = y
            count = 0
            while queue:
                px, py = queue.popleft()
                count += 1
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                min_y = min(min_y, py)
                max_y = max(max_y, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and mask[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True
                        queue.append((nx, ny))
            box_width = max_x - min_x + 1
            box_height = max_y - min_y + 1
            if count >= 110 and box_width >= 18 and box_height >= 18:
                padding = 18
                boxes.append(
                    (
                        max(0, min_x * 2 - padding),
                        max(0, min_y * 2 - padding),
                        min(image.width, (max_x + 1) * 2 + padding),
                        min(image.height, (max_y + 1) * 2 + padding),
                    )
                )
    boxes.sort(key=lambda box: (box[1] // 120, box[0]))
    return boxes


def preset_xml(template: str, display_name: str, brush_filename: str, diameter: int) -> str:
    xml = re.sub(r'<Preset([^>]*)name="[^"]*"', rf'<Preset\1name="{display_name}"', template, count=1)
    xml = xml.replace("<![CDATA[erase]]>", "<![CDATA[normal]]>", 1)
    xml = xml.replace('<![CDATA[true]]></param> <param type="string" name="PressureSoftness"', '<![CDATA[false]]></param> <param type="string" name="PressureSoftness"', 1)
    xml = re.sub(
        r'<param type="string" name="brush_definition"><!\[CDATA\[.*?\]\]></param>',
        (
            '<param type="string" name="brush_definition"><![CDATA['
            f'<Brush BrightnessAdjustment="0" useAutoSpacing="0" angle="0" scale="1" '
            f'AdjustmentMidPoint="127" BrushVersion="2" ContrastAdjustment="0" spacing="2" '
            f'preserveLightness="0" ColorAsMask="1" filename="{brush_filename}" '
            'autoSpacingCoeff="1" type="png_brush"/> ]]></param>'
        ),
        xml,
        count=1,
        flags=re.DOTALL,
    )
    xml = re.sub(
        r'<param type="string" name="requiredBrushFile"><!\[CDATA\[.*?\]\]></param>',
        f'<param type="string" name="requiredBrushFile"><![CDATA[{brush_filename}]]></param>',
        xml,
        count=1,
        flags=re.DOTALL,
    )
    xml = xml.replace("<Preset ", '<Preset embedded_resources="0" ', 1) if "embedded_resources=" not in xml else xml
    xml = re.sub(r'<MaskGenerator([^>]*)diameter="[^"]*"', rf'<MaskGenerator\1diameter="{diameter}"', xml)
    return xml


def make_preview(stamp: Image.Image) -> Image.Image:
    preview = Image.new("RGBA", (200, 200), (229, 232, 229, 255))
    sample = stamp.copy()
    sample.thumbnail((176, 176), Image.Resampling.LANCZOS)
    dark = Image.new("RGBA", sample.size, (16, 30, 42, 255))
    dark.putalpha(sample.getchannel("A"))
    preview.alpha_composite(dark, ((200 - sample.width) // 2, (200 - sample.height) // 2))
    return preview


def main() -> int:
    if not SOURCE_SHEET.exists():
        raise FileNotFoundError(SOURCE_SHEET)
    if not TEMPLATE_PRESET.exists():
        raise FileNotFoundError(TEMPLATE_PRESET)

    BRUSH_DIR.mkdir(parents=True, exist_ok=True)
    PRESET_DIR.mkdir(parents=True, exist_ok=True)
    PROJECT_EXPORT_DIR.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(SOURCE_SHEET).convert("RGBA")
    template_image = Image.open(TEMPLATE_PRESET)
    template_xml = template_image.info["preset"]
    template_version = template_image.info.get("version", "5.0")

    for path in BRUSH_DIR.glob(f"{PREFIX}*.png"):
        path.unlink()
    for path in PRESET_DIR.glob("TB_Blue_Biome_*.kpp"):
        path.unlink()
    for path in PROJECT_EXPORT_DIR.glob(f"{PREFIX}*.png"):
        path.unlink()
    for path in PROJECT_EXPORT_DIR.glob("TB_Blue_Biome_*.kpp"):
        path.unlink()

    installed: list[str] = []
    for index, (asset_name, box) in enumerate(MANUAL_STAMPS, start=1):
        stamp = sheet.crop(box)
        alpha_box = stamp.getchannel("A").getbbox()
        if alpha_box is None:
            continue
        stamp = stamp.crop(alpha_box)
        canvas = Image.new("RGBA", (stamp.width + 32, stamp.height + 32), (0, 0, 0, 0))
        ink = Image.new("RGBA", stamp.size, (0, 0, 0, 255))
        ink.putalpha(stamp.getchannel("A"))
        canvas.alpha_composite(ink, (16, 16))

        stem = f"{PREFIX}{index:02d}"
        brush_filename = f"{stem}.png"
        safe_name = asset_name.replace(" ", "_")
        preset_filename = f"TB_Blue_Biome_{safe_name}.kpp"
        display_name = f"TB Blue Biome - {asset_name}"

        canvas.save(BRUSH_DIR / brush_filename)
        canvas.save(PROJECT_EXPORT_DIR / brush_filename)
        xml = preset_xml(template_xml, display_name, brush_filename, max(canvas.size))
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text("preset", xml, zip=True)
        metadata.add_text("version", template_version)
        preview = make_preview(canvas)
        preview.save(PRESET_DIR / preset_filename, format="PNG", pnginfo=metadata)
        preview.save(PROJECT_EXPORT_DIR / preset_filename, format="PNG", pnginfo=metadata)
        installed.append(display_name)

    print(f"KRITA_STAMPS_INSTALLED count={len(installed)}")
    for name in installed:
        print(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
