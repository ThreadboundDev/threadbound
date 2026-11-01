# Threadbound modular building stamps v1

October 31, 2026. **36 painted stamps: 14 new components plus 22 matching pieces
from the current village library.** This is an art-authoring delivery for Krita.
It does not replace game art, alter tonight's build or add collision/door logic.

## Open these first

- [New components](catalog-new.jpg): plaster, timber, three windows, three doors,
  a straight blue eave and separate left/right curled roof returns.
- [Matching library parts](catalog-library.jpg): angled braces, supports,
  floating base, peaked roof, balconies/walkways, stone and five lamp styles.
- [Assembly example](assembly-example.jpg): a wide low building and a taller one.
- **`Building_Assembly_Example.ora`**: open in Krita, then Save As a `.kra` if
  desired. It has 34 separate named layers, including individual wall infill,
  beams, openings, roofs, lamp, background and guides. It is a sandbox example;
  continue your real level in its existing document.
- **`Threadbound_Modular_Buildings_v1.bundle`**: the importable brush collection.

## Import the brushes

In Krita, use **Settings → Manage Resource Libraries → Import**, choose the
`.bundle`, and make sure it is active. In Brush Presets choose the tag
**Village - Modular Buildings**, or one of its category tags. Click once to stamp;
use toolbar Size and Rotation. The PNGs are also usable directly as image layers.
These are full-color RGBA brushes, with one preset per image.
[Krita's resource-library instructions](https://docs.krita.org/en/reference_manual/resource_management.html).

The 22 reused preset files and brush bytes match the existing library. Their
filenames/checksums are retained so they identify the same resources; the new
14 use a `Village_MB_` prefix. The extension adds a modular-building tag. It does
not overwrite the existing installed bundle, plugin or resource database.
Import/activation into Chase's normal profile is left for his next art session.

## Composition workflow

1. Block out the building silhouette, floors and walking surfaces. Use a
   selection/mask for the plaster footprint; wall fills are ordinary flat
   material fields, not ready-made framed rooms.
2. Paint plaster on a rear **WALL INFILL** layer. W01 is cleaner cream, W02 is
   weathered/damp, W03 exposes woven lath at a chipped corner. W01/W02 intentionally
   fill their complete rectangular canvas; the remaining components have alpha.
3. Put uprights and crossbeams on **STRUCTURE**, covering wall joins. Add braces
   where their ends actually meet a post, wall or deck. Keep material scale
   consistent; repeat/crop a beam middle or paint a joint instead of stretching
   every detail to an extreme proportion.
4. Add windows and doors on separate **OPENINGS** layers. Current player height
   is roughly 185 world pixels; begin around 224–256 px door height. The example
   includes a 185 px scale bar. Scale to the level's existing 1:1 map workflow.
5. Add roofs on **ROOF / FOREGROUND**, then stone bases and walkways. The straight
   eave and curled returns are hand-painted components, **not mathematically
   seamless tiles**. Match tile pitch, overlap joining ends and paint over seams.
   The example uses a straight low eave and the existing peaked roof rather than
   implying every return snaps together automatically.
6. Put lamps on **LAMPS - keep separate for lighting**. For playable buildings,
   keep exterior facade, interior wall, front trim/rails, doors and lamps separate
   so we can reproduce the drawing's depth and cutaways in Godot later.

Draw any footprint you like with these pieces. A sketch or layered Krita layout
can be the reference for a later game assembly; stable piece placement and
separate interactive layers make that much easier. Stamped pixels alone do not
create collision, a working door, water exclusion or an engine light.

## Contents and provenance

`generated/` contains 14 new selected images made using built-in `image_gen`,
derived from `Assets/BlueBiome/Art/PaintedComparison/fisher_house.png` as a style
reference. Exact prompts and tool source locations are in
`generation_prompts.json`; selected PNGs are copied into this folder and are
independent of the external generated-image cache. Earlier wall drafts were
superseded with full-bleed material fills to avoid distracting extraction edges.

`reused/` contains 22 byte-identical PNGs from the existing Slate Village Library;
`reused_sources.json` records original paths and hashes. `preset_sources/` and
`preset_template.xml` preserve resource inputs for rebuilding. Original source
pixels are not repainted or recolored by the packer. It converts PNG → RGBA GBR,
creates labeled preset thumbnails and lays out the separate example layers.

Run `python build_kit.py`, then `python validate_kit.py` with Pillow installed to
rebuild/check the package. Validation checks all 36 source hashes, exact RGBA
brush pixels, 72 bundle resource checksums, preset-to-brush links and independent
recomposition of the ORA's 34 layers against its merged image. Catalogs and the
assembly were visually reviewed. Native-profile brush activation and actual
stamping acceptance remain for Chase; `validation.json` reports the file checks.
An isolated offscreen/minimal Krita CLI export attempt exited with Windows code
`0xC0000005` and produced no export. Native loading is therefore unverified;
the normal resource profile was not touched. Individual PNGs remain independent
of the bundle. The attempt and its result are under
`work/building-stamps-2026-10-31/` at repository root.

Godot ignores this source directory via `.gdignore`; installable resources and
art are tracked with LFS. There are no runtime project changes in this delivery.
