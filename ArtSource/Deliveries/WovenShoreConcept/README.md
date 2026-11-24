# Woven Shore concept layout

Open `res://Src/Tests/Art/WovenWorld/woven_shore_concept.tscn` in Godot and press **F6**. The scene uses the project player, camera, Blue lake, interaction prompts, and the Eave Runner. The original shoreline scene and production Chamber route remain available.

- Leave the low Chamber mouth and cross the two islands to the farm road. The road leads to the Village Rooftops preview landing.
- Climb through the first island's tree perch to the floating route. Jump back left from the tree perch to find the shelf above the Chamber. The arrival camera is framed low enough to conceal it.
- Take the ridge walk from the Rooftops landing and use Interact from the east side of the upper gate to release the irrigation latch. The high route and farm road both connect back to the Rooftops.
- Dive beneath the broader second island and swim up between its rock legs. The bubbles mark a small sheltered air pocket.
- Swim to the barred intake under the village and use Interact to raise the grille. Swim through the masonry channel to the Aqueducts preview landing. Both gates stay open on room trips until the preview session ends.

## Painting and artwork

[Woven Shore Layout](Woven_Shore_Layout.ora) is an editable 5,430 × 1,810 OpenRaster canvas for Krita. [Layout preview](layout_preview.jpg) shows the composition. Each registered PNG under `Assets/BlueBiome/Art/WovenWorldChunks/ConceptLayout/` is placed individually in the scene. The camera separates the far landscape, underwater background, gameplay artwork, and near foliage. The cave, islands, water nook, floating rock silhouettes, irrigation walk, and Aqueducts come from the [approved concept](sources/approved_layout.png). The built-in image generation tool generated clean replacement plates for the [distant landscape](sources/landscape_plate.png) and [lakebed](sources/lakebed_plate.png).

[Registration](registration.json) records each stamp origin in the concept's pixel coordinates. World positions use a 2.5× scale. Run `tools/art/woven_world/build_shore_concept_art.py` with Python and Pillow to rebuild the registered PNGs and OpenRaster canvas. Godot collision and interaction nodes are edited directly in the scene.

## Verification

Godot 4.7.2 passed [31 headless checks](headless_checks.json) and [37 Forward+ checks](gpu_checks.json). The suite uses the existing jump, swim and Interact inputs to test the three main gaps, the floating route, the hidden shelf return jump, the swim-up nook, the gate openings, and the route handoffs. The renderer still reports the legacy glove animation warnings during swimming and water ledge grabs. The loaded player's swim and ledge traversal passed.

[Chamber arrival](game_chamber.png) · [Hidden shelf](game_hidden_shelf.png) · [High crossing](game_upper_route.png) · [Swim-up nook](game_swim_nook.png) · [Aqueducts intake](game_aqueduct_gate.png) · [Conduit](game_aqueduct_conduit.png)

## Generation prompts

## Landscape plate

Use image 1 as a registered art reference for a clean empty background plate for Threadbound Woven Shore. Maintain the exact same 3:1 wide side view and keep the scale, x/y positions, soft atmospheric color, and horizon of the pale blue dormant waterfall cliff near x=35%, distant indigo-roof stilt village silhouettes spread along the lake at y=46%-62%, blue sky, layered hills, waterline at precisely 67% of image height. This is the pristine far background with every foreground asset removed. Completely reconstruct quiet blue sky/hills/village silhouettes or turquoise water in the regions occluded by any foreground terrain. Remove all foreground rocks, caves, roots, plants, platforms, hills, farmhouses, aqueducts, gates, ruins, underwater scenery, left/right border framing. Across the top 67%, only the pale background sky, layered mountain range, village panorama and atmospheric far-lake water. Below y=67% use a smoothly deepening subdued teal water field to the bottom, same transparent-looking soft light as the reference, no objects or lakebed. No text or characters. Keep contrast soft for game parallax. Match the existing art exactly.

## Lakebed plate

Unobstructed decorative lakebed background plate for the Woven Shore 2D side-scrolling video game. Input is the exact art style and composition reference. Ultra-wide horizontal, strict side elevation as in the lower underwater third of the reference. Extend that underwater style to fill the frame. Subtle soft teal to blue haze and faint sun caustics above, rough low faceted gray-blue shelves, facets engraved with subtle woven fibers, tiny yellow-green underwater plants and pebbles densely arranged only along the very bottom edge and corners. Open blue-green water over the upper 80% of the plate, broad room to swim. No foreground islands, tunnels, aqueduct, cave ceilings, gates, columns, underwater animals, horizon/sky, letters or people. Atmospheric values behind gameplay, ensure that vertical map middle remains truly open. It will be layered separately behind near terrain. Keep all colors matching the lower underwater part of the attached game concept.
