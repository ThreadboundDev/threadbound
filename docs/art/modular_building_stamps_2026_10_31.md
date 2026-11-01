# Modular building stamps — October 31 delivery

Chase requested granular plaster, structural wood, windows, doors and supporting
parts with variations, so he can draw buildings of different sizes/shapes in
Krita and use that drawing as a later game-assembly reference.

[Start here: kit/workflow](../../ArtSource/BlueBiome/Placeables/BuildingStampsV1/README.md).
The new components use built-in `image_gen` with the current fisher-house painting
as the material/style reference. Selected outputs and exact prompts are saved in
the kit. There are 14 new pieces: three plaster treatments, two timber parts,
three windows, three doors and three roof parts. The two intact plaster fields
are deliberately opaque full-bleed fills; other new pieces have transparent
surroundings. No existing PNG was repainted or replaced.

Twenty-two source-library parts supply matching support/brace variations,
stonework, peaked roof, walkways/veranda, five lights and two full building bays.
These source PNGs and their existing brush resources retain their bytes/hashes.
The exported bundle has 36 presets under Village - Modular Buildings and category
tags. New resource names use Village_MB_; existing resource names remain intact.

The 34-layer OpenRaster sample composes a low wide building and a tall building
at the map's world-pixel scale, with a 185 px character-height reference. Walls,
beams, windows, doors, roofs, lamp and footing remain independently editable.
It is an example sandbox, not a new active room or an overwrite of Chase's map.
The roof returns are hand-painted options needing tile-scale matching and seam
paint-over; they are not guaranteed seamless automatic construction pieces.

Validation checks 36 source hashes, exact RGBA brush pixels, all 72 bundle
resource links/checksums and exact independent recomposition of the ORA layers.
The catalogs and final example were visually reviewed. A native isolated Krita
CLI smoke attempt failed with 0xC0000005 before producing an export; native
opening/importing is unverified. Normal app resources/preferences were untouched.

The art directory is excluded from Godot via .gdignore, with binary deliveries
in LFS. No scene/collision/interaction/equipment changes are part of this task.
Tomorrow's T40 game retest stays pending. Acceptance of this kit is an art review
and a practical stamp/import check when Chase wants to work in Krita.
