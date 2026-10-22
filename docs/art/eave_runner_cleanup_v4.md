# Eave Runner v4 model cleanup

October 21, 2026. Task T16. Separate review candidate built from the current
saved v3 source on top of `96b2c039`; gameplay still uses v2. This delivery does
not accept the candidate or install it in encounters.

## References and diagnosis

The original silhouette is **A, Eave Runner**, in
[`Indoor_Enemies.png`](../../outputs/lakeside-character-concepts-2026-10-19/Indoor_Enemies.png).
The later
[`EaveRunner_Woven_Concept.png`](../../outputs/woven-blue-guardians-2026-10-20/EaveRunner_Woven_Concept.png)
develops that silhouette into the established woven guardian: cracked ivory
mask, indigo hood/scarf, layered wrap, gathered trousers, bound woven limbs and
fitted bamboo bracers. Both are existing project references, not new concepts.

Fresh source inspection found three different states that must not be confused:

| Asset | State before this task | Triangles |
| --- | --- | ---: |
| v2 | Active game asset; rounded hood, barrel-like tunic/straight shorts, oversized bracer cage | 264,312 |
| Current saved v3 | Retained, unfinished candidate; intersecting cropped tunic/wrap, thin shoulder flaps, exposed rear skull, irregular cut edges and an isolated torso triangle | 657,226 |
| v4 | New native model candidate; 176 editable components, 18 exported meshes | 372,508 |

The candidate has 43% fewer triangles than current v3, but remains heavier than
active v2. These counts do not establish a frame-time improvement.

The earlier claim that the hem alone used 84% of v3's geometry came from an
older diagnostic and was corrected during this task. In the **current** v3,
the tunic has 124,894 triangles and the cut hem has 18,684. Historical renders
and reports are not current validation.

## What changed

- Rebuilt the torso as a coherent dark undershirt with broad overlapping indigo
  panels. Added thin physical cloth edges and fitted folded lapel hems.
- Rebuilt the hood as one continuous lined cloth shell, covering the rear skull,
  with an overhanging brow and broad asymmetric folds. Preserved the mask,
  apertures, forehead emblem and crack; tucked exposed fastening ends inward.
- Reworked the scarf into unequal diagonal folds and an asymmetric front drape.
- Replaced the shoulder rings/flaps with shorter, flatter layered cloth sleeves.
- Rebuilt fuller trousers with diagonal tension and knee gathers; tapered them
  to the existing knee knots. Added short asymmetric waist tabs with restrained
  hem variation.
- Fitted the existing bracers and waist bindings more closely. Reduced cloth
  normal-map strength and simplified dense woven/braid surfaces while retaining
  articulated hands and finger meshes.
- Preserved all sixty named bones and twelve named action durations. Export
  joins material-compatible meshes in memory; the saved Blender file keeps
  editable semantic components and packed source textures.

This is a native mesh delivery, not an image retouch. Existing materials and
texture inputs are reused. It moves the silhouette and clothing construction
toward the concept; it does not reproduce every painted chip, stitch or cream
pattern from the illustration. Existing action choreography remains unchanged.

## Review files

- Native source:
  [`EaveRunner_Woven_v4.blend`](../../ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v4.blend)
- Self-contained candidate:
  [`EaveRunner_v4.glb`](../../work/eave-runner-v4/EaveRunner_v4.glb)
- [Three-quarter](../../work/eave-runner-v4/renders/Eave_v4_ThreeQuarter.png),
  [front](../../work/eave-runner-v4/renders/Eave_v4_Front.png),
  [back](../../work/eave-runner-v4/renders/Eave_v4_Back.png),
  [game-side angle](../../work/eave-runner-v4/renders/Eave_v4_GameSide.png)
- [Wall perch](../../work/eave-runner-v4/renders/Eave_v4_WallPerch.png),
  [jump slash](../../work/eave-runner-v4/renders/Eave_v4_JumpSlash.png),
  [landing](../../work/eave-runner-v4/renders/Eave_v4_Landing.png),
  [throw](../../work/eave-runner-v4/renders/Eave_v4_Throw.png)
