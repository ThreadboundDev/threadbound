# Woven Blue cave foliage trial

The starting slice runs from the cave mouth to the first bridge post in
[Blue Blockout](../../../../Src/Environment/BlueBiome/blue_blockout.tscn).
Press **R** in the playtest to return to the cave.

## Krita

- **Woven Blue - Inking** has Terrain Ink at 30 px and Floating Ink at
  20 px. Both are fixed-width pens that use the current foreground color.
- **Woven Blue - Cave Foliage** has Soft Grass Patch, Upright Grass Tuft,
  Splayed Grass Fan, and Cave Lip Moss. Each is a Lightness Map stamp.
  Pick a foreground swatch and vary the brush size to stack the patches.
  Olive `#778854`, yellow-green `#9fa65f`, and cool green `#5b856d`
  are starting swatches for this scene.

The original **z) Stamp Herbals** is still available under **Textures**.
Keep terrain ink above the painted stone. Tuck most of the soft moss and
backing grass under the ink, and keep any grass that needs to move on its
own layer. Export the ground rim separately when a new painted edge needs
to cover the player's boots.

## Godot

The [foliage scene](../../../../Src/Environment/BlueBiome/ArtPlaceables/Foliage/blue_cave_mouth_foliage.tscn)
instances the painted-rock rim and three transparent grass textures.
The current tree and original painted grass remain in the level artwork.
Grass roots stay planted. The UV height weights the bend, and a passing
player pushes the tips in their direction of travel. Each placement lists
its x coordinate, root y coordinate, and width in world units.

- [Brush bundle](Threadbound_Woven_Blue_Cave_Foliage.bundle)
- [Preset catalog](catalog.jpg)
- [Godot textures](../../../../Assets/BlueBiome/Art/CaveMouthFoliage/)
- [ImageGen prompts and texture checksums](manifest.json)
