# Tide Duelist — playable first pass

The swordfish samurai holds its ground while gently hovering and flexing its body/tail, curls into a draw stance, flashes its eye, and dashes along a fixed direction. Taking damage interrupts the attack and plays a recoil clip. It uses the existing EnemyBase states, health/hurtbox/hitbox components, death feedback, and save-point reset behavior.

One instance is in `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` at `(640, 760)`, in the water below the first dive. The reusable scene is `Src/Enemies/TideDuelist/tide_duelist.tscn`. It has a live, static 3D editor preview, so it can be moved and duplicated in the 2D editor.

## Behavior and timing

- Holds its physics position, including when it detects a visible player outside attack range. Awareness lights the eye; visual aim eases toward the target.
- Locks aim at the start of the 0.733-second curl. The last part holds the curled pose, leaving a dodge opportunity.
- Eye flashes ivory-hot during the last 0.12 seconds of the harmless windup.
- Plays the original release/dash, then a streamlined tail-beat loop during the committed swim. Its first 0.04 seconds straighten the blade before movement and damage activate. Dash speed is 1050 pixels/second; the dash ends at terrain/water boundaries, with a 2400-pixel safety cap.
- Stops in place for 0.567 seconds of head-shaking recovery, reorienting toward the player late in recovery, followed by the existing 1.2-second cooldown.
- A dash deals 18 base damage once per target. Passive body contact, the windup, and recovery do no damage. Difficulty scaling still uses EnemyBase.
- Hurt animation lasts at least 0.4 seconds; received knockback is preserved and decelerated in water. Hurt and death immediately disable the blade.
- Movement is checked in steps of at most six pixels, against terrain and a conservative envelope around the model. The fish cannot cross the lake surface or dry air pockets. Blade hits also check line of sight and water between fish and victim.

Terrain blocks its strike; it does not find a route around walls or between disconnected pools. A placement without polygon water pauses movement and reports a warning. Allow roughly 100 pixels around its center when placing it near shores or air pockets. Optional `water_path` explicitly binds it to a polygon lake; otherwise it finds the containing lake at spawn.

## Tuning and sources

`tide_duelist_stats.tres` controls health, patrol/chase speeds, damage, attack timings, cooldown, and hurt response. The scene's Inspector exposes `dash_speed`, `attack_range`, `patrol_distance`, and `patrol_height`.

### Living motion pass

`Visuals/Fish` has a **Living Motion** Inspector group. Default idle is a 4.8-second body-to-tail vertical wave with slight head counter-motion, a three-pixel visual bob, and 1.4 degrees of pitch. Tail-tip motion defaults to nine degrees. Instances start at different phases, and awareness/idle changes do not restart the animation. This suggests an animal actively holding station, without moving the damage/body collision or disturbing the surrounding still water.

`life/hover` and `life/dash_glide` are generated from the existing rig at runtime; the approved GLB and Blender sources are untouched. The dash loop starts only after the original blade release finishes, so it never repeats the curl or changes damage timing. Hover fades out for attack windup, clears immediately on hurt, and all living animation stops on death. Save-point reset restores it. Setting `living_motion_enabled` to false before starting restores the original static presentation.

`tools/enemies/render_tide_duelist_life.tscn` renders a three-row contact sheet (original still / living idle / dash glide). Integration checks additionally cover bounded bob, actual skeletal motion, seamless loop endpoints, dash-glide activation, hurt/death suppression, and reset.

The current painted model, rig and generation workflow are documented in [the painted v2 notes](tide_duelist_painted_v2.md). Earlier study outputs remain available for reference:

- `ArtSource/BlueBiome/Blender/Enemies/TideDuelist_animated.blend`
- `Assets/BlueBiome/Enemies/Models/TideDuelist_animated.glb`
- Clips: `swim`, `draw_curl`, `dash`, `recover`, `hurt`.
- `tools/art/animate_tide_duelist.py` rebuilds the animated outputs from `TideDuelist_v1.blend` using Blender 5.2. It blends neck weights so the head can curl without separating from the body.
- `ArtSource/BlueBiome/Blender/Enemies/TideDuelist_animation_review.gif` shows the imported clips; this is a pose review, without gameplay translation.
- `ArtSource/BlueBiome/Blender/Enemies/TideDuelist_lake_gameplay.png` shows the curled pose in the actual lake scene.

These remain simple first-pass animations and materials. Reedhook now has its own [playable behavior and animation pass](reedhook_behavior.md).

## Verification

Run Godot with the project and `tools/enemies/verify_tide_duelist.tscn` (use the scene, not `--script`, so project autoloads initialize before the combat scripts).

The integration checks cover stationary idle and awareness, both eye materials, harmless prestrike flash, fixed aim, one hit per dash, disabled recovery hitbox, accepted player damage, hurt interruption and knockback, a six-pixel-wide air pocket, shoreline containment, solid-wall collision and occlusion, imported clips, lethal damage, and save-point reset. Imported Godot renders confirm the painted rig's still, curl and dash poses.
