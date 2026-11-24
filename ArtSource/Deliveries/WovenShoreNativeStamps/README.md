# Woven Shore standalone stamps

Open `res://Src/Tests/Art/WovenWorld/woven_shore_concept.tscn` in Godot and press **F6**. Select the `Art` node to edit the terrain, trees, foliage, buildings, gates, dock and masonry bays as individual pieces.

The active room uses 25 new high-resolution object PNGs, plus individually authored trees, vegetation, terraces and a farmstead from the existing kit. The new PNGs were each generated in a separate image generation call, then trimmed to the alpha bounds with the original pixels intact. The 55 new sprite placements draw at or below their source pixel dimensions. [Stamp catalog](stamp_catalog.jpg) · [Dimensions and full generation prompts](asset_manifest.json)

The [approved concept](../WovenShoreConcept/sources/approved_layout.png) and [layered layout](../WovenShoreConcept/Woven_Shore_Layout.ora) remain available as visual guides. The scene draws the distant village and falls and the atmospheric lakebed in separate background layers. Contact shadows, the Blue lake, the Eave Runner, and both route interactions use the existing gameplay.

The launch path, jumps, swim-up nook and Aqueducts use the same colliders and controls as the concept playtest. The farm road and irrigation walk lead to the Rooftops preview landing, and the submerged passage leads to the Aqueducts preview landing.

[Chamber](game_chamber.png) · [Hidden shelf](game_hidden_shelf.png) · [High crossing](game_upper_route.png) · [Swim-up nook](game_swim_nook.png) · [Farm road](game_farm_road.png) · [Aqueducts intake](game_aqueduct_gate.png) · [Submerged conduit](game_aqueduct_conduit.png)

Godot 4.7.2 passed [34 headless checks](headless_checks.json) and [41 Forward+ checks](gpu_checks.json). The test checks that no gameplay sprite uses a concept crop or draws larger than its PNG, then verifies the platforming, swimming and route transitions. The captures are from the running game at 1,920 × 1,080.
