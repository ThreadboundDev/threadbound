# Environment Production Pipeline

Threadbound environments should be designed as playable platforming spaces before they are illustrated.

## Pipeline

1. Establish the biome map and persistent geography.
2. Greybox one room.
3. Playtest the baseline and expressive routes.
4. Iterate until movement feels good.
5. Capture a clean screenshot of the approved blockout.
6. Interpret the geometry as environmental forms.
7. Produce separated art layers and reusable assets.
8. Assemble those layers over the unchanged gameplay collision.
9. Add restrained animation, environmental systems, and effects.
10. Polish readability and transitions.

The first validation target is `blue_village_room_01`. Do not block the entire Blue wing before this room proves that the workflow is fast and produces a strong result.

## Art Interpretation

Greybox forms are prompts, not literal final materials. A block may become a roof, branch, stone ledge, dock, or shoreline while its simple collision remains underneath.

Separate finished rooms into far background, midground, gameplay layer, and foreground. Gameplay surfaces receive the strongest contour and value contrast. Deeper layers should be progressively softer.

AI-assisted interpretation may help develop paint-overs or asset ideas, but it should follow the approved room geometry and the biome visual bible rather than reinventing the region for every room.

## Polygon-Guided Asset Pass

For large irregular rooms, author one `ArtGenerationRegion2D` at a time around
a logical section of approved collision. The polygon is a measurement and art
handoff tool, not collision. Export its exact world polygon, bounds, target
pixel size, layer, orientation, and overlap requirement before generating art.

Keep one active region whenever practical. Generate and place that asset,
review it in-game at native scale, then archive or replace the region before
moving to the next section. Place seams in quiet material and preserve overlap
for masking. Gameplay collision remains authoritative throughout this pass.

Blue Biome assets must follow
`res://Docs/art/blue_biome_palette_and_rendering_rules.md`.

## Collision and Placeable Art

Gameplay collision and illustrated architecture are separate authoring layers.
Terrain and one-way collision remain on the fast 128 px greybox grid. Building
facades, roof skins, stone caps, plants, and other finished artwork are
collision-free, freely positioned scenes under an `ArtPlaceables` container.
The Blue ground-art TileMap is also collision-free: it may mirror the greybox
grid for speed, while its multiple stone, moss, grass, and blossom variants
break repetition. Broad ground can therefore stay tile-authored without making
special silhouettes, house layers, or decoration conform to the grid.

A roof collider should normally receive both a roof skin at its walkable edge
and a building facade or visible support beneath it. Avoid isolated floating
roof art unless the level fiction clearly supports a suspended structure.

For Blue village color balance, use warm brown wood and neutral slate in the
gameplay architecture. Green grass and foliage plus dark/mid/light pink cherry
blossoms provide natural contrast against blue water and atmosphere. Thread
blue belongs primarily to water, distance, and restrained fabric accents; it
should not wash every foreground material into the same hue.

Generated placeable sheets must leave generous empty space between elements
and around every canvas edge. Prefer one complete building per source image.
Keep original renders alongside cleanup/keyed versions so edge work can be
revisited non-destructively in Krita.

Use the hybrid kit in this order: generate the varied ground-art base from
approved collision, place collision-backed wood platforms only where traversal
needs them, align rear buildings under the playable surfaces, then add
collision-free supports and foreground frames for depth. Finish with asymmetric
grass and cherry clusters rather than distributing decoration evenly.

## Building Cutaways

Buildings intended for entry use separate interior, exterior, gameplay, and
foreground layers. A doorway-sized detection zone fades the exterior shell and
raises the interior lighting while the player remains in the same room and on
the same collision. Foreground beams stay visible above the player to sell
depth. This approach avoids loading a second level for a small house and keeps
the camera and movement continuous.

The exterior should remain partially visible during a cutaway rather than
vanishing completely. A faint shell preserves the building silhouette and
communicates that the character is occupying the same physical structure.
