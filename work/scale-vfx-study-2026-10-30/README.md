# Character scale and original sweep study — October 30, 2026

[Findings and next-step scope](../../docs/design/character_scale_and_vfx_study_2026_10_30.md).

- `camera-comparison.jpg`: actual demo/Blue cameras, runtime-only 0.83 preview,
  and an attributed Belmont reference frame.
- `posture-comparison.jpg`: the same character at equal displayed body height.
- `environment-scale.jpg`: current Blue house and preserved 3D trial context.
- `combo-comparison.gif`: current vs candidate, normal-speed combo, 20 fps.
- `vfx-comparison.jpg`, `vfx-left-facing.jpg`, `vfx-gameplay-scale.jpg`:
  matching stills, true left-facing samples and a full-screen composition.
- `existing-hitbox-overlay.jpg`: existing damage geometry over the candidate.
- `thread_sweep.gd`: original procedural effect, accepting blade points and
  explicit contact events. No copied game art, damage or collision code.
- `vfx_review_driver.gd`: isolated adapter observing the current player and
  issuing its existing public attack/queue calls. Contacts are illustrative
  timer events; the stage has no enemies or successful damage events.
- `measurements.json`, `validation.json`: measurements and capture invariants.
- `reference-library-03h19m55s.jpg`: attributed BeardBear walkthrough frame
  used only for the camera comparison. Source/timestamp are in the measurements.

No production files under `Src/` or `Assets/` are modified. `.gdignore` keeps
this review package outside normal Godot importing. Scripts are explicitly
loaded by the command-line fixtures; the main game never loads them.

From the repository root in PowerShell:

```powershell
./work/scale-vfx-study-2026-10-30/run_review.ps1
```

The helper finds the local Godot console engine and Codex Python runtime.
Override `-Engine` and `-Python` on another machine (Godot 4.7.2 and Python 3
with Pillow). It renders sequentially, redirects `APPDATA`/Godot `user://`
into ignored task scratch, and restores the environment afterward. Close
unneeded game/editor instances first to leave GPU memory for the full scenes.
It does not close apps, save scenes, install dependencies or alter real saves.

Use `-BuildOnly` to package existing raw captures. Raw frames/logs stay in
ignored `tmp/scale-vfx-study`; only curated evidence is versioned. The single
reference frame used by the camera figure is included in this research package;
the source provenance is in the measurements and
[prior research](../../docs/design/belmonts_curse_reference_study_2026_10_30.md).
It is not a production asset. Run against an already imported working project.

Captured with Forward+ on RX 6800 XT for production, Compatibility for the
independent 3D trial. The current project logs known texture/ObjectDB shutdown
leaks even for the baseline fixture; these are recorded as limitations rather
than labeled a clean engine log. Custom study scripts finish without parse,
runtime or polygon triangulation errors. Appearance/feel acceptance remains
Chase's review.
