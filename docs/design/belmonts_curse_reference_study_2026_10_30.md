# Belmont's Curse / Dead Cells reference study

October 30, 2026. Threadbound baseline: `dac26f02`.
**Research delivered; all implementation suggestions remain proposals.**

## Findings to use first

Threadbound's next combat target should be **a connected encounter**, with readable
entry, contact, reaction and exit. Fast individual attacks alone do not establish
that connection. The art target is a deliberate hierarchy of silhouettes,
planes, landmarks and bright action accents. A larger asset inventory or more
particles will not establish that hierarchy by itself.

Three useful starting points from this study:

1. Keep the live 3D player and 2D movement. Audit transitions between current
   actions before adding weapons or importing another controller.
2. Establish one blade-attached, clearly shaped contact effect and one enemy's
   consistent response at the actual gameplay camera.
3. Compose one Blue view using different apparent depths and recognizable woven
   construction. Match the demo's visual grammar while keeping Blue outdoors.

The full study below separates **observations**, **measurements**, **developer
statements**, **public mod code** and **Threadbound proposals**. None is a claim
that we have the commercial game's original combat source or production files.

## 1. Evidence and coverage

KONAMI's [official game page](https://www.konami.com/games/castlevania/belmonts_curse/eu/en/)
lists release on October 15, 2026 and credits Evil Empire as development studio
with Motion Twin advising. It presents the whip as a shared combat/traversal
tool and identifies seven weapon categories. This is a released-game study,
with an additional pre-release trailer reference.

### Footage actually inspected

