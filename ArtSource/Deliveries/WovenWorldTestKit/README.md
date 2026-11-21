# Woven low-poly world test kit — November 20, 2026

Chase authorized a small reusable kit and an in-game comparison after reviewing
the woven lakeside concept. The direction is dimensional low-poly forms with
directional, interlaced surface lines. Trees and foliage carry the strongest
treatment; stone uses restrained mineral striations. Existing Blue identity,
wooden player identity and gameplay remain the reference.

This is an art audition. Production art is not replaced, and visual acceptance
remains pending Chase's playtest.

## Open the test

In Godot, open `res://Src/Tests/Art/WovenWorld/woven_world_review.tscn` and press
**F6**. Alternatively, from the repository root:

```powershell
& tools/art/woven_world/start_review.ps1
```

- **1 / 2:** switch between the lakeside grove and rock garden.
- **T:** expose terrain cell boundaries, walkable edge and collision shapes.
- **R:** reset position in the current view.
- Use normal movement, jump and other existing player controls.

The scene instances the actual `Src/Characters/Player/player.tscn`, including
its live modular wooden doll and current equipment. It contains no save points,
enemies, pickups or progression triggers. It reuses the existing StillVillage
sky/cliff and village background textures so this audition focuses on the kit.

## Delivered artwork

Runtime files are in `Assets/BlueBiome/Art/WovenWorldTestKit/`:

| File | Purpose |
| --- | --- |
| `tree.png` | One full interlaced timber/cherry tree |
| `foliage_green.png` | Ground leaves and fern cluster with directional veins |
| `foliage_blossom.png` | Separate flowering branch cluster |
| `rock_low.png` | Broad low boulder |
| `rock_wide.png` | Moss-topped slab used on raised platforms |
| `rock_tall.png` | Tall irregular framing rock |
| `terrain_atlas.png` | Two 256 px top cells and one 256 px fill cell |
| `terrain_tileset.tres` | Collision-free Godot TileSet for the atlas |

Both arrangements reuse all six stamps. This intentionally small terrain set
proves horizontal and vertical joins; it is not a complete autotile set with
slopes, concave corners and independent end caps. Raised slabs are separate
stamps over simple one-way colliders. Decorative boulders and trees do not add
collision. Ground collision is authored separately from the tile artwork.

## Sources and reproducibility

Artwork was generated with the **built-in image_gen tool**, using the accepted
exploratory woven lakeside image as a style reference. The tool does not expose
its backend model version. `generation_manifest.json` contains every full prompt
and the generation source paths. The original alpha images and reference are
retained in `sources/`; delivered PNGs and runtime PNGs use Git LFS.

`tools/art/woven_world/prepare_kit.ps1` trims alpha bounds, scales the stamps and
constructs the terrain atlas from one shared source. It blends a narrow border
band to share exact neighboring boundary pixels. It does not generate replacement
artwork or redraw the stamps. Run it to reproduce the delivered images and
`asset_checks.json`. Boundary equality is a numerical check, not proof that
repetition or the blend bands are invisible in motion.

## Review criteria

Judge at normal gameplay zoom first:

1. Do the tree and leaf lines still read as woven rather than fine noise?
2. Does the actual doll belong beside the generated scenery?
3. Are moss edges and raised slabs clear under the character's boots?
4. Can you spot repeating cells or smooth bands, especially with T switched off?
5. Do reused stamps feel coherent across both arrangements?

## Verification

Run `start_review.ps1 -Headless` for data, floor contact, movement and jump checks.
Run `start_review.ps1 -Verify` for the same checks with Forward+ screenshots.
The verify mode closes when finished and writes its report here.

Final validation on the local working baseline:

- **37 headless checks passed**, including stamp reuse/transparency, terrain
  borders, the actual modular doll, actor-only daylight, floor contact, movement
  across joins, jump and landing in both arrangements.
- **40 Forward+ checks passed** on the RX 6800 XT, including 1920 x 1080 captures
  of both views and exposed terrain joins. See `gpu_checks.json`, `layout_a.png`,
  `layout_b.png` and `terrain_join_view.png`.
- All eight terrain neighbor checks report zero RGBA border difference in
  `asset_checks.json`.
- Six existing save/settings CFG files have unchanged hashes after verification;
  see `user_data_checks.json`. No checkpoint is created by the review scene.
- Render inspection corrected the boots/moss contact, floating blossom branch,
  distant-village scale and actor daylight. The uniform point light respects the
  actor's light mask; source stamp colors retain their original lighting.
- Repeated terrain faces and a horizontal blend band remain visible. This is
  an explicit review target, not a claim that the three-cell atlas is final art.
- Godot reported a shader-cache folder permission diagnostic and shutdown
  texture/RID/ObjectDB/resource diagnostics. The GPU run still completed all
  40 checks with no failed assertions. These diagnostics are not resolved by
  this art delivery.

The Git checkpoint is recorded in the current work list. Screenshots are
evidence from the actual Godot renderer, not generated concept compositions.
Chase's visual acceptance is still required before using this kit as the basis
for a production art pass. The initial repository had substantial unrelated
edits and staged source deletions; those are preserved outside this checkpoint.
