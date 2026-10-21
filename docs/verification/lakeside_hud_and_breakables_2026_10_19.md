# Lakeside HUD, enemy reset and blue breakable stone

The lakeside Krita playtest now instances the established combat HUD. The
player's existing HUD synchronization supplies health, AP, cooldowns, momentum,
identity and pattern; a numeric readout makes values easy to compare in tests.
No player stats, equipment rules or HUD artwork were changed.

The scene captures authored enemy and wall PackedScenes in `_enter_tree`, before
runtime `_ready` methods create health bars, lights and AI state. F2/the respawn
button replaces the three enemy instances at their original positions, with all
scene overrides intact. Replacing the instances also prevents pending death
timers from hiding newly restored actors. F1 restores the wall snapshots and
cleans up any surviving rock effects. This is local playtest support.

The reusable blue rock prefab subclasses the existing swordfish-only greybox
wall. The base now has `hits_to_break`, `hits_taken` and a `damaged` signal.
The swordfish exposes a monotonically increasing dash activation ID so terrain
substeps cannot exhaust a reinforced wall in one dash. Return values preserve
the original contract: false while solid, true only once collision is released.
Single-hit greybox behavior remains covered by its existing integration test.

The blue visual uses the original map `quarry_block.png`, with fifteen
deterministic Voronoi stone fragments, silhouette-clipped branching cracks,
four damage stages, widening seams, blue pulse/impact flash and a small local
blue light. Stone renders under the existing lake overlay; an unlit crack layer
keeps the glow visible above the water tint. A separate non-colliding Node2D draws the same textured fragments
after the physical wall is deleted; shards drift, rotate, shrink slightly and
fade before the effect frees itself. Gravity remains downward for rotated walls.

## Scope

- `Src/Environment/BlueBiome/Prototypes/lakeside_krita_playtest.gd`
- `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
- `Src/Environment/Greybox/greybox_breakable_wall.gd`
- `Src/Enemies/TideDuelist/tide_duelist.gd` (dash ID only in this task)
- New `blue_breakable_rock.gd`, `.tscn` and `blue_rock_shatter.gd` in the prototype folder
- `tools/environment/verify_lakeside_hud_and_breakables.gd`
- `tools/environment/verify_lakeside_krita.gd` (new painted wall assertion)
- Playtest instructions, previews and this verification note

## Validation

Godot 4.7.2, headless and actual Vulkan Forward+ on Radeon RX 6800 XT. The
dedicated integration script passes 65 gameplay checks headlessly and 111 total
checks including captures in Forward+. It exercises health and AP signals independently;
initial binding and momentum; F2/F1 dispatch and the visible button; death-time,
missing and repeated enemy respawn; authored transforms and tuning; actual
swordfish movement into one-hit and four-hit walls; duplicate probes; partial
wall recovery; same-dash traversal and ordinary-terrain blocking; fragment
cleanup; and wall restoration without moving the player.

`verify_greybox_walls_and_bulb_art.tscn` also passes its existing 26 checks.
`verify_lakeside_krita.gd` passes the map integration, including all 41 painted
chunks, 51 rock polygons, 9,871 terrain samples with zero mismatches, original
water/air pockets, building floors/cutaways and original 4K PBR textures.

Test runs use scratch APPDATA so user settings and saves are unaffected. The
project still reports its pre-existing equipment/resource shutdown leak
diagnostics; there are no runtime script errors in the passing verification.
See the JSON reports and rendered captures in `work/lakeside-ui-rock` and the
selected user-facing copies in `outputs/lakeside-krita-playtest`.
