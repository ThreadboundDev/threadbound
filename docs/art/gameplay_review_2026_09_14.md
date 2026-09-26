# Gameplay, combat VFX, and art review — September 14, 2026

## Evidence and scope

Reviewed the supplied `2026-09-14 11-20-11.mp4` (2560 × 1440, 60 fps, approximately 52 seconds) through timestamped frames across the recording, with denser 0.1-second samples of ground combat at 3.6–4.3 seconds and aerial combat at 19.3–20.8 seconds. These samples support visual observations, not exact input latency or damage counts.

Inspected selected frames and a frame-stepped combat passage from [Castlevania: Belmont’s Curse Gameplay & Commentary Trailer, XBOX](https://www.youtube.com/watch?v=mRT4JE4BJ5o). Useful reference points: approximately 0:29 for a compact gold weapon trail, 0:34–0:39 for combat against a large enemy, 0:48 for an airborne weapon connection, 0:58 for a large impact burst, and 1:08 for traversal readability. The early trailer also includes a Dead Cells comparison; do not confuse that footage with Belmont’s Curse.

Cross-checked the current local Godot scripts and Blender export pipeline. The checkout has substantial existing uncommitted work. This review adds documentation and a recording-extraction utility; no runtime, combat, animation, or art asset has been changed. Recommendations below are proposed work, not completed fixes or a replacement of approved art direction.

## Findings

| Area | Recording observation | Confirmed implementation |
| --- | --- | --- |
| Sword smears | The ground attacks around 0:04 have weak, disconnected trails. The weapon path is difficult to read against the brown background. | `player_live_3d_visual.gd` spawns copies of the sword mesh every 0.055 seconds, at 0.16 alpha, lasting 0.16 seconds. Emission follows the entire attack action, without a strike-phase or blade-speed test. |
| Air attack | The sequence around 0:19–0:21 has a large overhead body gesture and little clear sweep information. It does not communicate a compact basic aerial slash. | `play_air_attack()` plays `attack_1`. The controller still uses `Air_Double_Attack` and two active windows: source frames 5–7 and 16–18. Each window enables the hitbox and triggers strike audio/VFX. This is a behavioral mismatch, not only an outdated animation name. Actual damage count per target still needs a runtime test. |
| Player/enemy cohesion | The player reads as a dark, solid mass; enemies read as pale, finely detailed illustrated forms. This is particularly apparent around 0:04 and 0:44–0:47. | The player uses a lit 3D model composited into 2D; existing enemies use sprites. Medium alone does not establish why they clash. Value distribution, edge treatment, internal detail, and animation cadence all need comparison. |
| Water visibility | Around 0:25–0:29, the player is largely hidden by the blue fill. Similar disappearances recur later. This removes movement feedback. | `greybox_water.gd` explicitly forces fill alpha to 1.0; the playground basin also specifies alpha 1.0. Polygon water is a separate path and defaults to 0.92 alpha. Changing the reflective-water shader alone would not fix this basin. |
| Dive | Bank-to-water movement lacks a clearly staged dive. | `enter_prototype_water()` starts `jumping_into_water_1` after overlap, when entering with downward velocity. The asset exists; triggering it earlier and coordinating motion are the missing pieces. |

## Combat and VFX target

The reference makes movement legible with continuous directional lines, sharply bounded shapes, and concentrated flashes. Its bright effects contrast with broad darker architectural forms. Threadbound should adopt those readability principles using its own woven visual language.

1. **One visible slash, one strike window.** Author the basic aerial attack in Blender on the existing rig. Use an airborne ready pose, a short readable anticipation, one decisive sword sweep, and a compact recovery into falling. Keep the shield out of the sword silhouette. Avoid a second windup or an authored takeoff/landing inside this clip; Godot should own the jump trajectory.
2. **Create a continuous sweep.** Replace the duplicate-sword technique with a tapered ribbon following the projected blade path. Give it a crisp ivory leading edge, a restrained warm-gold body, and at most a few thread filaments on the disappearing edge. Maintain open space around the torso and face. Do not solve weak readability by simply making every effect larger or brighter.
3. **Tie shape to motion.** Emit during the fast slash, taper through follow-through, and stop before recovery. A starting visual target is roughly 80–120 ms of trail persistence, subject to normal-speed review. Interpolate samples at low frame rates; reset history on facing changes, teleportation, attack cancellation, and clip transitions. Movement of the player must not drag old trail samples along incorrectly.
4. **Separate swing from impact.** A miss gets the sweep and swing sound. A confirmed hit adds a small sharp contact flash and a few directional fragments. Reserve larger bursts for stronger events. The large flare around reference 0:58 is useful for shape design, but its scale should not become the default light-hit effect.
5. **Preserve escalation.** Base attacks must read without Flow. Flow may add a controlled secondary accent, but must not double the main sweep or obscure enemy tells. Review existing Flow swing emissions when integrating the new smear.

Author `air_light_1` as a new action in a versioned Blender file. Keep `attack_1` intact as an overhead-special candidate. Do not silently assign it a special attack, cost, or damage rule. Retain the existing downward pogo behavior while correcting the ordinary air slash.

Choose the new clip’s contact frames from the actual sword passage, then synchronize damage, sound, and VFX to those frames. Do not carry over the current 5–7 window as if it were valid for a newly authored clip. Test at all supported attack-speed multipliers.

## Art direction recommendation

Continue evaluating the hybrid 3D-player/2D-enemy approach. The recording does not justify rebuilding the enemies or abandoning the player model. Lighting and finished environments will help, but cannot alone reconcile silhouette, line weight, or motion style.

Build a small representative in-game comparison before a broad art pass: the same player and enemy together on the same platform, under one warm key/cool fill direction, with restrained background contrast. Compare exterior edge weight, player shadow values, enemy highlight coverage, and internal texture detail at the actual gameplay camera scale. Review both still poses and motion. The player's lower body and weapon must remain distinct without requiring a bright halo.

Use Threadbound’s established loom, spindle, tension, and woven architecture language. The reference is a guide to contrast, depth, and effects, not authorization to replace Threadbound with Castlevania architecture or lore. A larger environment or enemy asset pass requires its own concrete scope after this comparison.

## Water entry target

At suitable banks, show the existing interact binding with “Dive” when the player is close, grounded, and facing a valid landing volume. Pressing it starts the existing dive animation above water. Coordinate a collision-aware launch with the authored pose; create the splash on actual surface crossing, then blend to swimming. Prevent repeated entry triggers while volumes overlap.

Retain normal collision handling for unprompted falls and airborne entries. A bank prompt should not freeze the player at an invisible boundary or require interaction in midair. This proposal does not introduce a new progression requirement or change the current debug unlock policy.

Make the water body translucent enough to track the player and nearby boundaries, with a clearer surface line and quieter submerged contrast. Validate rectangular and polygon volumes independently. Avoid transparency settings that make the surface itself disappear.

## Proposed implementation files — approval scope

### Pass A: air slash and smears

Modify:

- `Src/Characters/Player/player.gd` — ordinary aerial attack becomes one synchronized strike; preserve pogo and other attacks.
- `Src/Characters/Player/player_live_3d_visual.gd` — load the versioned model, map `air_light_1`, and supply blade samples and attack phase to the new sweep.
- `Src/Characters/Player/flow_state_aura.gd` — coordinate Flow accents with the main sweep.
- `tools/art/export_equipped_live_3d_test.py` — accept explicit source and destination paths so the versioned animation can be exported without overwriting the current model.
- `Src/Tests/EquippedPlayer3D/equipped_player_3d_test.gd` — exercise the new action and preserve existing action mappings.
- `tools/vfx/verify_combat_vfx.gd` — verify emission cleanup and relevant VFX integration.
- `docs/art/player_animation_gameplay_map.md` — record the new basic attack and preserved special candidate.
- `docs/art/gameplay_review_2026_09_14.md` — record results and actual validation.

Create:

- `tools/art/build_air_light_animation.py` — reproducible Blender authoring script.
- `ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Air_Light_v1.blend` — versioned animation source.
- `Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_air_light_v1.glb` — versioned runtime export.
- `Src/VFX/sword_sweep_vfx.gd` — blade-path ribbon and lifecycle.
- `Src/VFX/sword_sweep.gdshader` — crisp edge and tapered fade.
- `tools/combat/verify_air_light.gd` and `tools/combat/verify_air_light.tscn` — count actual hit events per target per activation and verify cancellation.

Godot may generate corresponding `.uid` and `.import` sidecars for these new resources. Existing Blender and GLB sources remain available. No player scene-tree restructuring is proposed.

### Pass B: readable water and prompted dive

Modify:

- `Src/Environment/Greybox/greybox_water.gd` — honor configured transparency.
- `Src/Environment/Greybox/greybox_polygon_water.gd` — tune submerged readability consistently.
- `Src/Environment/BlueBiome/Prototypes/blue_water_playground.tscn` — basin material values and bank entry instances.
- `Src/Characters/Player/player.gd` — deliberate bank entry, collision-aware motion, and transition handling.
- `Src/Characters/Player/player_live_3d_visual.gd` — synchronize dive pose and swim transition.
- `tools/environment/verify_blue_water.gd` — prompted and unprompted entry cases.
- `docs/design/blue_water_momentum_prototype.md` — document bank interaction.
- `docs/art/gameplay_review_2026_09_14.md` — record results.

Create:

- `Src/Environment/BlueBiome/Water/water_dive_entry.gd` and `water_dive_entry.tscn` — bank detection, prompt, and destination configuration.

Corresponding Godot sidecars may be generated. This adds bank interaction scene instances; it requires approval under the repository scene/combat rules. Broader impact/death/splash art replacements and a representative environment art pass are subsequent proposals, not hidden additions to this file list.

## Acceptance checks

- One ordinary air input opens one damage window; each eligible target receives at most one hit from that activation. Ground chains and pogo retain their intended behavior.
- Attack pose, sweep, audio, and contact agree at normal speed and supported speed multipliers. Check both facings, rising/falling, landing, interruptions, and hit/miss cases.
- Smears remain continuous at 30/60/120 fps, disappear cleanly, and stay legible against dark and light backgrounds with Flow on/off. Judge actual game-scale capture, not only enlarged stills.
- The player remains trackable through the basin. Dive starts above the surface; splash timing follows contact; swimming begins reliably. Check overlapping water volumes, blocked launch paths, falls, exit, and re-entry.
- Headless checks establish behavior; normal-speed visual capture and frame stepping establish animation quality. Neither substitutes for the other.

## Implemented after approval

Chase approved the work and refined the scope: white smears with small weighted identity accents, a single neutral air slash, blue-tinted test water, prompted bank diving, and forward guard locomotion. Broad art matching is deferred.

- Added versioned Blender source and GLB with `air_light_1`; kept the overhead clip. Rendered review established source-frame contact at 9-14 and a more open airborne leg pose.
- Replaced sword ghosts with procedural tapered crescents. Damage sectors determine reach; source-animation phase determines timing, with projected blade input for the aerial sweep. Ground sweeps follow their configured windows because the imported ground actions still have side-view limitations. No damage-range increase was introduced.
- White remains the main effect color. Small internal lines read identity channels and weights through a defensive-copy API, also outside Flow. No new identity or equipment system was added.
- Removed the second ordinary air strike window; neutral air faces forward. Pogo keeps its separate behavior. Live-animation frames now also drive dash-cancel window checks.
- Forward standing guard reverses `run_2`; backpedaling plays it normally.
- Both test-basin banks offer the existing interact binding for a collision-aware dive into swimming. Test water is translucent blue. The older reflective treatment remains in the production Blue Chamber.

Validation: `verify_air_light.tscn` checks one hit per activation, both facings, source-frame sampling at four speeds, actual AnimationPlayer advancement at 30/60/120 fps and four speeds, reverse guard, identity snapshots, and cleanup. `verify_bank_dive.tscn` verifies both actual banks, prompts, above-water takeoff, and transition to swimming. Existing `verify_blue_water.tscn` reports `BLUE_REFLECTIVE_WATER_VERIFY_OK`. GPU captures were inspected for air poses and all three ground strikes.

Headless Godot also reports environment-level log/certificate/editor-setting access messages and shutdown resource-leak warnings. Verification markers pass; this is not a warning-free engine run. No commit was created. Existing unrelated checkout changes were preserved.

This is a playable first pass. Ground-animation side-view cleanup, broader impact/splash art, and animated underwater presentation remain future polish. Normal user playtesting is still needed to judge feel.

