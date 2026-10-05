# Bellstriker — playable prototype

## Current v4: attached wrists and trailing swimming feet

Live model: `Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v4.glb`. Editable source: `ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v4.blend`. v3 is preserved. `tools/art/revise_bellstriker_attachment_v4.py` loads the saved v3 rather than rebuilding its rig or combat poses.

The old mesh-space split missed the near glove because the supplied model faces diagonally: the glove remained attached to the body while the near fist bone moved leg details. v4 extracts both actual glove shells (retaining their faces/UVs) and mounts each at its existing animated wrist, facing forward. Those misplaced leg details are rebound to the body/limbs. The accepted head skin and original rear-body skin remain intact. Rigid navy wrist sockets/bridges overlap both forearm ends and glove surfaces, following each fist without stretching its shell. Swimming upper legs, shins and feet now flex subtly with a delayed traveling rhythm, rather than kicking in a walking gait. Swim idle uses a reduced version. All original body, tail and combat animation curves, bones, damage and timings remain unchanged. The original fused model still has shoulder/head details that would benefit from manual art cleanup.

`tools/art/verify_bellstriker_attachment_v4.py` checks actual wrist/glove mesh proximity, arm-chain continuity across the combos, unchanged original curves outside the swimming leg rotations, and seamless moving foot loops. Existing imported-pose and combat checks also target v4. Use `render_bellstriker.tscn -- --combo-frames --output=<directory>` for six samples of each water combo segment and the swim cycle.

## Previous v3: full-spine swimming and vertical boxing

The live visual now uses `Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v3.glb`, with editable source `ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v3.blend`. v1/v2 and the supplied high-resolution model remain untouched. `tools/art/revise_bellstriker_spine_v3.py` builds v3 from v2 and refuses to overwrite an existing v3 source unless explicitly told it is still an untouched generated output.

The 44-bone rig includes body/thorax/neck/head, a connected six-segment abdomen-to-tail-fan chain, shoulder/elbow/fist chains, four three-joint legs per side, and antenna branches. The tail chain extends past the end of the mesh; tail-fan vertices have full tail-fan influence, not a mix with the stationary torso. Swim and swim-idle use a traveling vertical wave through the entire rear body, with smaller counter-motion in the thorax/head and tucked legs that follow their corresponding body segment. Vertex weights are normalized. Swim/guard loops match at their endpoints.

Underwater guard rotates the central trunk fully vertical, curls the upper spine/head and lower tail toward the opponent, and holds both fists forward near head height. The head stays forward-focused through torso twist. Small spine/fist/leg motion keeps guard alive. Travel pitch is suppressed while boxing. Transition into the first water charge and between-punch guard is softened without changing attack timing.

Jab extends the lead arm while the other remains in guard. Cross extends the rear arm with opposite torso twist. The finisher gathers both fists together overhead and swings down/forward with body weight, then returns to guard. The arm poses use an analytic two-bone solve baked into the connected bones; the file contains ordinary editable bone keys, not live IK control widgets. Clubs keep rigid weights and have joint links at the articulated attachments. This is still prototype skinning of a fused generated model; shoulder seams, feelers, and small leg details remain candidates for a manual art cleanup pass.

Land walking, amphibious pursuit/leaps, hitboxes, timings, damage, aim locking, hurt/death, and reset behavior are unchanged. The render viewport has extra room for the overhead pose while retaining the same pixels-per-world-unit and apparent creature size.

Verification: `tools/art/verify_bellstriker_spine_v3.py` checks the saved Blender chain, weights, actual rear-mesh motion in three body bands, and rigid claw deformation. `tools/enemies/verify_bellstriker_animation.gd` checks imported bones/poses, head focus, raised guard, jab/cross extension, gathered overhead fists, simultaneous smash, whole-chain motion, and loop endpoints. The existing `verify_bellstriker.tscn` integration scene checks all prior combat/environment behavior. `render_bellstriker.tscn` includes all three water charges for visual review.

## Previous v2: swimming and boxing (historical)

The live scene now uses `Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v2.glb`, authored in `ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v2.blend`. Previous v1 source/export are preserved. `tools/art/revise_bellstriker_boxing.py` generates the initial v2 source; never regenerate over manual edits.

