from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ATLAS_PATH = REPO_ROOT / "Assets/chamber_of_first_weave/Blue Wing/blue_wing_decor_atlas.png"
OUTPUT_DIR = REPO_ROOT / "Assets/chamber_of_first_weave/Blue Wing/FreePlaceProps"
RESOURCE_PATH = "res://Assets/chamber_of_first_weave/Blue Wing/blue_wing_decor_atlas.png"
TEXTURE_UID = "uid://e580sefoqxg5"

# Exact 256x256 cells in the hand-spaced atlas. Blank cells are intentionally
# omitted, and filter_clip prevents neighboring cells from bleeding in.
PROPS = [
    ("blue_rock_spire", (0, 0)),
    ("blue_rock_cluster", (1, 0)),
    ("blue_rock_monolith", (2, 0)),
    ("blue_rock_blocks", (3, 0)),
    ("blue_rock_ledge", (5, 0)),
    ("blue_foliage_tall", (0, 1)),
    ("blue_foliage_broad", (1, 1)),
    ("blue_foliage_lotus", (2, 1)),
    ("blue_foliage_low", (4, 1)),
    ("blue_reeds_tall", (5, 1)),
    ("blue_reeds_short", (6, 1)),
    ("blue_bamboo_tall", (0, 2)),
    ("blue_bamboo_medium", (1, 2)),
    ("blue_bamboo_short", (2, 2)),
    ("blue_bonsai_large", (3, 2)),
    ("blue_bonsai_medium", (4, 2)),
    ("blue_bonsai_small", (5, 2)),
    ("blue_lotus_large", (0, 3)),
    ("blue_bellflowers", (1, 3)),
    ("blue_lotus_small", (2, 3)),
    ("blue_root_large", (3, 3)),
    ("blue_root_small", (4, 3)),
    ("blue_shrine_fragment_round", (5, 3)),
    ("blue_shrine_fragment_lotus", (6, 3)),
]


def scene_text(name: str, region: tuple[int, int, int, int]) -> str:
    node_name = "".join(part.capitalize() for part in name.split("_"))
    x, y, width, height = region
    return f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" uid="{TEXTURE_UID}" path="{RESOURCE_PATH}" id="1_atlas"]

[sub_resource type="AtlasTexture" id="AtlasTexture_prop"]
atlas = ExtResource("1_atlas")
region = Rect2({x}, {y}, {width}, {height})
filter_clip = true

[node name="{node_name}" type="Sprite2D"]
texture = SubResource("AtlasTexture_prop")
'''


def main() -> None:
    if not ATLAS_PATH.exists():
        raise FileNotFoundError(ATLAS_PATH)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, (column, row) in PROPS:
        region = (column * 256, row * 256, 256, 256)
        destination = OUTPUT_DIR / f"{name}.tscn"
        destination.write_text(scene_text(name, region), encoding="utf-8", newline="\n")
        print(f"{destination.relative_to(REPO_ROOT)}: Rect2{region}")


if __name__ == "__main__":
    main()
