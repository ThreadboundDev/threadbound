# Lakeside Krita playtest

Open this scene in the Threadbound Godot project and press **F6**:

`res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`

The saved 6912 × 5888 Krita map is imported at its original scale: one image
pixel per gameplay pixel, with world origin **(-1408, -2560)**. Reference guides
are excluded. The tower remains 1200 pixels wide and 4100 pixels tall. The
approved tower, net workshop, fisher house and covered boat slip share the
original tower materials and render through the existing 2D gameplay view.

## Collision follows the artwork

The old terrain TileMap's collision is disabled in this playtest scene.
`Geometry/RockCollision` is one StaticBody2D with **51 editable
CollisionPolygon2D outlines**, traced from the actual painted stone layers.
The silhouette is smoothed over an eight-pixel radius, pulled four pixels
inside the art, and simplified by five pixels. Tiny vertical connector edges
from tracing are collapsed into ramps, so the rectangular player body does
not catch on one-pixel walls. Sections keep
cave openings and the lower tunnel hollow; rear timber braces and the recessed
upper cave backdrop are non-solid. No image-alpha collision runs during play.

To adjust a rock edge by hand:

1. Expand `Geometry/RockCollision` in the playtest scene.
2. Select the `Outline_...` child at that location.
3. Use Godot's polygon edit tool to move, add or remove points.

Editable Children is enabled on the collision instance. Alternatively, open
`res://Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_rock_collision.tscn`
and edit the outlines directly. Saved manual edits persist: nothing retraces
or regenerates collision on scene load. The separate authoring tool
`tools/environment/build_lakeside_rock_collision.gd` overwrites this collision
scene **only when explicitly run** with its prepared solid-rock mask.

Buildings have separately named polygon floors, walls and roof landings under
`Geometry/BuildingCollision`. Bridge landings are one-way. The boat-slip center
and tower basin have no permanent floor across their openings. Existing
swordfish-breakable seals remain separate objects with their existing behavior.
Roof collision now follows continuous slopes instead of flat stair-step slabs.

## House clarity

All buildings now use the exact original Blender **4K PNG color, normal and
roughness maps**, with high-quality texture compression and anisotropic
sampling. The building viewports render at **125% resolution with 4x MSAA**,
then composite with linear filtering. Previously these passes rendered at 80%
and used 2K normal/roughness maps. Scale, geometry, UVs and material identities
are preserved. Restart the scene with F6 to load the new imports.

The shore spawn was moved inward to the actual painted ledge; the old blockout
spawn sat beyond the painted rock edge. The obsolete rectangular test-water
volume above the lake is excluded. The main lake and its three air pockets
retain their authored shapes and swimming behavior.

## Playtest and dressing

Bottom-screen buttons switch between play and overview, day and dusk, facade
cutaways, collision display and the shore/cave/building test positions. Normal
movement and swimming use the project's existing controls. Facades open when
the player enters and restore on exit.

Add foliage scene instances under `RearFoliage` or `FrontFoliage`; they are
separate from the artwork so sway can be added in Godot. Four lanterns live
under `Lighting` and illuminate the 3D architecture and 2D actors. Sunlight,
shadows and ambient presets are on `LakesideArtStage`.

The original Krita file and `blue_lake_greybox.tscn` are preserved. New map
resources live under `Assets/BlueBiome/Art/LakesideMap` with an import manifest
recording scale, source hash, image positions and assembly information.

## Validation

Godot integration checks cover the actual player standing on model floors,
the painted cave floor, entry/exit cutaways, original swimming and dry tower
air pocket, open lower passages, all 41 artwork chunks at exact coordinates,
and terrain physics sampled across the alpha mask. Rendered Forward+ views
cover overview, cutaways, shore, cave, tower interior and workshop.

Fourteen bidirectional player-size walking tests pass without stalls across
the shore, cave, right shore, ruin ledge and all three small-building roofs.
The current probe uses the player's capsule, speed, gravity and default floor
settings; no movement assistance was added.
The separate lakebed stress route still encounters large slopes above the
player's normal climb angle; those retain their intended jump/swim traversal.

The remaining visual work is environmental dressing and lighting refinement.

