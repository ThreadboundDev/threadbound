from __future__ import annotations

from pathlib import Path
import re

import numpy as np
from PIL import Image, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
TILES = ROOT / "Assets" / "chamber_of_first_weave" / "Tiles"
READABLE_OUT = TILES / "generated_versions" / "readable_passes"

PASS_NAME = "readable_v2"

SRC_256 = TILES / "cotfw_chamber_tileset_atlas_256_current.png"
OUT_256 = READABLE_OUT / f"cotfw_chamber_tileset_atlas_256_{PASS_NAME}.png"
OUT_128 = READABLE_OUT / f"cotfw_chamber_tileset_atlas_128_{PASS_NAME}.png"
OUT_COMPARE = READABLE_OUT / f"cotfw_chamber_tileset_{PASS_NAME}_compare.png"

LAYOUT_256 = TILES / "cotfw_chamber_tileset_atlas_256_current_layout.txt"
LAYOUT_128 = TILES / "cotfw_chamber_tileset_atlas_128_current_layout.txt"
OUT_LAYOUT_256 = READABLE_OUT / f"cotfw_chamber_tileset_atlas_256_{PASS_NAME}_layout.txt"
OUT_LAYOUT_128 = READABLE_OUT / f"cotfw_chamber_tileset_atlas_128_{PASS_NAME}_layout.txt"

TILESET_128 = TILES / "cotfw_chamber_tileset_128_current.tres"
TILESET_256 = TILES / "cotfw_chamber_tileset_256_current.tres"
OUT_TILESET_128 = READABLE_OUT / f"cotfw_chamber_tileset_128_{PASS_NAME}.tres"
OUT_TILESET_256 = READABLE_OUT / f"cotfw_chamber_tileset_256_{PASS_NAME}.tres"


