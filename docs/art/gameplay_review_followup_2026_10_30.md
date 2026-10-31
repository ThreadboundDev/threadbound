# October 30 hands-on follow-up

Chase accepted the upright idle enthusiastically. Keep that pose. The demo
lighting is improved; the brightest head highlights warrant a restrained check.
The pontoon direction and underwater backdrop are positive, with follow-ups
below. These observations do not close the remaining Blue art review.

## Run posture

Carry the straighter torso into the existing run without replacing its gait.
`player_live_3d_visual.gd` installs isolated copies of `run_1`/`run_2` for both
the visible rig and grapple sampler. Only spine, chest, neck and head rotation
keys change. Legs, pelvis, arms, translations, timing, source GLB and idle remain
unchanged. `upright_run_strength = 0` restores the original selection.

[Four sampled poses](../../work/gameplay-review-followup-2026-10-30/run-comparison.jpg).
Forward+ verification: 15 passing checks, including stride/arm/source isolation,
unrelated action equality, both sampler clips and actual grapple start/finish.
This is a presentation refinement; Chase's moving/transition review remains open.
Existing texture/RID/ObjectDB shutdown diagnostics persist.

## Remaining requested work, in order

1. Integrate the preferred filled slash into actual gameplay; it was previously
   only in the isolated study. Keep attack timing, damage and collisions intact.
   Contact bursts must follow real confirmed hits, not the study's staged contacts.
2. Underwater: slow the far backdrop further, separate its contrast/color from
   solid contact rock, remove the visible waterline cut, and investigate stray
   bright/dry patches. Preserve real dry-pocket physics.
3. Interior: investigate the off-center rectangular focus/lighting boundary in
   the workshop screenshot, including stretched-window coordinates.
4. Clouds: substantially increase varied coverage. Chase clarified **wind drift
   only, no camera response**. Keep this treatment above water.
5. Bridges: remove duplicate wood on painted rock bridges, inspect scale and
   front/rear railing depth at actual gameplay scale. Do not resize the player,
   collision or level globally to fix one prop family.
6. Compare Patterns, porcelain masks, and the combination at gameplay scale,
   with Identity color mixes. This is a visual study, not selection of a new
   equipment architecture, replacement lore, or a catalog of production armor.

Chase's nine attached screenshots supply the review evidence (images 7 and 8
repeat the same view). They show waterline truncation, weak rear/solid rock
separation, rectangular highlights/dry boundaries, workshop focus offset, small
rail/deck proportions, and timber overlapping painted rock bridge art.

## Mask/Pattern study constraints

Existing [Pattern design](../design/pattern_system.md) distinguishes Identity
palette, equipment silhouette and embroidered Pattern motifs. The current live
3D visual hides the old 2D Pattern overlay. Test decorative motifs and mask
variants on the current rig before production equipment work. A mask could be
readable through silhouette/value at distance, while fine embroidery may need
larger cuffs/hems. Those are hypotheses until rendered at the saved 0.83 zoom.

No decision has been made to replace Patterns with masks or to tie mask choice
to permanent classes/builds. Additional armor/weapon meshes require their own
concrete asset scope after this first comparison.
