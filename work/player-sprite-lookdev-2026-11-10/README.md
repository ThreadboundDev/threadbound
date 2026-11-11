# Player rendered-sprite comparison — November 10, 2026

Status: **Awaiting Chase's visual review.** This is a requested rendering-only
proof using the retained detailed character. It does not select a final art
direction, replace the current player, or change equipment or combat systems.

## In-game movement preview follow-up

Chase subsequently requested seeing the character in game. `play_preview.gd`
now supplies an isolated movement trial in the actual Chamber using the existing
controller, HUD and camera. It hides the original presentation only at runtime
and follows the player with the rendered idle/run/jump atlases, including facing.
The production scene/controller remain untouched. Combat, grapple and equipment
swap animations are unsupported in this trial; other controller states use the
available movement images. This is not a complete player conversion.

From the prepared `import_project/`, launch Godot with
`--path . --script res://review/play_preview.gd --rendering-method forward_plus`.
Use the normal movement bindings. Append `-- --verify` for the automated trial.
Six checks passed for initial grounding, movement distance, run selection,
airborne state, jump selection and landing. See `play_validation.json` and
`play_idle.png`, `play_run.png`, `play_jump.png` for evidence.

## Review these first

- [Original sprite / retained model / illustrated render](comparison.png).
- [Actual Chamber: original reference beside the rendered study](chamber_reference_pair.png).
- [Actual Chamber: assembled sword-and-shield sprite](chamber_rendered.png).
- [Idle](idle_preview.gif), [run](run_preview.gif), [jump](jump_preview.gif).
- [Sampled animation poses](motion_contact.png).
- [Side and three-quarter equipment views](equipment_comparison.png).

The comparison uses equal standing display heights, including a 180 px strip.
The original reference and the new reference pose are different artworks and
poses; they are not pixel-registered copies. The middle and right panels use
the identical mesh, pose and camera, isolating the material/outline treatment.

## What changed in the experiment

Retained input:
`ArtSource/Player/Blender/imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend`.
Its packed textures, detailed 982,421-vertex body, rig and equipped animation
library are reused. Its SHA-256 remains
`b6de66d8ae292024ec6a8e18401b1cbe2fe1da9fb23f170323b136817aee002b`.
No existing `.blend`, mesh, rest skeleton, clothing, or runtime asset is saved
over. The scripts define the reproducible experimental materials and camera;
there is no duplicate model source to maintain.

The experiment substitutes broader normal-based shading and restrained ambient
occlusion for the model's metallic/specular and normal-map response. It warms
the ivory and leather and changes texture-value contrast. The relaxed
reference pose lowers the arms without altering rest bones or geometry.

The exterior black edge is deterministic circular alpha growth, composited
behind the assembled character. Radius is three pixels on the 600 × 800 render,
equivalent to about 1.2 pixels at the 0.4 review/game scale. This is the same
type of operation as Chase's Krita silhouette-growth process; its numeric
source radius should not be compared without accounting for image scale.
It preserves interior painted texture detail but does not create a separate
internal sword/body contour.

The shader and outline improve separation, but the reference still has a
larger, rounder head, broader hands and simpler clothing. The retained model
has a narrower head and long ragged panels. Rendering alone does not fix
those differences. No shape-correction pass is approved by this delivery.

## Animation output and remaining questions

There are 51 fixed-canvas samples: 31 idle, nine run and 11 jump, at approximately
12 fps using the original clip durations (77, 22 and 26 source frames at 30 fps).
All frames retain a 600 × 800 render canvas and are uniformly reduced to
240 × 320 cells. The atlas metadata identifies every cell, source frame and
duration. No frame is independently trimmed or rescaled. Baked airborne pelvis
lift is removed from jump, following the earlier Godot export convention;
future world movement remains the controller's responsibility.

These are the earlier transferred motions, not newly authored animations or a
demonstration of the full current library. Pose deformation, foot contact,
transitions and timing still need review. The reference source has unfinished
cloth/shoulder/hand behavior. Grapple motion, attacks, both facings, mixed gear,
equipment masks and upper/lower-body combinations are not established here.
One assembled outfit avoids introducing those production questions into the
initial look comparison.

## Actual-engine evidence

`capture_chamber.gd` instantiates the actual
`Src/Environment/World/Chamber Of The First Weave.tscn`, lets the existing player
settle on its floor, and freezes the scene for matched visual captures.
It temporarily hides that player and displays the rendered image in the same
scene. This is a frozen-scene visual study, **not a playable sprite-controller
integration or gameplay acceptance**.

`prepare_preview.ps1` makes an ignored `import_project/` using local junctions
to the existing resources and import cache, with a distinct project name and
save directory. It copies the project configuration and cache metadata; it
does not edit production project files. The review must be run from that
isolated project. Do not run an editor import scan through the junctions.

The final captures use Godot 4.7.2 Forward+ on the RX 6800 XT. Both reference
sprites preserve baked colors through an unshaded canvas material. The
additional [lit variant](chamber_rendered_lit.png) demonstrates the Chamber's
2D lights applied on top of baked shading. This is an experimental comparison,
not a decision about production light response. The actual
[current-player baseline](chamber_current.png) receives its normal lighting.

Capture assertions passed, and the four images were visually inspected.
The engine reported a camera interpolation warning and shutdown cleanup
diagnostics: null RenderingServer during CompressedTexture2D teardown,
texture RID leaks, ten ObjectDB instances and five resources still in use.
No script parse/runtime failure occurred during the successful capture.
Similar standalone shutdown diagnostics are documented elsewhere in the
project; this delivery does not resolve or certify their origin.

## Reproduce

Using installed Blender and Python with Pillow:

```powershell
& $blender --background --factory-startup --python work/player-sprite-lookdev-2026-11-10/inspect_source.py
& $blender --background --factory-startup --python work/player-sprite-lookdev-2026-11-10/render_study.py
& $blender --background --factory-startup --python work/player-sprite-lookdev-2026-11-10/render_study.py -- motion
& $python work/player-sprite-lookdev-2026-11-10/package_study.py
& ./work/player-sprite-lookdev-2026-11-10/prepare_preview.ps1
```

Run the Godot executable from `import_project/` with:

```text
--path . --script res://review/capture_chamber.gd --rendering-method forward_plus --audio-driver Dummy --resolution 1280x720
```

Use a hidden background process for unattended capture. Existing display
settings can resize the actual captured framebuffer to 1920 × 1080. The
preview project needs permission to create its own user-data directory.

The `.gdignore` prevents this art package from entering normal Godot imports.
Review images, raw frames, atlases, manifests, source inspection, render
recipes and validation are retained together. Temporary logs, the local
baseline-status snapshot and isolated linked project are excluded from Git.

Checkpoint: `art: render player sprite comparison from retained rig` on
`threadbound/art-player-sprite-lookdev`. Production appearance and any next
shape changes await Chase's decision.
