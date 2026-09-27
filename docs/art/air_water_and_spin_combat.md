# Air/water slash and directional special

Air and water basic attacks reuse the first swing of `slash_2`, the existing grounded opener. The live clip runs from 0 to 1.10 seconds of source time; damage and sword VFX use source frames 16–24 at 30 FPS. Playback speed scales both together. Water attacks remain single swings, including when touching the lake floor.

A hidden animation sampler keeps the jumping, swimming, or water-idle lower body. Water also retains its torso/head pose and swimming tilt. The sword arm performs the authored swing, with a constant directional shoulder rotation instead of continuously pinning the blade toward the aim point. Starting a slash blends over 0.08 seconds and preserves the current swim phase. Downward aerial hits retain pogo behavior; downward water hits do not bounce the swimmer.

Hold left or right and press the existing SpecialAttack control while grounded and dry to use `attack_2`, the previously unused spinning slash. No direction retains the neutral explosion. The spin costs the same two action points as neutral special, lasts 0.85 seconds, and moves at 420 px/s during source frames 8–25. This produces approximately 155–165 pixels of travel. Movement uses normal collision response. A radius-175 circular hitbox follows the body during that window, hits each target once, and knocks targets radially outward. Damage is 1.8 times base attack damage, with existing skill/momentum scaling. Dash cancellation is allowed before the active swing or during recovery. No underwater special or underwater combo is added.

The runtime model `threadborne_equipped_combat_swings.glb` is exported from the existing final equipped Blender source, with `attack_2` and `attack_3` included in the exporter allowlist. Grounded normal attacks and the neutral special keep their existing clips.

Validation: `tools/combat/verify_lake_attack_refresh.gd` checks directional selection, action-point cost, radial hits and deduplication, active source frames, cleanup, neutral-special preservation, and water attacks at rest and while swimming horizontally/vertically. A separate physics run checked left/right travel and stopping at a solid wall. Rendered pose review: `air_water_slash_review.png` (air, water idle, swimming); `spin_source_review.png` (spin clip).

These are animation/combat checks, not a replacement for the user's controller feel review. Existing Godot certificate-store and shutdown resource warnings remain.
