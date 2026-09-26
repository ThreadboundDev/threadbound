# Hanging Bell — Trapped Flowing Water

First 3D implementation of approved concept A. This is an editable source asset
and motion prototype; it does not replace the gameplay bulb scene yet.

## Review

- `water_bulb_review.png`: rendered form and state comparison.
- `water_bulb_rushing_loop.gif`: seamless ready-state current loop.
- `water_bulb_pop_refill.gif`: ready, pressure release, spent flower, and refill.
- `water_bulb_hero.png`: transparent full-resolution orthographic render.

The flower stays mostly still. Independent water ribbons and carried bubbles
keep moving inside the sac; the flower twitches under pressure, snaps when the
water escapes, then refills with the current already running. The animation is
authored geometry and transforms, not a baked fluid simulation.

## Editable deliverables

- `WaterBulb_HangingBell_v1.blend`: separate editable stem curves, petals,
  calyx, membrane, water body, current ribbons, bubbles, and splash droplets.
  Includes lights, a fixed orthographic camera, and named timeline markers.
- `WaterBulb_HangingBell_v1.glb`: portable mesh export with transform animation.
  The decorative camera-facing contour is deliberately excluded.
- `manifest.json`: frame ranges and render settings.
- `frames/`: transparent 360 × 480 PNG sequence, 24 fps.

| State | Blender frames | Use |
|---|---|---|
| Rush | 1–24 | Loop while bulb is intact |
| Pop | 25–36 | Trigger once when gameplay consumes bulb |
| Spent | 37–42 | Empty flower; can hold until regeneration |
| Refill | 43–72 | Restore appearance before returning to rush |

The glTF export has one combined timeline. Split it using these frame ranges
when integrating. Material appearance, transparency sorting, collision scale,
and performance still need an engine pass. Gameplay should continue owning
the pop trigger and regeneration timing; art should not change launch rules.
The source is deliberately detailed enough to review before optimization.

## Rebuild

Run background Blender with `--factory-startup --threads 8 --python
tools/art/build_water_bulb.py`. Add `-- --preview-only` to render only the hero.
Then run `tools/art/package_water_bulb_preview.py` with Python + Pillow.
Both scripts write only this new asset folder. Existing character sources and
the user's open Blender session are untouched.
