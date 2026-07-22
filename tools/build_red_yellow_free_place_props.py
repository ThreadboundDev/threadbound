from pathlib import Path
import sys

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parent.parent
CELL_SIZE = 256
CONTENT_SIZE = 228

WINGS = {
    "Red Wing": {
        "atlas": "red_wing_decor_atlas.png",
        "uid": "uid://06wlgov655wl",
        "columns": 6,
        "props": [
            ("red_rock_spire", (35, 10, 285, 225)),
            ("red_rock_slab", (315, 20, 610, 225)),
            ("red_rock_monolith", (625, 10, 920, 225)),
            ("red_rock_blocks", (945, 20, 1205, 225)),
            ("red_rock_ledge", (1205, 20, 1515, 225)),
            ("red_root_spiked_large", (45, 220, 325, 430)),
            ("red_root_twisted_large", (340, 220, 690, 430)),
            ("red_root_spiked_small", (755, 220, 1070, 430)),
            ("red_root_twisted_small", (1135, 225, 1425, 430)),
            ("red_foliage_broad", (45, 420, 325, 570)),
            ("red_foliage_cluster", (390, 420, 710, 570)),
            ("red_foliage_dense", (755, 420, 1050, 570)),
            ("red_foliage_tall", (1120, 420, 1435, 570)),
            ("red_grass_tall", (80, 555, 320, 730)),
            ("red_grass_broad", (385, 555, 675, 730)),
            ("red_grass_short", (735, 555, 985, 730)),
            ("red_dead_tree_large", (55, 730, 310, 880)),
            ("red_dead_tree_medium", (375, 730, 650, 880)),
            ("red_dead_tree_small", (720, 730, 950, 880)),
            ("red_shrine_fragment_spire", (980, 610, 1245, 880)),
            ("red_shrine_fragment_arch", (1240, 610, 1515, 880)),
            ("red_rubble_spears", (70, 885, 450, 1024)),
            ("red_rubble_banner", (560, 885, 975, 1024)),
            ("red_flower_single", (1000, 885, 1235, 1024)),
        ],
    },
    "Yellow Wing": {
        "atlas": "yellow_wing_decor_atlas.png",
        "uid": "uid://bcd3f07u0kh4v",
        "columns": 7,
        "props": [
            ("yellow_rock_spire", (20, 10, 300, 245)),
            ("yellow_rock_blocks", (300, 10, 625, 245)),
            ("yellow_rock_ledge", (625, 15, 935, 245)),
            ("yellow_rock_monolith", (930, 10, 1225, 245)),
            ("yellow_rock_slab", (1210, 20, 1535, 245)),
            ("yellow_flowers_large", (15, 265, 285, 490)),
            ("yellow_flowers_broad", (275, 265, 540, 490)),
            ("yellow_flowers_lily", (535, 270, 785, 490)),
            ("yellow_flowers_small", (775, 275, 1000, 490)),
            ("yellow_grass_tall", (1000, 270, 1165, 490)),
            ("yellow_grass_medium", (1140, 265, 1320, 490)),
            ("yellow_grass_broad", (1300, 265, 1535, 490)),
            ("yellow_tree_large", (20, 480, 270, 765)),
            ("yellow_tree_medium", (265, 490, 470, 765)),
            ("yellow_tree_small", (455, 490, 650, 765)),
            ("yellow_books_scrolls", (620, 500, 915, 765)),
            ("yellow_books_open", (890, 500, 1200, 765)),
            ("yellow_books_stack", (1185, 500, 1535, 765)),
            ("yellow_shrine_fragment_arch", (15, 750, 265, 1024)),
            ("yellow_shrine_fragment_round", (245, 750, 485, 1024)),
            ("yellow_root_large", (455, 750, 700, 1024)),
            ("yellow_root_small", (680, 750, 920, 1024)),
            ("yellow_scholar_book", (890, 755, 1270, 1024)),
            ("yellow_writing_set", (1260, 750, 1536, 1024)),
        ],
    },
}