## Live HUD and repeatable combat tests

The existing combat HUD is now part of the playtest scene, showing the player's
health, action-point orbs and recharge, momentum, and equipped identity/pattern.
A numerical HP/AP/momentum readout sits below it for testing. These follow real
player values and retain the project's existing HUD behavior.

Click **Respawn enemies** or press **F2** to restore the swordfish, Reedhook and
Bellstriker at their authored positions with full health. Each instance retains
its scene-specific tuning. This also works during an enemy's death animation,
or after an enemy has been removed. The player and map stay in place.

Click **Restore rocks** or press **F1** to restore all three breakable walls.
The **Breakable rock** landmark button moves the player beside the left-hand
four-hit wall for a closer look. Debug controls belong to this playtest only.

## Blue breakable cave stone

The walls use the exact painted quarry-stone stamp already used on this map.
Four visual states progress from hairline cracks through branching blue glow,
wider splits and a bright final fracture. Cracks stop at the stone silhouette.
The last hit releases collision immediately, throws fifteen textured stone
fragments outward with blue glints, and fades the debris over 1.8 seconds.
Fragments have no collision and remove themselves after fading.

The existing **committed swordfish dash** remains the damage trigger. Normal
attacks, swimming contact, windup and blade-unsheathing cannot break these
walls. One dash counts once even when movement probes the wall many times;
a partially damaged wall stops the fish in recovery. A final hit allows the
same dash to continue through the opening and hit another wall behind it.

To place or tune a wall:

1. Instance `res://Src/Environment/BlueBiome/Prototypes/blue_breakable_rock.tscn`.
2. Set **Size** for its existing rectangular collision and matching art.
3. Set **Hits To Break** (1–16). The current three examples use 1, 2 and 4 hits.
4. Change **Preview Damage Stage** (0–3) to inspect the art in the editor. This
   preview never starts the runtime wall damaged.
5. **Fracture Seed**, **Crack Color** and **Debris Lifetime** control variations.

The greybox wall still defaults to one hit, and other rooms keep their existing
placeholder visuals. Only the lakeside playtest uses the painted rock prefab.

Verification covers real health/AP updates, F1/F2 input and the respawn button,
death-animation reset timing, missing/repeated enemy respawns, all four damage
states, one hit per dash, same-dash traversal, debris cleanup and wall restore.
Rendered Forward+ previews show the HUD, underwater wall and fracture stages.

Previews: `hud-in-game.png`, `breakable-rock-stages.png`,
`breakable-rock-critical-in-game.png` and `breakable-rock-animation.gif`.
The dedicated checks pass 65 gameplay assertions and 111 checks with captures.

## Capsule and hand-height ledge contact

The player's movement body is now a 37px-wide, 126.245px-tall capsule. Crouching
shortens it to 62% height, keeps its radius and planted feet, and checks the
standing capsule against ceilings before allowing a stand. Damage hurtboxes
and attack shapes retain their separate existing behavior.

Ledge grabs require a lip within 12px of the hand reach height, 84px above the
player origin. Torso, knee and foot contact alone cannot start a grab or wall
cling. Full-height walls still allow normal clinging. During the entry and
hang animations, the player follows the projected forward hand so it meets
the real edge in either facing. Grapple assistance extends horizontal reach
without widening the hand-height band.

The contact verifier passes 49 checks, including low-ceiling crouch/stand,
one-way jump/drop, valid and invalid ledges, pull-over and ledge jump, and
actual rendered hand registration. Restart the scene with F6 to try it.

## Working villagers

The fisher house contains the net mender and net frame. The workshop contains
the boatwright and planing bench. Click **Net mender** or **Boatwright** in the
bottom landmark controls, then use the displayed interaction key (currently E).
They pause work and turn to face your side. Interact again, walk away, or wait
six seconds for them to return to work. Their workstations stay fixed.

Reusable NPC and furniture prefabs are under
`res://Src/Environment/BlueBiome/Villagers/`. **Show Workstation** lets you place
the character alone; furniture-only prefabs are included. See
`docs/art/lakeside_villagers_v1.md` for placement, source and animation details.
This is the first modeled pass based on the approved character concepts.
