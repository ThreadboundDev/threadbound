# Painted comparison playtest corrections — October 22

Chase reports incorrect collision alignment and bouncing 2D artwork during the
first hands-on T18 test. Earlier 168 assertions established that collision stayed
unchanged, but did not establish visual contact alignment or motion stability.
T18 is not accepted.

## Camera drift

The painted SubViewport Camera2Ds and interpolated output sprites independently
resampled the main camera. On moving, smoothed camera paths, a marker drawn through
the painted pass drifted from a direct world marker:

| FPS cap | Before: maximum drift | Fixed: maximum drift |
| --- | --- | --- |
| 30 | 9.22 px | 0.71 px |
| 90 | 17.20 px | 0.71 px |
| 144 | 11.72 px | 0.71 px |

Each case measures 45 actual GPU frames with physics interpolation enabled and
camera smoothing. The fix uses the main canvas transform directly, supersampled,
and disables duplicate interpolation on comparison output sprites and cameras.
Only the comparison controller changes; the original room and gameplay are intact.

Fixture: `tools/environment/verify_painted_registration.gd`.
Evidence: `work/painted-registration-2026-10-22/motion_before.json` and
`motion_after.json`. Vulkan / Forward+, Godot 4.7.2, RX 6800 XT.
Existing texture RID / six ObjectDB / three resource teardown diagnostics remain;
these results do not claim to fix T04 shutdown cleanup.

## Contact alignment

Still under investigation: overall image-envelope registration does not align
every painted floor/platform to its original physical surface. The tower in
particular needs individual platform contact anchors. Do not move established
collision just to accommodate the comparison artwork.
