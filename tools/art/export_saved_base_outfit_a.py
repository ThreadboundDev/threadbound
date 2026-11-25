"""Export the saved Outfit A fit without editing or saving the Blender source.

Run Blender in background with Threadbound_Base_Armor_Fit.blend, then run
this script with -- --output <directory>. The export uses the shared game rig.
"""
from argparse import ArgumentParser
from pathlib import Path
import sys

import bpy


def main():
    parser = ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    output = parser.parse_args(sys.argv[sys.argv.index("--") + 1:]).output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import export_base_outfit_b as exporter

    layer = bpy.context.scene.view_layers["A - Original pieces"]
    bpy.context.window.view_layer = layer
    exporter.LAYER = layer
    outfit = bpy.data.objects["A - Original pieces, unified outfit"]
    assert outfit.get("source_rear_fit_v2") and outfit.get("hem_motion_review")
    # Review-reel displacements are frame-specific and driven by Blender-only
    # properties. Export the authored neutral fit and let the game rig pose it.
    for modifier in list(outfit.modifiers):
        if modifier.type == "DISPLACE":
            outfit.modifiers.remove(modifier)
    outfit.data.validate(clean_customdata=False)
    bpy.context.view_layer.update()

    exporter.apply_budget(outfit, .55)
    outfit.data.validate(clean_customdata=False)
    exporter.export_item(exporter.RIG.data, [outfit], output / "base_outfit_a.glb")


if __name__ == "__main__":
    main()
