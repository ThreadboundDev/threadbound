# Polished third-person level study

Chase requested a more useful 3D playtest after reviewing T27: downloaded models,
better animation/enemies, a populated village, collision grappling and clean attack
effects. This is the authorized separate experiment, not a replacement of the
production 2D game. Main scenes, player/equipment controllers, approved art and
story files are unchanged. Chase's final appearance/feel acceptance remains pending.

## Installed project and controls

The standalone project is `C:\Users\chase\Documents\Threadbound 3D Study`.
Its versioned source is `work/third-person-study-2026-10-28/project` and is excluded
from the main game's imports by the parent `.gdignore`. Launch with
`tools/study/start_third_person_study.ps1`.

| Control | Action |
| --- | --- |
| WASD, mouse, wheel | Camera-relative movement, look, camera distance |
| Shift / Ctrl | Run / dash |
| Space | Jump, air jump, or jump-release an attached grapple |
| E | Fire/release the collision hookshot; arrival releases automatically |
| Left/right mouse | Buffered sword combo / shield and fresh-press parry |
| Q | Neutral special; movement + Q selects directional spin |
| Space + airborne attack / C + airborne attack | Upward attack / downward pogo |
| C in water | Descend; Space ascends/breaches; attacks and specials work underwater |
| Hold F while stationary | Meditation; faster AP recharge and Momentum-funded healing |
| Tab / V / R | Lock target / compare original and downloaded sword/shield / reset demo |
| H / M / Esc | Full controller bindings and help / mute / pause |

Dash, grapple and air jump cost one AP. Specials cost two. Six points recharge
independently from base ten-second timers, modified by Momentum and meditation.
At zero Momentum the recharge multiplier is 0.9, so an empty point takes about
11.1 seconds. Ordinary attacks, ground/wall jumps and successful pogo cost no AP.
Pogo restores the aerial strike, without restoring AP or the air jump.

## Level and downloaded art

- Original working-villager workshop plus three additional collidable cottages,
  market stalls, barrels, crates, bench, lanterns, practice dummy and equipment props.
- Six elevated decks/scaffolds with supported thread markers, rooftop access,
  bridge, swimmable river/bed, surrounding hills, vegetation and a ruin clearing.
- Four field opponents using two adult Quaternius Ranger rigs: Woven Swordsman
  and Spindle Runner. UAL1/2 supply idle, walk/jog, sword, dash, hit and death clips.
  Their names describe study actors and do not establish new canonical factions.
- The downloaded Fab armored golem is the 3.15 m guardian, with its own ten-clip
  motion set and a three-attack sequence. FBX bind units and animation scale are
  normalized before export. Woven skin/limb bindings adapt its presentation.
- FreeStylized website rocks, broken walls, arch, trees and ground foliage are
  used locally. Foliage bark and monochrome leaf masks are handled separately;
  materials use alpha cutouts. Selected source maps are reduced to 1K working copies.
- The existing Threadborne mesh, clothing and authored attack identity are retained.
  KayKit's optional sword/shield remain available alongside the original pair.

## Mechanics carried over

| Existing interaction | Study implementation |
| --- | --- |
| Ground combo, attack windows and hit deduplication | Three buffered strikes; 3D cone/range and wall occlusion checks |
| Authored forward/up/down air poses | Original authored library and runtime retiming, remapped to the same skeleton |
| Pogo as combat/traversal | Real enemy/surface contact, normal-jump rebound and strike recovery |
| Dash, air jump, grapple and AP | Original base costs; parallel recharge, dash duration/cooldown and invulnerability |
| Solid-surface hookshot | Camera/hand collision rays, moving targets, capsule support offsets for walls/floors/ceilings, stall/obstruction release |
| Enemy grapple strike | One strike, long-range damage bonus and recoil |
| Wall slide/jump and ledge movement | Wall contact, short cling, outward wall jump and capsule-cleared mantle |
| Water combat | Swim/vertical control, breach, 3-hit water combo, neutral/spin special and directional water dash; grapple cancels on entry |
| Momentum and Flow | Staleness, weave variety, gain curve, tier interpolation, Flow threshold/drain and action/recharge multipliers |
| Meditation | Hold delay, 2x AP recharge, ten-Momentum healing pulses with the existing health bands/75% ceiling |
| Feedback | Actual skinned-blade surface trail, contained woven neutral wave, impact flecks, Flow weave, spatial Foley/ambience/music |
| Recovery | Safe landing checkpoints, death/reset, pause/help and mute |

Distances, movement speeds, aiming and camera behavior are adapted to metres and
third-person space. This level exercises the base kit; it is not a complete port
of the campaign, saves, quests, every equipment variant or radial equipment UI.
Those production systems remain preserved in the original game. No 3D conversion
decision or production replacement is implied by this demo.

## Source and license handling

The retained Quaternius/KayKit releases include explicit CC0 notices already
recorded in the inventory. The existing CC0 NOX sound selection and forest music
remain. The general CC0-only collection policy is unchanged.

Chase explicitly requested the golem and confirmed the FreeStylized packs were
website downloads. The [Fab Standard terms](https://www.fab.com/eula?lang=en)
permit compatible-engine project use/modification without mandatory credit;
[FreeStylized's website terms](https://freestylized.com/disclaimer/) permit
commercial use without mandatory credit but impose redistribution restrictions.
These are custom-licensed local demo dependencies, **not CC0**.

The public repository excludes `project/assets/local_licensed/`. It contains no
Fab/FreeStylized GLBs, raw FBXs/textures, source ZIPs or asset-containing Blender
files. Local installation copies the authorized derivatives into the standalone
project. Import recipes, selected-member hashes, provenance and rendered review
images are versioned. See `polish_source_manifest.json` for exact member hashes.

Rebuild using `prepare_third_person_assets.py`, `prepare_polished_assets.py`, the
player exporter with `--player-only`, and `export_polished_assets.py` with
`--sentinels`, `--golem`, `--village`, `--props`, `--stylized`. These require the
user's original archives in the documented library/Downloads locations. Then
run Godot's editor import and `install_third_person_study.py`.

## Verification and playtest card

Current automated baseline: 55 integrated polish checks, 59 combat/traversal
checks and 20 movement/camera checks pass. New tests include ordinary wall,
floor and ceiling hookshots, evaluated boss bone scale, actual pogo contact,
mantle clearance, air-jump costs, water specials/dash, meditation and Flow.
The asset audit checks self-contained GLBs, project-local links and unchanged
original inputs. Timed GPU pose captures review player/sentinel/golem attacks,
swimming and Flow. Final installed verification is recorded after handoff.

For Chase's feel review: explore the workshop/market; jump and grapple onto
ordinary roofs/decks; fight the two field silhouettes; swim below the bridge and
try both specials; cross to the guardian and read/dodge/parry its three attacks.
Chain movement and attacks to earn Flow, then try meditation after taking damage.
R restores every encounter, AP, health, Momentum and traversal state.
