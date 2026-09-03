"""Extract exact 512px working tiles from the current 3x3 terrain atlas."""

from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[2]
ASSETS = PROJECT / "Assets/BlueBiome/Art/TerrainPaintTests"
SOURCE = ASSETS / "blue_biome_krita_tileset_poc_01.png"
WORK = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit/Repeatable3x3Work"


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    if atlas.size != (1536, 1536):
        raise RuntimeError(f"Expected 1536x1536 atlas, got {atlas.size}")
    WORK.mkdir(parents=True, exist_ok=True)
    names = (
        ("top_left", "top_middle", "top_right"),
        ("left_middle", "center", "right_middle"),
        ("bottom_left", "bottom_middle", "bottom_right"),
    )
    for y, row in enumerate(names):
        for x, name in enumerate(row):
            tile = atlas.crop((x * 512, y * 512, (x + 1) * 512, (y + 1) * 512))
            tile.save(WORK / f"{name}.png", optimize=True)
    print(f"Extracted nine exact 512px tiles to {WORK}")


if __name__ == "__main__":
    main()
