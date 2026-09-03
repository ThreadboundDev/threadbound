"""Enforce repeatable contracts on the authored 3x3 terrain atlas."""

from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageFilter


PROJECT = Path(__file__).resolve().parents[2]
ASSETS = PROJECT / "Assets/BlueBiome/Art/TerrainPaintTests"
SOURCE = ASSETS / "blue_biome_krita_tileset_poc_01.png"
BACKUP = ASSETS / "blue_biome_krita_tileset_poc_01_pre_repeatable.png"
CENTER_RAW = Path.home() / ".codex/generated_images/01a03135-c67f-7e62-901c-94cb30e0c202/exec-8c38d211-4b16-43cd-be17-05b1957b2ea1.png"
OUTPUT = SOURCE
TILE = 512
SEAM = 48


def mirror_x(image: Image.Image) -> Image.Image:
    half = image.crop((0, 0, TILE // 2, TILE))
    result = Image.new("RGBA", (TILE, TILE))
    result.paste(half, (0, 0))
    result.paste(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (TILE // 2, 0))
    return result


def mirror_y(image: Image.Image) -> Image.Image:
    half = image.crop((0, 0, TILE, TILE // 2))
    result = Image.new("RGBA", (TILE, TILE))
    result.paste(half, (0, 0))
    result.paste(half.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, TILE // 2))
    return result


def mirror_xy(image: Image.Image) -> Image.Image:
    quarter = image.crop((TILE // 4, TILE // 4, TILE // 4 + TILE // 2, TILE // 4 + TILE // 2))
    quarter = quarter.resize((TILE // 2, TILE // 2), Image.Resampling.LANCZOS)
    top = Image.new("RGBA", (TILE, TILE // 2))
    top.paste(quarter, (0, 0))
    top.paste(quarter.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (TILE // 2, 0))
    result = Image.new("RGBA", (TILE, TILE))
    result.paste(top, (0, 0))
    result.paste(top.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, TILE // 2))
    return result


def paste_edge(target: Image.Image, source: Image.Image, target_edge: str, source_edge: str) -> None:
    if source_edge == "left":
        strip = source.crop((0, 0, SEAM, TILE))
    elif source_edge == "right":
        strip = source.crop((TILE - SEAM, 0, TILE, TILE))
    elif source_edge == "top":
        strip = source.crop((0, 0, TILE, SEAM))
    else:
        strip = source.crop((0, TILE - SEAM, TILE, TILE))

    # Adjacent tiles face one another, so reverse the copied strip across the
    # seam axis. This puts the source's boundary pixel directly against the
    # target's boundary pixel while the remaining strip feathers inward.
    if (target_edge, source_edge) in (("left", "right"), ("right", "left")):
        strip = strip.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    elif (target_edge, source_edge) in (("top", "bottom"), ("bottom", "top")):
        strip = strip.transpose(Image.Transpose.FLIP_TOP_BOTTOM)

    mask = Image.new("L", strip.size, 255)
    values = np.asarray(mask).copy()
    ramp = np.linspace(255, 0, SEAM, dtype=np.uint8)
    if target_edge == "left":
        values[:] = ramp[None, :]
        position = (0, 0)
    elif target_edge == "right":
        values[:] = ramp[::-1][None, :]
        position = (TILE - SEAM, 0)
    elif target_edge == "top":
        values[:] = ramp[:, None]
        position = (0, 0)
    else:
        values[:] = ramp[::-1][:, None]
        position = (0, TILE - SEAM)
    target.paste(strip, position, Image.fromarray(values, "L"))


def clean_transparency(image: Image.Image) -> Image.Image:
    pixels = np.asarray(image.convert("RGBA")).copy()
    pixels[pixels[:, :, 3] < 8] = (0, 0, 0, 0)
    return Image.fromarray(pixels, "RGBA")


def average_boundaries(tiles: list[list[Image.Image]]) -> list[list[Image.Image]]:
    arrays = [[np.asarray(tile).copy() for tile in row] for row in tiles]

    def vertical_group(members: list[tuple[int, int, int]]) -> None:
        values = [arrays[y][x][:, column].astype(np.uint16) for y, x, column in members]
        shared = (sum(values) // len(values)).astype(np.uint8)
        for y, x, column in members:
            arrays[y][x][:, column] = shared

    def horizontal_group(members: list[tuple[int, int, int]]) -> None:
        values = [arrays[y][x][row, :].astype(np.uint16) for y, x, row in members]
        shared = (sum(values) // len(values)).astype(np.uint8)
        for y, x, row in members:
            arrays[y][x][row, :] = shared

    vertical_group([(0, 0, -1), (0, 1, 0), (0, 1, -1), (0, 2, 0)])
    vertical_group([(1, 0, -1), (1, 1, 0), (1, 1, -1), (1, 2, 0)])
    vertical_group([(2, 0, -1), (2, 1, 0), (2, 1, -1), (2, 2, 0)])
    horizontal_group([(0, 0, -1), (1, 0, 0), (1, 0, -1), (2, 0, 0)])
    horizontal_group([(0, 1, -1), (1, 1, 0), (1, 1, -1), (2, 1, 0)])
    horizontal_group([(0, 2, -1), (1, 2, 0), (1, 2, -1), (2, 2, 0)])
    return [[Image.fromarray(arrays[y][x], "RGBA") for x in range(3)] for y in range(3)]


def main() -> None:
    if not BACKUP.exists():
        shutil.copy2(SOURCE, BACKUP)
    atlas = Image.open(BACKUP).convert("RGBA")
    tiles = [[atlas.crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE)) for x in range(3)] for y in range(3)]

    # Four edge middles repeat along their long axis. The clean center fill is
    # periodic in both axes and contains no flowers or landmark vegetation.
    tiles[0][1] = mirror_x(tiles[0][1])
    tiles[2][1] = mirror_x(tiles[2][1])
    tiles[1][0] = mirror_y(tiles[1][0])
    tiles[1][2] = mirror_y(tiles[1][2])
    center = Image.open(CENTER_RAW).convert("RGBA").resize((TILE, TILE), Image.Resampling.LANCZOS)
    tiles[1][1] = mirror_xy(center)

    # Make every inner edge share the center tile's exact rock continuation.
    paste_edge(tiles[0][1], tiles[1][1], "bottom", "top")
    paste_edge(tiles[2][1], tiles[1][1], "top", "bottom")
    paste_edge(tiles[1][0], tiles[1][1], "right", "left")
    paste_edge(tiles[1][2], tiles[1][1], "left", "right")

    # Corners inherit their two joining strips from the finalized edge tiles.
    paste_edge(tiles[0][0], tiles[0][1], "right", "left")
    paste_edge(tiles[0][0], tiles[1][0], "bottom", "top")
    paste_edge(tiles[0][2], tiles[0][1], "left", "right")
    paste_edge(tiles[0][2], tiles[1][2], "bottom", "top")
    paste_edge(tiles[2][0], tiles[2][1], "right", "left")
    paste_edge(tiles[2][0], tiles[1][0], "top", "bottom")
    paste_edge(tiles[2][2], tiles[2][1], "left", "right")
    paste_edge(tiles[2][2], tiles[1][2], "top", "bottom")

    tiles = average_boundaries(tiles)

    result = Image.new("RGBA", (TILE * 3, TILE * 3), (0, 0, 0, 0))
    for y in range(3):
        for x in range(3):
            result.alpha_composite(clean_transparency(tiles[y][x]), (x * TILE, y * TILE))
    result.save(OUTPUT, optimize=True)
    print(f"repeatable_atlas={OUTPUT} size={result.size} cell={TILE}")


if __name__ == "__main__":
    main()