Water pursuit uses a tail/body swimming cycle with tucked legs, not the terrestrial walk cycle. Water idle floats with tucked legs. In close combat the thorax raises 52 degrees; head and claws counter-rotate to face forward. Presentation aims toward the target around the body center. Land movement remains walking, and water/land leaps are retained. The generated fused source required separating the club shells into rigid pieces to prevent stretched triangles; shoulders, leg weights, and transitions are still prototype art and need a manual cleanup pass.

Combo: left jab, right cross, heavy double-claw smash. Windups: 0.32 / 0.27 / 0.62 seconds. Active windows: 0.12 / 0.14 / 0.22 seconds. Damage: 16 / 21 / 32 before existing scaling. Each punch damages a receiver once, with light hitstop on the first two and stronger hitstop on the finisher. Aim tracks between punches and during initial windup, then locks for 0.10 seconds (0.20 for finisher); released punches never home. Small approach steps between punches maintain pressure. Walls or an escaping target end the sequence early. Final recovery is 0.90 seconds, plus 0.45-second cooldown. Hurt/death interrupt the sequence and disable damage.

The existing F6 test scene and lake spawn both use v2. Integration checks cover swimming vs walking clips, upright charge, all three punches and single-hit damage, locked aim in both facings, escape cancellation, harmless gaps/recovery, wall occlusion, leaps, air pockets, hurt/death, and save reset. The v1 tuning below is historical and superseded by this section.

Implements the amphibious elite in `docs/design/blue_swordfish_ecosystem_and_environmental_combat.md` using the supplied `hitem3d.glb`. This is a gameplay and animation first pass, not final creature animation.

## Test locations

- Open `Src/Enemies/Bellstriker/bellstriker_test.tscn` in Godot and press F6. Start on the dock, bait the water-to-land leap, then swim into the pool to test underwater combat. Swimming is unlocked in this scene.
- Also placed in `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` at `(2500, 820)`, beyond the initial fish/reedhook encounters.
- Reusable enemy scene: `Src/Enemies/Bellstriker/bellstriker.tscn`.

## Current behavior

Two-axis aquatic pursuit and short-burst terrestrial pursuit. Launches ballistic leaps toward nearby land/platform targets or off ledges toward water. Air pockets count as dry space. Terrain blocks movement and strike damage.

Charge lasts 0.70 seconds. Aim follows the player initially, then locks for the final 0.20 seconds, with a gold warning and bell cue. The claw strike commits for up to 0.20 seconds, ending early against a wall. Recovery lasts 0.80 seconds before pursuit resumes, followed by a 0.45-second attack cooldown. There is no passive contact damage; charge and recovery are safe to punish. Each strike can hit a receiver only once.

Starting tuning: 320 HP, 28 strike damage (subject to existing enemy scaling), reduced incoming knockback. Uses shared hurt, hit flash, hitstop, health bar, death, pickups, and save-point reset systems. Bell audio is synthesized locally; no external audio dependency.

## Editable assets

Original preserved unchanged: `ArtSource/BlueBiome/Enemies/Bellstriker_HighRes_Source.glb`.

Blender source: `ArtSource/BlueBiome/Enemies/Bellstriker_Rigged_v1.blend`.

Game export: `Assets/BlueBiome/Enemies/Models/Bellstriker_Rigged_v1.glb`.

Approximately 50,000 triangles instead of the source's two million, with 2048-pixel textures. Body, head, claws, antennae, tail, and six leg controls have first-pass weights. Eight clips: idle, pursue, charge, strike, recover, leap, hurt, dead. Forward is +X in Blender, feet at Z=0. Refine weights and animation in Blender before final art; fused source geometry limits fully independent claw and leg movement. This prototype does not include platform navigation/pathfinding, wall-sticking, variant colors, or environment-break interactions.

`tools/art/build_bellstriker.py` generates the initial assets and refuses to replace an existing Blender source by default. Do not use `--replace-generated` after manual edits.

## Verification

`godot --headless --path . res://tools/enemies/verify_bellstriker.tscn`

Tests actual water/dry-pocket classification, aquatic pursuit, all imported clips, harmless charge, locked aim, single-hit strike, recovery timing, wall occlusion, ballistic dock landing, hurt interruption, death, and save-point restoration.

GPU animation previews: `godot --path . res://tools/enemies/render_bellstriker.tscn -- --output=<absolute-directory>`.
