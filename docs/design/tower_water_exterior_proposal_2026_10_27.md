# Tower exterior water continuity — proposed correction

**Approved by Chase on October 27, 2026:** "Approve exterior-water plan; keep dry interior."
Implementation and verification follow the approved dolphin correction.

The October 27 screenshot shows the submerged
tower facade much drier/brighter than the surrounding lake. The tower's air
pocket currently removes the water presentation even while the exterior is
closed. The always-front facade also receives a lighter grade than scenery
behind the lake and actor-immersion passes.

Recommended behavior: **continue water across the closed tower exterior**.
Keep the existing dry interior for walking/platform traversal. Only reveal its
dry water mask when the existing tower cutaway actually opens for an occupant.
Keep the front stone rim, existing underside entrance, platforms and collision.
Match the closed facade's submerged grade to the surrounding lake; do not replace
the model or add another camera/render pass.

This addresses the visible dry cutout without silently flooding the lower tower
or changing its traversal. If Chase instead wants the entire submerged tower
flooded, revise the plan for that gameplay change before implementation.

Files to modify:

- `Src/Environment/Greybox/greybox_polygon_water.gd`: optional presentation-owner
  link for an air pocket, so its visual mask/caustics follow the building reveal
  while physical dry-state queries remain independent.
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_model_2d.gd`: expose
  the existing cutaway state as a read-only query.
- `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`:
  link only the tower air pocket to `Buildings/Tower`.
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_art_stage_2d.gd` and
  `Src/Environment/BlueBiome/Water/submerged_facade.gdshader`: align the foreground
  facade grade with the existing lake/immersion colors and strength.
- `tools/environment/verify_lakeside_water_delivery.gd`: check the linked visual
  mask separately from physical dry pockets.
- New `tools/environment/verify_tower_water_exterior.gd` and UID sidecar:
  compare closed exterior/open interior pixels, physical wet/dry state and rim
  occlusion from below and beside the tower.
- New `work/tower-water-exterior-2026-10-27/` reports/captures with `.gdignore`.
- This proposal, `docs/project_status_and_worklist.md`, `docs/next_test_session.md`
  and `docs/verification/lakeside_followups_2026_10_27.md`.

Verification: GPU before/after views at the reported left edge and base; closed
exterior remains wet, dry interior is revealed on entry, swimmer crosses behind
the stone rim, waterline/reflections remain registered, other air pockets retain
their presentation, and tower movement/collision remain unchanged.

Approval is required because this changes the relationship between the room's
air-pocket presentation and building cutaway. AGENTS.md requires: "Before making
any architectural changes" explain the change, reason and files, then "Wait for
approval before editing." Chase's approval above authorizes this scope;
implementation and appearance acceptance are tracked separately.
