# Loom Crossing 3D trial — October 29

Chase approved the complete separate 3D pass overnight. The production 2D game,
its scenes, assets and project settings are untouched. No 3D conversion decision
has been made. This is a playable experiment for Chase's morning verdict.
Chase reconfirmed approval for game-related work during the final verification.

## Play

The independent project is `C:/Users/chase/Documents/Threadbound 3D Study`.
Launch with `tools/study/start_third_person_study.ps1`; its import completes before
the game opens. The default scene is `scenes/loom_crossing_trial.tscn`.

| Input | Action |
| --- | --- |
| WASD / mouse | Camera-relative movement and looking; always run |
| Space | Jump, AP air jump, release grapple; ascend in water |
| Ctrl / B | Committed dodge with vulnerable startup/tail |
| LMB / RT | Time another tap near attack end to continue the three-hit combo |
| RMB / LT | Guard; fresh frontal guard can parry |
| Q / X | Weapon special, 2 AP; movement chooses directional variant |
| 1 / 2 / 3; V / Y | Sword/shield, thread staff, balance spear; cycle |
| E / RB | Zip grapple to a solid collider; press again to detach |
| Shift / LB + E / RB | Rope swing; steer and jump to release |
| Tab / right-stick click | Lock on |
| C / left-stick click | Down air strike / dive |
| X / D-pad Left + attack | Explicit upward air strike |
| G / D-pad Up | Interact, shrine, nearby spool |
| F2 | Normal, armored, runner or guardian duel practice |
| F / D-pad Down | Meditation and healing |
| R / Back | Reset; H controls, M mute, Esc pause |

## Suggested 10-minute test

1. Leave the worker and houses; fight the first swordsman. Compare timed combo
   taps with mashing. Dodge through a strike, then punish recovery.
2. Take the five scaffold jumps. Thread rings save the last landing. Try zipping
   to the beams, then Shift+E swinging and Space release.
3. Try the plated swordsman. Frontal light hits resist; finishers, heavy specials
   and rear attacks create openings. F2 isolates opponents when needed.
4. Switch to staff: a three-shot chain, charged orb and directional three-bolt
   volley. Switch to spear: three melee motions, neutral burst and directional
   lunge. All roles are available immediately, with the same six-AP foundation.
5. Strike or pluck GOLD, BLUE, RED receivers to weave the optional physical
   bridge. Staff shots, melee and G interaction work. Wrong order resets gently.
6. Cross by bridge, grapple or swimming. At the southern ramps, C dives and
   Space ascends/exits. Test the guardian; ranged shots wake it, and standing
   in its fixed ground telegraph hurts. The ending blossom is behind the court.

## What changed

A compact route replaces the oversized disconnected trial layout. Downloaded
CC0 houses, workshop/worker, props, trees and weapons sit beside the locally
licensed Fab guardian and FreeStylized ruins/rocks. Indigo woven clothing now
unifies field enemies; the plated variant retains distinct metal armor.

The accepted library run and tightened legs remain unchanged. Native retained
Mixamo `casting_2`, `attack_1`, `attack_3` and `attack_4` supply staff/pole actions;
there is no newly invented gait or claim of bow-specific animation. The staff
holds its downloaded rod and releases from the extended weaving hand. The spear
uses a palm attachment and a blade-following ribbon. Basic combos have recovery;
attack cancellation, dodge windows, armor/stance and readable enemy commitment
carry the combat work from `0d3ed1a6`.

Hit pause, reactions, camera response, metal contact and a quiet low contact layer
provide weight. Enemy footsteps, wooden deck footsteps, water entry/strokes,
river/wind and retained ambience complete the sound pass. New ground detail is
[Poly Haven Dirt](https://polyhaven.com/a/dirt), CC0; water has animated ripples and
an environment reflection probe. This is not a claim of dynamic planar reflections.

## Validation and limits

- 250 source and installed gameplay checks: 61 polish, 60 combat, 20 movement,
  46 demo feel, 23 committed combat and 40 Loom Crossing.
- Trial checks exercise actual projectile collision, three-hit spear combo,
  special AP use, palm grip/size, five consecutive running jumps, real spool
  shots/melee, solid bridge, swimming/dive/exit, gravity-driven constrained swing and release,
  ranged guardian warning/damage/avoidance and the ending.
- Five safe-installer cases preserve manual edits, reject conflicts atomically,
  confine paths, adopt identical UIDs and remove only unchanged managed files.
- Asset audit: 46 self-contained GLBs, 54 resource references, 16 unchanged
  original inputs. Selected KayKit weapons retain the bundled CC0 notice;
  hashes/provenance accompany the weapons, texture, audio and animation donors.
- GPU captures inspect the village, route, water and actual staff/spear poses.
  Fixed scripted duels establish counterplay; they do not establish human feel.

The source lives under an ignored-by-production independent Godot project.
Fab/FreeStylized raw derivatives remain in ignored `assets/local_licensed` and
are copied locally by the installer; they are not redistributed in public Git.
The handoff remains experimental: camera, contact feel, encounter difficulty and
whether this art direction earns a full 3D conversion need Chase's playtest.
The earlier [combat evidence](combat_pressure_2026_10_29.md) records the referenced
Reddit discussion and the inaccessible video-caption limitation.
