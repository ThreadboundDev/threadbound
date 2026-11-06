# Blue outline and idle return

Reviewed report `2026-11-06T01-59-28_6168_265848_4`, captured November 5 at
20:59 America/Indianapolis. It includes the screenshot, 162 recording frames
over 18.72 seconds, and diagnostics showing zero errors and one warning.
Full Blue gear is equipped. Camera zoom is approximately 4.95.

The report was captured at source commit `21b2df33`, before the shared
outline corrections in `2d6a5115`. It confirms the same faint outer shadow
and split sword tips on Blue. Current Compatibility captures for Blue idle,
run, and grapple are in `LocalOnly/Equipment/BlueOutlineReview/`.
They use the corrected circular alpha expansion and restrained sword shell.

The title also reports the sword snapping when idle returns. The existing
14-degree idle hand correction was applied at full strength as soon as the
current action changed to `idle_4`. It bypassed animation blending.
Ease that correction in and out over 0.15 seconds during idle variations.
Other gameplay actions reset the idle correction.

A real-player headless check verifies both endpoints and both directions of
the transition. The maximum correction step at 60 FPS is 1.56 degrees,
compared with the previous single 14-degree step. Hands-on review of the
complete idle sequence remains open. Existing resource cleanup diagnostics
still appear on test exit.
