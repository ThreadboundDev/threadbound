# Eave Runner v4 model cleanup

October 21 candidate, installed October 22, 2026. Task T16. Built from the
saved v3 source on top of `96b2c039`; candidate checkpoint `4f8c79dd` retained
active v2. Chase subsequently approved installing v4, accepting it for now
while explicitly noting remaining roughness. Gameplay and the art-only scene
now use v4. Further art polish and hands-on acceptance remain open.

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
approved swap. The later Forward+ wrapper captures below provide actual Godot
shading evidence; normal-scale play and frame-time acceptance remain open.

## Approved live replacement — installed October 22

Chase approved the documented swap: "Yes you can swap it. It still is rough
but I guess ill get over it for now lol." This is provisional acceptance of
the current iteration, not a claim that it fully matches the concept. Approved
scope, implemented after that approval:

1. Added `Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v4.glb` and its
   Godot `.glb.import` sidecar, using the checked candidate.
2. Changed only the model resource path in
   `Src/Enemies/EaveRunner/eave_runner.tscn` and
   `Src/Enemies/EaveRunner/eave_runner_model_3d.tscn`.
3. Extended `tools/art/verify_eave_cleanup_v4.gd` to check those active model
   references and the existing wrapper compatibility, with its `.gd.uid` if
   generated by Godot.
4. Recorded import/encounter results in this report, `docs/project_status_and_worklist.md`,
   `docs/next_test_session.md` and `work/eave-runner-v4/runtime_verification.json`.

No gameplay scene-tree restructuring, attack timing, collision, stats, enemy
placements, equipment or lore changes were made. The old v2/v3 exports and all
native sources remain available and hash-identical. The only changes to the
two active scenes are their model resource paths.

### Packaging and validation

`tools/art/install_eave_cleanup_v4.py` packages the checked candidate through
the existing isolated-import utilities. All fifteen embedded texture entries
match thirteen existing canonical PNG files byte-for-byte. The runtime GLB
references those maps, rather than duplicating them: **13,704,428 bytes**, down
from the self-contained review package's 224,900,208 bytes. All **1,995 remaining
geometry/animation buffers** and material parameters are verified unchanged.
This is packaging deduplication, not a measured frame-time improvement. No new
texture files or edits to existing textures/sidecars are required.

Reproduce package/import with Python `tools/art/install_eave_cleanup_v4.py`
using `package`, then `prepare`; run Godot `--headless --editor --import` on
`tmp/eave_cleanup_v4/runtime_import`, then run the tool's `install` mode. It
checks source checksums and imported caches before installing the new sidecar.
It does not edit scene references. The saved candidate/source remain untouched.

Godot 4.7.2 stable mono, isolated `APPDATA`, installed resources:

| Check | Result |
| --- | --- |
| `verify_eave_cleanup_v4.gd -- --runtime` | 271 checks pass: topology, bones/clips, both scene references, wrapper, material maps/normal strength, camera, body/hurtbox/attack geometry |
| Same fixture, `--runtime --render-preview`, real Windows Forward+ | 276 checks pass; idle/slash GPU viewport captures inspected |
| `tools/enemies/verify_woven_guardians.gd` | 134 checks pass: wall attach/perch/leap/slash/recovery, fallback pin, interruption, contact/terrain and save reset |
| `tools/enemies/verify_woven_lakeside.gd` | 19 checks pass with the real player/authored room, repeat wall leap, encounter damage and F2 restoration |

[Actual Godot idle](../../work/eave-runner-v4/runtime_renders/idle.png) and
[slash](../../work/eave-runner-v4/runtime_renders/jump_slash.png) use the unchanged
1536-square gameplay wrapper, span 3.8, yaw 72 degrees, 4x MSAA and 96 game
pixels/metre. Render device: AMD Radeon RX 6800 XT, Vulkan 1.4.315, Forward+.
The files are full-resolution transparent viewport captures, not whole-room
screenshots or Chase's hands-on acceptance. Cloth, bracers, mask, blade and
textures resolve; no missing material or detached weapon appeared in these
two sampled poses.

Diagnostics remain explicit: the lakeside fixture reports camera/interpolation
warnings, six ObjectDB instances and three resources in use at shutdown, as
previously recorded. The GPU fixture also reports one TextureStorage RID,
two Texture RIDs and a CompressedTexture2D teardown message about a null
RenderingServer. These are not assertion failures, but are unresolved shutdown
diagnostics for T04; they are not declared harmless. No in-play script failure
was observed in the exercised checks. Normal gameplay appearance, remaining
rough art and measured performance remain separate review items.

Checkpoint subject for this candidate:
`art: refine Eave Runner toward saved concept`.

Approved installation checkpoint subject:
`asset: install approved Eave Runner v4`.
