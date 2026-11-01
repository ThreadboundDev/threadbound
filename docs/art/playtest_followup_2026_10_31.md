# October 31 playtest follow-up

Chase accepts the run animation. Spin should travel farther, with a higher,
larger waist-level sweep; enlarge the special effect family. Leading Identity
color extending the visible gesture is a future visual direction, not new
damage reach or an approved rewrite of Identity color rules.

The 27.58-second test video was visually reviewed in three-second samples across
its full duration. It shows the reflection/reveal crossing and camera-attached
rear-rock movement; the six screenshots additionally identify facade clipping,
backdrop covering tower interiors, dry-room water masking and solid-rock trapping.
The complete clip was not listened to or watched continuously.

## Collision fix

Double-Down previously disabled terrain layer 1 and teleported the body 18 units
down, even on solid floor. The fix accepts only verified one-way floor shapes,
temporarily excludes their specific physics bodies and sweeps the nudge against
other terrain. It preserves the entire collision mask. A local recent-clear
position history restores deep overlaps to a verified clear point on the recent
approach; external teleports reset that history. It does not search random free
space across walls. Recovery respects ordinary collision exceptions and debug
noclip. Thirty-one engine checks pass for repeated solid-floor rejection,
legitimate platform drops onto rock, exception expiry and overlap recovery.
The house handoff regression exposed the need to assign the complete physics
query exclusion array at once; this was corrected and covered explicitly.
All 20 house handoff checks now pass again.

## Water, tower and roof delivery

The rear rock now scrolls at 12% of ordinary world movement on both axes and
draws behind the building composite. It is no longer pinned to the camera or
painted over a revealed tower wall. The importer retains the same settings.
Water reflection distortion and time-driven shimmer/caustics are static;
existing body crossings and movement still produce local ripples/bubbles.
The 22-check GPU fixture verifies fixed undisturbed samples and dry building
contents even while the observer's head is above water. Active linked building
masks always exclude front water; open cave masks retain the observer reveal.

Tower occupancy reuses the existing interior focus helper, zooms closer, follows
vertical progress and dims outside scenery to 8% brightness. Leaving restores
the previous camera. Eight real-room GPU checks, 31 tower/exterior checks,
20 house handoff checks and 78 room/depth/bridge checks pass. All 148 world
collision polygons exactly match the baseline. [Below-water interior](../../work/oct31-feedback/tower_below.jpg)
and [upper interior](../../work/oct31-feedback/tower_above.jpg).

The fisher-house atlas rectangle omitted the last part of the closed roof.
Its crop is widened from 715 to 730 pixels, with its world envelope extended
proportionally and contact registration updated to preserve existing pixel scale,
door and floor contacts. The approved PNG is unchanged.
[Roof render](../../work/oct31-feedback/fisher_roof.jpg).

Existing packing/camera-interpolation/shutdown diagnostics remain. Captures use
1x building rendering and isolated save profiles. Static samples and fixtures
do not replace Chase's moving review of water crossing, rocks and tower traversal.
## Spin and special delivery

Spin dash speed increases from 420 to 560. A matched actual-physics land fixture
travels 214.67 world units versus 161.00 at the old speed (33.3% farther).
The visible spin sweep rises 28 world units toward the waist and grows 25%.
Neutral special, grapple burst and grapple trail also grow 25%. Their damage
radii, AP, animation/active windows and lifetime are retained. VFX extensions
are presentation and do not expand damage reach. Identity-colored leading edges
remain the recorded future direction; no new color-mixing rules are introduced.

Thirty-two GPU attack-family checks pass, including both vertical attacks and
facings, raised/enlarged spin, neutral scale, specials in both media, cleanup and
the matched movement comparison. The existing underwater neutral/left/right
special regression passes its source-motion, anchor, movement, AP, damage,
medium-transition and cleanup assertions.
[Special comparison](../../work/oct31-feedback/specials-comparison.jpg).

Implementation is delivered for Chase's moving review. Collision checkpoints:
`4ea92971` and `f6a8b30e`; water/tower/roof checkpoint: `129660c1`.
Keep T40 acceptance open until the retest; the accepted run is preserved.
