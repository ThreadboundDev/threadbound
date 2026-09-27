"""Normalize an ImageGen terrain render and place it on the authored KRA canvas."""

from __future__ import annotations

import os
from pathlib import Path
import shutil

import numpy as np
from PIL import Image


PROJECT = Path(__file__).resolve().parents[2]
KIT = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit"
GENERATED = Path.home() / ".codex/generated_images/01a03135-c67f-7e62-901c-94cb30e0c202"
RAW_NAME = os.environ.get(
    "THREADBOUND_PAINT_RAW_NAME",
    "exec-f1e2fc04-f632-4a3f-816d-d79d911330a0.png",
)
PASS_NAME = os.environ.get("THREADBOUND_PAINT_PASS", "01")
REFERENCE = KIT / "blue_biome_terrain_paint_reference.png"
BOUNDS_FILE = KIT / "blue_biome_terrain_paint_reference_bounds.txt"
RAW_ARCHIVE = KIT / "GeneratedPaint" / f"terrain_paint_test_{PASS_NAME}_raw.png"
OUTPUT = KIT / f"terrain_paint_test_{PASS_NAME}_canvas_layer.png"
CANVAS_SIZE = (4096, 2560)


def content_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    rgb = np.asarray(image.convert("RGB"))
    # Generated exterior is true/near black; the authored navy material is
    # lighter and remains selected. Restricting the threshold to the border
    # background keeps the deep rock crevices inside the crop.
    visible = rgb.max(axis=2) > 18
    ys, xs = np.nonzero(visible)
    if len(xs) == 0:
        raise RuntimeError("Generated paint pass contains no visible terrain")
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def main() -> None:
    source = GENERATED / RAW_NAME
    if not source.exists():
        raise FileNotFoundError(source)
    RAW_ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, RAW_ARCHIVE)

    reference = Image.open(REFERENCE).convert("RGBA")
    mask = reference.getchannel("A")
    generated = Image.open(source).convert("RGB")
    generated = generated.crop(content_bounds(generated))
    generated = generated.resize(reference.size, Image.Resampling.LANCZOS).convert("RGBA")
    generated.putalpha(mask)

    bounds = tuple(int(value) for value in BOUNDS_FILE.read_text(encoding="utf-8").split(","))
    if len(bounds) != 4:
        raise RuntimeError(f"Invalid authored bounds: {bounds}")
    left, top, right, bottom = bounds
    if (right - left, bottom - top) != reference.size:
        raise RuntimeError("Reference dimensions do not match its recorded canvas bounds")

    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    canvas.alpha_composite(generated, (left, top))
    canvas.save(OUTPUT, optimize=True)
    print(f"paint_layer={OUTPUT} size={canvas.size} authored_bounds={bounds}")


if __name__ == "__main__":
    main()
