# Demo character lighting and double jump — October 30

Chase's demo replay is positive about overall feel and the existing 2D enemies.
He reported that lighting misses the current character and that double jump has
no new animation. He requested replaying the jump, slightly faster. The wider
2D/stamp direction is recorded in the [direction document](../design/2d_asset_reuse_direction_2026_10_29.md).

## Changes

- `room_hue_grade.gd`: after scene readiness, add receiver layer 2 to demo
  environment lights which already illuminate scenery on layer 1. This includes
  the generated central thread lights and instantiated wing fixtures. Existing
  color, energy, shadow settings and scenery masks remain intact. CharacterBody2D
  descendants retain their existing effect masks, including the player's own
  soul glow and enemy auras. This is a one-time setup pass for level fixtures;
  it does not install a global light listener or convert the 3D lighting rig.
- `player.gd`: detect when the existing boots action actually consumes an air
  jump and notify the live visual. No animation event for a rejected AP spend.
  Existing attack-owned visuals keep priority. Jump forces, AP cost, availability
  and equipment behavior are unchanged.
- `player_live_3d_visual.gd`: `Double_Jump` force-restarts existing `jump_1` at
  1.2× its ordinary playback rate. The same clip can restart during ascent;
  waiting for an ascent/apex/descent state change was the missing event.

The character's receiver mask was already 2, while legacy demo lights used 1.
Godot's [Light2D mask documentation](https://docs.godotengine.org/en/stable/classes/class_light2d.html#class-light2d-property-range-item-cull-mask)
describes the matching receiver/cull-mask requirement. No shader or art change
was needed for the corrected environment light to reach the composite.

## Verification

Use `tools/player_animation/verify_demo_jump_lighting.gd` with Godot 4.7.2:

```text
Godot --headless --path . --script tools/player_animation/verify_demo_jump_lighting.gd
Godot --path . --script tools/player_animation/verify_demo_jump_lighting.gd -- --render-fixtures
```

- Real input/physics checks cover first jump, early and falling double jumps,
  clip restart and 20% faster playback, landing/normal-speed restoration,
  retained one-AP cost, and rejection without an animation reset.
- The complete demo loads headless and audits all 88 environment lights,
  including generated thread lights. Enemy glow masks and self-light exclusion
  are checked separately: **134 checks pass**. The baseline reproduced the missing restart/rate and
  mismatched environment masks before the fixes.
- A small Forward+ scene runs the actual atmosphere code, shared live player and
  red-wing fixture. Turning the fixture off/on changes 71,780 rendered pixels
  toward red; **three render checks pass** and both character captures were inspected. This establishes rendered
  light response, not acceptance of the full demo's final lighting balance.
  [Light on](../../work/demo-jump-lighting-2026-10-30/fixture_lit.png),
  [light off](../../work/demo-jump-lighting-2026-10-30/fixture_lights_off.png).
- Full-demo GPU capture hit Vulkan memory allocation/swapchain limits while
  Chase's editor was open. It produced no usable full-level visual evidence.
  The smaller fixture review passed without closing or altering that editor.
- Camera interpolation and resource/renderer shutdown diagnostics remain.
  The full headless test reports eight ObjectDB/three retained resources; the
  isolated render reports six ObjectDB/three retained resources plus texture
  shutdown messages. These fixes do not close T04 diagnostics.

## Acceptance and checkpoint

**Delivered; lighting balance and second-jump feel await Chase's retest.**
Restart the demo scene with F6. Walk between dim floor, the cave opening,
central threads and colored wing lights. Double-jump early and while falling,
then land and jump again. The second jump should visibly replay the takeoff,
slightly faster, with normal speed restored on the next grounded jump.

Checkpoint: `fix: restore demo character lighting and double jump animation`
on `threadbound/fix-demo-lighting-double-jump` (resolve hash in Git history).
No lake background acceptance or enemy-art replacement is inferred from this review.
