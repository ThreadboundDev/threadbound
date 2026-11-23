# Woven Shore painting kit

The blank painting canvas is **12,800 × 4,608 px** at 1:1 game scale. Its starter layers leave room to compose the shoreline above and below water. The separate scale layer shows a 1,920 × 1,080 example camera view at 1× zoom and a 192 px actor-height reference. Those are references for painting, with no map layout or fixed waterline drawn onto the canvas.

| File | Use |
| --- | --- |
| [Woven Shore Painting](Woven_Shore_Painting.ora) | Blank layered OpenRaster document, opened and verified in Krita |
| [Woven Shore Atlas](Woven_Shore_Atlas.ora) | All 15 pieces on individual layers at their delivered scale |
| [Atlas preview](Atlas_preview.jpg) | Quick overview of the kit |
| [Stamp manifest](manifest.json) | Individual PNG paths, dimensions, hashes, references and full image prompts |

Copy a stamp layer from the atlas into the painting or place its transparent PNG from `stamps/`. Hide the scale guides and the preview matte for final layer exports. The stamp atlas also has its own selectable labels and preview matte. The lake and sky can go behind the tall or low cave openings, which have real transparency through the middle. The older shoreline entrance has a straight join on its left for burying against a wall or the edge of the map.

The library includes three ground shapes, three floating ledges, a wall, a ceiling and a pillar, three openings, and three opaque cave interiors. The deepest ground chunk is 963 px tall. The ledges reveal their natural stone surfaces so there is room to register a standing line inside the top. The third interior has subdued teal values and an open center for a wide underwater route.

Fourteen new originals were created with the built-in image generation tool. `sources/` holds the original PNGs, including the existing opening for reproducibility. The alpha crop and proportional resize preserve the generated surfaces. `stamp_spec.json` preserves the inputs for `tools/art/woven_world/prepare_painting_kit.ps1` and `tools/art/woven_world/build_painting_workspace.ps1`. The latter assembles the editable documents at 1:1. `verification.json` records the checked PNG hashes, dimensions, transparent openings and independent layer bounds.

## Character review

The shoreline was still loading the November 21 `OutfitATrial` export with the modular doll and the older fitted B boots. The November 23 working Blender file, `LocalOnly/Equipment/BaseArmorReview/Threadbound_Base_Armor_Fit.blend`, contains the newer Outfit A cloth fitting and the `Outfit A | animation review` NLA track. The earlier Godot checks confirmed the configured export paths, which were older than the fitting file.

The [outline on](character_review/outline_on.png) and [outline off](character_review/outline_off.png) images capture the same frozen Godot pose. The triangular edges above the boot and gaps between the fingers remain with 34 outline shells hidden. This isolates them to the current rendered mesh, fit or pose in that frame. The comparisons and [loaded asset paths](character_review/rendered_model.json) are available for a separate export and fitting pass.

Chase will paint the terrain and backdrop in Krita. Collision, traversal, combat, the route puzzle, and houses, trees and other interactable props follow the approved painting layout in a later Godot pass.