def crop_visible(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = image.crop(box)
    alpha = crop.getchannel("A")
    visible = alpha.point(lambda value: 255 if value > 4 else 0)
    bounds = visible.getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels found in source box {box}")
    return crop.crop(bounds)


def fit_in_cell(prop: Image.Image) -> Image.Image:
    scale = min(CONTENT_SIZE / prop.width, CONTENT_SIZE / prop.height, 1.0)
    if scale < 1.0:
        size = (max(1, round(prop.width * scale)), max(1, round(prop.height * scale)))
        prop = prop.resize(size, Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    x = (CELL_SIZE - prop.width) // 2
    y = CELL_SIZE - 12 - prop.height
    cell.alpha_composite(prop, (x, y))
    return cell


def scene_text(name: str, uid: str, resource_path: str, column: int, row: int) -> str:
    node_name = "".join(part.capitalize() for part in name.split("_"))
    return f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" uid="{uid}" path="{resource_path}" id="1_atlas"]

[sub_resource type="AtlasTexture" id="AtlasTexture_prop"]
atlas = ExtResource("1_atlas")
region = Rect2({column * CELL_SIZE}, {row * CELL_SIZE}, {CELL_SIZE}, {CELL_SIZE})
filter_clip = true

[node name="{node_name}" type="Sprite2D"]
texture = SubResource("AtlasTexture_prop")
'''


def build_wing(wing_name: str, config: dict) -> None:
    wing_dir = REPO_ROOT / "Assets/chamber_of_first_weave" / wing_name
    atlas_path = wing_dir / config["atlas"]
    source = Image.open(atlas_path).convert("RGBA")
    props = config["props"]
    columns = config["columns"]
    rows = (len(props) + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * CELL_SIZE, rows * CELL_SIZE), (0, 0, 0, 0))
    output_dir = wing_dir / "FreePlaceProps"
    output_dir.mkdir(parents=True, exist_ok=True)
    resource_path = f"res://Assets/chamber_of_first_weave/{wing_name}/{config['atlas']}"

    for index, (name, source_box) in enumerate(props):
        column = index % columns
        row = index // columns
        cell = fit_in_cell(crop_visible(source, source_box))
        atlas.alpha_composite(cell, (column * CELL_SIZE, row * CELL_SIZE))
        destination = output_dir / f"{name}.tscn"
        destination.write_text(
            scene_text(name, config["uid"], resource_path, column, row),
            encoding="utf-8",
            newline="\n",
        )
        print(f"{name}: cell ({column}, {row})")

    atlas.save(atlas_path, optimize=True)
    print(f"Saved {atlas_path.relative_to(REPO_ROOT)} at {atlas.width}x{atlas.height}")


def build_scenes_from_existing_grid(wing_name: str, config: dict) -> None:
    wing_dir = REPO_ROOT / "Assets/chamber_of_first_weave" / wing_name
    atlas_path = wing_dir / config["atlas"]
    atlas = Image.open(atlas_path)
    columns = config["columns"]
    props = config["props"]
    required_rows = (len(props) + columns - 1) // columns
    expected_size = (columns * CELL_SIZE, required_rows * CELL_SIZE)
    if atlas.size != expected_size:
        raise ValueError(f"{atlas_path} is {atlas.size}; expected exact grid {expected_size}")

    output_dir = wing_dir / "FreePlaceProps"
    output_dir.mkdir(parents=True, exist_ok=True)
    resource_path = f"res://Assets/chamber_of_first_weave/{wing_name}/{config['atlas']}"
    for index, (name, _source_box) in enumerate(props):
        column = index % columns
        row = index // columns
        destination = output_dir / f"{name}.tscn"
        destination.write_text(
            scene_text(name, config["uid"], resource_path, column, row),
            encoding="utf-8",
            newline="\n",
        )
        print(f"{name}: Rect2({column * CELL_SIZE}, {row * CELL_SIZE}, 256, 256)")


def main() -> None:
    if "--validate-only" in sys.argv:
        for wing_name, config in WINGS.items():
            atlas_path = REPO_ROOT / "Assets/chamber_of_first_weave" / wing_name / config["atlas"]
            atlas = Image.open(atlas_path).convert("RGBA")
            padding: list[int] = []
            for index in range(len(config["props"])):
                column = index % config["columns"]
                row = index // config["columns"]
                bounds = atlas.crop((
                    column * CELL_SIZE,
                    row * CELL_SIZE,
                    (column + 1) * CELL_SIZE,
                    (row + 1) * CELL_SIZE,
                )).getchannel("A").getbbox()
                if bounds is None:
                    raise ValueError(f"Blank generated cell {index} in {atlas_path}")
                padding.extend((bounds[0], bounds[1], CELL_SIZE - bounds[2], CELL_SIZE - bounds[3]))
            print(
                f"{atlas_path.relative_to(REPO_ROOT)}: {atlas.width}x{atlas.height}, "
                f"{len(config['props'])} occupied cells, minimum padding {min(padding)}px"
            )
        return
    if "--scenes-only" in sys.argv:
        wing_filter = sys.argv[sys.argv.index("--scenes-only") + 1].lower()
        for wing_name, config in WINGS.items():
            if wing_name.lower().startswith(wing_filter):
                build_scenes_from_existing_grid(wing_name, config)
                return
        raise ValueError(f"Unknown wing filter: {wing_filter}")
    for wing_name, config in WINGS.items():
        build_wing(wing_name, config)


if __name__ == "__main__":
    main()
