# Wing grass mask editing

The game uses:

`Assets/chamber_of_first_weave/Tiles/new_tiles_atlas_grass_mask.png`

The mask must stay exactly **1024 x 1300 pixels**.

- White pixels are recolored.
- Black pixels keep the original atlas color.
- Gray pixels blend between the two.

## Quick Krita workflow

1. Open `new_tiles_atlas_grass_mask_guide.png` for visual reference.
2. Open the game mask listed above in a second tab.
3. Use a hard-edged white brush to add missing leaves.
4. Use a hard-edged black brush to remove brass, stone, or unwanted edges.
5. Export over the game mask as a grayscale PNG without resizing it.

The guide uses red only to show current mask coverage. It is ignored by Godot
and is not included in game exports.
