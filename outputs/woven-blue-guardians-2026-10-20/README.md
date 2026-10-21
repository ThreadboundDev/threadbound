# Woven Blue guardians — October 20 art pass

Chase authorized a rigged, animated wall-assassin asset and requested flying
enemy concepts. The earlier Reedhook is still a prototype and its enemy design
is not accepted for further production. Keep that placeholder until a deliberate
replacement decision; this pass does not replace it or alter its combat.

## Faction and visual direction

The Eave Runner now explores the Hermit's guardians as visibly woven beings:
dark cord bundles for exposed limbs and fingers, tied joints, an ivory ceramic
face, short indigo cloth tails and a repeated paired binding knot. Human villagers
provide contrast and keep the settlement inhabited. A shared cloth color alone
does not define allegiance.

The enemy's visual affiliation is the Hermit's faction. Its exact maker remains
unspecified. Being woven does not automatically make it one of the Weaver's
Frayed. This is a visual proposal consistent with the
enemy context direction (`docs/design/enemy_factions_and_world_context.md`), not a
new account of how the Hermit or Weaver created life.

## Delivered wall-assassin art

Editable source:
`ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v1.blend`.
The file includes the deform rig, named material slots, packed images, animation
actions and review lights/camera. The floor and reference wall are review-only
objects and are excluded from the runtime export.

Runtime model:
`Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v1.glb`, with shared external
PNG textures in the adjacent `Textures` directory. Keep that directory with the
GLB when importing elsewhere. The art prefab is
`res://Src/Enemies/EaveRunner/eave_runner_model_3d.tscn`.

The skeleton has 60 deform bones, including fingers, blade/pin attachments and
three bones for each of the two short cloth tails. There are ten material
surfaces. Mesh counts are recorded in `build_report.json`; images are at least
1024px, with newly generated 1254px cord/ceramic color maps and existing village
4K wood maps. Mipmaps, normal maps and high-quality VRAM compression are enabled.

| Clip | Nominal seconds | Purpose |
| --- | ---: | --- |
| `idle` | 2.40 | Ready stance with breathing and small cloth motion; loops |
| `run` | 0.80 | In-place repositioning gait; loops |
| `wall_attach` | 0.35 | Transition to wall contacts |
| `wall_perch` | 1.60 | Braced wall stance; loops |
| `wall_windup` | 0.45 | Coiled launch anticipation |
| `wall_launch` | 0.30 | Push away from the wall |
| `jump_slash` | 0.65 | Committed arm/blade sweep with tucked legs |
| `land_recover` | 0.60 | Crouched landing into ready stance |
| `throw_windup` | 0.45 | Draw the throwing hand back |
| `throw_release` | 0.35 | Release the held pin and follow through |
| `hurt` | 0.40 | Short recoil |
| `death` | 1.20 | Collapse toward a kneeling pose |

Times are quantized to 30fps. Authoring event markers and proposed seconds are
saved in `animation_events.json`. They describe future attack timing; they do
not create hitboxes or projectiles. All clips are in place. A future gameplay
controller must move the character and align its wall contacts. Local forward is
-Y in Blender and +Z in Godot; the wall-brace reference is behind it, local -Z
in Godot. The weapon stays on the right wrist; the free left hand braces or throws.

This delivery is the animated art asset. Wall detection, navigation, jump
physics, damage, projectile spawning, combat interruption and level placement
remain combat-integration work. There is no new playable enemy controller in
this pass. The first model and its animations remain subject to art/feel review.

## Review in Godot

Run `res://Src/Tests/Art/eave_runner_art_review.tscn` with F6. Choose a clip,
replay it, cycle the set, or toggle the gameplay side view. The source's wall
reference appears for the wall clips. The review shows the actual imported
skinned model and materials, not the concept image.

The supplied animation GIF is captured from this Godot review. The studio PNGs
come from the saved model in Blender. Concept sheets are separate references.

## Flying-enemy options — concepts only

The concept board is
`outputs/woven-blue-guardians-2026-10-20/Woven_Flying_Concepts.png`.

**A — Loom Heron:** reed/wood spars, broad indigo fabric wing panels, pointed
ceramic face and short cord feet. It perches near roofs or water, telegraphs a
diagonal dive, commits to the line and brakes into a reachable recovery. It is
the recommended common flyer: a clear bird shape tied to a fishing settlement,
with a different movement space from the indoor assassin.

**B — Bobbin Moth:** a compact wound-thread spindle with four framed cloth wings
and a small ceramic face. It provides slower hovering pressure, visibly draws
back, then releases one straight needle before repositioning. Its dark spindle
body avoids the luminous globe/petal silhouette of friendly Water Bulbs.

Both designs share the woven construction and binding mark without human
anatomy. Their working names, attacks and faction roles remain proposals. They
are not modeled, rigged or implemented yet; this request asked for flyer concepts
to choose from. Select a direction before producing its 3D assets.

## Sources and reproduction

`tools/art/build_eave_runner.py` authors the model and animations in background
Blender. `tools/art/import_eave_runner.py` packages standard glTF material tints,
externalizes images without modifying mesh/animation buffers, and imports only
these new assets through an isolated project.

The existing CC0 MakeHuman base and weights provide the fitting/deformation
surface, with a new reduced skeleton and remapped weights. Its source/license
records remain in `ArtSource/BlueBiome/Villagers/CC0_Source`. Garments, mask,
cord geometry, bindings, weapons and animation are authored in the builder.
No MakeHuman program code is incorporated. Village textile/wood detail maps
are reused. Two new color maps and two concept sheets were generated with the
built-in image generation tool. Exact prompts, references and mode are saved
beside the Blender source in `generation_prompts.json`; provenance includes
hashes and image dimensions.

Source validation samples actual saved skinned geometry and verifies deform
weights, packed textures, real motion, plausible bounds and loop endpoints.
Godot validation checks the imported skeleton, clips, cloth bones, material
tints, normals, wrist attachment and pin release, then captures the actual
Forward+ renderer. Detailed results are in the review delivery's verification
record. Existing engine texture cleanup diagnostics at shutdown are recorded
separately from asset checks.
