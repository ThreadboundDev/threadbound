# Flow State VFX Direction

## Status

Approved visual specification for the Chamber of the First Weave demo.

This pass changes Flow State presentation only. Flow State mechanics, statistics,
drain behavior, and activation rules remain unchanged.

## Visual Goal

Flow State should make earned momentum feel powerful, responsive, and distinctly
Threadbound. The player should appear to weave light through every action rather
than stand inside a generic flame aura.

The effect should communicate three things immediately:

- the player has entered peak momentum;
- the player's current demo Thread attunement is visible; and
- movement and attacks have become visually amplified.

The effect must remain elegant, ancient, woven, and readable at gameplay scale.

## Palette Contract

### Invariant Core

Every Flow State palette retains an ivory-hot core. This is the highest-value
part of the effect and keeps the player readable across every identity
combination and environment.

Antique gold is the baseline Thread color. It defines the structural weave,
small sparks, and neutral accents when the player has not collected a demo
Thread.

The ivory core and antique-gold structure remain present after colored channels
become active. Identity percentages describe the distribution among active
colored channels, not the percentage of the entire effect.

### Demo Thread Channels

The three collectible demo Threads supply these visual channels:

| Collected Thread | Channel |
| --- | --- |
| Power | Red |
| Balance | Blue |
| Essence | Yellow |

Channel weights are derived from the set of collected Threads:

| Active channels | Distribution |
| --- | --- |
| None | Ivory core with antique-gold weave |
| One | That colored channel receives 100% of the identity accents |
| Two | Each colored channel receives 50% of the identity accents |
| Three | Red, blue, and yellow each receive one third of the identity accents |

Multiple channels must remain visually discrete. They should appear as
interlaced strands, alternating particles, layered ribbons, or distinct pulses.
Do not average the channels into one flat mixed color. In particular, the
three-Thread state is a red-blue-yellow braid around the invariant ivory core,
not a white or black aura.

The palette must respond immediately when a demo Thread is collected and must
restore correctly from saved demo progress.

### Demo-Only Identity Proxy

Collected demo Threads are a proof-of-concept input for identity-responsive
VFX. They do not represent the final Absorb/Spare identity system.

Collecting all three demo Threads must not be interpreted as canonical full
absorption. The demo does not apply the blackened full-absorption result or the
pale full-sparing result. Future identity work may replace this temporary input
while preserving the same multi-channel VFX interface.

## Effect Sequence

### Momentum Buildup

Before Flow State activates, buildup remains restrained.

- Early momentum has no persistent aura.
- Higher momentum adds a small number of short-lived fibers or sparks.
- Buildup accents may become slightly more frequent or coherent as momentum
  rises.
- The effect may hint at the active palette, but it must not resemble the full
  Flow State aura.
- Buildup must never obscure the player silhouette or compete with combat
  telegraphs.

The large visual reward is reserved for entering Flow State.

The existing meditation feedback may reuse a restrained ivory-and-gold subset of
the same authored assets. Meditation does not play the Flow ignition, identity
channels, weapon trails, or full active aura.

### Entry

Flow State entry is a brief, authored ignition beat.

- An ivory-hot pulse begins at the player's core.
- A woven ring or compact filament burst expands outward.
- Colored channels reveal themselves as separate strands.
- A short silhouette highlight establishes the state change.
- Entry swells and brightens the live silhouette shell itself instead of
  overlaying a separate opaque transition sprite.
- The brightest and largest frame occurs during this transition, then settles
  quickly into the active aura.

Entry should feel decisive without reading as an attack hitbox, explosion, or
damage event.

### Active Aura

The persistent aura is derived from the player's live animation silhouette. It
must hug every pose at a tunable outward distance rather than place the player
inside a static oval or flame shape.

- The silhouette shell expands approximately 12-16 pixels beyond the current
  visible player frame.
- Only the translucent outer energy band renders; the duplicated character
  interior remains invisible.
- Animated noise breaks the band into breathing filaments and prevents it from
  reading as a conventional solid outline.
- Sparse translucent wisps continually peel upward from alternating sides of
  the silhouette, adding motion without hiding the current pose.
- The aura pulses in waves with moments of relative calm.
- Antique-gold structure and the ivory core unify the active identity channels.
- Colored strands retain enough separation to identify the current combination.
- Rear layers carry most of the aura mass.
- Front layers remain sparse and avoid covering the face, hands, weapon, or
  attack pose.
- The aura follows the player's intent and motion without lagging far enough to
  look detached.

The active aura should feel substantial but should not remain at maximum entry
intensity for the entire state.

### Movement

Flow State amplifies motion with short, action-specific accents.

- Running sheds brief fibers in the direction opposite travel.
- Jump takeoff pulls a small bundle upward from the ground.
- Air movement may leave sparse, quickly fading strands.
- Landing begins at low opacity, travels outward along the floor, grows over
  most of a second, briefly holds its bloom, and ends with a feathered decay
  instead of a single-frame flash.
- Dash receives the strongest movement treatment: an authored stretched
  silhouette, afterimage, or ribbon burst that rapidly draws back into the
  player.

Movement trails must preserve direction and timing. They should not become a
continuous screen-length ribbon or imply a second character.

### Attacks

Attacks receive authored weapon and impact accents while Flow State is active.

- A luminous ribbon or smear follows the real weapon path.
- Trail timing is synchronized to the authored attack animation and active
  strike window, not merely to attack input.
