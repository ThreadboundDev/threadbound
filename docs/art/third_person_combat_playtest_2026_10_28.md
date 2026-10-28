# Third-person combat and traversal playtest — October 28, 2026

Chase authorized extending the separate 3D study with two enemies, a boss,
grapple, existing specials, platforming, sound and a clean presentation that
captures Threadbound's theme. This supersedes the initial study's movement-only
scope. **Delivered for hands-on review; not a production conversion.**

## Run and controls

Use the installed independent project at
`C:\Users\chase\Documents\Threadbound 3D Study\project.godot`, or the
[launcher](../../tools/study/start_third_person_study.ps1). The checkpointed
[source project](../../work/third-person-study-2026-10-28/project/README.md)
stays beneath a `.gdignore` in the main repository. No main-game scenes,
controllers, enemy sources, art files or globals are modified.

| Action | Keyboard / mouse | Controller |
| --- | --- | --- |
| Move / camera | WASD / mouse; wheel zoom | Left / right sticks |
| Jump / jump off grapple | Space | A |
| Run / dash | Shift / Ctrl | LB / B |
| Sword combo; airborne strike | Tap LMB; tap again to buffer next segment | RT |
| Guard / timed frontal parry | Hold RMB / fresh press near impact | LT |
| Neutral burst / directional spin | Q / movement + Q | X / movement + X |
| Hookshot / enemy grapple strike | Hold E; release E or jump to disengage | Hold RB |
| Lock / unlock nearest visible enemy | Tab | Right-stick click |
| Reset whole playtest | R | Back / Select |
| Original / new weapons | V | Y |
| Pause / resume; help; mute | Esc; H; M | Start pauses; keyboard H/M also available |

Six AP recharge independently over ten seconds. Both specials cost two AP;
insufficient AP rejects the cast. Neutral is a radial burst after a charge;
movement + special is a traveling spin. Ordinary attacks can be buffered into
three strikes and have one-hit-per-enemy windows. Dry airborne attacks use the
existing air clip; dry airborne specials remain unavailable.

## Test route

Start at the safe workshop and watch the worker if desired. Turn toward the
field encounters for Reedhook and Eave Runner. Try basic strikes, buffering,
air attacks, guarding, a fresh parry, dash cancellation and specials. Idle
contact, windup, recovery and attacks that miss do not deal damage.

The elevated Threadmarked Rise has six rings, woven landing mats and safe
return markers. Aim near a ring and hold grapple; the hook fires, connects and
pulls toward its landing. Release keeps momentum; jump releases upward. The
current landing's ring is ignored, making consecutive targeting predictable.
Walls occlude targets and stalled pulls detach. A locked enemy can receive one
30-damage grapple strike with recoil. These follow the current **base hookshot**
intent; this is not a new free-swinging rope/glove system.

Cross the stream by bridge or the high grapple route to reach the Bellstriker
champion. Its jab, cross and heavy smash have separate tells and locked release
directions, followed by an opening. Later windups shorten modestly below half
health. This is a larger arena variant of an existing enemy, not new boss lore.
Falls return to the last marked landing; death returns to a restored clearing.
R restores enemies, health and AP so the same encounter can be repeated.

Review captures: [two-enemy burst](../../work/third-person-study-2026-10-28/playtest_action.png),
[champion arena](../../work/third-person-study-2026-10-28/playtest_combat.png),
[elevated route](../../work/third-person-study-2026-10-28/playtest_traversal.png).

## Enemy and visual reuse

- **Reedhook:** current animated model; deliberate hook sweep, 0.6-second tell,
  short step, harmless recovery, interruptible by damage. 95 study HP.
- **Eave Runner:** current v4 body/rig and clips; faster approach and committed
  jump-slash/lunge. 75 study HP. Wall-perch/projectile behavior is outside this pass.
- **Bellstriker champion:** current Boxing v4 model/rig, enlarged; 420 study HP,
  three-step jab/cross/smash sequence using the existing 16/21/32 damage values.

The current Threadborne body, clothing and rig remain intact. Selected original
combo, air strike, roll, charge, grapple, impact and death clips are added to the
working-copy export; the original/new weapon toggle remains. Existing woven
cloth, flax bindings, walnut and ceramic enemy materials carry the world identity.
Thread rings, stitched landing mats, indigo markers, arena banners, gold/cyan
stitch bursts and unravel strands reinforce it. Existing source forward axes
are normalized to the new 3D actor facing.

Foliage is excluded from encounters, landing areas and the full camera orbit
around the arena. Remaining trunks collide with the player and foliage has a
separate camera collision layer. Bridge/porch approach ramps remove accidental
small lips. Lock-on, orbit/zoom, pause/help, health/AP display, hit numbers and
reset prompts are included. The sky/water/layout remain a compact art study.

