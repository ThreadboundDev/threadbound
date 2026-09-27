"""Build a tangent-space normal map from a transparent terrain albedo."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--strength", type=float, default=2.2)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    alpha = source.getchannel("A")
    height = source.convert("L").filter(ImageFilter.GaussianBlur(radius=1.25))
    width, height_px = source.size
    src = height.load()
    mask = alpha.load()
    normal = Image.new("RGBA", source.size, (128, 128, 255, 0))
    dst = normal.load()

    for y in range(height_px):
        ym = max(0, y - 1)
        yp = min(height_px - 1, y + 1)
        for x in range(width):
            if mask[x, y] == 0:
                continue
            xm = max(0, x - 1)
            xp = min(width - 1, x + 1)
            dx = (src[xp, y] - src[xm, y]) / 255.0 * args.strength
            dy = (src[x, yp] - src[x, ym]) / 255.0 * args.strength
            nx, ny, nz = -dx, -dy, 1.0
            length = (nx * nx + ny * ny + nz * nz) ** 0.5
            dst[x, y] = (
                round((nx / length * 0.5 + 0.5) * 255),
                round((ny / length * 0.5 + 0.5) * 255),
                round((nz / length * 0.5 + 0.5) * 255),
                mask[x, y],
            )

    args.destination.parent.mkdir(parents=True, exist_ok=True)
    normal.save(args.destination)


if __name__ == "__main__":
    main()
