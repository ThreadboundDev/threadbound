# Still Village material study V2

Material refinement of the approved twelve-piece 3D kit. Wood has directional grain and stronger tonal variation; slate has mottled surface color and subtle relief; ambient occlusion strengthens joints. Foliage and cloth receive restrained variation. Mesh geometry, silhouettes, lighting, camera framing, sprite pivots and gameplay are preserved.

## Review

- `material_comparison.png`: actual V1/V2 renders under identical lighting.
- `room_start_preview.png` and `room_overview_preview.png`: Godot captures.
- `StillVillage_Material_v2.blend`: editable 3D source with procedural material nodes.
- `verification.json`: all twelve PNGs checked for identical dimensions and alpha to V1, and changed material pixels.

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_material_preview.tscn` in Godot and run with F6. This optional scene inherits the original preview and substitutes the V2 textures. The original preview remains available for comparison.

Runtime textures are under `Assets/BlueBiome/StillVillage/MaterialV2/`. These are orthographic renders of the 3D assets for the existing 2D room. The procedural shaders are saved in Blender; this version does not include newly baked GLB materials. V1 GLBs retain their original materials.

Rebuild with background Blender running `tools/art/refine_still_village_materials.py`, then Python/Pillow running `tools/art/review_still_village_materials.py`. The refinement script requires the V1 blend and manifest. No V1 files are overwritten.

This is a material study, not a claim of complete concept parity: the concept's irregular stone contours and hand-shaped timber silhouettes would require a separate geometry pass.
