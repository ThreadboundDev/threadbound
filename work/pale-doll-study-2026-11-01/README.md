# Pale lacquered doll: reference and isolated rig study

November 1, 2026. Chase selected the pale lacquered articulated doll, likes its
wear and tear, and likes both the hooded and exposed-head base outfits. He
authorized a consistent modeling reference and a simple separate 3D body test.
This delivery does not install a new player or implement modular equipment.

**Current revision: v2.** Chase corrected the first silhouette: the character
is a boy doll, or at least subtly masculine. The revised body has a flat broader
chest, straighter fuller waist, compact narrower pelvis and leaner upper thighs.
The worn finish, head, hands, joint positions and animation rig are retained.

## Review

- [Clean front T-pose](Threadborne_Pale_Doll_TPose_Front_v2.png): single unclothed
  front figure on white, with open hands and all joints visible, for 3D modeling.
  Chase likes the corrected v2 direction and requested this separate input image.
  [Generation prompt](clean_tpose_prompt.md). It is a generated visual reference,
  not a dimensional replacement for the measured rig or the actual mesh views.
- [Corrected modeling concept sheet](modeling_reference_masculine_v2.png): front, side, back and dressed
  front, plus head, hand and elbow details. Generated with the built-in ImageGen
  tool using the three selected references below. This is an illustration, not
  a dimensionally authoritative CAD turnaround. Use measured rig positions and
  the actual 3D views to resolve generated-view discrepancies.
  The [correction prompt](modeling_reference_masculine_prompt.md) is retained.
  The [v1 sheet](modeling_reference.png) and its [prompt](modeling_reference_prompt.md)
  remain as superseded shape references.
- [Selected pale doll](selected_pale_doll.png), [hooded outfit](base_gear_hooded.png)
  and [exposed-head outfit](base_gear_exposed_head.png): retained material/outfit
  references; their first body silhouette is superseded by v2.
- [Actual 3D rest views](body_rest_review.jpg): one geometry set seen from three
  orthographic directions. These are Blender renders, not generated images.
- [Actual source-animation poses](pose_review.jpg) and
  [run motion review](run_body_review.gif): body only, with no weapon or clothing.
- [Editable v2 Blender study](../../ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Study_v2.blend)
  and [v2 GLB](../../ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Study_v2.glb).
  Original v1 source/export files remain alongside them. Earlier
  [rest](v1_body_rest_review.jpg) and [pose](v1_pose_review.jpg) figures are retained
  for comparison; the unprefixed figures and reports describe v2.

The Blender file opens with the source `idle_4` action. Select the existing
actions in the Action Editor to inspect them; switch the armature to Rest
Position for the authored T-pose. Components remain separately named and
editable. The GLB joins compatible surfaces only for export.

## What the source inspection established

The production `threadborne_equipped_combat_swings.glb` has one 62-bone skin,
including 30 finger bones, and 48 animation clips. The clothed body is one
large textured surface, rather than an already separated mannequin and outfit.
The imported body has 464,260 vertices; this is an inventory count, not a
performance measurement. See [source inspection](source_inspection.json).

The new study is constructed around the source skeleton's exact rest joints.
It has rigidly weighted carved body pieces, shoulder/hip pivots, elbow/knee
caps, segmented fingers, and an integrated ivory head with two recessed eyes.
The native material uses a rest-coordinate attribute so procedural lacquer
wear remains attached during deformation. The export uses flat material
colors: the procedural Blender finish is not a baked game-ready texture.

## Validation and limits

[Build report](body_test_report.json) records 21 checks: retained bones/rest
transforms and source action curves, valid rigid bindings, normalized weights,
30 finger segments, two eye interiors, finite geometry, finite sampled poses,
and preserved bone lengths in six poses. The exported study has 34,516
triangles. The [export verification](export_verification.json) checks the saved
GLB independently against the production source with 18 additional checks.
The native action curves are unchanged. Export sampling can change a clip's
duration by up to 0.0334 seconds; this GLB has not been installed for gameplay.

The pose checks establish that the body can follow the existing skeleton;
they do not prove collision clearance, anatomical polish, weapon grip fit,
clothing fit, final performance or gameplay feel. There are visible overlaps
at complex joints and torso sections to refine before clothing production.
The captures use source clips, without the live visual's later upright idle/run
adjustments. No gameplay acceptance is claimed.

The existing player GLB, Blender sources, runtime script, equipment resources,
collision and game scenes are unchanged. `.gdignore` files keep the review
artifacts outside Godot's import graph. The GLB is an inspection/export artifact,
not a newly installed player resource.

## Next scoped step

Review the reference and body proportions, then refine shoulder/hip/torso
clearance and hands against the existing weapon sockets. Fit a separate starter
outfit with exposed elbow/knee details and hood variations only after the body
is accepted for that work. A production asset replacement or equipment-system
change requires its own concrete scope under `AGENTS.md`.

## Reproduce

Run background Blender; it will not open a visible window or alter a live file:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --threads 8 --python tools/art/build_pale_doll_study.py
& 'C:/Users/chase/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/art/package_pale_doll_study.py
& 'C:/Users/chase/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/art/verify_pale_doll_study.py
```

Source code and reports are committed alongside the selected concepts, native
study and review figures. Raw render intermediates and logs remain in ignored
`temp/`. PNG/JPG/GIF images in this work folder and the BLEND/GLB use LFS.

Checkpoint: `art: add pale doll modeling reference and rig study` on
`threadbound/art-pale-doll-model-study`. Body appearance and motion acceptance
remain Chase's review, separate from the technical checks.

Correction checkpoint: `art: correct doll study to subtly masculine proportions`
on the same branch; 21 build and 18 independent export checks pass again.

Clean reference checkpoint: `art: add clean boy doll front T-pose reference` on
the same branch. Visual review, PNG integrity, links and staged whitespace were
checked. This image delivery does not change the 3D source or its test results.
