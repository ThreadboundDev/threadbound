# Tower exterior-water correction — October 27, 2026

Approved exterior-water plan, preserving the dry interior. Baseline source:
`9f09f306`. `before.json` records seven expected failures in 27 checks. The
before images reproduce the bright dry wedge outside the closed tower.

`verification.json` records 33 passing GPU checks. Compare `before_left_exterior`
and `after_left_exterior`, plus the below-approach and dry-interior PNGs.
`after_dry_platform.png` shows the real player standing dry on an existing floor.
The final fixture also checks returning to swimming and closing the dry mask.
The front stone still occludes about 96% of the test silhouette at the opening.
Building collision signature and physical air-pocket polygon match the baseline.

`room/verification.json`: 97 passing GPU water-room checks / eight captures.
`reflection/visible_reflection.json`: 6 passing reflected-pixel checks, including
source movement despite an earlier screen reader. The independent headless
surface run reports 16 passing checks to the console.

Godot 4.7.2 mono, Forward+, RX 6800 XT, disposable APPDATA under
`tmp/oct27-playtest/`. Run from the repository root with its Godot executable:

```text
--path . --max-fps 60 --script res://tools/environment/verify_tower_water_exterior.gd
--path . --max-fps 60 --script res://tools/environment/verify_lakeside_water_delivery.gd -- --capture --render-scale=0.5 --output=res://work/tower-water-exterior-2026-10-27/room
--path . --max-fps 60 --script res://tools/environment/verify_visible_lake_reflection.gd -- --output=res://work/tower-water-exterior-2026-10-27/reflection
--path . --headless --script res://tools/environment/verify_lakeside_water_surface.gd
```

The first three require GPU rendering. The scenery verification scale is reduced
beside the open editor/game; project rendering defaults are unchanged. Baseline
images require the baseline source; `--baseline` only changes output filenames.
Initial fixture setup/ROI issues were repaired before the saved passing result.
Existing engine teardown/interpolation diagnostics and the missing legacy glove
Swim_Idle notice remain T04. These checks do not accept appearance on Chase's behalf.
