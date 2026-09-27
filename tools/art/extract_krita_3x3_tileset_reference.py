"""Extract the authored upper-left 3x3 grid from the current Krita document."""

from pathlib import Path
import zipfile

import numpy as np
from PIL import Image


PROJECT = Path(__file__).resolve().parents[2]
KIT = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit"
SOURCE = KIT / "blue_biome_terrain_before_toolbox_restore.kra"
OUTPUT = KIT / "blue_biome_terrain_3x3_reference.png"
ATLAS_SIZE = 1536


def main() -> None:
    with zipfile.ZipFile(SOURCE) as archive:
        with archive.open("mergedimage.png") as merged:
            image = Image.open(merged).convert("RGBA").crop((0, 0, ATLAS_SIZE, ATLAS_SIZE))

    pixels = np.asarray(image).copy()
    # Remove only the cyan guide pixels. They are a viewing aid, not artwork.
    cyan_guide = (
        (pixels[:, :, 0] < 45)
        & (pixels[:, :, 1] > 85)
        & (pixels[:, :, 2] > 105)
        & ((pixels[:, :, 2].astype(int) - pixels[:, :, 0].astype(int)) > 70)
    )
    pixels[cyan_guide, 3] = 0
    yellow_forbidden = (
        (pixels[:, :, 0] > 175)
        & (pixels[:, :, 1] > 175)
        & (pixels[:, :, 2] < 115)
    )
    pixels[yellow_forbidden, 3] = 0
    # The guide is aligned exactly to the 512px grid. Clear its narrow bands
    # explicitly as Krita's color-managed projection makes the cyan darker
    # over the navy silhouette than it is over transparency.
    for coordinate in (0, 512, 1024, 1536):
        low = max(0, coordinate - 4)
        high = min(ATLAS_SIZE, coordinate + 5)
        pixels[:, low:high, 3] = 0
        pixels[low:high, :, 3] = 0
    Image.fromarray(pixels, "RGBA").save(OUTPUT, optimize=True)
    print(f"reference={OUTPUT} size={image.size} cells=3x3 cell_size=512")


if __name__ == "__main__":
    main()
