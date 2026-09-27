"""Build the exact authored 3x3, 512px Krita terrain atlas."""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[2]
RAW = Path.home() / ".codex/generated_images/01a03135-c67f-7e62-901c-94cb30e0c202/exec-786927f7-644d-4dd7-81a0-17ae61caec66.png"
OUTPUT = PROJECT / "Assets/BlueBiome/Art/TerrainPaintTests/blue_biome_krita_tileset_poc_01.png"
ATLAS_SIZE = (1536, 1536)


def main() -> None:
    raw = Image.open(RAW).convert("RGB")
    # ImageGen encoded its transparency preview as a white checkerboard. Flood
    # fill only the border-connected checker so white flowers remain intact.
    keyed = raw.copy()
    ImageDraw.floodfill(keyed, (0, 0), (255, 0, 255), thresh=80)
    keyed_pixels = np.asarray(keyed)
    background = (
        (keyed_pixels[:, :, 0] == 255)
        & (keyed_pixels[:, :, 1] == 0)
        & (keyed_pixels[:, :, 2] == 255)
    )
    rgba = raw.convert("RGBA")
    alpha = np.full((raw.height, raw.width), 255, dtype=np.uint8)
    alpha[background] = 0
    rgba.putalpha(Image.fromarray(alpha, "L"))
    atlas = rgba.resize(ATLAS_SIZE, Image.Resampling.LANCZOS)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)
    print(f"atlas={OUTPUT} size={atlas.size} grid=3x3 cell=512")


if __name__ == "__main__":
    main()
