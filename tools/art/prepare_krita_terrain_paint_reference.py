"""Prepare a no-grid, tightly cropped reference from the terrain-composition KRA."""

from __future__ import annotations

from pathlib import Path
import os
import re
import shutil
import tempfile
import zipfile

from PIL import Image


PROJECT = Path(__file__).resolve().parents[2]
KIT = PROJECT / "ArtSource/BlueBiome/KritaTerrainKit"
SOURCE = Path(
    os.environ.get(
        "THREADBOUND_KRITA_SOURCE",
        str(KIT / "blue_biome_terrain_section_512_grid.kra"),
    )
)
NO_GRID = KIT / "blue_biome_terrain_section_no_grid_temp.kra"
FULL_EXPORT = KIT / "blue_biome_terrain_section_no_grid_full.png"
CROP = KIT / "blue_biome_terrain_paint_reference.png"
BOUNDS_FILE = KIT / "blue_biome_terrain_paint_reference_bounds.txt"


def make_no_grid_copy() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        unpacked = Path(temporary)
        with zipfile.ZipFile(SOURCE) as archive:
            archive.extractall(unpacked)
        document = unpacked / "maindoc.xml"
        xml = document.read_text(encoding="utf-8")
        hidden_layers = (
            "08 GUIDE - 512px Grid (toggle)",
            "PAINT TEST 01 - Generated Color",
        )
        for layer_name in hidden_layers:
            pattern = rf'(<layer(?=[^>]*name="{re.escape(layer_name)}")[^>]*\bvisible=")1(")'
            xml = re.sub(pattern, r"\g<1>0\g<2>", xml, count=1)
        document.write_text(xml, encoding="utf-8")
        with zipfile.ZipFile(NO_GRID, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as output:
            for path in unpacked.rglob("*"):
                if not path.is_file():
                    continue
                relative = path.relative_to(unpacked).as_posix()
                compression = zipfile.ZIP_STORED if relative == "mimetype" else zipfile.ZIP_DEFLATED
                output.write(path, relative, compress_type=compression)


def crop_export() -> None:
    image = Image.open(FULL_EXPORT).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("The exported terrain reference is empty")
    image.crop(bounds).save(CROP, optimize=True)
    BOUNDS_FILE.write_text(",".join(str(value) for value in bounds), encoding="utf-8")
    print(f"paint_reference={CROP} size={Image.open(CROP).size} bounds={bounds}")


if __name__ == "__main__":
    make_no_grid_copy()
    if FULL_EXPORT.exists():
        crop_export()
    else:
        print(f"no_grid_copy={NO_GRID}")
