# Generated doll concept references — November 3, 2026

Chase clarifies that he wants newly generated character artwork using the earlier
concept we separated into individual garments. The native game-render package
is not the requested visual source. This package supersedes it for generation.

## Images

- `base_outfit_front.png`: corrected generated full-clothed front T-pose.
- `base_outfit_back.png`: matching generated back; pouch switches viewer side,
  boot heels and dorsal hands are shown.
- `master_bare_front.png`: byte-identical copy of the original generated blank-head
  doll reference, retained as the identity/proportion master.
- `master_bare_back.png`: newly generated complementary back of that bare doll.

Use the two `base_outfit` images together for the full-clothed 3D generation.
The bare pair supplies the underlying doll identity for later outfit styles.
Do not mix bare and clothed pictures as different angles of a single outfit.

## Clothing correction

Continuous ragged cropped trouser legs now cover the knees and extend toward
the mid-shin boot cuffs, leaving only a narrow strip of plain wooden shin.
There are no detached calf panels or circular knee windows. Actual knee centers
remain at the original height, concealed by the longer pants; the small band
above the boots is shin, not a relocated knee joint. Boots stay compact, closed
and below the knee. Blank stitched head, cowl without hood/tails, worn indigo
cloth, gold construction stitches, brown sash/pouch/bracers and bare hands remain.

The generation uses only the two original 2D concept references, not game renders
or Tripo-derived character meshes. `generation_prompts.json` records the exact
built-in ImageGen prompts, including the targeted joint/hand corrections.
`image_manifest.json` records image dimensions and file hashes. All four images
are visually inspected; the ZIP contains these files, the prompts and this README.

These are generated design views, not a geometric guarantee. Verify proportions,
joint interfaces and rig fitting when the new 3D candidate is made. This delivery
does not replace runtime models, submit a Tripo job or resolve animated clipping.
