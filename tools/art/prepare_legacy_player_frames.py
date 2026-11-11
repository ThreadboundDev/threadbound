"""Extract the archived 2D player's frame data into the local Chamber preview."""
import json
from pathlib import Path
import re
import subprocess


SOURCE = "efea62e9"
SCENE = "Src/Characters/Player/player.tscn"
OUTPUT = Path("LocalOnly/OG_Export_Trial/legacy_sprites")


def from_git(path):
    return subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])


def main():
    scene = from_git(SCENE).decode("utf-8")
    paths = {identifier: path.removeprefix("res://") for path, identifier in re.findall(
        r'\[ext_resource[^\]]*path="([^"]+)" id="([^"]+)"\]', scene
    )}
    atlas_frames = {}
    for identifier, sheet, rect in re.findall(
        r'\[sub_resource type="AtlasTexture" id="([^"]+)"\]\s+'
        r'atlas = ExtResource\("([^"]+)"\)\s+region = Rect2\(([^)]+)\)', scene
    ):
        atlas_frames[identifier] = (sheet, [float(value) for value in rect.split(",")])
    animation_text = re.search(
        r'\[sub_resource type="SpriteFrames" id="SpriteFrames_wf5ty"\]\s+animations = (.*?)\n\n',
        scene, re.DOTALL,
    ).group(1)
    animation_text = re.sub(r'(?:SubResource|ExtResource)\(("[^"]+")\)', r'\1', animation_text)
    animations = json.loads(animation_text.replace('&"', '"'))
    assert len(animations) == 24
    OUTPUT.mkdir(parents=True, exist_ok=True)
    written = set()
    clips = {}
    for animation in animations:
        frames = []
        for frame in animation["frames"]:
            texture = frame["texture"]
            sheet, rect = atlas_frames.get(texture, (texture, []))
            filename = Path(paths[sheet]).name
            if filename not in written:
                png = from_git(paths[sheet])
                if not png.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise ValueError(f"{paths[sheet]} did not resolve to a PNG")
                (OUTPUT / filename).write_bytes(png)
                written.add(filename)
            frames.append([filename, rect])
        clips[animation["name"]] = frames
    (OUTPUT / "frames.json").write_text(json.dumps(clips, indent=2), encoding="utf-8")
    print(f"Restored {len(clips)} original sprite clips from {len(written)} sheets for local comparison.")


if __name__ == "__main__":
    main()
