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

The Godot palette uses the strand masks from Krita's **z) Stamp Grass**
and **z) Stamp Grass Patch**. Both are in the default **Textures** tag.
The original **z) Stamp Herbals** is also there.
Keep terrain ink above the painted stone. Tuck most of the soft moss and
backing grass under the ink, and keep any grass that needs to move on its
own layer. The full-canvas Terrain Ink export follows the current visible
black linework. Refresh that export when repainting the outline.

## Godot

Open Blue Blockout in the 2D editor and click **Foliage Painter** in the
bottom panel. It is part of the Room Greybox plugin.

1. Pick **Mixed Grass** or a single stamp. **Broadleaf Accent** is the
   more detailed option for occasional use.
2. Choose **Front of Player** or **Behind Player**, then turn on **Paint**.
   Click for one stamp or drag to paint a row. The preview marks the root.
3. Adjust **Size**, **Spacing**, or **Variation**. **Random Flip** mirrors
   the texture and **Vary Tint** mixes four foliage greens.
4. Right-click to erase in the chosen layer. Godot's Undo reverses one
   stroke at a time. Turn **Paint** off to select and move stamps in the
   viewport. **Send Selection to Layer** shifts selected stamps to the
   chosen layer and preserves their positions.

Each placement is an editable mesh node under `Geometry/FoliageStamps`.
Brush strokes save with the room. The draw order from top to bottom is
Terrain Ink, front foliage, player, and back foliage. The ink covers the
roots and boot soles. Grass tips bend in wind and respond to passing feet.

The three strand textures are derived from the CC0 brush masks
`grass.gih` and `grass_patch.gih` in Krita's default 4.x bundle. The bundle
credits Deevad and the contributing Krita brush artists.

- [Brush bundle](Threadbound_Woven_Blue_Cave_Foliage.bundle)
- [Preset catalog](catalog.jpg)
- [Godot textures](../../../../Assets/BlueBiome/Art/CaveMouthFoliage/)
- [ImageGen prompts and texture checksums](manifest.json)
