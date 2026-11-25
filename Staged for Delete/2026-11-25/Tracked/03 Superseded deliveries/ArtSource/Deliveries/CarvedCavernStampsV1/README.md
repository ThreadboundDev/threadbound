# Carved cavern walkway stamps v1

November 2, 2026. Chase requests flat walking edges with jagged outcroppings on
the remaining sides, as though paths were carved from the cavern itself.
Six separate painted blue-gray stone PNGs, two each intended for short, medium
and long placements, plus a full-color Krita brush bundle. This is a new art
delivery for review; no existing game assets or scenes are replaced.

- [Catalog](catalog.jpg)
- [Importable Krita bundle](Threadbound_Carved_Cavern_v1.bundle)
- [Individual transparent PNGs](generated/)
- [Exact prompts and source provenance](generation_prompts.json)
- [Dimensions, hashes and packaging validation](manifest.json)

In Krita, Settings → Manage Resource Libraries → Import the bundle. Find the
tag **Cavern - Carved Walkways** in Brush Presets. Click once per stamp; adjust
toolbar Size as needed. Presets start at 384, 512, 768, 896, 1280 and 1408 px.
Those are brush canvas widths, including retained transparent padding, not
guaranteed exact walking lengths. PNGs can also be imported as image layers.
Align the visible top edges; overlap ends and mask joins into the existing cave.
These are varied painted pieces, not mathematically seamless tiles. Keep rock
facet scale consistent when combining pieces. Prefer cropping/overlapping long
pieces over stretching their texture sideways. Collision must be authored
separately if these are later integrated into the game.

The built-in image_gen tool made each asset using Chase's cave screenshot as a
material/style reference. S01 was revised to remove an obstruction above its
walking edge and the separate capstone seam. All selected source PNGs are copied
byte-for-byte from the generation cache. Packaging only trims fully transparent
outer margins for brushes and resizes previews; it does not repaint or remove
alpha. Very faint alpha remnants in some source margins are retained. Some
pieces have a stronger horizontal fracture beneath the top than S01; visual
acceptance of that treatment remains open. Top contours are visually level with
minor painted edge texture, not mathematically exact collision boundaries.

Run `build_kit.py` with Python and Pillow to rebuild. Validation checks full
alpha range, primary silhouette margins, exact serialized RGBA brush pixels,
ZIP integrity, resource hashes and preset links/color settings. Catalog and
generated images were visually inspected. Native Krita import and actual
stamping in Chase's document remain unverified. No normal Krita profile changed.

Checkpoint: `art: add carved cavern walkway stamps` on
`threadbound/art-carved-cavern-stamps`. Art Talk delivery only; this does not mark
the shared work list's ongoing organization/player tasks complete.