Primary long-form reference: BeardBear's
[100% walkthrough](https://www.youtube.com/watch?v=q3NuImErog8), uploaded October
17; retrieved player metadata gives 33,734 seconds, approximately 9 h 22 m.
The title's 100% claim belongs to the creator. This study does not independently
verify completion or inspect the whole recording.

| Recording window | Main reason for selection |
| --- | --- |
| [06:05–11:05](https://www.youtube.com/watch?v=q3NuImErog8&t=365s) | Opening camera, common enemies, tutorial movement, first save-room approach |
| [15:00–20:00](https://www.youtube.com/watch?v=q3NuImErog8&t=900s) | Boss spacing, reward/dialogue zoom, first whip traversal |
| [55:39–1:00:39](https://www.youtube.com/watch?v=q3NuImErog8&t=3339s) | Exterior depth, save room, interior contrast, ordinary encounters |
| [1:33:00–1:38:00](https://www.youtube.com/watch?v=q3NuImErog8&t=5580s) | Tight routes, hazards, mixed attacks, room fades |
| [3:16:00–3:21:00](https://www.youtube.com/watch?v=q3NuImErog8&t=11760s) | Large landmarks, vertical framing, multiple combat elevations |
| [4:40:00–4:45:00](https://www.youtube.com/watch?v=q3NuImErog8&t=16800s) | Story/camera handoff toward Notre-Dame; predominantly dialogue |
| [4:46:00–4:49:00](https://www.youtube.com/watch?v=q3NuImErog8&t=17160s) | Additional Notre-Dame navigation/encounters after the dialogue-heavy window |
| [6:50:00–6:55:00](https://www.youtube.com/watch?v=q3NuImErog8&t=24600s) | Mirror fast travel, later-room framing, heavier opponents |

These windows cover **38 minutes of recording**, reviewed as **456 sequential
frames at five-second intervals**. This is frame-sampled visual analysis, not
38 minutes of continuous real-time watching. Dialogue, menus and travel are
included. Source chapter labels do not always coincide with the currently
visible region; the 4:40 window includes a Main Hall story handoff.

The full 98-second KONAMI
[Gameplay & Commentary trailer](https://www.youtube.com/watch?v=h82FdvzU5pI)
was also inspected in two-second frame steps. Detailed sequences used:

- Walkthrough around 07:30–07:42: six samples/second for movement into attacks.
- Walkthrough around 07:00.5–07:01: two samples/second for parallax comparison.
- Walkthrough 57:15–57:45 and 1:33:16–1:33:28: one sample/second around transitions.
- Official trailer 00:07–00:09: 30 samples/second from its 1080p60 stream.
- Official trailer 00:29–00:33: six samples/second for whip attachment/release.
- The opening five-minute local excerpt: an automated five-samples/second
  near-black-frame scan, followed by selected before/after image inspection.

Broad-frame timestamps are approximate within half their sampling interval
(up to 2.5 seconds); fine samples have proportionately smaller uncertainty.
Frames were extracted using FFmpeg, with Pillow/NumPy for figures and a small
template-matching measurement. No listening analysis, hands-on play, input
latency test, complete map survey or original asset inspection was performed.
The browser tool reported disabled access; public video streams were retrieved
directly instead. No settings were changed.

[Machine-readable measurements and limitations](../../work/belmont-study-2026-10-30/measurements.json).
Raw recordings and bulk review frames remain in ignored `tmp/belmont-study`;
only five attributed analytical figures are checkpointed, outside runtime imports.

## 2. Traversal and combat: where the flow comes from

### Observed sequence

In the opening common-enemy sequence around 07:30–07:42, Rose slides past an
opponent, attacks, jumps across a projectile's line, lands into another strike,
casts, and moves toward the next opponent. Her screen position changes through
the exchange. The first boss sequence supplies a contrasting scale of threat
and space. These observations describe the recording, not the inputs or cancel
permissions that produced it. [Walkthrough reference](https://www.youtube.com/watch?v=q3NuImErog8&t=450s).

The official trailer around 00:30–00:32 visibly connects a lit anchor, a thin
tether, a pendulum arc and release into further travel. Around 00:08.5–00:08.8,
a bright hit expands and clears while the next pose becomes visible. The trailer
is edited; cuts are not evidence of seamless room traversal.
[Official footage](https://www.youtube.com/watch?v=h82FdvzU5pI&t=30s).

![Four stages of whip traversal](../../work/belmont-study-2026-10-30/whip-traversal.jpg)

### Developer-supported interpretation

In a [direct developer interview](https://darylbaxter.com/posts/castlevania-belmonts-curse-impressions-interview/),
the team describes connecting the whip to combat, traversal and exploration.
They connect strong color choices with readability during rapid movement and
identify classic Castlevania imagery and Italian horror as visual influences.
This supports the design intention; it does not establish engine internals.

For Threadbound, the useful lesson is to connect **where an action leaves the
player** with the next available decision. A strike that feels good alone can
still leave a bad distance, a dead recovery, an unreadable threat or a forced
return to idle. Those failures break flow independently of attack speed.

### Proposed combat audit

Use a single ordinary encounter, retaining current gear and opponents. Record
these moments in an input-overlay capture:

| Moment | What to record | What would indicate a problem |
| --- | --- | --- |
| Entry | Position, facing, speed, target distance | Player must stop and restart before engaging |
| First strike | Input, anticipation, first active frame, first contact | Input disappears or animation and damage disagree |
| Contact | Body/blade pose, flash, sound event, hit pause | All signals peak at different moments |
| Enemy reaction | Displacement and time before next decision | Next attack misses because every hit pushes the enemy away |
| Continuation | Early/late next-attack press and expiry | A stale press causes an unwanted extra attack |
| Exit | Dash, jump, turn and grapple attempts | Useful movement is blocked without a readable reason |
| Next threat | Its tell and available space | The only practical answer is holding/tapping attack repeatedly |

Test tap-stop, tap-chain, attack-then-dash, attack-then-jump, reversal, and
grapple entry separately before combining them. Test a miss as well as a hit:
hit pause changes the experienced spacing between actions. Judge at normal
speed first, then use frame stepping to locate the cause.

One small enemy dying to a successful combo is acceptable. Pressure can come
from positioning and a second readable threat. Heavier resistance should have
an identifiable action/pose and still acknowledge damage. This is a proposal
for Threadbound, not a claim that Belmont's Curse uses a particular armor rule.

Do not add universal anti-combo armor, permanent builds, a stamina system or
mandatory weapon counters to imitate the reference. Threadbound's free equipment
expression and optional precision-platforming direction remain the constraints.

## 3. VFX: shapes, timing and visual priority

![Contact effect sampled around the strike](../../work/belmont-study-2026-10-30/impact-sequence.jpg)

The official trailer's selected contact contains a curved attack shape, an
intense central burst, thin directional rays and a rapidly clearing residue.
In the sampled sequence, the largest contact brightness lasts on the order of
a tenth of a second, with residue extending beyond it. This is a visual duration
estimate at 30 Hz, not a measured hitstop, damage window or input response.
Persistent defensive/spell rings earlier in the sequence are different effects.
[Sequence to replay](https://www.youtube.com/watch?v=h82FdvzU5pI&t=8s).

### A practical Threadbound effect breakdown — proposed recipe

| Element | Job | How to author a small test |
| --- | --- | --- |
| Anticipation | Establish direction before the strike | One readable shoulder/weapon pose; restrained local accent |
| Attack smear | Explain the fast blade path | Tapered filled ribbon sampled from the actual hilt/tip path |
| Contact core | Mark the exact successful hit | Short white/ivory star or slash anchored at contact |
| Directional fragments | Explain force and material | A few stretched thread fibers aligned with the blow |
| Receiver reaction | Confirm target weight | Pose compression/recoil independent of physical travel |
| Physical displacement | Change combat spacing deliberately | Small common-hit push; stronger finisher only when useful |
| Camera/audio | Reinforce the same event | Small directional response and synchronized contact sound |
| Decay | Reveal the next decision | Fast reduction of filled area; a few longer thin fibers |

For a **future A/B**, start with an impact core visible roughly 50–90 ms, a
smear/fragment tail around 100–180 ms, and compare ordinary-hit pauses around
35–50 ms against the existing effective pause. These are test hypotheses,
not extracted Belmont values or approved tuning. Keep a stronger finisher
distinct rather than making every basic hit equally dramatic.

Construct the broad shape with an opaque/alpha-blended body and a restrained
bright inner edge. Use additive glow as support. An entirely additive cloud
can disappear over a bright lake; a dark seam or contrast edge may be needed.
Short hand-authored flipbooks, a polygon ribbon or a shader mask can all serve
this job. Choose the simplest method that stays attached to the actual blade.

The main effect should be readable as one shape at normal zoom. Do not replace
that shape with hundreds of small particles. Keep the player's outline, the
next enemy tell and the landing edge visible during the brightest frame.
Reserve Threadbound's strongest thread accent for an event with meaning;
preserve its existing equipment color language.

### Why the Dead Cells animation pipeline matters even without pixel art

In his [first-person production article](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-),
artist Thomas Vasseur describes modeling/rigging in 3D, authoring strong timed
poses, rendering frames plus normal maps, and using effects to convey the
fast movement between poses. Retiming the rig made iteration economical.

For Threadbound, keep the useful pose/timing workflow while retaining the
desired non-pixel rendering. A smoothly interpolated rig still needs decisive
contact poses. Rendering sprites from a rig is an available enemy-production
method; it does not automatically solve outline stability, registration or
weapon reach. The article documents Dead Cells, not Belmont's Curse's pipeline.

## 4. Camera framing: measured image scale

![Four gameplay scales compared with two dialogue scales](../../work/belmont-study-2026-10-30/camera-scale.jpg)

Manual boxes use hair/head to planted foot, excluding extended weapon and cloth
where practical. The poses are not identical upright calibration poses. Treat
the values as apparent body spans with the listed uncertainty. Every measured
image was 960 × 540, downsampled from the same 16:9 recording; percentages use
the **whole video frame**, not a guessed internal viewport or cropped letterbox.

| Sample, approximate timestamp | Visible body span | Fraction of frame height | Frame width / body span |
| --- | ---: | ---: | ---: |
| Paris gameplay, 07:32 | 66 ± 4 px | 12.2% | 14.5 |
| The Fallen gameplay, 15:15 | 71 ± 4 px | 13.1% | 13.5 |
| Cemetery gameplay, 56:29 | 75 ± 5 px | 13.9% | 12.8 |
| Library gameplay, 3:19:55 | 68 ± 4 px | 12.6% | 14.1 |
| Paris dialogue, 06:25 | 122 ± 4 px | 22.6% | 7.9 |
| Library dialogue, 3:18:50 | 103 ± 4 px | 19.1% | 9.3 |

The useful ordinary-gameplay starting range is **approximately 12–14% of frame
height**, based on these four selected poses, not a game-wide mean. Dialogue
images would suggest a materially closer camera. Internal engine units and an
exact universal zoom cannot be recovered from these images.

### Translating that into Godot

Let `H` be Threadborne's measured visible standing height in world units, `r`
the desired on-screen fraction, and the viewport be the project's 1920 × 1080:

```text
visible world height = H / r
visible world width  = (1920 / 1080) × H / r
Camera2D zoom        = 1080 × r / H
```

These relations assume uniform zoom and ordinary world/canvas scale. Godot's
[Camera2D documentation](https://docs.godotengine.org/en/stable/classes/class_camera2d.html)
also distinguishes the actual screen center from node position when smoothing
or limits apply. Measure the final rendered camera, not only its inspector.

Using **168 world units only as an illustration** from our older art guide:

| Desired body height | Visible world width × height | Uniform zoom |
| --- | ---: | ---: |
| 12% | 2489 × 1400 | 0.771 |
| 13% | 2297 × 1292 | 0.836 |
| 14% | 2133 × 1200 | 0.900 |

The Blue playtest scene already sets its normal camera to `0.9`; the `0.17`
preview is a separate diagnostic view. If the live player's actual standing
height is near that illustration, Blue is already near the measured range.
**Do not zoom everything out by assumption.** Capture the current character
first; the live model's fitted render scale may differ from the old guide.

For composition, protect space in the direction of travel and enough vertical
visibility to understand the landing or grapple destination. Let major rooms
have a composed reveal and bounded encounters have stable framing. Threadbound's
demo camera already has dead zones, movement/dash look-ahead and fall framing.
Review that behavior before building a new camera system.

## 5. Backdrops and art construction

![Distinct regions retain a consistent rendering language](../../work/belmont-study-2026-10-30/regional-composition.jpg)

### What the pictures establish, and what they cannot

The inspected views support analysis of the finished image: dark solid masses,
distinct contact edges, large architectural silhouettes, local lights, colored
distance and sharply prioritized action accents. They do not identify whether
a particular backdrop began as a painting, a rendered model, a layered composite
or an engine-lit surface. No public production breakdown sufficient to establish
Belmont's full environment/parallax authoring pipeline was found in this search.

The developer interview above confirms the intention behind vivid colors and
readability. Any layer counts, shader recipes and paint workflow below are
**ways we can achieve comparable visual functions**, not statements of how
Evil Empire authored each asset.

### Composition rules to apply to one Blue view

- Give the view one large organizing silhouette: a workshop loom/frame, a tied
  support span, a distant tower or the dry waterfall. Small props support it.
- Separate the terrain's readable contact edge from its quiet interior mass.
  Filling every solid area with equally sharp rock/wood detail fights the actors.
- Use foreground shapes at the outer frame and transitions between spaces.
  Keep them off the next required landing and enemy tell.
- Preserve a middle depth with useful scale cues: another dock, a house behind
  the route, suspended fabric and the lake shore beyond it.
- Compress distant values and detail while retaining distinct silhouettes.
  A blue tint over all layers cannot substitute for this separation.
- Place light where it establishes a material, destination or occupancy.
  Keep some shadow between local pools. Bright effects need a quieter surround.
- Repeat a construction vocabulary across regions; vary local shape, palette
  and landmarks. The Chamber and Blue should share edge/value discipline while
  retaining different geography and atmosphere.

For Threadbound specifically, cord bindings should carry loads, interlacing
should join structural pieces, and woven frames should belong to workspaces.
Pair these with established still-water evidence: inactive wheels, boats,
dry channels and the dry waterfall. Preserve human villagers and native wildlife;
not every object or creature needs to become a woven construct. These are visual
proposals using existing direction, not new lore about who built the village.

### Measured parallax example

![The same three tracked features during a short camera pan](../../work/belmont-study-2026-10-30/parallax-motion.jpg)

Around walkthrough 07:00.5–07:01, template matching in the 960 × 540 frames
found these approximate horizontal shifts:

| Tracked feature | Shift | Relative to gameplay plane | Correlation |
| --- | ---: | ---: | ---: |
| Gameplay-plane door detail | −120 px | 1.00 | 0.84 |
| Distant gate detail | −73 px | 0.61 | 0.86 |
| Foreground post | −149 px | 1.24 | 0.98 |

The boxed matches were visually checked. A single half-second pair establishes
different apparent motion in this view; it does not extract global parallax
settings. Small camera/vertical changes, compression and feature choice limit
precision. Do not treat the displayed ratios as exact production constants.

### Proposed Blue layer stack

Godot's [Parallax2D guide](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html)
documents `scroll_scale`: below one produces slower apparent scrolling and
above one faster scrolling. Threadbound already has anchored parallax helpers;
retain their authoring alignment if a later approved study uses them.

| Function | Starting horizontal scroll scale to audition | Art treatment |
| --- | ---: | --- |
| Sky / remote atmospheric field | 0.00–0.08 | Broad, quiet, complete coverage |
| Far cliffs / waterfall landmark | 0.10–0.25 | Large low-detail silhouettes |
| Distant village / shore | 0.30–0.45 | Grouped roofs and a few recognizable forms |
| Rear structures near the route | 0.55–0.75 | Clearer material, less contrast than actors |
| Playable structures / contact edges | 1.00 | Sharpest navigation information |
| Sparse foreground framing | 1.10–1.25 | Dark overlap; avoid required action space |

These are **our audition ranges**, not six confirmed Belmont layers. A layer
can contain many pieces. Avoid six full-resolution opaque paintings stacked
over each other. Use genuine cutouts for nearer planes and keep Blue's far
outdoor atmosphere light. Existing horizontal-only repetition rules still apply.

For a nonrepeating background, estimate required coverage before painting:

```text
background coverage width >= visible world width + scroll_scale × camera travel
```

At Blue's illustrative 2133-unit visible width, a 4779-unit camera travel needs
about 3089 units of art at scale 0.2, or 5000 at scale 0.6, before safety margins.
These are world-space coverage estimates; texture pixels also depend on export
density and node scale. Test both horizontal and vertical extremes. A seamless
repeat requires appropriate tile size/positioning; a unique landmark should
not visibly repeat simply to fill the canvas.

### Practical authoring order

1. Capture the actual gameplay camera with player and one existing enemy.
2. Sketch the large masses and route in three values at that scale.
3. Place one identity-defining landmark and preserve the action silhouette.
4. Divide the composition into independently moving planes, including edge
   overlap and coverage margins.
5. Use the current model/stamp library for construction; paint over joins and
   remove conflicting baked light before adding restrained scene lighting.
6. Preview a horizontal pan, vertical traversal and the brightest attack.
7. Review in grayscale and color, with and without the character. Only then
   refine small surface detail or create a larger prop family.

## 6. Screens, rooms, transitions and region length

### Terms matter

A **screen** is the current camera footprint. A **room** is a navigable space
with its own bounds/entrances. A **region** contains many rooms and revisits.
A **composition beat** can change within a continuous room. A **fade** in a
recording cannot establish whether the engine unloaded a scene or streamed data.

### Observed transition evidence

The opening excerpt's dark-frame candidates were checked against neighboring
images. Approximate full/dark central portions include:

| Around source time | Approximate dark central portion | Before / after |
| --- | ---: | --- |
| 06:22 | 1.2 s | Opening street passage → sewer interior |
| 07:52 | 1.6 s | Sewer climb → Outskirts |
| 08:04 | 1.4 s | Outskirts connector → Ruined Market |
| 10:03 | 1.4 s | Village route → Crystal Skull Chasm |
| 10:35 | 2.2 s | Chasm route → Mirror of Life room |
| 10:58 | 1.2 s | Mirror room → Sewer Reservoir |

The scan samples at 5 Hz and uses a central near-black threshold; timings are
approximate, with no claim about loading duration. An additional dark moment
around 09:33 belongs to the clue/card interface and is excluded. Adjacent
transition starts in this small sample are roughly 12–119 seconds apart,
including dialogue, menus and tutorials. This variability is the result;
there is no support here for a universal transition-every-N-seconds rule.

At [57:21–57:39](https://www.youtube.com/watch?v=q3NuImErog8&t=3441s), the player
enters a Mirror room, saves, opens a map and leaves through another boundary.
At [6:50:20–6:50:35](https://www.youtube.com/watch?v=q3NuImErog8&t=24620s), a
mirror interaction is followed by a travel/loading presentation and another
mirror room. These have different pacing functions from an ordinary doorway.

The walkthrough's first Paris chapter spans approximately 49.5 minutes before
its Cemetery chapter. That includes discovery, encounters, menus and story;
it is not a region-width measurement or a target for Threadbound.

### Starting room metrics for Threadbound — proposals, not copied dimensions

At a 13%-height character, one 16:9 screen is about **13.7 body heights wide**.
Design in that relative unit before deciding texture sizes or world coordinates.

| Space to audition | Initial footprint | Why |
| --- | --- | --- |
| Small encounter space | 1.2–1.8 screens wide | Room to enter, reposition and exit without chasing targets off-camera |
| Ordinary exploration room | 1.5–3 screens wide | A few connected compositions and one understandable local decision |
| Landmark approach | 3–5 screens along a route | Reveal, approach and arrival with visible changes in purpose |
| Tall room | Define visible landing/anchor groups first | Width alone says little about travel or camera burden |

Using the illustrative 2297-unit screen above, an ordinary room would be about
3446–6891 units wide. These are initial study envelopes, not production mandates.
Blue's current camera limits span 6912 horizontal units—only about 3.24 of its
0.9-zoom screens—so raw width alone does not explain its lack of cohesion.
Camera limits are not a complete map/collision measurement.

For a later route test, audition a meaningful change every roughly 20–45 seconds
of **active play**: encounter, overlook, discovery, shortcut or room boundary.
Do not require a fade for each change. A flat screen crossing can take only a
few seconds; combat and vertical travel change the duration substantially.
Time real runs rather than calculating level length from background-image width.

Keep Threadbound's main route forgiving. The sampled reference has substantial
spikes, saws and grapple precision; those should not become our mandatory
traversal standard. Put harder chains on optional routes with useful recovery.

## 7. Public code: what is actually available

No official complete Belmont's Curse or Dead Cells gameplay source was located
in this scoped search. Useful public material exists, but its provenance and
purpose differ. No mod binaries were installed and no commercial game files
were extracted.

### Best first code reference: deepnight/gamefeel

[Repository](https://github.com/deepnight/gamefeel), inspected revision
`09d24aa05abe1192ad07cd3acd7270e6a5842237`, MIT license. The developer's
[playable explanation](https://deepnight.net/games/game-feel/) explicitly
presents it as a toggleable teaching demonstration. It is not the Dead Cells
combat source.

| File at inspected revision | Specific thing to study |
| --- | --- |
| [Hero.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/en/Hero.hx) | `ControllerQueue`, consumption of buffered actions, coyote jump, small-step/cliff helpers and action-specific locks |
| [Entity.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/Entity.hx) | Separate base and bump velocities, presentation offsets, scaled/unscaled cooldowns |
| [Mob.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/en/Mob.hx) | Stronger first physical impact, reduced repeated bump, squash and flash handled separately |
| [Fx.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/Fx.hx) | Separate normal/additive particle batches; contact, dust, light, jump and dash functions |
| [Game.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/Game.hx) | Real-time slow-motion bookkeeping and a short stop-frame facility |
| [Options.hx](https://github.com/deepnight/gamefeel/blob/09d24aa05abe1192ad07cd3acd7270e6a5842237/src/game/Options.hx) | Independent toggles for visual recoil, physical movement, buffering, effects and camera response |

The useful adaptation is the **ability to compare one contribution at a time**.
The demonstration includes effects and control locks that may not suit our game;
do not copy all its options or its numbers. Its separately credited art is not
automatically covered by permission to reuse the code.

### deepnight/gameBase

[Repository](https://github.com/deepnight/gameBase), inspected revision
`a7af1d70dbbf62d7fc09cb05431ced606e0ed809`, MIT license. Its
[Camera.hx](https://github.com/deepnight/gameBase/blob/a7af1d70dbbf62d7fc09cb05431ced606e0ed809/src/game/Camera.hx)
separates follow focus, level clamping, dead zones, bumps, shake and zoom.
This is a reusable Haxe/Heaps framework. The creator's
[Dead Cells development page](https://deepnight.net/games/motion-twin/dead-cells/)
identifies GameBase as the underlying codebase used for that project; the public
template is not the shipped game's enemy/weapon implementation.

### Belmont's Curse ultrawide mod

[Repository](https://github.com/ollieatkinson/castlevania-belmonts-curse-ultrawide),
inspected revision `5422f877d8176caa4bcd11df44b72118031720bb`, MIT license.
[CameraPatches.cs](https://github.com/ollieatkinson/castlevania-belmonts-curse-ultrawide/blob/5422f877d8176caa4bcd11df44b72118031720bb/src/CameraPatches.cs)
hooks camera ratio and locked-fight bounds using orthographic camera size and
aspect. [ConfinerHooks.cs](https://github.com/ollieatkinson/castlevania-belmonts-curse-ultrawide/blob/5422f877d8176caa4bcd11df44b72118031720bb/src/ConfinerHooks.cs)
references Cinemachine lens/confiner behavior. This is useful third-party evidence
about room and encounter framing. It does not reveal exact default zoom,
background layers or the original camera implementation. The mod modifies
normal behavior; its settings are not baseline measurements.

### BelmontAbilityWheel

[Repository](https://github.com/leandrobueno/BelmontAbilityWheel), inspected
revision `c1d09121a245feba9662b8c75ee096ee8a47f029`, MIT license.
[Patches.cs](https://github.com/leandrobueno/BelmontAbilityWheel/blob/c1d09121a245feba9662b8c75ee096ee8a47f029/Patches.cs)
hooks `GamePlayerInput` processing;
[Wheel.cs](https://github.com/leandrobueno/BelmontAbilityWheel/blob/c1d09121a245feba9662b8c75ee096ee8a47f029/Wheel.cs)
routes requests through existing spell actions and retries some busy states.
It exposes useful integration concepts, but its retry timing and wheel behavior
are the mod author's choices. They cannot establish vanilla cancel/buffer rules.
Do not infer that the shipped game has Threadbound-style free equipment weaving.

### Alive Cells

[Repository](https://github.com/N3rdL0rd/alivecells), inspected revision
`c317bad4d39c58da8dfa0e70631018bb595d7e54`.
Its [README](https://github.com/N3rdL0rd/alivecells/blob/c317bad4d39c58da8dfa0e70631018bb595d7e54/README.md)
describes archive, atlas, save and animation-track tools. The old bytecode runner
is deprecated. The project is a modding toolkit, not a recreation or a complete
combat codebase. It explicitly separates its tooling license from the game and
assets. For our present question, the creator's gamefeel source is more direct
and does not require owning/extracting Dead Cells.

### Developer controls presentation and studio history

Sébastien Bénard's
[GDC 2019 slides](https://media.gdcvault.com/gdc2019/presentations/Benard-Sebastian-DeepCells.pdf),
especially slides 14–17 (PDF pages 13–16, zero-based), discuss forgiving jumps,
arrival correction, turning and aiming. They support testing player intention
and ordinary movement reliability alongside effects.

Dead Cells was not Motion Twin's first game. Its
[studio FAQ](https://motiontwin.com/faq) describes making web games from 2001,
and later collaboration with Evil Empire on Dead Cells. Belmont's Curse's
official credits distinguish Evil Empire development from Motion Twin advice.
The relevant lineage is shared action-game experience, not a single unchanged
team or an assumption of identical code/feel across games.

## 8. Threadbound code audit: foundations already present

This is a static review at `dac26f02`, not a new playtest. Findings identify
places to instrument and compare; they are not confirmed diagnoses.

| Existing area | Concrete source finding | Proposed next measurement |
| --- | --- | --- |
| [Combo input](../../Src/Characters/Player/player.gd) | `start_attack()` records a queued next attack during a ground combo; `_finish_ground_combo_attack()` starts it after the current segment completes. Queue fields here are booleans/family, not a timestamped expiry. | Input-to-first-hit and early/late queue behavior; stop after one intentional tap |
| [Dash exits](../../Src/Characters/Player/player.gd) | `can_start_dash()` checks `_is_attack_in_dash_cancel_window()`. Ground/air attacks allow exits around their strike frames. | Which requested exits are accepted during each visible pose; compare miss/hit |
| [Target response](../../Src/Enemies/EnemyBase/enemy_base.gd) | Normal damage sets physical velocity, plays recoil, restarts a 0.45 s attack cooldown and enters `Hurt` unless dead. Incoming response multipliers exist. | Whether repeated hits continually suppress an enemy; measure resulting spacing, not just velocity |
| [Hit pause](../../Src/Combat/combat_feedback.gd) | Requested pause is multiplied by 1.65 and clamped to 50–120 ms, with default time scale 0.08. A 40 ms request becomes 66 ms. Overlapping requests extend to the later end. | Compare ordinary-hit pause with visual/audio reinforcement; measure cumulative interruption across a combo |
| [Blade effects](../../Src/VFX/sword_sweep_vfx.gd) | Current non-spin sweep draws three narrow silver lines sampled from the actual blade; the live model projects hilt/tip to 2D. | Is the path readable at final zoom and over bright water? Compare a small attached filled ribbon |
| [Retired effect hook](../../Src/Characters/Player/flow_state_aura.gd) | `play_attack_swing()` is intentionally empty after the detached crescent was retired. | Do not mistake this for an absence of all trails or restore the rejected effect blindly |
| [Live visual](../../Src/Characters/Player/player_live_3d_visual.gd) | Clip playback and ground segment duration feed combat timing; base playback speed is 1.25 and blade pose supplies smear geometry. | Confirm pose, active window and contact remain aligned through speed changes |
| [Demo camera](../../Src/Camera/room_camera_controller.gd) | Dead zones, speed-dependent look-ahead, dash lead and fall framing already exist. | Compare actual demo and Blue captures before a camera rewrite |

The enemy cooldown finding applies to EnemyBase's path. Custom Blue enemies
may override it. The hit-pause finding is code behavior, not proof it is the
dominant feel problem. Existing stats-resource windup values alone do not
describe the live combo, which uses authored animation strike windows.

## 9. Proposed path from this study to a reviewable improvement

No runtime implementation is authorized by this research task. Keep one task
active, save/checkpoint each accepted unit, and obtain file-specific approval
for combat/equipment changes, scene restructuring or asset replacements.
T33 lighting/jump and T20 acceptance remain open.

### First: establish a short combat comparison

Propose a repeatable 20–30-second encounter using current player/gear and an
existing small enemy, then a reachable second threat. Record the baseline with
input/event timing. Compare one variable at a time:

1. Current timing/response, unchanged, to identify where control or spacing breaks.
2. A scoped queue/recovery adjustment only if the capture supports it.
3. A scoped receiver-displacement/interruption adjustment if needed.
4. One blade-attached VFX/contact pass with the selected response held constant.

Acceptance should include: one tap stops; a deliberate chain continues; next
hits remain reachable; an allowed exit responds consistently; enemy resistance
is legible; the next threat stays readable; and Chase enjoys repeating the
encounter without feeling compelled to spam. Automated checks can validate
input/damage/reset contracts, but Chase's normal-speed review establishes feel.

### Then: one Blue composition study

Use an existing camera/route location. Prepare a value sketch and layers using
current references before producing replacement art. Test normal movement,
vertical travel and the brightest selected effect. Accept depth, identity and
the transition from the demo before extending the room kit.

### Then: one enemy action sample

Keep the demo's outlined enemies as the visual authority. Choose one existing
Blue enemy and author anticipation, attack, recovery and hurt with consistent
body/feet registration. Compare a rig-rendered sprite workflow with a layered
cutout approach only if both are needed to choose a pipeline. Review at actual
zoom and normal speed. Preserve the live 3D player and defer roster replacement
until one complete sample works.

Equipment-fit studies remain useful, but should follow this first feel/visual
comparison rather than expanding three production efforts at once.

## Delivery and verification

- Five figures rendered and visually inspected, including body-box placement,
  frame labels and tracked parallax features.
- Measurements retain source URLs, sampling intervals, uncertainty and caveats.
- Public code inspected at pinned revisions; no vendored gameplay code or mod
  installation. Third-party reference imagery is not licensed Threadbound art.
- Relative links, figure dimensions, measurement arithmetic, staged diff and
  whitespace checked before committing. No gameplay regression run is warranted
  for this research-only change; no feel or art acceptance is claimed.
- Checkpoint: `docs: study Belmonts Curse combat visuals and framing` on
  `threadbound/docs-belmont-combat-visual-study`.
