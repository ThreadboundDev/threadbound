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

## Live VFX and requested scope

**Live slash implemented.** The preferred original filled blade sweep now runs
in the production `PlayerLive3DVisual` for ground/crouch/forward air/water slashes.
Directional thrusts and the spin retain their distinct existing silhouettes.
`Src/VFX/thread_sword_sweep.gd` is promoted from the reviewed study; its short
world-space trail and sparse flax accents follow the actual blade. The old thin
sweep is suppressed only for the filled styles. No attack-controller edits.

Hit bursts subscribe to the existing hitbox's confirmed-hit signal and are placed
at the target collision bounds nearest the blade. No staged preview contacts run
in gameplay. [Three-strike comparison](../../work/gameplay-review-followup-2026-10-30/live-sweep-comparison.jpg).
Six integration checks pass: matched old/new combo source times, activation and
damage polygons, all three swings emitting bounded samples, whiffs without
bursts, trail expiry, and an actual physics overlap producing a confirmed burst.
The slash remains smaller than parts of the existing broad damage sector; this
pass does not silently expand art or alter reach to resolve that earlier finding.
Checkpoint: `vfx: integrate the preferred filled sword sweep`.

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

## Blue presentation corrections

Implemented after the screenshot review:

- Far rock: camera ratios 0.50 horizontal / 0.75 vertical, down from 0.65/0.85;
  600 world units deeper at the same camera anchor. Desaturated distance grade
  and a 180-unit soft shallow fade replace the 6-unit waterline cut. Source PNGs
  remain unchanged; scoped reimport retains the settings and is idempotent.
- Solid cavern faces: the existing contact-art renderer now draws the complete
  collision faces above the water veil, using the same painted rock. Passages
  and rear rock remain underwater. This also conceals dry-mask slivers on solid
  rock. Two open cave pockets use a 100-unit visual feather and weaker caustics;
  the tower's linked mask and every physical pocket polygon/query stay intact.
- Workshop focus: normalized viewport coordinates replace mixed logical-pixel
  and framebuffer-pixel comparisons. The mask now tracks the room when stretched.
- Clouds: 48 sprites instead of twelve, seeded variation in placement, shape,
  scale, opacity, phase and wind speed. Both camera axes are cancelled; drift
  alone moves them. Existing billow and below-water clipping remain.
- Bridges: trim seven overlaps with stone landings, retain the nine walking
  surfaces, and replace tiny baked rails with 88-unit rear rails plus partial
  68-unit foreground rails. The foreground center remains open for readability.
  Two art passes live inside each reusable asset; no physics rails/buoyancy added.

[Surface](../../work/gameplay-review-followup-2026-10-30/blue-surface-comparison.jpg) ·
[Cavern depth](../../work/gameplay-review-followup-2026-10-30/blue-depth-comparison.jpg) ·
[Pocket edges](../../work/gameplay-review-followup-2026-10-30/blue-pocket-comparison.jpg) ·
[Clouds](../../work/gameplay-review-followup-2026-10-30/blue-sky-comparison.jpg) ·
[High bridge](../../work/gameplay-review-followup-2026-10-30/blue-Deck01-comparison.jpg) ·
[Tower bridge](../../work/gameplay-review-followup-2026-10-30/blue-Deck06-comparison.jpg) ·
[Pontoon](../../work/gameplay-review-followup-2026-10-30/blue-Deck08-comparison.jpg) ·
[Workshop focus](../../work/gameplay-review-followup-2026-10-30/workshop-focus.jpg).

Validation: 78 engine checks pass (layer ratios, world-locked timber, all nine
floors, five anchors, four waterlines, cloud camera independence and wind, solid
faces, visual-only feathers, normalized house mask). All 148 captured world
collision polygons match. Existing door handoff regression passes 20 checks in
painted/current house modes. Forward+ captures compile the updated shaders.
House entry also completes at the normal 2x building render scale in a separate
fresh capture; the larger route uses 1x art supersampling to reduce capture VRAM.

Limits: the initial long 2x capture hit a Vulkan allocation/swapchain failure at
the house; fresh normal-quality house verification succeeded. Baseline inherited
enemy ownership and shutdown resource diagnostics remain. High sky artwork still
has a finite coverage boundary visible above the uppermost landing. Open cave
air pockets remain visibly drier with softened edges; their geometry was not
redesigned. Chase's in-motion/art acceptance remains pending. Checkpoint:
`art: refine Blue depth clouds house focus and bridge scale`.

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

## Appearance lab delivered

Open `tools/art/appearance_lab.tscn` and press F6. The current rig can run, jump
and attack at zoom 0.83 while switching Plain / Pattern / Mask / Both. Three
cloth motifs, three bold face markings, nine Identity presets, two mixing
approaches and optional shoulder/long-weapon silhouette proxies are available.
[Instructions and figures](../../work/appearance-lab-2026-10-30/README.md).

The study copies the body mesh in memory and stores authored rest coordinates
in UV2 so marks remain attached during animation. It changes no production
equipment resources, GLB, lore, bonus logic or progression. Masks are markings
on the current pale face surface; newly sculpted shells and complete armor sets
are not delivered by this study. Fine embroidery reads as texture at distance;
the broad split/diagonal masks are more distinct in these captures. That is a
first visual finding, pending Chase's preference and review against real biomes.

The color comparison distinguishes the current aura's weighted RGB averaging
from explicitly authored R/Y/B pair hues and the documented black full-absorption
extreme. The Spared / pale preset tests whitening separately from today's dark
neutral outfit. Neither trial selects a new production color formula.

The softer porcelain toggle reduces only the pale face material's albedo and
specular response. It is a candidate for the bright-head report, not a claim
that the demo's brightest overlapping 2D lights have been retuned.

Ten engine checks pass, including actual running and attack inputs with the
study mesh, unchanged collision/default gear, camera and palette endpoints.
Twenty matching static GPU captures plus run/attack captures were reviewed.
Checkpoint: `art: add playable Pattern mask and Identity comparison lab`.
