# Build your lake test level

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn`. Save a copy under your own room name before laying out the level. F6 runs it. The player has water traversal unlocked in this starter only; the game's progression is unchanged.

## Draw the level

1. Select Geometry and open the **Room Greybox** bottom panel. **Terrain Tiles** selects the existing layer: paint solid terrain to route the underwater space and one-way tiles for decks. **Large Block** and **One-Way Block** add resizable pieces.
2. Select Volumes, press **Polygon Water**, then **Edit Water / Air Points**. Use Godot's native polygon toolbar to create or move vertices. Concave shapes, sloping edges and narrow passages are supported. Use separate volumes for disconnected bodies. Do not cross a polygon's own edges.
3. Press **Move Water** to select and move the entire volume. Shape editing and dock additions support editor undo/redo. New water or terrain is not accidentally nested inside the selected polygon child.
4. **Air Pocket** adds a dry polygon. Shape it with the same edit button and overlap it with water. The water fill is cut away there and the player uses normal gravity/ground movement. Add solid floors/walls where wanted; the pocket itself has no solid boundary.
5. Move the player onto your starting porch. Adjust the Player/Camera2D limits to fit an expanded room. Place **Water Bulb** volumes for launch routes.

Air pockets currently override swimming for the player. Enemy AI does not gain an underwater movement system from this tool. A pocket's movement boundary uses the player's origin, so leave clearance for their body. The greybox water shader supports 16 pockets / 256 combined pocket vertices per loaded scene and warns when exceeded. Water shapes themselves have no such authored-point cap. Split larger maps into rooms.

## Movement and tuning

Directional movement swims in eight directions; Jump also swims upward. Ordinary swimming accelerates toward 480 px/s, brakes when input is released, and can reverse without the old steering circle. Dashes and bulbs can exceed cruise speed; forward input preserves the burst longer as resistance reduces it. Slow exits preserve their speed rather than forcing a rocket launch. Fast upward exits retain a modest boost and existing brief launch recovery. Dry pockets do not generate breach boosts.

Tune the player's **Lake Swimming** properties: speed, acceleration, braking, and burst resistance. The older prototype tuning fields remain for serialized scene compatibility; the old minimum-drift and steering-arc model is retired. Ability timing/unlock design remains undecided; PageUp still toggles the debug water ability.

## Visual scope

The authored lake room now includes the village/cliff backgrounds, horizontal parallax, slate terrain and painted wooden decks. The art rebuilds from the terrain tiles in the editor; it adds no collision and preserves the authored layout. Run this same scene with F6 to see the water in motion.

Enable **Lake Presentation** on polygon water for moving screen-space reflections, subtle surface glints and depth coloring, alongside lower opacity when submerged, dry-pocket cutouts and local movement/contact rings. Reflections use the visible screen, so offscreen scenery is not reflected. This is a first visual pass, not a surface-wave simulation. Rectangular legacy volumes still load, but new work should use Polygon Water. Underwater enemy combat remains separate work.

Current art comparison: `blue_still_village_hybrid_preview.tscn`. Use the lake starter for level layout and the hybrid room for the approved mixed-art direction.

## Validation and cleanup

`tools/environment/verify_lake_authoring.gd` checks concave containment, entry from rest, cruise/braking/reversal, dry-pocket priority, re-entry, slow/fast exits, transformed pockets and independent rectangular collision sizes. A real Godot render was checked for the pocket cutout and submerged visibility.

Retired: the EquippedPlayer and EquippedPlayer3D comparison folders, broken Blender-style preview scene, MaterialV2/MaterialV3 comparison scenes and shared preview script, and their obsolete runtime texture copies. Their editable art sources are retained. The live player, approved houses, bulbs, hybrid preview, reusable tools, and regression tests are retained. Earlier material documentation describes historical studies and may reference those retired runtime outputs.
