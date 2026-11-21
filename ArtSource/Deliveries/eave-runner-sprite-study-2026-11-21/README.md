# Eave Runner 2D sprite study

November 21, 2026. **Delivered for Chase's visual review.** Chase redirected
the front/back 3D-generation reference request into a frame-by-frame 2D enemy
study matching the original demo enemies. This is an art audition, not an
accepted replacement or a combat integration.

![Idle, run and slash animation comparison](preview/overview.gif)

## Delivery

- 24 individually drawn poses: eight idle, eight run, eight short-dagger slash.
- Three transparent 2048 x 1024 atlases, with eight 512 x 512 cells each, under
  [`Assets/BlueBiome/Enemies/EaveRunner/SpriteStudy`](../../../Assets/BlueBiome/Enemies/EaveRunner/SpriteStudy).
- A reusable, purely 2D `AnimatedSprite2D` model and a separate interactive art
  scene under [`Src/Tests/Art/EaveRunnerSpriteStudy`](../../../Src/Tests/Art/EaveRunnerSpriteStudy).
- [Idle](preview/idle.gif), [run](preview/run.gif), [slash](preview/slash.gif)
  and the combined comparison above. These GIFs show the actual registered
  drawings used by the Godot model.
- Original generated sheets in `raw/`, full prompts and references in
  `generation_prompts.json`, and registration details in
  `preparation_report.json` and the asset manifest.

The existing Eave Runner scene, v4 model, AI, attacks, collision, damage and
encounter placements are untouched. No 3D viewport or 3D model is used by the
new sprite model. Idle and run loop; the slash plays once and returns to idle.
Both facings use the same drawings, mirrored horizontally.

## Review

From the repository root in PowerShell:

```powershell
./tools/art/start_eave_sprite_study.ps1
```

This prepares and launches a small standalone Godot project under
`LocalOnly/EaveRunnerSpriteStudy/preview_project`. It uses an isolated user-data
directory, loads no main-game autoloads and does not touch gameplay saves.
Alternatively, open `eave_runner_sprite_study.tscn` in the main project and F6.

- `1`, `2`, `3`: idle, run, slash. The slash returns to idle automatically.
- Left/right arrows: move the artwork across the review stage and face it.
- Space: pause/resume. `F`: mirror. `G`: large / approximately 180px gameplay size.
- `A`: cycle the three clips automatically. The slider changes playback speed.

The arrow movement is only a presentation control; it is not enemy AI or
combat. Review at normal speed first, then pause/slow down to inspect poses.

## Source and preparation

The built-in image generation tool drew three alpha-backed sheets. The original
Eave Runner woven concept and v4 model supplied identity and clothing; extracted
Threadling, Tensioner and Loomkin frames supplied the demo sprite style. The
exact prompts are preserved, including the requested pose sequences.

```powershell
node tools/art/prepare_eave_sprite_study.cjs
```

The preparer uses `sharp` from Node's installed dependencies or the Codex
runtime. It does not repaint the images or invent intermediate poses. It finds
complete connected character drawings, including poses that cross the
generator's nominal grid boundaries, preserves alpha, and registers them on a
shared floor and character anchor. Per-clip scale and per-frame anchor data
are explicit in the script and manifest. The run retains airborne lift, while
the slash has a small authored visual lunge. Timing is shared between GIFs and
Godot, with shorter strike frames and longer anticipation/recovery.

The standalone `overview.png` is a convenience still extracted from the GIF;
the preparer regenerates the atlases, manifest, reports and four animated GIFs.

## Verification and remaining review

- All 24 complete drawings were extracted and fit within their registered
  canvases, with at least four pixels of margin. Transparent backgrounds are
  genuine alpha; no color key was applied.
- Godot 4.7.2 Compatibility on the RX 6800 XT passed **69 checks**, including
  frame resources and timing, real run advancement, one-shot slash recovery,
  mirroring, pause, both display sizes and four GPU captures. Final run produced
  no resource, script, logging or shader-cache errors.
- GIF metadata confirms eight frames per single clip and 32 frames at 70ms per
  frame in the comparison. Registered idle, airborne run, strike and left-facing
  strike captures were visually inspected.
- [Verification record](preview/godot/verification.json) and
  [GPU captures](preview/godot/) are retained.

Visual acceptance is pending. Generated cloth edges, mask details and body
volumes vary slightly between drawings; the study is not a promise of final
production animation. A wall perch/pounce, throwing, hurt/death, continuous
transitions and a full controller adapter would be separate work after review.
No live swap is authorized or claimed by this delivery.

Git checkpoint: `art: add animated 2d Eave Runner sprite study` on
`threadbound/art-eave-runner-sprite-study`. This completed study remains separate
from work-list T16's provisional v4-model acceptance.
