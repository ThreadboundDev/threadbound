# OG clean base outfit — front/back T-pose references

November 10, 2026. **Awaiting Chase's visual review and model-generation trial.**
Requested for the morning's character-model experiment; these references do not
replace an existing character, rig, equipment asset or approved runtime palette.

## Modeling inputs

- `og_base_front_tpose.png`: straight front, palms facing forward.
- `og_base_back_tpose.png`: matching rear, dorsal hands and rear boot heels.
- `OG_Base_TPose_References.zip`: the two inputs, notes, prompts and integrity manifest.

Use the two individual images as front/back views of one character. Keep the
large round ivory head, black oval eyes and central stitching; the lean body,
human-shaped pale hands and original baggy trouser silhouette are deliberate.
The rear head has no facial features. Arms extend horizontally, and the full
fingertip span and soles are visible on white backgrounds. The pair uses the
original charcoal cloth, brown leather wraps, cowl collar and wrapped boots.
The original idle illustration is the identity and costume authority.

Created with built-in `image_gen.imagegen`. Exact prompts and ordered input
roles are in `prompts.json`. The first rear draft incorrectly retained palm
and front-toe shapes; a targeted edit corrected those before delivery. Only the
corrected rear is included in the ZIP. Both final outputs were visually checked
for view direction, framing, five-digit hands, rear heel orientation, garment
boundaries, matching scale and soft illustrated shading. The PNG manifest
records dimensions, checksums and decoding checks. Generated turnarounds remain
approximate; they are not measured projections of an existing 3D model.

## Base-gear recommendation

Prefer the original cleaner base silhouette for this experiment. Keep a worn
surface through small leather scuffs, stitching and cloth texture. Long torn
skirt/coat panels add overlaps and silhouette changes that complicate mixed
equipment and hide the cleaner original body shape. That is an authoring
recommendation for Chase's review, not a decision to remove player expression
or rewrite the equipment design.

Use consistent physical connection locations across outfits. The long sleeve
overlaps the bracer top, and the trouser hem tucks into the boot top. Define
which item owns each visible cover before cutting the actual mesh; overlap
alone does not establish interchangeable topology or prove animated clearance.
Verify a Base/Blue mixed outfit against the selected skeleton after generation.
Do not infer millimeter cut positions or the final rig from these pictures.

## Color and shading handoff

These PNGs show the requested OG appearance, with soft painted form shading,
readable charcoal folds and clear dark outlines. Their charcoal is a reference
appearance, not a change to the Identity system's neutral-state rules.

Preserve the established material roles when authoring the actual UVs/textures:
main cloth, secondary cloth/trim, natural leather, and ivory head/hands. Keep
natural material finishes independent of Identity dyes. Author explicit material
slots or dye masks, so changing cloth color can preserve its folds and texture
without tinting the leather, head or outlines. Avoid crushing dyeable surfaces
to black or baking all lighting into the color texture. The illustration is
not an albedo map, UV layout, dye mask or proof that a generated mesh will have
usable material separation. Texture work is a possible later task, not delivered
here. Optional Pattern embroidery remains separate from construction stitches.

No weapons, shield or grapple are included in these clean body inputs. Existing
gear-specific grapple behavior and mounting conventions remain in force and
need a separate fitting pass; this reference does not redefine them.

Checkpoint: `art: prepare OG clean-base front and back T poses` on
`threadbound/art-og-base-turnaround`. Next: Chase reviews this cleaner base
direction, generates a model, then compares its actual shape and deformation
in game before deciding on a production visual or sprite pipeline.
