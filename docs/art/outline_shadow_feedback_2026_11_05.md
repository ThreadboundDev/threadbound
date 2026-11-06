# Outline shadow and sword tip follow-up

Reviewed feedback `2026-11-06T01-56-38_6168_95920_2`, captured on November 5
at 20:56 America/Indianapolis. Read both report files, the screenshot, and
frames from the 14.399-second recording, including 1.15, 7.2, and 13 seconds.
The report contains 128 JPEG frames, zero logged errors, and one warning.
Camera zoom is approximately 3.96 in the still capture.

The previous character shader expanded fractional alpha into a translucent
second edge. It also sampled diagonals farther than the cardinal directions.
Use a circular sampling pattern and threshold source alpha into an opaque
silhouette stroke. This removes the faint shadow band around the dark edge.

The sword shell normalized projected normals. Near face-on tip surfaces then
expanded as far as genuine silhouette surfaces, creating separate black points.
Preserve the projected normal's length so those nearly face-on surfaces have
a smaller displacement.

Matching idle, run, and grapple captures render in Forward+ and Compatibility,
with additional pose samples at a later animation time in Forward+.
The local review directories are `LocalOnly/Equipment/OutlineReview/`,
`OutlineReviewCompatibility/`, and `OutlineTurnReview/`.
The captures show a firm character edge and a more restrained sword edge.
Hands-on acceptance in the lit Chamber remains open.

The live weapon uses the downloaded sword and the fitted forearm shield.
The shield's front retains the imported ornament geometry. The fitted shield
back has two arm straps. Removing front ornaments would replace asset geometry
and remains a separate art cleanup decision.

Existing resource cleanup diagnostics still appear at test shutdown.
