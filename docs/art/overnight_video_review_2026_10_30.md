# October 30 late playtest follow-up

Source: Chase's `2026-10-30 22-34-21.mp4`, 130.18 seconds, 2560x1440 at
60 fps. Reviewed 130 one-second visual samples across the complete clip and
additional 8-fps samples of 60–66 seconds for the run/guard presentation. Audio
has not been transcribed. Original video is retained in Chase's Videos folder;
raw extracted frames remain under `tmp/overnight-feedback-2026-10-30`.

## Feedback and observations

- Upright posture and the filled VFX are positively reviewed; preserve them.
- Sword-arm movement does not read clearly during the run around 60–64 seconds.
  Imported `run_1` has animated arm tracks (about 38 degrees shoulder / 26 elbow),
  so this is a projected guard-pose/readability issue rather than absent keys.
- Swimming at 2–45 seconds exposes conspicuous rear-rock travel and the sharp
  value difference between bright collision rock and the rear wall. Around
  48–53 seconds, crossing the surface produces little visible character change.
- The new simple rails are rejected. Use the approved painted stamp artwork,
  with independently placeable deck, rails, floats and supports.
- House focus around 69–71 and 90–94 seconds and cloud coverage are approved.
- The sky illustration ends in a dark horizontal void at high traversal heights
  around 79–86 and 100–104 seconds. Fix its coverage without changing the route.
- Up/down air attacks and special attacks need the same filled visual language.

Chase explicitly authorized an overnight level/feedback pass and choosing a
modular bridge approach. Routine commits/pushes remain authorized. Preserve
walking collision, damage/attack timing, input freedom, accepted idle/posture,
house focus and wind-only cloud treatment.

## Delivery sequence

1. Improve the run's readable sword-arm motion while retaining its gait.
2. Extend filled ivory/cool sweep/flax accents to directional air and specials.
3. Replace simple rails with modular parts drawn from approved stamp textures.
4. Test a screen-anchored far wall, submerged contact-rock grade, and a painted
   reflective water surface opening smoothly as the observer submerges. Repair
   high sky coverage. Keep this presentation adjustable for the next review.

## Run sword-arm delivery

The same upright run now gets a camera-plane arm adjustment synchronized to
its original cycle. Skeleton-local arm axes mainly twist the guard in depth;
the correction uses the skeleton-global side-camera depth axis so hand motion
reads on screen. The original local animation curves, stride and timing stay
intact. The adjustment clears on action changes and does not apply to blocking
or grappling. `run_sword_arm_motion = 0` restores the previous arm presentation.

Projected sword-hilt travel is now 34.74 world units horizontally, versus 14.99
previously (about 28.8 versus 12.4 screen pixels at zoom 0.83). Seventeen engine
checks pass, including source isolation, unchanged gait/action curves, sampler,
grapple handoff and return to the accepted idle. GPU poses and an enlarged loop:
[comparison](../../work/overnight-playtest-2026-10-30/run-arm-comparison.jpg) ·
[loop](../../work/overnight-playtest-2026-10-30/run-arm-loop.gif).
Existing shutdown resource diagnostics remain. Chase's moving review is pending.
Checkpoint: `e96de00a` — `art: give the upright run readable sword-arm motion`.

## Filled attack-family delivery

Vertical air attacks now use the same cool filled body, pale edge and sparse
flax accents as the accepted slashes. Their silhouette remains blade-directed:
up/down thrusts get a filled tapered cleave rather than a detached horizontal
arc. Spin uses filled sweeping ribbons; neutral uses a fast expanding filled
shock front; grapple burst/trail use the same palette and tapered fill.
`thread_vfx_palette.gd` centralizes the shared presentation. Original ground
slash colors/curves stay intact. No attack-controller or damage-resource edits.

Twenty-five GPU checks pass for both vertical directions/facings, blade alignment,
unchanged damage state, actual land/water special activation/cleanup and grapple
effect expiry. Existing six-check ground combo/confirmed-hit regression passes;
the underwater neutral/left-spin/right-spin regression also passes, including
animation, AP, steering, damage activation, medium changes and interruption.
[Effect-family poses](../../work/overnight-playtest-2026-10-30/vfx-family-review.jpg).
The grapple figure directly illustrates its effect resources; the other figures
use the production attack controller at manually sampled animation phases.
Checkpoint: `5786aac6` — `vfx: unify vertical and special attack presentation`.

