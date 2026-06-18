from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "art" / "concept_art" / "Weavers_Shuttle.png"
OUT_DIR = ROOT / "Assets" / "Threadborne" / "Equipment"
OUT_ASSET = OUT_DIR / "Weavers_Shuttle_Club.png"
OUT_SMEAR = OUT_DIR / "Weavers_Shuttle_Club_Smear.png"


def flood_background_alpha(image: Image.Image, threshold: int = 36) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    seen = set()
    q: deque[tuple[int, int]] = deque()

    for x in range(width):
        q.append((x, 0))
        q.append((x, height - 1))
    for y in range(height):
        q.append((0, y))
        q.append((width - 1, y))

    while q:
        x, y = q.popleft()
        if (x, y) in seen or x < 0 or y < 0 or x >= width or y >= height:
            continue
        seen.add((x, y))
        r, g, b, a = pixels[x, y]
        brightness = max(r, g, b)
        if a == 0 or brightness > threshold:
            continue

        pixels[x, y] = (r, g, b, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))

    return rgba


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if (x, y) in visited or alpha.getpixel((x, y)) <= 8:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            component: list[tuple[int, int]] = []
            visited.add((x, y))
            while q:
                px, py = q.popleft()
                component.append((px, py))
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height or (nx, ny) in visited:
                        continue
                    visited.add((nx, ny))
                    if alpha.getpixel((nx, ny)) > 8:
                        q.append((nx, ny))
            components.append(component)

    if not components:
        return rgba

    largest = max(components, key=len)
    keep = set(largest)
    pixels = rgba.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return rgba


def trim_alpha(image: Image.Image, padding: int = 8) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def center_on_canvas(image: Image.Image, size: tuple[int, int], scale_to_height: int) -> Image.Image:
    image = trim_alpha(image)
    scale = scale_to_height / image.height
    if image.width * scale > size[0] - 20:
        scale = (size[0] - 20) / image.width
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - resized.width) // 2
    y = (size[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def make_smear(asset: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (320, 220), (0, 0, 0, 0))
    base = trim_alpha(asset)
    base = base.resize((round(base.width * 0.58), round(base.height * 0.58)), Image.Resampling.LANCZOS)

    for i, angle in enumerate((-64, -42, -22, 0)):
        copy = base.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
        alpha = copy.getchannel("A")
        alpha = ImageEnhance.Brightness(alpha).enhance(0.16 + i * 0.11)
        copy.putalpha(alpha)
        tint = Image.new("RGBA", copy.size, (225, 195, 130, 255))
        copy = ImageChops.multiply(copy, tint)
        x = 34 + i * 24
        y = 76 - i * 12
        canvas.alpha_composite(copy, (x, y))

    leading = base.rotate(2, expand=True, resample=Image.Resampling.BICUBIC)
    x = 164
    y = 42
    canvas.alpha_composite(leading, (x, y))

    alpha = canvas.getchannel("A").filter(ImageFilter.GaussianBlur(0.35))
    canvas.putalpha(alpha)
    return trim_alpha(canvas, padding=10)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")

    # Front orthographic drawing from the concept sheet.
    front = source.crop((626, 618, 784, 1148))
    front = flood_background_alpha(front)
    front = keep_largest_alpha_component(front)
    front = center_on_canvas(front, (256, 256), 220)
    front.save(OUT_ASSET)

    smear = make_smear(front)
    smear.save(OUT_SMEAR)

    print(f"Wrote {OUT_ASSET}")
    print(f"Wrote {OUT_SMEAR}")


if __name__ == "__main__":
    main()