## Audio and provenance

The mix includes existing registered Threadborne jump, dash, sword, cloth-rip,
grapple throw/connect and enemy swing/stomp sounds. Selected retained **NOX CC0**
recordings supply grass/wood footstep variations, landings, forest wind and a
spatial river loop. NOX previews were converted to PCM16 at original level,
sample rate and channel count, without peak normalization. A bounded voice pool,
native loops, low ambience/music levels and a -1 dB master limiter control the mix.
M mutes it; final listening balance is still a hands-on decision.

New music: [Cathedral in the forest (ambient loop)](https://opengameart.org/content/cathedral-in-the-forest-ambient-loop)
by congusbongus. The individual work page identifies CC0. The unchanged OGG,
primary link, source hash and local evidence note are retained; it plays quietly.

See [combat/audio provenance](../../work/third-person-study-2026-10-28/project/assets/combat_provenance.json),
[Eave Runner provenance](../../work/third-person-study-2026-10-28/project/assets/eave_runner_provenance.json),
and the original [asset manifest](../../work/third-person-study-2026-10-28/project/assets/provenance.json).
The study is not represented as an entirely CC0 asset pack: existing game
characters/audio retain their existing provenance. New downloaded music is CC0.

## New Downloads review

The three new ZIPs match these creator posts, confirmed by filename and Chase's
browser-history screenshot:

- [Free Ruins 01](https://www.patreon.com/FreeStylized/posts/free-ruins-01-119705391):
  `Ruins1_(AssetPack4).zip`, 42 files, FBX/Blend/textures/Unity/Unreal inputs.
- [Free Rocks 01](https://www.patreon.com/FreeStylized/posts/free-rocks-01-114690300):
  `Rocks1_(AssetPack2).zip`, 65 files, 51 FBXs including LOD variants.
- [Starter Nature Pack](https://www.patreon.com/FreeStylized/posts/free-starter-kit-119706348):
  `StarterNaturePack_(FoliageKit1).zip`, 46 files, 33 FBXs and Unity/Unreal inputs.

All three ZIP CRCs passed; none contains a license/readme notice. The website's
[terms](https://freestylized.com/disclaimer/) permit commercial use without
required credit, but describe custom redistribution limits and distinguish
Patreon content from CC0. They are **not cleared as standard CC0** under the
standing collection policy. Raw files remain in Downloads, unimported and
undeleted. [Hashes, counts and disposition](../../work/third-person-study-2026-10-28/new_download_review.json).
Their painted rocks/ruins could suit a later art pass if separately accepted
under their actual terms; their Unity/Unreal wind shaders are not Godot-ready effects.

## Verification and limits

- **57/57 combat/traversal checks pass**, including all six consecutive landings,
  light hit windows/buffering, radial/spin coverage, AP/no-AP cases, guard/parry
  direction, dash invulnerability/cooldown, harmless tells, interruption,
  individual enemy attacks, full boss combo, enemy grapple hit, occlusion,
  death/reset, checkpoints, pause/resume and mute.
- **20/20 original movement/camera checks pass.**
- A fresh import of the installed standalone copy also passes **57/57** and its
  action/arena/route GPU captures have no new errors. Evidence:
  [source checks](../../work/third-person-study-2026-10-28/combat_verification.json),
  [installed checks](../../work/third-person-study-2026-10-28/installed_combat_verification.json),
  [movement regression](../../work/third-person-study-2026-10-28/movement_regression.json).
- Asset audit: ten self-contained GLBs, 21 resource links, 13 unchanged original
  source hashes; adapted workshop maps are <=1K. Eave Runner's working-copy maps
  are embedded at 1K; original enemy/player exports remain unchanged.
- Actual Godot GPU views check the arena, traversal space and active neutral burst.
  Initialization material errors caused by creating and immediately discarding
  unwanted foliage were resolved by filtering placements before instantiation.
  Audio shutdown now explicitly stops/releases streams; final checks/captures
  have no new script, missing-resource or shutdown errors.

This adapts the existing ideas to 3D; it is not a one-to-one port of every combat
system. Meter distances, movement tuning, aiming assistance and encounter HP are
study values. No production save/progression, equipment swapping, swimming,
full enemy navigation, wall-perch ecosystem, or full Momentum/Flow simulation.
Enemy collision/hits use readable actor volumes, ranges and line-of-sight, not
frame-exact 3D blade/fist collision. Physical-controller feel, sound balance,
camera comfort and normal-speed combat acceptance remain Chase's playtest.

Checkpoint: `feature: expand 3d study with combat and threaded traversal`.
Use the project work list for current acceptance; T20 remains the production priority.
