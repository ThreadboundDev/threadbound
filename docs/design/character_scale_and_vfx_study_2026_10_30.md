# Character scale and attack VFX — October 30, 2026

Chase's new order is **character scale first, VFX second**. Combo flow/manual
animation, environment cohesion, outlined enemies and Threadbound identity remain
important follow-ups. Full 3D remains parked. This delivers measurements and an
original, isolated VFX prototype. In the follow-up, Chase said the new VFX look
great and substantially better than the current effects. Carry the filled-sweep
appearance forward as his preferred direction; live integration remains pending.

## What the measurements say

The 2D character is somewhat larger on screen than the sampled Belmont character,
especially in the demo. Blue is already close to the upper end of those samples.
The preserved 3D trial uses much closer perspective framing. None of these
measurements supports shrinking every production asset or rebuilding the map.

| View / sampled pose | Visible body height | Portion of screen height |
| --- | ---: | ---: |
| Threadbound demo, zoom 1.00, idle at 0.20s | 172.5 / 1080 px | 15.97% |
| Threadbound Blue, zoom 0.90, same idle | 155.25 / 1080 px | 14.37% |
| Threadbound Blue, run at 0.20s | 148.50 / 1080 px | 13.75% |
| Runtime preview, zoom 0.83, current idle | 143.18 / 1080 px | 13.26% |
| Belmont, Paris gameplay sample | 66 +/- 4 / 540 px | 12.22% |
| Belmont, Fallen arena sample | 71 +/- 4 / 540 px | 13.15% |
| Belmont, cemetery sample | 75 +/- 5 / 540 px | 13.89% |
| Belmont, library sample | 68 +/- 4 / 540 px | 12.59% |
| Preserved Loom Crossing 3D trial, spawn | 250 / 900 px | 27.78% |