def rgba_to_hsv_masks(arr: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    rgb = arr[..., :3].astype(np.float32) / 255.0
    alpha = arr[..., 3].astype(np.float32) / 255.0
    maxc = rgb.max(axis=2)
    minc = rgb.min(axis=2)
    delta = maxc - minc
    sat = np.where(maxc <= 0.0001, 0.0, delta / maxc)
    return rgb, alpha, sat, maxc


def lerp_rgb(base: np.ndarray, target: np.ndarray, mask: np.ndarray, amount: float) -> np.ndarray:
    out = base.copy()
    m = (mask.astype(np.float32) * amount)[..., None]
    out[..., :3] = out[..., :3] * (1.0 - m) + target[..., :3] * m
    return out


def make_inner_outline(alpha: Image.Image, radius: int) -> Image.Image:
    eroded = alpha.filter(ImageFilter.MinFilter(radius * 2 + 1))
    outline = Image.fromarray(np.maximum(np.array(alpha, dtype=np.int16) - np.array(eroded, dtype=np.int16), 0).astype(np.uint8))
    return outline.filter(ImageFilter.GaussianBlur(max(0.4, radius * 0.35)))


def readable_pass(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    arr = np.array(src).astype(np.float32)
    rgb, alpha, sat, val = rgba_to_hsv_masks(arr.astype(np.uint8))

    opaque = alpha > 0.08
    r = rgb[..., 0]
    g = rgb[..., 1]
    b = rgb[..., 2]

    greenish = opaque & (g > r * 0.92) & (g > b * 1.08) & (val > 0.08)
    bronze = opaque & (r > 0.22) & (g > 0.16) & (r >= g * 0.92) & (g > b * 1.18) & (sat > 0.18)
    stone = opaque & ~greenish & ~bronze & ((sat < 0.42) | (val < 0.24)) & (val < 0.58)

    height, width = alpha.shape
    cell = 256
    local_y = np.indices((height, width))[0] % cell
    local_x = np.indices((height, width))[1] % cell
    top_edge_band = local_y < 46
    side_edge_band = (local_x < 34) | (local_x > cell - 35)
    interior_green = greenish & ~top_edge_band & ~side_edge_band

    # Broad painterly planes: blur and lightly posterize only the noisy stone masses.
    blurred_image = src.filter(ImageFilter.GaussianBlur(4.4))
    poster_rgb = ImageOps.posterize(blurred_image.convert("RGB"), 4).convert("RGBA")
    poster = np.array(poster_rgb).astype(np.float32)
    poster[..., 3] = arr[..., 3]
    smoothed = lerp_rgb(arr, poster, stone, 0.86)

    # Calm grass chatter without erasing the organic top silhouette.
    grass_blur = np.array(src.filter(ImageFilter.GaussianBlur(1.6))).astype(np.float32)
    smoothed = lerp_rgb(smoothed, grass_blur, greenish, 0.38)

    # Interior moss becomes a quiet black mass, like the Mossy pack.
    dark_moss = smoothed.copy()
    dark_moss[..., 0] *= 0.08
    dark_moss[..., 1] *= 0.10
    dark_moss[..., 2] *= 0.08
    smoothed = lerp_rgb(smoothed, dark_moss, interior_green, 0.94)

    # Bring platform/wall centers into larger value groups.
    stone_shadow = smoothed.copy()
    stone_shadow[..., 0] *= 0.82
    stone_shadow[..., 1] *= 0.83
    stone_shadow[..., 2] *= 0.84
    smoothed = lerp_rgb(smoothed, stone_shadow, stone, 0.48)

    # Subtle per-tile dark fade keeps large fills calm and edge-led.
    tile_fade = np.clip((local_y.astype(np.float32) - 52.0) / 190.0, 0.0, 1.0)
    fade_mask = stone & ~top_edge_band
    faded = smoothed.copy()
    faded[..., :3] *= (1.0 - tile_fade[..., None] * 0.12)
    smoothed = np.where(fade_mask[..., None], faded, smoothed)

    # Keep bronze/gold trim crisp enough to define edges.
    crisp = np.array(src.filter(ImageFilter.UnsharpMask(radius=1.0, percent=90, threshold=5))).astype(np.float32)
    smoothed = lerp_rgb(smoothed, crisp, bronze, 0.34)

    # Add crisp dark interior edge support so silhouettes read at gameplay distance.
    alpha_img = src.getchannel("A")
    outline = np.array(make_inner_outline(alpha_img, 3)).astype(np.float32) / 255.0
    outline_mask = (outline > 0.02) & opaque
    dark = smoothed.copy()
    dark[..., :3] *= 0.48
    smoothed = lerp_rgb(smoothed, dark, outline_mask, 0.56)

    # Reduce isolated white fringe/noisy antialias sparkle around transparent edges.
    fringe = opaque & (alpha < 0.92) & (val > 0.55) & ~bronze
    smoothed[..., :3] = np.where(fringe[..., None], smoothed[..., :3] * 0.72, smoothed[..., :3])
    low_alpha = (alpha > 0.0) & (alpha < 0.18)
    smoothed[..., :3] = np.where(low_alpha[..., None], smoothed[..., :3] * 0.35, smoothed[..., :3])

    smoothed[..., 3] = arr[..., 3]
    return Image.fromarray(np.clip(smoothed, 0, 255).astype(np.uint8), "RGBA")


def downscale_128(img: Image.Image) -> Image.Image:
    return img.resize((img.width // 2, img.height // 2), Image.Resampling.LANCZOS)


def write_retargeted_tileset(src: Path, out: Path, old_atlas: str, new_atlas: str) -> None:
    text = src.read_text(encoding="utf-8")
    text = re.sub(r"\[gd_resource type=\"TileSet\" format=3 uid=\"uid://[^\"]+\"\]", "[gd_resource type=\"TileSet\" format=3]", text)
    text = re.sub(r"\[ext_resource type=\"Texture2D\" uid=\"uid://[^\"]+\" path=", "[ext_resource type=\"Texture2D\" path=", text)
    text = text.replace(old_atlas, new_atlas)
    suffix = "128" if "128" in out.stem else "256"
    text = text.replace("TileSetAtlasSource_current_128", f"TileSetAtlasSource_{PASS_NAME}_{suffix}")
    text = text.replace("TileSetAtlasSource_current_256", f"TileSetAtlasSource_{PASS_NAME}_{suffix}")
    text = text.replace("TileSetAtlasSource_current", f"TileSetAtlasSource_{PASS_NAME}_{suffix}")
    out.write_text(text, encoding="utf-8")


def make_compare(original: Image.Image, readable: Image.Image) -> Image.Image:
    scale_w = 512
    original_small = original.resize((scale_w, int(original.height * scale_w / original.width)), Image.Resampling.LANCZOS)
    readable_small = readable.resize(original_small.size, Image.Resampling.LANCZOS)
    compare = Image.new("RGBA", (original_small.width * 2 + 24, original_small.height), (24, 24, 24, 255))
    compare.alpha_composite(original_small, (0, 0))
    compare.alpha_composite(readable_small, (original_small.width + 24, 0))
    return compare


def main() -> None:
    READABLE_OUT.mkdir(parents=True, exist_ok=True)
    original = Image.open(SRC_256).convert("RGBA")
    readable = readable_pass(original)
    readable_128 = downscale_128(readable)

    readable.save(OUT_256)
    readable_128.save(OUT_128)
    make_compare(original, readable).save(OUT_COMPARE)

    OUT_LAYOUT_256.write_text(LAYOUT_256.read_text(encoding="utf-8").replace("_current", f"_{PASS_NAME}"), encoding="utf-8")
    OUT_LAYOUT_128.write_text(LAYOUT_128.read_text(encoding="utf-8").replace("_current", f"_{PASS_NAME}"), encoding="utf-8")

    write_retargeted_tileset(
        TILESET_128,
        OUT_TILESET_128,
        "cotfw_chamber_tileset_atlas_128_current.png",
        f"generated_versions/readable_passes/cotfw_chamber_tileset_atlas_128_{PASS_NAME}.png",
    )
    write_retargeted_tileset(
        TILESET_256,
        OUT_TILESET_256,
        "cotfw_chamber_tileset_atlas_256_current.png",
        f"generated_versions/readable_passes/cotfw_chamber_tileset_atlas_256_{PASS_NAME}.png",
    )

    print(OUT_256)
    print(OUT_128)
    print(OUT_COMPARE)
    print(OUT_TILESET_128)
    print(OUT_TILESET_256)


if __name__ == "__main__":
    main()
