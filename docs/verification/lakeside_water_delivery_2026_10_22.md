# T17 water readability implementation

Chase approved proceeding with the October 22 review's waterline, contact rims
and exterior/interior compositing recommendations. The new Krita background is
not available yet; this delivery reuses current art. Manual saved scene edits
were checkpointed first as `4130555b`, including the Bellstriker placement.

## Checkpoint 1 — shared surface and honest controls

The lake's three upper vertices now share world y=411. The volume's
`get_surface_global_y()` supplies both presentation and backdrop/cloud cutoff.
The shader uses exported shallow/deep colors and actual normal/underwater
opacity (.34/.16 defaults); wet state is explicit rather than inferred from
equal alpha values. Camera clarity blends over .25 seconds.

`verify_lakeside_water_surface.gd`: 14 checks pass, including physical wet/dry
classification at y=410/412, all top vertices, backdrop alignment, material
controls and equal-opacity false-submersion regression. Existing lake authoring
fixture passes. Existing six-ObjectDB/three-resource shutdown diagnostics remain
tracked under T04. Candidate commit subject:
`fix: align lakeside water surface and presentation controls`.

## Remaining approved implementation

Contact rims: new `lakeside_contact_rims.gd` and a child in
`lakeside_krita_artwork.tscn`; derive narrow textured strips from existing upper
collision edges and rear-cave PNG alpha. No collision edits or replacement art.

Compositing: `greybox_polygon_water.gd`, `polygon_lake.gdshader`, new
`polygon_lake_immersion.gdshader`, `air_pocket_caustics.gdshader`,
`lakeside_art_stage_2d.gd`, new `submerged_facade.gdshader`, and the room's third
pocket setting. Keep rear reflections behind actors/contact rims, apply light
wet tint in front of actors, and grade submerged exterior facades independently
of the dry-interior mask. Preserve existing entry/cutaway behavior.

Focused verification tools, delivery images/reports, this document, the current
work list and next test card are updated alongside each coherent checkpoint.
The source review and its previews remain historical evidence, not final images.

## Checkpoint 2 — front rock contact

`RockContactRims` derives front strips from exposed floor-facing collision
contours, rejecting internal seams and retaining source PNG alpha/UV registration.
Only 3px projects outside the existing collision; the matching painted solid
face continues 24px inward, preventing a boot from reappearing below a thin mask.
The cave back wall stays at -5; rims draw at +3. No collision or source PNG is
changed. Current build: 918 short boundary segments, 31 batched texture meshes,
2,049 triangles. Editor rebuild follows edited collision; runtime builds once.

Forward+ delivery fixture: 68 checks pass; cave contact and corrected shoreline
captures inspected. Existing house entry: 405 checks pass. Shader/resource
shutdown diagnostics remain tracked as above. Contact appearance still needs
Chase's normal-speed review, including wide stances beside small painted rocks.
Commit subject: `fix: add foreground rock contact rims`.