- Fresh same-camera before views:
  [active v2 source](../../work/eave-runner-v4/renders/Eave_v2_Before.png),
  [retained v3 source](../../work/eave-runner-v4/renders/Eave_v3_Before.png).

The game-side image is a close model inspection at the existing 72-degree yaw.
A separate [native scale view](../../work/eave-runner-v4/renders/Eave_v4_GameReadability.png)
uses span 3.8 at 96 pixels/metre to inspect the apparent gameplay size. Neither
is an in-game screenshot or measured performance result.

## Rebuild and checks

Use Blender 5.2.1 LTS in background mode from the repository root, in this order:

```powershell
& $blender --background --factory-startup --python-exit-code 1 --python tools/art/build_eave_cleanup_v4.py
& $blender --background --factory-startup --python-exit-code 1 --python tools/art/verify_eave_cleanup_v4.py
& $blender --background --factory-startup --python-exit-code 1 --python tools/art/render_eave_cleanup_v4.py
& $blender --background --factory-startup --python-exit-code 1 --python tools/art/export_eave_cleanup_v4.py
```

Set `$blender` to the local executable. Builds use ignored `tmp/eave_cleanup_v4`
for intermediate saves. The only final source written is the new v4 file;
v2/v3 source files and active resources are opened read-only.

For Godot, create a disposable project outside the main imported tree, copy the
candidate GLB and `tools/art/verify_eave_cleanup_v4.gd` into it as `verify.gd`,
and write `expected.json` containing the triangle count from `build_report.json`.
Import with Godot 4.7.2, then run `--headless --path <sandbox> --script res://verify.gd`.
Use isolated `APPDATA`. The verifier never loads the gameplay prefab.

Current results and exact source/export hashes are recorded under
[`work/eave-runner-v4`](../../work/eave-runner-v4): build, source, export, Godot
and provenance reports. Source checks cover finite non-degenerate geometry,
no isolated single triangles or long spikes, normalized skin weights, exact
rig/action contracts and sampled mesh deformation. Godot checks independently
cover imported topology, UVs/weights, action durations, real sampled bone
motion, in-place root and wrist weapon attachment.

Final native source: **1,279 checks passed**, no failures. Final Godot import:
**127 checks passed**, no failures, matching all **372,508 triangles**, sixty
bones and twelve clips. The hood is a closed manifold shell with 10,592
triangles. Blender previews were inspected from front, back and side and in
the retained wall-perch, slash, landing and throw poses. The saved sources,
active v2/v3 exports, controller, stats and active prefab pass the recorded
unchanged-hash comparison.

Automated passes do not establish concept acceptance, animation appeal or
Forward+ performance. The embedded-texture GLB is a review package; it is not
a measured runtime optimization or release build. Review shoulders, scarf
intersections and all action transitions at normal playing scale after an
approved swap. Native Blender rendering and headless imported-data checks are
separate evidence; Godot GPU shading/material parity still needs visible review.

## Proposed live replacement — approval pending

Install the reviewed candidate so the game uses the cleaned model instead of
v2. This is an asset replacement under `AGENTS.md`, so it requires Chase's
approval before editing active references. The concrete scope is:

1. Add `Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v4.glb` and its
   Godot `.glb.import` sidecar, using the checked candidate.
2. Change only the model resource path in
   `Src/Enemies/EaveRunner/eave_runner.tscn` and
   `Src/Enemies/EaveRunner/eave_runner_model_3d.tscn`.
3. Extend `tools/art/verify_eave_cleanup_v4.gd` to check those active model
   references and the existing wrapper compatibility, with its `.gd.uid` if
   generated by Godot.
4. Record import/encounter results in this report, `docs/project_status_and_worklist.md`,
   `docs/next_test_session.md` and `work/eave-runner-v4/runtime_verification.json`.

No gameplay scene-tree restructuring, attack timing, collision, stats, enemy
placements, equipment or lore changes are part of that proposal. The old v2
and v3 files remain available. Required live validation: import/reference
checks, existing guardian encounter/reset checks, art wrapper/animation checks,
then visible inspection in the actual game. Commit and push that separately
after the approved integration.

Checkpoint subject for this candidate:
`art: refine Eave Runner toward saved concept`.
