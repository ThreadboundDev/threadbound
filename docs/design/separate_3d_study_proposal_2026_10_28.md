# Separate 3D study proposal — October 28, 2026

Chase likes stylized/low-poly 3D and is considering a separate project to see
whether Threadbound would benefit from 3D presentation or gameplay. This records
that interest and a proposed experiment, not approval to convert the game or
start a new implementation. The [curated shortlist](../assets/curated_asset_shortlist_2026_10_28.md)
provides concrete CC0 candidates.

## The question to answer

**Can we make a small space that looks like Threadbound and feels enjoyable to
move through in 3D?** A beautiful house render can answer an art question; it
cannot establish whether a third-person camera, depth judgments or grapple
target selection work. We should test those separately and keep either result
useful even if we retain the current side-on game.

Two meanings of 3D remain open:

- **3D art with side-on movement:** reusable models, rigs, lighting and animation
  while preserving planar route reading. This can already benefit the game.
- **Full 3D movement with a third-person camera:** movement and aiming gain a
  depth axis. Camera obstruction, target selection, combat direction, swimming
  and level composition need fresh design/verification.

The camera/control choice remains open. This proposal treats third-person
movement as the more exploratory option and side-on presentation as a comparison
view. Neither is an accepted direction.

## Small first scene

Proposed independent Godot project folder:
`C:\Users\chase\Documents\Threadbound 3D Study`.
Keep its own source/history and copied selected assets. The production project's
autoloads, scene tree and asset imports should not be dependencies of the study.

Make one compact workshop clearing or dock approach:

1. One retained modular house, one clothed peasant at a table, a few resource
   props, and a small tree/rock selection. Author a restrained material palette
   and simple woven accents; compare the existing workshop study.
2. A short route with ground, a low step, a jump gap and an elevated destination.
   A player-sized stand-in, camera, run and jump provide an initial playable view.
3. A working animation on the villager, one hand tool and a small sound selection
   make the place feel active. Prefer an existing compatible rig; retarget only
   the few motions actually needed. Measure feet/wrist/tool contact.
4. Capture the same location from a side-on camera and the proposed third-person
   camera, then play the route with the chosen controls.

The initial view is an **art/camera/movement study**, not evidence that combat or
the whole game has successfully translated. A second bounded step, if the first
is promising, should add a dash and one grapple route/anchor so we can judge the
identity-defining traversal. Scope those controls from the current design before
implementing them; do not invent new progression or weaken the existing rules to
make the test easier. A full-3D commitment should wait for that traversal check.

## Assets and restraint

Use P09/P03 house/props, P10/P13 peasant and P07 resource dressing first. Add
KayKit Forest Free for a few silhouettes. KayKit work motions/tools are useful
if their compatibility/adaptation cost beats the table-work motion already
prepared. NOX supplies immediate audio candidates. Kenney particles can supply
subtle dust/motes after the space reads well.

No further broad asset hunt is needed before a first study. A matching-rig KayKit
Adventurer is an optional technical stand-in, not a replacement player decision.
The Fab golem is not necessary for this CC0 experiment and its licensing
exception remains undecided. New combat, weapon progression, boss lore,
inventories, quests, save migration and a whole biome are outside this study.

## Proposed implementation files for a later approval

All paths below would be **new files inside the separate study folder**:

- `project.godot`, `.gitignore`, `.gitattributes`, `README.md`.
- `scenes/workshop_study.tscn`, `scenes/study_actor.tscn`.
- `scripts/study_actor.gd`, `scripts/study_camera.gd`,
  `scripts/study_controls.gd`, `scripts/worker_loop.gd`.
- `assets/provenance.json`, `assets/licenses/` and only explicitly selected
  model/texture/motion/audio working copies.
- `docs/study_results.md` and recorded comparison captures.

Exact selected binary paths and any additional files must be listed with the
implementation scope after the asset choices. The prospective dash/grapple
step needs a separate file/control plan. No production file modification is
proposed. This documentation task does not create that project or install assets.

## How to decide whether it is worth continuing

Evaluate at actual gameplay scale, normal speed and with keyboard/controller:

| Question | Evidence to collect |
| --- | --- |
| Does the world still read as Threadbound? | Compare silhouettes, material palette, woven details and player visibility against the existing room/art study, not just an attractive close-up. |
| Does 3D improve movement choices? | Play the same short route repeatedly. Record missed jumps, depth confusion, camera obstruction and whether turning/camera correction interrupts flow. |
| Does the worker belong in the scene? | Watch loops for foot sliding, hand/tool separation, abrupt resets and animation scale mismatch. |
| Does it run and import cleanly? | Record hardware, renderer, resolution and frame time for the selected scene; check collisions, missing textures, animation/skin errors and source dependencies. No result is assumed in advance. |
| Is full 3D traversal promising? | After a separately scoped dash/grapple step, judge anchor visibility, aiming effort, momentum and recovery. The visual-only scene cannot answer this. |

Possible outcomes are all useful: keep low-poly assets in the current side-on
game; use models to render 2D scenery/animation; continue a full-3D prototype; or
retain the current mixed presentation. Prefer the approach that improves feel
and makes production sustainable, rather than choosing solely from a still image.

T20 remains the production priority. This study is proposed, unimplemented and
unaccepted. No scene restructuring, asset replacement, gameplay architecture,
combat/equipment change or lore change has been approved through this document.
