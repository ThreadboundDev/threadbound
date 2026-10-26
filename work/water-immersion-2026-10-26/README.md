# Water immersion follow-up — October 26, 2026

Baseline: `49cd5b99`, before the water-presentation correction. `before.json`
records four expected failures: observer-dependent scenery/reflection fade,
weak actor immersion, and wakes behind actors. `before_*.png` are that run.

After: `verification.json` has 10 passing GPU checks. `after_*.png` show the
same fixture and actual 3D swimmer with the independent foreground veil.
`reflection/visible_reflection.json` records 6 passing GPU checks, including
moving source scenery after an earlier screen reader. `room/verification.json`
records 94 passing checks and eight authored-room captures. The independent
headless water-surface run reports 16 passing checks in the console.

Runtime: Godot 4.7.2 mono, Forward+, AMD RX 6800 XT; disposable APPDATA directories
under `tmp/water-immersion/`. All tests use the authored base room rather than
the locally edited comparison scene. Existing engine teardown/interpolation
diagnostics and the missing legacy glove Swim_Idle notice remain open under T04.
The first fixture scripts needed repairs before these final passing runs.

Reproduce with the repository's Godot executable and `--path .`:

```text
--script res://tools/environment/verify_water_immersion.gd
--script res://tools/environment/verify_visible_lake_reflection.gd -- --output=res://work/water-immersion-2026-10-26/reflection
--script res://tools/environment/verify_lakeside_water_delivery.gd -- --capture --output=res://work/water-immersion-2026-10-26/room
--headless --script res://tools/environment/verify_lakeside_water_surface.gd
```

The first three require a GPU. The current code cannot reproduce the old baseline
without checking out its source; `--baseline` only labels the output filenames.
Player appearance/feel still needs Chase's review. Reflections retain their
screen-space limitation when reflected scenery moves outside the camera view.
