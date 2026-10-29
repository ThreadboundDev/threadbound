# Chamber of the First Weave — separate 3D demo feel pass

October 28, 2026. T29 implements Chase's review of T28. **Appearance and feel still
require Chase's playtest.** This is a separate 3D experiment, not a release build
or approval to replace the 2D game.

## Delivered

- Ruin runs by default using a dedicated 20-frame athletic cycle: narrow foot
  tracking, alternating flight/stance, raised knees and bent counter-swinging
  arms. Sword carry points down/back. Intentional shield guarding remains.
- The editable 3D source is
  `work/third-person-study-2026-10-28/source/Threadborne_3D_Demo.blend`.
  It includes keyed IK controls, the baked `demo_run` NLA track and existing
  combat/water actions. `Threadborne_Pre3D_Reference.glb` is kept beside it,
  outside the runnable assets. Rebuild with
  `tools/study/build_3d_player_animation_source.py` through Blender.
  Production player files and the production animation library are untouched.
- Confirmed sword hits pause the attacker and victim briefly, add restrained
  contact particles/rings, sound and controller feedback. Whiffs do not produce
  contact feedback. Attacks accept a late deliberate follow-up tap; a three-hit
  chain ends with recovery. Early spam and attacks during recovery are rejected.
  Basic attacks retain their original free AP cost; no stamina system was added.
- Downloaded sentinels have closed grip poses, weapons aligned through their
  hands and an armed jog. Root motion remains physics-controlled. Hit impulses
  decay separately from chase velocity. Committed lunges retain their full speed.
- Navigation accounts for the baked surface height and the largest enemy's
  clearance. Agents follow routes around obstacles, avoid each other, step over
  small debris and return home using navigation. Targets on unreachable geometry
  no longer make enemies push directly into walls.
- The main scene now frames the workshop/tutorial clearing, Red/Blue/Yellow
  wings, three any-order thread pickups, the existing lake tower copied into this
  project, roof/platform routes and the guardian clearing. Pickups color Flow's
  individual strands. No new progression gate or permanent class was introduced.
- G / D-pad Up interacts with workshop guidance, the resting shrine and the
  ending blossom. The shrine restores health/AP and records a respawn point.
  Defeating the study guardian offers **Keep Exploring** or **Continue to End
  Demo**, followed by a thank-you/restart screen. This does not replace the
  canonical 2D Proto-Weaver implementation or rewrite its lore.

## Preserved and deferred

The existing AP recharge, neutral/spin specials, shield/parry, dash, aerial
attacks, pogo, air jump, wall/mantle movement, grapple against solid collision,
lock-on, Momentum/Flow, meditation and water controls retain their regression
coverage. The 2D `Src`, `Assets`, `Scenes`, `ArtSource` and root project settings
are unchanged. Water texture/reflection improvements are deferred as requested.

FreeStylized and Fab derivatives remain local under ignored `local_licensed`;
they are included in the local study install but excluded from the public Git
repository. CC0 sentinel derivatives and the existing production tower/SFX copy
retain provenance. No new remote asset was needed for this pass.

## Validation

Source and independently installed projects: 61 asset/level checks, 60 combat checks, 20 movement checks and
37 new demo/feel checks: **178 passing**. New checks exercise deliberate combo
buffering, finisher recovery, local contact pauses, whiffs, default run, low-step
collision, full walls, navigation around a wall, crowd progress/separation,
closed sword fingers, boss light/heavy stagger rules, wing collection, shrine
respawn, retained exploration progress and the actual ending/restart loop.
Implementation checkpoint: `c088dbd78c6a402418f8bcc818af7abbad27ed5a`, pushed to
`threadbound/feature-polished-3d-demo`. Standalone checks and both GPU capture
scripts also pass. Asset audit: 44 self-contained GLBs, 42 resource links and
15 unchanged production inputs. The launcher and verifier import new GLBs
synchronously before starting gameplay. Existing Godot-resaved settings were
preserved when updating the install entry scene.

Five installer safety cases cover conflicts, atomic preflight, interrupted-copy
recovery, path confinement and removal of unchanged obsolete managed files.

Godot GPU captures review six run phases from two angles, weapon grip and five
chamber viewpoints. These are visual inspection and scripted play checks;
they do not establish that Chase likes the feel. Native live input was not used
for this pass after the earlier desktop-app approval timed out.

Run `tools/study/verify_polished_study.ps1 -RepositoryCopy` for source checks,
or omit the switch for the installed study; `-Capture` renders review images.
`tools/study/audit_third_person_assets.py` verifies embedded GLB dependencies,
resource links and original source hashes.

## Chase's retest route

1. Begin the demo. Run and turn without Shift; jump and dash around the workshop.
2. Tap a sword attack once, try early spam, then time two follow-ups late in each
   swing. Compare hit contact, whiffs and the finisher's recovery.
3. Approach the Red and Yellow opponents; watch grip, armed jog, corners and
   return paths. Use shield/parry, Q neutral, movement+Q spin and C air pogo.
4. Grapple cottage walls, stonework, platforms and the lake tower. Try swimming
   and returning to shore. Collect the three thread markers in any order.
5. G at the workshop shrine, take damage/die and confirm the resting point.
   Defeat the guardian, approach the blossom on its right, and try both ending
   choices and restart.

The installed project is `C:/Users/chase/Documents/Threadbound 3D Study`.
Launcher: `tools/study/start_third_person_study.ps1`.
