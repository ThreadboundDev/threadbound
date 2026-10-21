# Woven guardian art validation — October 20, 2026

The source verifier reopens `EaveRunner_Woven_v1.blend` in Blender 5.2.1 LTS.
It checks all vertices for real, normalized weights with at most four influences,
the 60-bone rig and six tail bones, absence of live authoring constraints, 13
packed images, matching mesh statistics, real bone motion and matching loop
endpoints. It samples the actual deformed mesh through every clip for finite
coordinates and plausible bounds. There are 156 source checks. The saved actor
has 66,052 triangles and 34,349 vertices; the glTF index counts are also compared
to the source report during packaging.

`tools/art/verify_eave_runner.gd` verifies the imported model in Godot 4.7.2,
including twelve clips, rig/cloth bones, actual motion and valid poses, loop
configuration, material tints/normal maps, wrist attachment, and pin visibility
and release. The final export slides every clip's first key to time zero so
Blender's frame-one offset does not delay the release relative to its marker.
The standalone review scene supplies no enemy AI or movement/damage physics.

The Forward+ run on the Radeon RX 6800 XT captures actual imported geometry from
the studio and side cameras, then a sampled sequence across all twelve clips.
The packaged verification record contains the exact pass/failure results and
capture paths. Body posing and side-view review prompted corrections to wrist
orientation, cloth blending and chest-binding fit before delivery.

The engine still reports texture cleanup diagnostics at shutdown, as it does in
the existing project. Those are separate from asset checks. This verification
does not claim combat behavior, wall-navigation AI, in-level encounter balance
or final art acceptance. Flying enemies remain concept images only.
