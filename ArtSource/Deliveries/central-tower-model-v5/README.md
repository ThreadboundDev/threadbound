# Central tower v5 — foreground entrance rim

`CentralTower_Editable.blend` retains v4 roofs, materials and dimensions. The
existing front basin stone is a sibling assembly `Entry_Foreground_Always`, so
the stone lip can occlude a swimmer even after the facade cutaway opens. Rear
basin stone remains behind the character. No new blocking geometry/collision.

Build with Blender background and `tools/art/split_tower_entry_foreground.py`.
The runtime GLB partitions v4 triangle indices directly, retaining original
vertex/UV/normal/image data. It references the same installed 4K textures.
The Blender source carries the equivalent editable split and packed textures.
Verification and in-game captures: `work/lakeside-entry-focus-2026-10-26/`.
