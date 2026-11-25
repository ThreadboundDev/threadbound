# Blue Ricefield Crossing

Open `blue_ricefield_crossing.tscn` and press **F6**. The cave mouth starts on
the west shore. Jump onto the long timber crossing, then double-tap **Down** at
the Lower Walk sign to descend to the rice terraces and their gatehouse. The
lake reaches the background horizon at world Y = 0. The stone aqueduct arch
and its cool lanterns mark the submerged approach. **R** returns to the cave.

The original `blue_blockout.tscn` holds Chase's 512 authored cells and route
markers. The dressed scene retains the same tile bytes and uses the player
position Chase placed as its spawn. Toggle `Geometry/GreyboxTerrain` in the
editor to compare the art with collision. The lake, scenery, and encounters
have independent branches. Rocks, decks, railings, braces, buildings, crops,
lanterns, and lakebed props remain individually selectable in the scene tree.
The runtime art folder has the original path and hash of each copied stamp.

The west cave, ricefield gate and aqueduct are route landmarks in this scene.
A Terrace Watcher and Tide Duelist give the lower routes different encounters.
The local tileset and one-cell physics quadrants let the existing one-way drop
identify the contacted tile. The upper deck remains grappleable.

Verification covered 24 level checks and 31 platform-drop regression checks.
Normal controls reached the upper deck, dropped to the lower walk, reached the
ricefield bank, and swam through the aqueduct approach. The ricefield route
check isolated the geometry by removing its encounter in the test instance.
The Forward+ playtest inspected the cave entry, east bank and submerged arch.
The editor playtest also confirmed a layer-4 ray hits the high deck at Y = -1536.