## Modular bridge delivery

The rejected rails are replaced by separately reusable deck, painted rail,
float and brace scenes. The two existing bridge assemblies use these parts
without changing the room's nine walking surfaces. Source stamp textures are
sampled directly, preserving their painting. Thirty-two modular checks and the
78 existing room checks pass; all 148 world polygons match the prior baseline.
[Asset guide, provenance and room comparisons](modular_stamped_bridges_2026_10_30.md).
Checkpoint: `8ec09d82` — `art: build modular bridges from approved painted stamps`.

## Water and sky delivery

The Blue lake now opts into a presentation experiment: a nearly opaque painted
reflective surface when the character's head is above water, opening smoothly to
a translucent view as it goes below. The rendered head is projected through the
same 3D-to-2D transform as the character; a soft 26-unit crossing band and a short
temporal blend prevent a binary pop. Above-water pixels stay dry. Normal entry
still uses existing movement and animation behavior; no stop, launch, dive-input
requirement, camera cut or forced animation lock was added.

Broken horizontal strokes and a pale surface edge make the water plane visible.
The front pass covers player, enemies, solid rocks and the near facade consistently;
the legacy facade veil is omitted in this mode to avoid applying the grade twice.
Dry chambers reveal through the surface after submerging, and physical air-pocket
queries retain their original polygons. Solid submerged rock receives a light
spatial water grade, preserving brighter collision faces against the darker wall.

The 25-section far rock backdrop is now screen-anchored on both axes, rather than
scrolling at 50% horizontally / 75% vertically. Its existing deeper placement and
waterline haze remain. Timber and collision rock still move with the world. The
importer records the same configuration so a later art import keeps this change.
High jumps also get continuous sky beyond the finite far plate, using its sampled
top-row color. Approved cloud motion/density, houses, camera zoom and source PNGs
remain intact.

[Surface comparison](../../work/overnight-playtest-2026-10-30/water-surface-comparison.jpg) ·
[Reveal loop](../../work/overnight-playtest-2026-10-30/water-reveal-loop.gif) ·
[Depth comparison](../../work/overnight-playtest-2026-10-30/water-depth-comparison.jpg) ·
[Dry chamber](../../work/overnight-playtest-2026-10-30/water-pocket-comparison.jpg) ·
[High sky](../../work/overnight-playtest-2026-10-30/high-sky-coverage.jpg).
The water A/B uses the same current scene/backdrop, toggling the water treatment;
it is not a full before/after of every overnight edit. The loop moves the observer
through a fixed-camera fixture, not a recording of normal player input.

Validation: 20 new GPU pixel/transition checks, 10 legacy-water pixel checks,
31 tower/exterior checks (including real-room entrances), 20 house-handoff checks,
122 water-entry/grapple checks and 78 room/depth/bridge checks pass. The rear wall
has effectively zero screen displacement on both tested camera axes. A separate
capture audit confirms the rendered head drives the reveal and all 148 world
collision polygons exactly match the prior baseline. Test profiles are isolated
from Chase's saves. Existing enemy-packing, camera interpolation and shutdown
resource diagnostics remain; logs are not error-free. Long comparison captures
use stage render scale 1.0 for GPU memory. A fresh two-view GPU smoke test at the
normal 2.0 setting also passes: [full-quality comparison](../../work/overnight-playtest-2026-10-30/water-full-quality-review.jpg).
This is a short render check, not a long-session performance test.

Tune `Volumes/Lake.painted_surface` to compare the old/new water live;
`surface_opacity` (0.96), `immersion_opacity` (0.22), and
`submerge_transition_seconds` (0.30) control the experiment. The eye offset is a
fallback for non-rigged observers. Outside opacity intentionally conceals most
underwater enemies, and screen-space reflection can only use visible source art.
The static wall and reflection/reveal style still need Chase's moving review.
Checkpoint: `3596f404` — `art: reveal the underwater scene through a painted lake surface`.

## Water-entry recommendation

Ordinary running/jumping into water should remain immediate and controllable.
Use a brief visual crossing transition—surface splash/ripple, stronger wet/dry
separation, and a smooth change of water treatment—to announce the underwater
space. Keep the existing full bank dive optional. Do not force a standing
anticipation or freeze movement to play the complete 1.23-second dive clip.
A short airborne portion can be tested as a visual overlay if it reads well;
movement, collision and control remain authoritative.
