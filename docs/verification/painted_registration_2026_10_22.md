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

The two houses now register source-art floor contacts against the live floor
polygons. Horizontal registration keeps doors and inner walls aligned through
the house height; straight posts remain straight. The tower's nine platform
heights use individually measured source rows. A comparison-only UV lookup
fits the drawing to these anchors without editing original PNG pixels or moving
established collision. The original room, collision and player are unchanged.

Building cutaways now measure their own horizontal alpha crop. Reusing exterior
padding displaced the central tower cutaway by roughly 95 world pixels and
clipped its left edge. Missing roofs still retain empty vertical space; cutaways
are not stretched to replace their missing roofs.

The added worker/enemy sine bob is removed. Idle bulbs hold their registered
first frame rather than flipping between separate, differently drawn poses.
Existing enemy body/animation movement remains intact.

Validation: 13 actual shader contact rows match physical floor heights within
0.0001 world pixels (two states per house and nine tower platforms), independent
cutaway crop assertions pass, and camera drift remains at most 0.71 pixels.
`contacts_and_motion_after.json` records those results. The existing comparison
fixture again passes all 168 assertions and refreshes its 32 GPU captures.

These are contact-height checks, not a claim that every illustrated contour or
tower platform width exactly matches the model geometry. The tower's appearance
and overall 2D preference remain open for Chase's review.

## Further playtest feedback

Chase clarified that the mismatch was in the houses and could have been the
bouncing artwork. Enemies bounced too. The central building looked weird and
has not been accepted in 2D. Swordfish motion was clunky and needs more animation
frames; other enemies have not yet been reviewed. Finish the registration Git
checkpoint before that animation follow-up.
