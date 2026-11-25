# Woven Shore

Open `res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn` in Godot and press F6. The starting point is under the cavern overhang. Walk right out to the islands, and use the existing Interact action at a route marker or sluice.

- The east road, beside the indigo sign and lantern, leads to the Village Rooftops landing.
- Swim down in the second gap to the cyan arch for the Flooded Cistern landing. The usual water recovery stones still let swimmers get back to shore.
- Open the amber sluices on the first and third islands, then climb the stepping platforms to the Waterfall Lookout gate. Each sluice contributes once. The gate opens when both are active.

Each landing has a return interaction to the corresponding shore exit. Sluice state carries between these rooms during play and resets on a fresh F6 run. These rooms establish the entrances for later level expansion. The production Chamber still has its existing ending route.

Outfit A and the fitted grapple glove now populate the existing fitted base visual slots. The modular doll continues to supply the rig, animation, sword, shield and boot placement. Blue variants retain their existing slots.

The saved `ShoreFinish` assembly contains farm overlooks, lower foliage, the parallax silhouettes, point lights, Eave Runner and Loom Heron placements, and the route markers. `Backdrop` uses the existing village panorama and dormant falls with separately adjustable parallax. `ShoreWater/Lake` uses the existing painted Blue lake, underwater reveal and swimmable volume. The two left points extend past camera coverage and the authored deeper polygon is retained.

The four new transparent PNGs live under `Assets/BlueBiome/Art/WovenWorldChunks/ShoreFinish/`. Built-in image generation used `tree_alt.png` as the style reference. The assets are used directly at editable scene scales.

## Art prompts

### cavern

Create ONE large modular side-view game sprite, a natural cavern mouth cutaway at the LEFT edge of a vibrant woven low-poly lakeside platformer. Style reference is the supplied tree only for facets and engraved woven lines. Grey slate, warm pale mineral seams arranged like thread, chunky angular geological shapes, dark cool recess on LEFT with open dark passage across the lower middle continuing out into genuine TRANSPARENT opening on the RIGHT. Rock arch ceiling sweeps across top then tapers at right at about 65% width, and left stone boundary; leave lower right completely empty transparent so a side-scroller character walks directly out at ground height. Wide roughly 2:1 framing. Natural lush moss in little fringes around exposed edges, roots of cherry tree in ceiling hints. Large readable shapes, subtler cool shadow interior, restrained weave. No text, character, ground plane beyond the entrance, no background or checkerboard. Single isolated game asset, genuine transparent alpha outside shape.

### farmstead

Create ONE isolated Blue Biome lakeside farm outpost cottage sprite. Style reference image is the supplied tree: match saturated moss, angular low-poly planes, etched interlaced directional weave lines, warm daylight and restrained outlines. Side-scrolling game elevation with shallow visible depth to the roof, aged warm wood, curved flowing indigo roof with bamboo framing, small porch, indigo hanging fabric with an original subtle thread pattern, warm paper lantern and pink blossom accents. Grounded chunky wooden supports individually ending, no continuous cropped base, no backdrop, no character, no text. Royalath 2:1 wide composition. Entire cottage with margins, genuine transparent alpha.

### terraces

Create ONE isolated layered decorative landscape sprite for a 2D side-scrolling woven low-poly game. Composition is a broad mound of small terraced paddy fields receding in shallow elevation, three tiers of clean blue irrigation water with golden-green rows of rice, short dry slate walls, occasional bamboo reeds and one little wood sluice. Match the reference tree's faceted illustrative rendering, restrained engraved weave lines in earth and leaves, in softer midground colors. Wide low 2.5:1 rectangular bounding box with irregular COMPLETE natural shape, no straight exposed cropped baseline or horizon, all perimeter genuinely transparent alpha, no background, no sky, no buildings, no labels or people.

### gate

One isolated modular stone doorway asset for a 2D woven low-poly fantasy videogame, to mark a flooded passage under a lake. Match the supplied tree's design language of large planar facets and delicate engraved lines like woven thread. Three-quarter shallow side-view facade, ash grey teal-tinted chunky slate doorway with a dark recessed rounded opening inside the stone, restrained woven diamond engraving around arch, short asymmetric trailing green reeds and pale cyan filaments at foot. Natural taper and individually completed stems. Sole object centered with space around frame and real transparent background. No letters, symbols that read like text, backdrop, floor plane, person, or bubbles outside object.

## Verification

The shore suite exercises grounded contacts, dry and underwater traversal, camera limits, the original jumping route, and outline/foliage comparisons. The route suite uses the normal Interact input, verifies both authored encounters load, checks the Outfit A model paths, and travels through all three exits and back. It verifies sluice state at zero, one and two opened controls, including repeat-use behavior and consistency across a room trip.

`headless_checks.json` and `gpu_checks.json` record the traversal pass. `routes_headless.json` and `routes_gpu.json` record the round trips. The screenshots are captures from the running game. The engine's existing shader-cache and shutdown warnings, including the legacy `Missing glove anim: Swim_Idle` diagnostic, remain in the local logs. The actual doll uses its live swim animation.
