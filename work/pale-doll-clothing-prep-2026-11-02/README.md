# Ragged starter clothing: separate generation inputs

November 2, 2026. Chase asks to prepare the existing base outfit for 3D
generation: no hood, a compact cowl/scarf with no tails, exposed elbows and
fingers, and boots covering the feet. His follow-up requests more ragged cloth
and rejects pants that restart below the knees. Use torn-off knee-length
breeches, with short frayed points slightly overlapping the tops of the knees;
leave the remaining knees and a short upper-shin gap visible above boot tops.

## Files to use

- [Five generation inputs, zipped](generation_inputs.zip), with START_HERE.txt.
- [Revised full-outfit fit reference](00_outfit_fit_reference_ragged_v2.png):
  review the composition and joint exposure. Do not feed this full doll image
  into a clothing-only generation job.

| Input | One generation job produces | Fit constraint |
| --- | --- | --- |
| [01_cowl.png](01_cowl.png) | Short folded cowl | Neck opening; no hood or tails |
| [02_tunic_sash.png](02_tunic_sash.png) | Tunic, sash and close waist pouch assembly | Torn sleeves above elbows; short skirt above knees |
| [03_ragged_breeches.png](03_ragged_breeches.png) | One connected pair of knee-length breeches | Torn hems end at knee tops; no calf fabric |
| [04_forearm_wrap_single.png](04_forearm_wrap_single.png) | One leather forearm cuff | Stops below elbow and above wrist; mirror later |
| [05_boot_single.png](05_boot_single.png) | One calf-high closed boot | Below knee, covers foot/toes; mirror later |

These five authoring assets can become seven fitted pieces after mirroring the
wrap and boot. They do not establish new gameplay slots. The sash/pouch are
grouped with the tunic for this first generation input; Blender separation can
be considered during fitting if needed.

## Individual jobs, optional batch queue

Use one garment image per Image-to-3D job. Tripo's
[image-to-3D guidance](https://www.tripo3d.ai/product-doc/model-generation/image-to-3d)
recommends a single subject and supports batch inputs. Its
[multi-view workflow](https://www.tripo3d.ai/product-doc/model-generation/multi-view-to-3d)
combines consistent views of the SAME object. Do not combine these five
different garments as multi-view inputs to one model. Different garments in
one image could be fused or require segmentation; separate jobs are the
recommended first pass for this modular outfit.

Start with tunic and breeches as a fit trial before spending effort on every
permutation. Generated meshes still need their openings, shell thickness,
back surfaces, topology, symmetry and tears inspected. Dark interior shading
in a reference does not guarantee the generator will preserve a hollow mesh.
All scale and joint positions must be fitted to the SAME accepted doll and
rest pose in Blender; the images do not automatically share world units.

Mirror the cuff and boot in Blender, apply transforms and check normals. Keep
clearance around elbows and wrists; place boot tops below the knees. Check
knees through a deep bend so the torn breeches retain the intended exposure.
Closed boots support avoiding individually articulated toe animation in this
clothing pass; ankle/foot motion and deformation still need checking.

The full outfit uses a blank oval stitched doll head, charcoal-indigo cloth,
brown leather and restrained antique-gold construction stitches. Cloth is
ragged at sleeve, skirt and breeches hems; the cowl is frayed but compact.
No decorative Pattern overlay or mask variant is selected by this delivery.

## Generation and verification

All six selected images were made with built-in ImageGen, using this chat's
existing original 2D doll/outfit concepts. No local Tripo-derived model or rig
was used as an image input or published in this package. The
[exact prompt set](generation_prompts.json) is retained. The earlier clean/
knee-window trial was superseded by Chase's ragged-breeches feedback and is
not included in the upload bundle.

The selected PNGs are saved without resizing or retouching. Visual inspection
checks the blank head, compact cowl, no hood/tails, exposed joints/fingers,
closed boots, ragged hems, and absence of a body in the five garment inputs.
[Image manifest](image_manifest.json) records dimensions and SHA-256 checksums;
the ZIP members are checked against those source images. Documentation links
and staged whitespace are also checked. These are reference-image checks,
not 3D fit, rigging, topology or game performance validation.

Concurrent doll/rigging/player integration work is left intact. Local character
artwork remains outside this checkpoint.
This task does not edit a 3D source, production asset, player script, gameplay
equipment resource or scene. The work folder is excluded from Godot imports.

Checkpoint: `art: prepare ragged starter clothing generation inputs` on
`threadbound/art-pale-doll-model-study`. Appearance and generated-model fit
remain for review; no external 3D generation job was submitted.
