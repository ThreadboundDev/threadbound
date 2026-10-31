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
Checkpoint: `art: give the upright run readable sword-arm motion`.

## Water-entry recommendation

Ordinary running/jumping into water should remain immediate and controllable.
Use a brief visual crossing transition—surface splash/ripple, stronger wet/dry
separation, and a smooth change of water treatment—to announce the underwater
space. Keep the existing full bank dive optional. Do not force a standing
anticipation or freeze movement to play the complete 1.23-second dive clip.
A short airborne portion can be tested as a visual overlay if it reads well;
movement, collision and control remain authoritative.
