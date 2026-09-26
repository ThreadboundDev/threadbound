# Reedhook — playable first pass

Reedhook patrols dry platforms, approaches a nearby player on the same level, plants his feet for a raised hook windup, and makes one forward sweep with a short step. Recovery leaves an opening. Received damage interrupts the attack and plays a recoil animation. Existing EnemyBase handles health, damage feedback, death, and save-point resets; no shared combat architecture was changed.

One instance is placed at `(1408, 370)` in `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn`, on the deck to the right of the first dive. It settles onto the floor at about Y=384. The reusable scene is `Src/Enemies/Reedhook/reedhook.tscn`; it displays the model in the editor.

## Behavior

- Patrol speed 65 pixels/second, pursuit speed 105. Walking playback follows movement speed.
- 0.6-second windup; 0.267-second sweep; 0.6-second recovery; 0.8-second cooldown.
- The first 35% of the sweep lowers the hook from the raised pose before damage activates. The short forward step occurs during the damaging part.
- Each sweep deals 18 base damage once per target. Idle contact, windup, and recovery do no damage. Existing difficulty scaling applies.
- Facing locks during the attack. The player can dodge behind him; the swing does not track them through the windup.
- Ground probes stop patrol, pursuit, and attack steps at platform edges. He does not intentionally walk into lake water. He can patrol dry air-pocket floors.
- Walls block target acquisition and attack hits. He does not jump gaps, climb, or navigate between platforms.
- Hurt lasts at least 0.4 seconds and cancels the blade immediately. Death and save-point restoration reuse the established behavior.

The stats resource controls damage, health, speeds, and timing. `patrol_distance` and `start_facing` can be adjusted per scene instance. Place his origin at the floor or slightly above it.

## Animation assets

`ArtSource/BlueBiome/Blender/Enemies/Reedhook_animated.blend` retains separate editable pieces. `Assets/BlueBiome/Enemies/Models/Reedhook_animated.glb` contains the skinned runtime model and six clips: `idle`, `walk`, `windup`, `sweep`, `recover`, and `hurt`. The original v1 model remains unchanged.

The weapon drives both hand positions. Two-bone limb solves are baked into each clip, including planted attack feet and alternating walking foot lifts. The walk is in place; the game supplies translation. These are simple first-pass animations, without cloth simulation or a custom death clip.

Rebuild using Blender 5.2 with `tools/art/animate_reedhook.py`. This overwrites the animated outputs, so save manual edits as a new version first.

Previews under `ArtSource/BlueBiome/Blender/Enemies/`:

- `Reedhook_animation_review.gif`: imported poses in sequence, without gameplay movement.
- `Reedhook_lake_gameplay.png`: actual model placed on the lake's greybox deck.

## Verification

Run Godot against `tools/enemies/verify_reedhook.tscn`. Checks cover floor placement, patrol motion and walking playback, ledge turns, attacks in both directions, one hit per sweep, harmless windup/recovery, accepted damage, interruption and recoil, attack-step ledge safety, wall occlusion, all imported clips, death, and reset.

A rendered lake check confirmed the placed enemy is grounded and visible. Blender sampling of every baked frame found a maximum hand-to-grip position error below 0.000001 model units across all six clips.
