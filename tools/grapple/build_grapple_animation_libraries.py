"""Build glove AnimationLibraries and connect all glove scenes.

The generated keys are intentionally placeholders. Idle uses sparse control poses
for smooth motion; action animations retain exact frame-aligned keys.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EQUIPMENT = ROOT / "Src" / "Equipment"

ANIMATIONS = (
    ("Air_Double_Attack", 27, 40.0, False),
    ("Dash", 1, 5.0, True),
    ("Grapple_Diagonal", 6, 18.0, False),
    ("Grapple_Horizontal", 6, 18.0, False),
    ("Grapple_Strike", 11, 40.0, False),
    ("Ground_Attack_Combo_1", 14, 30.0, False),
    ("Ground_Attack_Combo_1_Backpedal", 14, 30.0, False),
    ("Ground_Attack_Combo_2", 19, 30.0, False),
    ("Ground_Attack_Combo_2_Backpedal", 19, 30.0, False),
    ("Ground_Attack_Combo_2_Stationary", 19, 30.0, False),
    ("Idle", 33, 24.0, True),
    ("Jump_Apex", 4, 8.0, True),
    ("Jump_Ascent", 4, 8.0, True),
    ("Jump_Descent", 4, 8.0, True),
    ("Jump_Land", 4, 12.0, False),
    ("Ledge_Climb", 4, 20.0, False),
    ("Neutral_Special_Attack", 48, 40.0, False),
    ("Run", 11, 24.0, True),
    ("Sit", 48, 18.0, False),
    ("Wall_Cling", 4, 6.0, True),
)

TRACKS = (
    ("Equipment/RightHandAnchor:position", "position"),
    ("Equipment/RightHandAnchor/WristWrapPivot:rotation", "rotation"),
    ("Equipment/RightHandAnchor/WristWrapPivot:scale", "scale"),
)


def number(value: float) -> str:
    rendered = f"{value:.9f}".rstrip("0").rstrip(".")
    return "0" if rendered == "-0" else rendered


def repeated(value: str, count: int) -> str:
    return ", ".join([value] * count)


def make_library(position: tuple[float, float], rotation: float, scale: tuple[float, float]) -> str:
    defaults = {
        "position": f"Vector2({number(position[0])}, {number(position[1])})",
        "rotation": number(rotation),
        "scale": f"Vector2({number(scale[0])}, {number(scale[1])})",
    }
    sections = [f'[gd_resource type="AnimationLibrary" load_steps={len(ANIMATIONS) + 1} format=3]\n']
    entries: list[str] = []

    for index, (name, frame_count, fps, loop) in enumerate(ANIMATIONS):
        resource_id = f"Animation_{index:02d}_{name.lower()}"
        entries.append(f'&"{name}": SubResource("{resource_id}")')
        key_frames = (0, 5, 11, 20, 32) if name == "Idle" else range(frame_count)
        key_count = len(key_frames)
        times = ", ".join(number(frame / fps) for frame in key_frames)
        transitions = repeated("1", key_count)
        lines = [
            f'[sub_resource type="Animation" id="{resource_id}"]',
            f'resource_name = "{name}"',
            f"length = {number(frame_count / fps)}",
            f"step = {number(1.0 / fps)}",
        ]
        if loop:
            lines.append("loop_mode = 1")
        for track_index, (path, default_name) in enumerate(TRACKS):
            interpolation = "1"
            update_mode = "0"
            lines.extend(
                (
                    f'tracks/{track_index}/type = "value"',
                    f"tracks/{track_index}/imported = false",
                    f"tracks/{track_index}/enabled = true",
                    f'tracks/{track_index}/path = NodePath("{path}")',
                    f"tracks/{track_index}/interp = {interpolation}",
                    f"tracks/{track_index}/loop_wrap = true",
                    f"tracks/{track_index}/keys = {{",
                    f'"times": PackedFloat32Array({times}),',
                    f'"transitions": PackedFloat32Array({transitions}),',
                    f'"update": {update_mode},',
                    f'"values": [{repeated(defaults[default_name], key_count)}]',
                    "}",
                )
            )
        sections.append("\n".join(lines) + "\n")

    sections.append("[resource]\n_data = {\n" + ",\n".join(entries) + "\n}\n")
    return "\n".join(sections)


def connect_scene(scene_name: str, library_path: str) -> None:
    path = EQUIPMENT / scene_name
    text = path.read_text(encoding="utf-8")

    # Retire only Animation and AnimationLibrary subresources. Colored glove
    # preview SpriteFrames/AtlasTextures remain untouched.
    text = re.sub(
        r'\[sub_resource type="Animation(?:Library)?"[^\n]*\]\n.*?(?=\n\[(?:sub_resource|node))\n?',
        "",
        text,
        flags=re.DOTALL,
    )

    ext_line = (
        f'[ext_resource type="AnimationLibrary" path="res://{library_path}" '
        'id="grapple_pose_library"]'
    )
    if ext_line not in text:
        insertion_candidates = [
            offset
            for marker in ("[sub_resource", "[node")
            if (offset := text.find(marker)) >= 0
        ]
        if not insertion_candidates:
            raise RuntimeError(f"Could not locate resource or node body in {path}")
        insertion_offset = min(insertion_candidates)
        text = text[:insertion_offset] + ext_line + "\n\n" + text[insertion_offset:]

    text, replacements = re.subn(
        r'libraries/ = (?:SubResource|ExtResource)\("[^"]+"\)',
        'libraries/ = ExtResource("grapple_pose_library")',
        text,
        count=1,
    )
    if replacements != 1:
        raise RuntimeError(f"Expected one AnimationPlayer library in {path}")
    path.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
    (EQUIPMENT / "base_grapple_animation_library.tres").write_text(
        make_library((-18.0, -15.0), -1.267109, (1.235, 1.235)),
        encoding="utf-8",
        newline="\n",
    )
    connect_scene("base_gloves.tscn", "Src/Equipment/base_grapple_animation_library.tres")
    for scene_name in ("red_gloves.tscn", "blue_gloves.tscn", "yellow_gloves.tscn"):
        connect_scene(scene_name, "Src/Equipment/base_grapple_animation_library.tres")


if __name__ == "__main__":
    main()
