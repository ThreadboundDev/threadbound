# Pale doll character base: v3

This separate character base follows the blank-head T-pose supplied on November
1, 2026, and the project's earlier pale lacquered doll and clothing references.
It preserves the subtly masculine proportions and is intended as a starting
point for fitting equipment, not as a replacement for the live player.

## Review and files

- [Front rest pose](body_rest_front.png), [side](body_rest_side.png),
  [back](body_rest_back.png), and [three-quarter](body_rest_three_quarter.png).
- Saved GLB reimport: [front](v3_export_front.png), [side](v3_export_side.png),
  [back](v3_export_back.png), and [three-quarter](v3_export_three_quarter.png).
- Existing-animation samples: [idle](pose_idle_4.png), [run](pose_run_1.png),
  [attack](pose_attack_1.png), [crouch](pose_crouch_1.png),
  [jump](pose_jump_1.png), and [grapple](pose_grapple_swinging_1.png).
- [Editable Blender source](../../ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Base_v3_final.blend)
  and [self-contained GLB](../../ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Base_v3_final.glb).
- [Source image and earlier studies](../pale-doll-study-2026-11-01/README.md).

The source uses separately named components, a blank oval head with center
stitches, an articulated-looking body, and individual modeled fingers and toes.
The GLB includes an embedded baked base-color texture. Blender retains the
procedural material and bump; that bump is not baked into the export.

## Scope and remaining work

This is a modeled and rigged **blockout for review**, with simpler shapes and
surface detail than the illustration. Proportion, silhouette, joint clearances,
and material appearance need Chase's review and further art polish. The rig
retains the original animation set, but each hand is currently weighted as one
rigid unit to avoid finger separation. The finger bones remain in the skeleton,
but they do not independently animate this hand geometry. A finger rig and
weighting pass, weapon grip checks, and clothing fitting are needed before
production use. No equipment or game scene is changed by this delivery.

The Blender source opens with an existing idle action; switch the armature to
Rest Position for the T-pose. The animation samples are snapshots of existing
clips and do not establish gameplay or continuous-motion acceptance.

## Rebuild and verify

Use background Blender to avoid changing an open editor session:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --threads 8 --python tools/art/build_pale_doll_base_v3.py
& 'C:/Users/chase/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/art/verify_pale_doll_base_v3.py
```

The build script generates the native file, export, pose renders and
[build report](body_test_report.json). The independent
[export report](export_verification.json) checks the saved GLB's geometry,
skin, skeleton, animation names and durations, and embedded color image. These
checks do not establish final appearance, clothing fit or gameplay readiness.
The final build passed 21 checks; the saved export passed 41 checks. It has
34,540 exported vertices and 48,140 triangles, and retains the original 62
joint names and rest transforms and 48 animation names and durations within
one 24 fps frame. This is a structural check, not a performance measurement.
The saved GLB was also reimported into Blender and visually inspected from
four angles. The color variation is subtle and the bump is Blender-only.
