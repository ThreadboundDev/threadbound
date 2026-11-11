# OG character in Blue gear — November 10, 2026

Status: **Awaiting Chase's concept review.** Chase is considering returning to
the original 2D character and requested Blue-gear visualizations for morning
review. This does not approve an art replacement or a new rigging pipeline.

- [Full established Blue outfit, with wicker hat](og_blue_full_gear.png).
- [Hat-off study retaining the OG face and silhouette](og_blue_hat_off.png).
- [Side-oriented standing and running pose study](og_blue_movement_study.png).

The original `docs/art/concept_art/Idle right first.png` is the identity and
style authority: rounded stitched ivory head, black oval eyes, pale human-shaped
hands, lean body, baggy tapered trousers, painted shading and firm black edges.
The established November 4 Blue Hermit references supply the indigo cloth,
fitted brown three-toggle vest, curved hip panels, bell sleeves, shallow wicker
brim, sash, shin wraps and compact split-toe footwear. Exposed mechanical doll
joints and the narrow wooden mannequin face are intentionally excluded.

All three assets were created with the built-in `image_gen.imagegen` tool.
The exact prompts and ordered reference roles are retained in [prompts.json](prompts.json).
Outputs were visually inspected for identity, complete framing, costume,
silhouette and painted contours. The images retain the OG design more closely
than the earlier 3D-source render experiment, but remain generated concepts.
There is illustrative drift: collar ribbons multiply in places, and the
standing pose sheet is side-oriented rather than a strict orthographic profile.
Use the established outfit references for the actual two ribbon attachment
points. These images are not rigging turnarounds or fitted equipment sources.

The hat-off image is a visualization option, not a change to Blue's established
hat or acquisition rules. No masks, shield or grapple obscure this clothing
study; their fit and appearance remain to be assessed separately.

The running drawing does not establish animation consistency, current skeleton
compatibility, UV layout, mesh deformation, draw order or equipment swapping.
A 2D deformation-rig experiment, if chosen, should first prove the shoulder,
bell sleeve and elbow overlap in a small range of poses while protecting the
original painted head and proportions. That work has not started here.

All three final images are saved in this folder, with a `.gdignore` so Godot
does not import the concept package into normal gameplay. Existing character,
equipment, scene and native-art sources are untouched by this task.

Checkpoint: `art: visualize OG character in established Blue gear` on
`threadbound/art-og-blue-gear-concepts`. Concept acceptance and any next rigging
or model decision await Chase's review.
