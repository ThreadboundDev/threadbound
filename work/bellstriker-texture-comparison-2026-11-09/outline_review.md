# Thin outline study

November 9, 2026. Chase compared the two texture deliveries and prefers the
Codex-painted version. This records texture preference, not approval to replace
the runtime Bellstriker or acceptance of its geometry, rigging, or animation.
Chase also supplied Tripo cartoon-style screenshots as the outline target.

The desired treatment has fine exterior contours and selective internal plate
overlap lines. The screenshot also appears flatter and brighter, so line width
alone should not be assumed to reproduce the entire presentation.

`preview_thin_outline.png` is an isolated Blender Freestyle study of the saved
painted model with its existing camera and lighting. Line thickness is 1.1 render
pixels, color (0.012, 0.016, 0.025), alpha 0.95; silhouette, border, contour and
external contour are enabled; generic crease detection is disabled. It preserves
the existing surface shading to isolate the line treatment. No game shader or
model was changed. This is not a tested Godot implementation or animation result.

Current Bellstriker uses a canvas alpha-silhouette outline; it cannot describe
internal plate boundaries by itself. The player uses expanded back-face geometry
with depth offset and separate object outlines. Matching the reference requires
judging both outer width and selected internal contours at gameplay resolution,
through motion and zoom, before applying any player change.
