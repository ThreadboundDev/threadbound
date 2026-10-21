"""Package/import the Loom Heron v3 without changing other character assets.

Run package, prepare, the isolated Godot --headless --editor --import command,
then install. Import must finish successfully before install will accept it.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "work/loom-heron-v3"
SANDBOX = WORK / "import_project"
MODEL = ROOT / "Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v3.glb"
NEW_TEXTURES = ROOT / "Assets/BlueBiome/Enemies/LoomHeron/TexturesV3"
MANIFEST = WORK / "runtime_manifest.json"
FACTORS = WORK / "material_factors.json"
DEDUP_FOLDERS = [
    "Assets/BlueBiome/Characters/SharedTexturesV2",
    "Assets/BlueBiome/Enemies/LoomHeron/Textures",
    "Assets/BlueBiome/Enemies/EaveRunner/Textures",
    "Assets/BlueBiome/Art/Lakeside3D/Textures",
    "Assets/BlueBiome/Enemies/LoomHeron/TexturesV3",
]
CACHE_RE = re.compile(r"res://\.godot/imported/([^\"\n]+)")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, size = struct.unpack_from("<III", data)
    if magic != 0x46546C67 or version != 2 or size != len(data):
        raise ValueError(f"Invalid GLB: {path}")
    chunks = {}
    offset = 12
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunks[kind] = data[offset + 8 : offset + 8 + length]
        offset += 8 + length
    return json.loads(chunks[0x4E4F534A]), chunks.get(0x004E4942, b"")


def write_glb(path: Path, document: dict, binary: bytes) -> None:
    encoded = json.dumps(document, separators=(",", ":")).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary += b"\0" * (-len(binary) % 4)
    result = struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
    result += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    result += struct.pack("<II", len(binary), 0x004E4942) + binary
    path.write_bytes(result)


def relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def package() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    NEW_TEXTURES.mkdir(parents=True, exist_ok=True)
    known = {}
    # Prefer an existing canonical map to another duplicate with the same bytes.
    for folder in DEDUP_FOLDERS:
        for file in sorted((ROOT / folder).rglob("*.png")):
            known.setdefault(digest(file.read_bytes()), file)
    factors = json.loads(FACTORS.read_text())
    document, binary = read_glb(MODEL)
    for material in document.get("materials", []):
        name = material.get("name", "")
        if name in factors:
            value = factors[name]
            if len(value) != 4 or not all(isinstance(v, (int, float)) for v in value):
                raise ValueError(f"Invalid RGBA material factor: {name}")
            material.setdefault("pbrMetallicRoughness", {})["baseColorFactor"] = value
        material["doubleSided"] = True
    removed = set()
    images = []
    for entry in document.get("images", []):
        if "bufferView" in entry:
            index = entry.pop("bufferView")
            view = document["bufferViews"][index]
            start = view.get("byteOffset", 0)
            content = binary[start : start + view["byteLength"]]
            if not content.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Heron texture export must use PNG images")
            image_hash = digest(content)
            target = known.get(image_hash)
            if target is None:
                label = re.sub(r"[^A-Za-z0-9_-]", "_", entry.get("name", "Surface"))[:70]
                target = NEW_TEXTURES / f"{label}_{image_hash[:10]}.png"
                target.write_bytes(content)
                known[image_hash] = target
            entry["uri"] = os.path.relpath(target, MODEL.parent).replace("\\", "/")
            entry.pop("mimeType", None)
            removed.add(index)
        else:
            target = (MODEL.parent / entry["uri"]).resolve()
        if not target.is_file() or target.suffix.lower() != ".png":
            raise ValueError(f"Missing/unsupported texture: {target}")
        images.append(relative(target))

    rebuilt = bytearray()
    views, mapping, original_hashes = [], {}, []
    for index, view in enumerate(document.get("bufferViews", [])):
        if index in removed:
            continue
        start = view.get("byteOffset", 0)
        content = binary[start : start + view["byteLength"]]
        original_hashes.append(digest(content))
        rebuilt.extend(b"\0" * (-len(rebuilt) % 4))
        mapping[index] = len(views)
        views.append({**view, "byteOffset": len(rebuilt)})
        rebuilt.extend(content)

    def remap(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key == "bufferView":
                    value[key] = mapping[item]
                else:
                    remap(item)
        elif isinstance(value, list):
            for item in value:
                remap(item)

    document["bufferViews"] = views
    remap(document)
    document["buffers"][0]["byteLength"] = len(rebuilt)
    assert original_hashes == [digest(rebuilt[v["byteOffset"] : v["byteOffset"] + v["byteLength"]]) for v in views]
    write_glb(MODEL, document, bytes(rebuilt))
    normal_images = {
        document["textures"][m["normalTexture"]["index"]]["source"]
        for m in document.get("materials", []) if "normalTexture" in m
    }
    report = {
        "model": relative(MODEL), "bytes": MODEL.stat().st_size,
        "animations": [a["name"] for a in document.get("animations", [])],
        "textures": sorted(set(images)),
        "normal_textures": sorted({images[i] for i in normal_images}),
        "triangles": sum(document["accessors"][p["indices"]]["count"] // 3 for mesh in document.get("meshes", []) for p in mesh["primitives"]),
        "geometry_buffers_verified": len(views),
    }
    MANIFEST.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


def cache_files(sidecar: Path, project: Path) -> list[Path]:
    """Include variant-independent .md5, not the erroneous .bptc.md5 name."""
    files = set()
    for filename in set(CACHE_RE.findall(sidecar.read_text())):
        cache = project / ".godot/imported" / filename
        if cache.is_file():
            files.add(cache)
        stem = re.sub(r"(?:\.(?:bptc|s3tc|astc|etc2))?\.(?:ctex|scn)$", "", filename)
        md5 = cache.parent / (stem + ".md5")
        if md5.is_file():
            files.add(md5)
    return sorted(files)


def copy_cache(sidecar: Path, source_project: Path, destination: Path) -> int:
    files = cache_files(sidecar, source_project)
    for file in files:
        target = destination / file.relative_to(source_project)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file, target)
    return len(files)


def new_import(template: str, file: Path, extension: str) -> str:
    uri = "res://" + relative(file)
    cache = file.name + "-" + hashlib.md5(uri.encode()).hexdigest() + extension
    text = re.sub(r"^uid=.*\n", "", template, flags=re.M)
    text = CACHE_RE.sub("res://.godot/imported/" + cache, text)
    return re.sub(r"^source_file=.*$", 'source_file="' + uri + '"', text, flags=re.M)


def prepare() -> None:
    report = json.loads(MANIFEST.read_text())
    texture_template = (ROOT / "Assets/BlueBiome/Characters/SharedTexturesV2/IndigoWeave_BaseColor_4K.png.import").read_text()
    model_template = MODEL.with_name("LoomHeron_v2.glb.import").read_text()
    inputs = [ROOT / report["model"], *(ROOT / p for p in report["textures"])]
    for file in inputs:
        output = SANDBOX / relative(file)
        output.parent.mkdir(parents=True, exist_ok=True)
        old_import = file.with_suffix(file.suffix + ".import")
        sidecar = output.with_suffix(output.suffix + ".import")
        # Keep successful isolated texture imports on subsequent art revisions.
        # Replacing their cache with an older root copy while retaining the new
        # .md5 forces Godot to recompress unchanged 4K images unnecessarily.
        if file != MODEL and output.is_file() and sidecar.is_file():
            if digest(output.read_bytes()) == digest(file.read_bytes()):
                source_hash = hashlib.md5(file.read_bytes()).hexdigest()
                cached = cache_files(sidecar, SANDBOX)
                names = set(CACHE_RE.findall(sidecar.read_text()))
                complete = names and all((SANDBOX / ".godot/imported" / name).is_file() for name in names)
                checksum_ok = any(p.suffix == ".md5" and f'source_md5="{source_hash}"' in p.read_text() for p in cached)
                if complete and checksum_ok:
                    continue
        shutil.copy2(file, output)
        if file != MODEL and NEW_TEXTURES not in file.parents and old_import.is_file():
            shutil.copy2(old_import, sidecar)
            copy_cache(old_import, ROOT, SANDBOX)
        elif file == MODEL:
            text = new_import(model_template, file, ".scn")
            text = re.sub(r"^meshes/generate_lods=.*$", "meshes/generate_lods=false", text, flags=re.M)
            text = re.sub(r"^meshes/force_disable_compression=.*$", "meshes/force_disable_compression=true", text, flags=re.M)
            sidecar.write_text(text)
        else:
            text = new_import(texture_template, file, ".bptc.ctex")
            is_normal = relative(file) in report["normal_textures"]
            text = re.sub(r"^compress/normal_map=.*$", f"compress/normal_map={int(is_normal)}", text, flags=re.M)
            sidecar.write_text(text)
    (SANDBOX / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="Loom Heron v3 isolated import"\n'
        'config/features=PackedStringArray("4.7", "Forward Plus")\n'
        '[threading]\nworker_pool/max_threads=2\n'
    )
    print("HERON_V3_IMPORT_PREPARED", len(inputs), "files", SANDBOX)


def install() -> None:
    report = json.loads(MANIFEST.read_text())
    inputs = [ROOT / report["model"], *(ROOT / p for p in report["textures"])]
    # Preflight all dependencies before changing any production sidecars/cache.
    for file in inputs:
        copied = SANDBOX / relative(file)
        sidecar = copied.with_suffix(copied.suffix + ".import")
        if not sidecar.is_file() or 'uid="uid://' not in sidecar.read_text():
            raise RuntimeError(f"Godot import has not completed: {sidecar}")
        cache_names = set(CACHE_RE.findall(sidecar.read_text()))
        if not cache_names or not all((SANDBOX / ".godot/imported" / name).is_file() for name in cache_names):
            raise RuntimeError(f"Missing imported cache: {sidecar}")
        checksums = [p for p in cache_files(sidecar, SANDBOX) if p.suffix == ".md5"]
        source_hash = hashlib.md5(copied.read_bytes()).hexdigest()
        if not checksums or not any(f'source_md5="{source_hash}"' in p.read_text() for p in checksums):
            raise RuntimeError(f"Stale/incomplete imported source checksum: {copied}")
        if digest(file.read_bytes()) != digest(copied.read_bytes()):
            raise RuntimeError(f"Source changed after isolated import: {file}")
    count = 0
    for file in inputs:
        copied = SANDBOX / relative(file)
        sidecar = copied.with_suffix(copied.suffix + ".import")
        if file == MODEL or NEW_TEXTURES in file.parents:
            shutil.copy2(sidecar, file.with_suffix(file.suffix + ".import"))
        count += copy_cache(sidecar, SANDBOX, ROOT)
    print("HERON_V3_IMPORT_INSTALLED", count, "cache/checksum files")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("package", "prepare", "install"))
    args = parser.parse_args()
    {"package": package, "prepare": prepare, "install": install}[args.mode]()