[Camera comparison](../../work/scale-vfx-study-2026-10-30/camera-comparison.jpg).
The zoom-0.83 image is a runtime preview, not a saved camera edit. Belmont samples
are from the [BeardBear walkthrough](https://www.youtube.com/watch?v=q3NuImErog8),
including the [library at about 3:19:55](https://www.youtube.com/watch?v=q3NuImErog8&t=11995s).
They are four selected poses, not a full-game average or identical standing poses.
See the [earlier source study](belmonts_curse_reference_study_2026_10_30.md) for
timestamps, uncertainty, dialogue zooms and sampling limits.

**Resolution clarification:** 540 is the height of the resized 960 x 540 analysis
frames. The walkthrough stream used was 1280 x 720. Neither measurement establishes
Castlevania's internal game viewport or rendering resolution. A 68-pixel character
in a 540-pixel-high image and a 136-pixel character in a 1080-pixel-high image both
occupy 12.59% of screen height. Matching that proportion does not require changing
Threadbound's 1920 x 1080 base viewport to 540p.

Method: render the actual shared player through its live transparent 3D viewport;
temporarily hide equipment meshes on the runtime instance to measure just the
clothed character's alpha bounds. Multiply its 345-pixel idle span by the existing
0.5 display scale, then the actual Camera2D zoom. The run sample spans 330 source
pixels. Outlines/antialiasing can add a few display pixels. These are sampled
poses, not extrema across every animation. Full-scene GPU captures verify demo
zoom 1 and Blue zoom 0.9 at the project's 1920 x 1080 viewport. The demo's welcome
is dismissed and tutorial dimming hidden only inside the capture instance.

The 3D figure uses the preserved trial's authored spawn camera (62-degree FOV,
5.4-unit spring arm), with a separate transparent body render at that camera's
transform. Its body rest AABB is approximately 1.80 units tall; its collider is
1.90. The workshop is 4.45 units tall, about 2.47 rest-body heights. Perspective,
the near player and more distant scenery make it read larger on screen. This
checks the current preserved trial's spawn, not every earlier 3D revision or
every camera position. It does not establish that all imported props are correct.

## Posture contributes separately

[Equal-height posture comparison](../../work/scale-vfx-study-2026-10-30/posture-comparison.jpg).

The idle silhouette is 136.5 world units wide and 172.5 high (width/height 0.79),
excluding sword/shield. Its broad stance, bent knees, forward head angle and wide
trousers/coat give it more visual mass. Simply reducing scale keeps that shape.
The run sample is wider still; different poses should not be used as anatomy
measurements against Rose.

Resetting the same skeleton to its rig rest pose produces a 193.5-world-unit
vertical silhouette. Idle is about 10.9% shorter than that rest reference; the
rest reference is about 12.2% taller than idle. The model can already present a
straighter silhouette. That rest pose is not an animation proposal: its arms and
equipment presentation are unsuitable for shipping as idle.

Recommended manual pose study: bring the feet closer, reduce constant knee flexion,
align the head more comfortably over the torso, and reserve deeper compression
for anticipation/landing/guard. Keep the mask, clothing, model detail and equipment
identity. Judge this with sword and shield equipped. No mesh/anatomy alteration
is selected. A more upright pose increases visible height, so measure it before
locking the camera: zoom 0.83 gives 13.26% for today's idle but about 14.87% for
the rest-height silhouette. A 13% target at rest height would need roughly 0.726.

The existing 2D movement capsule is about 126.245 units tall, while the current
clothed idle is 172.5. They already differ. Do not resize collision, jump/grapple
distances or equipment sockets as a side effect of a visual composition test.

## Buildings and asset size

[Building and 3D-trial context](../../work/scale-vfx-study-2026-10-30/environment-scale.jpg).

The current Blue fisher house bounds are about 745 x 835 world units, or **4.84
idle-body heights tall**. Its manually read outer door-frame assembly is
approximately 254 +/- 8 screen pixels high at zoom 0.9, versus the player's
155.25: about 1.64 body heights. That includes the lintel/threshold, not just the
clear opening. The separate procedural entry overlay declares a 218-unit opening
(1.26 body heights). These measure different presentation features; neither is
a collision-clearance audit. Use clear openings consistently when setting a
future human-scale prop reference.

This house does not make the 2D character nearly building-height. The 3D trial's
smaller workshop and near-camera composition are a different visual reference.
Room dimensions also follow traversal speed, jump/grapple reach and encounter
spacing, not just the model's apparent size. A global world resize would disturb
those relationships without necessarily changing the screen ratio.

At zoom 0.83, this 745 x 835 house occupies about **618 x 693 screen pixels** at
1080p. An adequately cropped 1024–1536-pixel source can cover that example; the
export size should follow visible bounds and the closest intended camera, with
filtering/zoom margin. There is no requirement to generate one enormous image
for an entire room. Modular foreground pieces and separate background layers
remain useful. This is a sizing illustration, not approval to replace the house
or select a new asset workflow.

For the current idle, a **runtime camera A/B at 0.83** is a sensible first trial:
2313 x 1301 visible world units, versus Blue's 2133 x 1200. That shows 8.4% more
world in each direction (about 17.6% more area), so a pullback exposes more art;
it does not automatically solve cohesion or reduce coverage work. From demo zoom
1.0 the width increase is 20.5%. Review room edges, HUD, threats, tall movement,
foreground occlusion and indoor camera behavior before saving any new default.

## Original VFX delivered

Start with the [normal-speed combo comparison GIF](../../work/scale-vfx-study-2026-10-30/combo-comparison.gif).
Then inspect [matched stills](../../work/scale-vfx-study-2026-10-30/vfx-comparison.jpg),
[left-facing samples](../../work/scale-vfx-study-2026-10-30/vfx-left-facing.jpg) and
the [full-screen gameplay-scale view](../../work/scale-vfx-study-2026-10-30/vfx-gameplay-scale.jpg).

The review stage runs the **unchanged production three-strike combo** through
the existing public attack/queue API. Current thin strokes appear beside a new
procedural filled sweep. The new effect takes animated world-space blade points,
uses a tapered curved surface rather than three parallel lines, adds a bright
ivory edge and two sparse flax-colored fibers, and extends the blade-led gesture
by 14%. The physical sword mesh stays the same size. Catmull interpolation smooths
the sampled curve; explicit nondegenerate triangles handle projected reversals.
History expires after 75ms and clears across strikes or large discontinuities.

A separate 130ms contact burst uses a short pale center and seven sparse rays.
Its events are **illustrative**, triggered by phase in this empty review stage.
They are not successful hits, damage feedback or proof of combat feel. In a live
pass, ordinary swings should show only the sweep; contact bursts must follow
accepted contact/guard events, with distinct blocked/parried responses as needed.
The existing `HitboxComponent.hit_landed` signal is a useful accepted-contact hook;
it also covers some ignored-health contacts, so health loss must not be inferred
from that signal alone.

The visual principles come from the studied Castlevania footage: a readable
filled gesture, a concentrated bright contact, fast clearance and minimal
lingering clutter. Shapes, code and thread accents here are original. No Belmont,
Hollow Knight or Silksong sprites, textures or proprietary code are imported.
This does not claim those games use this rendering implementation.

## The reach mismatch needs a separate decision

[Existing damage-sector overlay](../../work/scale-vfx-study-2026-10-30/existing-hitbox-overlay.jpg).

The current grounded attack already uses a **205-unit radius / 130-degree sector**.
Its damage area is substantially broader than the thin sword traces. The new
filled surface improves the gesture but still does not communicate that entire
area. Covering the whole sector with a persistent white fan would obscure the
character and enemy tells. Nor should a cosmetic effect be assumed to grant
damage wherever a faint fiber or tail passes.

The eventual live pass should compare the **time-varying** sword/VFX sweep,
damaging region and enemy contact together. Select a readable attack envelope,
then make collision and presentation agree over the attack. Do not grow hitboxes
again merely to match an oversized effect. The finisher particularly needs its
own ground-contact shape and timing review: the existing smear window begins
around source frame 71, while damage starts at 79. It should not be judged as
just the first swing rotated downward. This prototype preserves those timings.

This study cannot establish combo responsiveness, hitstun, armor fairness, impact
sound, real-time hit pause or movement cancels. Those need the short enemy combat
comparison already proposed in the reference study, after scale and visual shape
are selected. VFX will clarify the attack; it will not repair every animation or
enemy-reaction problem by itself.

## Proposed next bounded passes

These are review scopes, not changes made in this checkpoint. Follow the root
AGENTS approval requirements before production replacements or combat changes.

1. **Camera A/B with the current pose.** Candidate files: the existing Camera2D
   settings in `Src/Environment/World/Chamber Of The First Weave.tscn` and
   `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`,
   plus the work list/test card. Try the pullback in a few representative rooms;
   do not restructure scenes or change movement/collisions. Keep it provisional
   until the manual idle pose is selected.
2. **Manual idle/attack poses.** Select the editable rig source with Chase before
   listing its implementation files. Preserve equipment fit and strong readable
   poses. The rest-pose comparison demonstrates the issue; it is not an approved
   source-asset replacement.
3. **Selected sweep into live presentation.** Likely narrow scope:
   `Src/VFX/sword_sweep_vfx.gd` for the selected fill and per-strike shapes,
   `Src/Characters/Player/player_live_3d_visual.gd` for accepted-contact binding,
   and the work list/test card. Preserve other actions until each is reviewed.
   No damage, queue, movement, armor, stun or hit-pause changes in that visual
   pass. If the chosen design requires a new source asset or more files, scope
   them explicitly before editing. The reviewed code is in
   `work/scale-vfx-study-2026-10-30/thread_sweep.gd`.

## Verification and checkpoint

All new code is under the ignored-by-Godot review directory; there are no edits
to `Src/`, `Assets/`, production scenes or the preserved 3D project's sources.
Full-scene production GPU captures, body-only pose captures, the 3D camera sample,
three-strike VFX captures in both facings and a gameplay-scale capture ran.
Baseline/candidate pairs have identical source animation times, blade points,
damage polygons and activation states across 104 frames at 60fps. Actual facing
values are checked, not just filenames. The GIF presents every third source frame
at 20fps and normal speed. Captures/figures were visually inspected.

The [measurement data](../../work/scale-vfx-study-2026-10-30/measurements.json),
[validation report](../../work/scale-vfx-study-2026-10-30/validation.json) and
[reproduction helper](../../work/scale-vfx-study-2026-10-30/README.md) are versioned.
Raw frames/logs stay in ignored task scratch. Fixtures redirect Godot user data,
preserving normal saves/preferences. The normal project still logs texture/RID
and ObjectDB shutdown leaks in the baseline; these are not a clean-engine-log
claim. Earlier capture-fixture startup/triangulation mistakes were corrected
before the final captures. No game implementation fix is claimed for them.

Checkpoint: `vfx: add character scale audit and isolated sweep study` on
`threadbound/vfx-scale-and-impact-study`. T35 diagnosis is delivered; T36 first
prototype has positive appearance feedback. Live changes and T33/T20 acceptance
remain pending. Feedback/clarification checkpoint:
`docs: record sweep preference and clarify reference resolution` on the same branch.
Validation: measurement/source metadata, local viewport settings and staged diff
review. This follow-up changes documentation only.
