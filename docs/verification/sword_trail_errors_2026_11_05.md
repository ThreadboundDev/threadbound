# Sword trail triangulation errors

The development game log contained 632 instances of
`Invalid polygon data, triangulation failed.` from
`thread_sword_sweep.gd::_draw_strip_quad`. The strip was already split into
triangles, but each triangle was submitted through the general polygon
triangulator. Thin projected triangles at larger world coordinates could
fail that extra triangulation.

Submit the triangles directly with `draw_primitive`, keeping the existing
area filter, colors, sample lifetime, and subdivision.

The rendered regression test covers 36 strip cases with both winding
directions, zero and narrow areas, and origin, Chamber, and large world
positions. The previous implementation produces six triangulation errors
on those cases. The corrected implementation produces zero.

The existing rendered live attack test passes all six checks at fixed
60 FPS, including all three combo swings, bounded samples, matched timing
and hit polygons, whiffs, expiration, and a confirmed contact burst.
Run `tools/vfx/verify_live_thread_sweep.gd` with `--fixed-fps 60` so the
capture samples cover the full combo.

Existing texture/resource cleanup diagnostics remain at application exit.
Restart the game and clear the editor's retained debugger entries to review
a fresh session.