- Attack trails use broad, translucent filament smears that follow the strike
  direction without reading as solid crescents or energy projectiles.
- Impact creates a compact woven burst at the actual contact point.
- Identity channels may alternate or braid within the trail.
- The ivory core remains the hottest highlight, with colored channels providing
  identity.
- Effects must use the single equipped weapon and must never introduce a second
  weapon silhouette.

Attack VFX support the pose and weapon arc. They do not replace readable attack
animation or collision feedback.

### Exit

Flow State ends by visibly unweaving.

- Persistent strands contract, loosen, or break into drifting fibers.
- Colored channels fade back into the ivory-and-gold structure.
- Remaining light settles toward the player rather than bursting outward like
  an attack.
- The exit completes quickly enough that the screen accurately reflects the
  inactive gameplay state.

The final fibers may linger briefly, but the active aura must not remain visible
after Flow State has ended.

## Asset Direction

Action accents use authored raster VFX assets, including sprites, sprite sheets,
or texture-based particles. The persistent shell is generated by sampling the
live player-frame alpha in a shader so it can maintain an exact distance from
every pose. Procedurally drawn polylines are not
the visual foundation of the finished effect.

The authored asset set should cover, at minimum:

- momentum buildup fibers and sparks;
- entry core pulse and woven burst;
- rear and front active-aura loops;
- ground contact or weave accents;
- run and airborne trails;
- jump takeoff and landing accents;
- dash smear or afterimage;
- weapon-path ribbons;
- impact bursts; and
- exit or unravel fibers.

Runtime systems may place, time, scale, flip, tint, and combine authored
textures. Identity-neutral source art may be tinted into the active channels
when that preserves the intended values and material quality. Texture animation
must remain the visible source of the woven forms rather than code-generated
line art.

Assets should use transparent backgrounds, consistent registration points, and
enough padding to prevent clipping. Looping sheets must not visibly pop at their
seams. Directional assets must remain correct when flipped.

## Layering and Readability

Readability overrides spectacle.

- The player silhouette, weapon, feet, and current pose must remain legible.
- Enemy silhouettes, projectiles, hazards, pickups, and attack telegraphs must
  remain distinguishable through the aura.
- Most persistent energy belongs behind the player.
- Front-facing strands should cross the silhouette only briefly and in
  low-density areas.
- Ground effects must not hide platform edges or landing surfaces.
- Saturated red, blue, and yellow are precious accents rather than full-screen
  color washes.
- The ivory core must not overexpose the character into a featureless shape.
- Entry may temporarily exceed the active aura's footprint, but persistent
  effects should return to a controlled envelope around the player.
- Motion trails should decay before they become environmental clutter.

The effect must be judged at normal gameplay zoom and against bright, dark, and
similarly colored room backgrounds.

## Performance Constraints

The system must remain bounded and reusable.

- Use atlases and shared materials where practical.
- Reuse or pool frequently spawned effects when profiling shows allocation
  pressure.
- Cap concurrent trails, afterimages, impact bursts, and loose particles.
- Prevent emitters from accumulating during sustained movement or rapid attacks.
- Stop hidden loops and unnecessary processing when Flow State is inactive.
- Avoid stacking duplicate copies of the same effect when state changes occur
  rapidly.
- Keep transparent overdraw controlled, especially where rear aura, front aura,
  dash trails, and weapon effects overlap.
- Validate the worst case: three active color channels during rapid movement and
  attacks in a busy combat scene.

Exact budgets should be set through profiling on the demo's target hardware,
but visual tuning must not depend on unbounded particle counts or screen-filling
layers.

## Verification Checklist

- Buildup remains subtle at every pre-Flow momentum level.
- Entry is unmistakable and settles cleanly into the active loop.
- The ivory-hot core remains visible in every palette.
- With no collected Threads, the effect uses the ivory-and-antique-gold
  baseline.
- One collected Thread uses only its matching colored identity channel.
- Two collected Threads divide colored accents evenly.
- Three collected Threads remain a discrete, equal red-blue-yellow braid.
- Saved Thread progress produces the correct palette when the scene loads.
- Collecting a Thread updates the palette without requiring a scene reload.
- Run, jump, landing, dash, attack, impact, and exit accents trigger at the
  correct authored moments.
- No effect produces a duplicate weapon or misleading hitbox shape.
- The player and nearby threats remain readable at normal gameplay zoom.
- Effects terminate cleanly when Flow State ends, the player dies, or the scene
  changes.
- Worst-case multi-channel combat remains within the profiled performance
  budget.

## Out of Scope

This VFX pass does not:

- change Flow State statistics, duration, drain, or activation;
- lock Flow State behind an item;
- add or implement a Pattern accessory;
- add an accessory equipment slot;
- gate wing doors, the boss door, or any other progression behind a Pattern;
- extend the opening tutorial with Pattern acquisition;
- define Pattern bonuses or embroidery behavior;
- implement Absorb/Spare choices; or
- establish final identity outcomes for the full game.

Pattern and accessory work remains a separate design and implementation decision.

## Debug Identity Sandbox

Debug builds expose a non-persistent tuning sandbox on the player:

- `F10`: add 10% Power/red.
- `F11`: add 10% Balance/blue.
- `F12`: add 10% Essence/yellow.
- `Home`: clear the override and return to the collected-thread identity.
- `End`: toggle Flow State through the real momentum system.

Each identity channel caps at 100%. These controls alter only the active Flow
VFX instance; they do not claim Threads or modify saved demo progress.
