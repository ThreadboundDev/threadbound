"""Convert the authored nine-panel render into an exact 1536px Godot atlas."""

from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageFilter


PROJECT = Path(__file__).resolve().parents[2]
RAW = Path.home() / ".codex/generated_images/01a03135-c67f-7e62-901c-94cb30e0c202/exec-a93c7922-e7f4-4f64-9cbe-0b13b440aca6.png"
ASSETS = PROJECT / "Assets/BlueBiome/Art/TerrainPaintTests"
OUTPUT = ASSETS / "blue_biome_krita_tileset_poc_01.png"
ARCHIVE = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit/GeneratedPaint/terrain_tileset_3x3_authored_gutters_raw.png"
CELL = 512
BASE_NAVY = (16, 38, 61, 255)


def remove_checker(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    pixels = np.asarray(rgb)
    # This pass intentionally contains no white flowers, so every bright
    # near-neutral pixel is generator checker/matte and can be removed. Doing
    # this globally (rather than border flood-fill only) also removes the
    # checker gutters separating the nine rendered panels.
    background = (
        (pixels.min(axis=2) > 210)
        & ((pixels.max(axis=2).astype(int) - pixels.min(axis=2).astype(int)) < 28)
    )
    alpha = Image.fromarray((~background).astype(np.uint8) * 255, "L")
    # Pull the silhouette one source pixel inward to discard antialiasing that
    # was composited against the generator's white checker preview.
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def clean_tile(tile: Image.Image, column: int, row: int) -> Image.Image:
    bounds = tile.getchannel("A").getbbox()
    if bounds is None:
        return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    left, top, right, bottom = bounds
    # Remove the dark presentation frame ImageGen placed around each panel,
    # but only on edges that meet another tile. Preserve the true exterior
    # foliage/ceiling silhouette on the outside of the 3x3 set.
    inset = 5
    if column > 0:
        left += inset
    if column < 2:
        right -= inset
    if row > 0:
        top += inset
    if row < 2:
        bottom -= inset
    tile = tile.crop((left, top, right, bottom)).resize((CELL, CELL), Image.Resampling.LANCZOS)
    pixels = np.asarray(tile).copy()
    pixels[pixels[:, :, 3] < 12] = (0, 0, 0, 0)
    # Any remaining pale, partially transparent matte belongs to the removed
    # checker, not the dark-outlined terrain.
    pale_fringe = (
        (pixels[:, :, 3] < 245)
        & (pixels[:, :, :3].min(axis=2) > 205)
    )
    pixels[pale_fringe] = (0, 0, 0, 0)
    # Internal boundaries are opaque base material, never holes. One exact
    # shared navy pixel is enough to prevent filtering from exposing a seam
    # without creating another conspicuous empty corridor.
    if column > 0:
        pixels[:, 0] = BASE_NAVY
    if column < 2:
        pixels[:, -1] = BASE_NAVY
    if row > 0:
        pixels[0, :] = BASE_NAVY
    if row < 2:
        pixels[-1, :] = BASE_NAVY
    return Image.fromarray(pixels, "RGBA")


def main() -> None:
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(RAW, ARCHIVE)
    raw = remove_checker(Image.open(RAW))
    atlas = Image.new("RGBA", (CELL * 3, CELL * 3), (0, 0, 0, 0))
    for y in range(3):
        top = round(y * raw.height / 3)
        bottom = round((y + 1) * raw.height / 3)
        for x in range(3):
            left = round(x * raw.width / 3)
            right = round((x + 1) * raw.width / 3)
            tile = clean_tile(raw.crop((left, top, right, bottom)), x, y)
            atlas.alpha_composite(tile, (x * CELL, y * CELL))
    atlas.save(OUTPUT, optimize=True)
    print(f"atlas={OUTPUT} size={atlas.size} cells=3x3 cell_size={CELL}")


if __name__ == "__main__":
    main()
