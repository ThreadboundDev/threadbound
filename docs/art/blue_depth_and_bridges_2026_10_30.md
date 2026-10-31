# Blue depth and reusable bridge supports — October 30, 2026

Chase requested slow, far underwater rock with world-locked structural timber,
reusable in-game beams/bridges, floating pontoons and better attached high braces.
This follows the authorized 0.83 camera/upright-idle pass (`bed83ed3`) and its
delayed-variation fix (`017de695`). The current branch contains both.

## Delivered

- The 25 existing underwater rock sections now belong to a native Parallax2D
  at the same node path, behind the independent 15-section rear timber group.
  No child paths are reparented. Rock scrolls at **0.65 horizontally / 0.85
  vertically** relative to normal world motion. Timber, collision, bridges and
  actors retain normal world alignment.
- The existing anchored-parallax helper is reused. Original rock placement
  agrees at camera center (2048,1600), calibrated to the 1920 x 1080 base viewport.
  A world-space shader clips decorative rock below the lake's y=411 surface,
  including during vertical scrolling. Painted PNG pixels and the KRA are intact.
- Four existing near-water landings (`Deck05/07/08/09`) now use the reusable
  `pontoon_bridge_2d.tscn`: paired moored floats, iron bands and rope bindings.
  Their individual waterline offsets meet y=411. These are art on the existing
  static floors; a buoyancy/moving-platform system is not introduced.
- Five higher landings (`Deck01/02/03/04/06`) use `braced_landing_2d.tscn`.
  Their exported Support Anchor ends inside real rock collision, or the existing
  tower wall for Deck06. Points were ray-surveyed and then independently checked
  with physics overlap queries. A thin edge at Deck02 required a shallower inset.
- Existing deck surfaces, node paths, span widths and all nine world collision
  polygons are unchanged. The approved deck art is reused without the old short
  disconnected piles; timber grain for new structures comes from that same art.

These support the requested workflow: use Krita for distant scenery and paint
integration, and place repeatable structural assets in Godot where walking
surfaces and anchor points can be inspected together. Existing painted rear
timbers remain as background dressing. New bridge/support art is independent of
the painting. Selective foreground beams can be a later art pass; they should
leave landing edges and enemy tells readable.

[Floating bridge comparison](../../work/blue-depth-bridges-2026-10-30/floating-comparison.jpg),
[higher braces](../../work/blue-depth-bridges-2026-10-30/high-comparison.jpg),
[underwater comparison](../../work/blue-depth-bridges-2026-10-30/underwater_1-comparison.jpg),
[reusable asset view](../../work/blue-depth-bridges-2026-10-30/reusable-assets.jpg).

## Validation and limits

`tools/environment/verify_blue_depth_bridges.gd` passes **70 checks**: layer order,
section independence/local source coordinates, waterline clipping, unchanged
world collision polygons, all nine visual walking-plane alignments, four float
waterlines, five solid anchor endpoints and measured camera-relative motion.
For a 400-world-unit camera pan at zoom 0.83, timber moves 332 screen pixels while
rock moves about 215.8. Vertical motion is 85% of timber. The camera-center anchor
is checked directly. Native scroll-scale behavior is documented by
[Godot](https://docs.godotengine.org/en/stable/classes/class_parallax2d.html).

Forward+ captures of the actual painted comparison scene cover waterline bridges,
a high landing and an underwater camera pan. Captures were visually inspected;
they are not a hands-on movement or combat acceptance test. Existing air-pocket
tint boundaries and lake scene-ownership/shutdown diagnostics remain in the
baseline as well. This pass does not claim to resolve those broader issues.

The scoped underwater importer now preserves this presentation. Its pure scene
composition is idempotent, and the scoped application changes no painted PNGs.
Do not run the legacy full map/physics rebuild to reimport this layer.

The [data, tools and reproduction notes](../../work/blue-depth-bridges-2026-10-30/README.md)
record the evidence. Raw PNG captures are ignored; curated JPGs use Git LFS.
Normal saves/settings are preserved through task-local Godot user data.

Checkpoint: `art: separate underwater depth and anchor bridge supports` on
`threadbound/art-blue-depth-and-bridge-supports`. **Implemented; Chase's art and
feel review pending.** The new slash-VFX prototype remains a separate integration
task. T33/T20 acceptance is not closed by these automated checks.
