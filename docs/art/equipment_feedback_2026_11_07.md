# November 7 equipment review and approved repairs

Status: Chase approved the scoped repair with “Do it.” Implementation and
verification are complete. The three source reports remain open for Chase's
appearance review after restarting the art-test session.

**Later appearance review rejected the hand/cuff/shin surface quality.** The
23:25 report runs `617581fc` and shows jagged rigid pieces and lumpy visible
transitions despite passing the structural checks. See the
[surface diagnosis and replacement scope](equipment_surface_review_2026_11_07_2325.md).
No further runtime assets were changed during that review; a focused replacement
pass requires approval. The earlier passing counts below are structural evidence,
not acceptance of the current appearance.

## Approved repair checkpoint

The shared hands now use rigid palm/phalange pieces with rounded brown hinges,
centered on the unchanged wrist and finger pivots. Both glove variants reuse the
same repair. Native Blender checks cover 32 samples across eight authored clips:
all hand vertices have one rigid influence, no edge crosses between owners, and
the maximum measured edge-length change is below 0.001 mm. The original 62 rest
bones and 48 clips are retained. This verifies rigidity, not final grip appearance.

Both shin joins use the Blue ellipse through a 22 mm overlap band (0.401–0.423 m).
The trousers sit 0.5% inside the boot wall; the band follows the same shin bone.
The native validator passes 170 checks covering both hands, all four exported
join profiles and animated coverage. The boot top stays below the knee and the remap fades away from
the hidden band. Original assets are backed up in the local review folder.

Independent, depth-tested mesh outlines replace the combined alpha expansion.
An outline-only mesh uses welded normals; the original shading mesh is preserved.
Opaque source fronts and a depth recession prevent black hulls showing through
folds. Small fingers, grapple hardware and the wicker crown use finer ink. The
object verifier passes 281 checks and captures four poses per outfit. Controlled
blade/body crossings measure equal ink width (within one pixel) across and outside
the body at two camera scales, and verify that body depth hides a blade behind it.
Repeated swaps reuse cached outline geometry. The paused inventory uses the same
shader, with its own fixed portrait width.

## Completed cloth extension and final verification

Base has four short hem chains (16 appended bones). Their skin contribution fades
to at most 30% on the outer loose tunic, retaining the original animated weights
underneath and keeping the belt/cowl fixed. Its profile uses stiffness 30, drag
0.96, gravity 0.04 and a smaller acceleration force. Blue keeps the four toned-down
sleeve chains and adds one shoulder ribbon and three hanging sash chains (32
cloth bones total). Short leather hip panels remain rigid. Blue's hanging cloth
uses stiffness 18, drag 0.92 and gravity 0.08; sleeves retain 4 / 0.86 / 0.05.

Torso collision affects sleeves; torso, hip and thigh proxies affect hanging
cloth. Profiles reset on swaps, teleports, long frames, doors and instant pose
cuts. Three synchronous warm-up steps resolve the initial collision chain before
the first displayed frame without advancing authored animation. The original
62 animated bones/rest bases and 48 clips are preserved; the reusable live rig
appends up to 48 cloth bones and does not grow during repeated swaps.

Final results on the local assets:

- Native Blender joint validator: **170 checks pass**. Both gloves have the same
  rigid hands; all four shin combinations retain 22 mm axial overlap through 32
  samples across eight clips, with the whole band on the shared shin.
- Forward+ equipment regression: **747 checks pass** across eight loadouts,
  eight poses and both facing directions. Dynamic cloth checks cover both outfits
  in the same actions; roots remain fixed and link error stays below 0.001 mm.
  Sampled sleeve penetration into the torso proxy is about 82% lower than the
  same rigid sleeves, within the existing 1.5 cm tip-clearance tolerance.
- Forward+ outline verifier: **281 checks pass**, including depth, overlap,
  two camera scales, opaque source materials and geometry-cache reuse.
- Inventory verifier: **786 checks pass** in Forward+ and headless runs. The
  paused portrait mirrors all mixed loadouts/masks, uses independent cloth and
  skeleton clocks, and leaves the gameplay pose/animation unchanged.

Forward+ standalone runs retain the previously reproduced texture RID /
CompressedTexture2D release warning at shutdown, after successful checks. The
headless inventory verifier exits cleanly. There are no running script errors
in the final verification logs. Collision is a bone/proxy approximation; broad
fabric and final hand-grip appearance still need Chase's in-game review.

Editable sources and captures: `LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend`,
`LocalOnly/Equipment/FeedbackReview2026_11_07/Shared_Hands_Repair.blend`, and the
adjacent joint/outline reports. Inventory captures remain in
`LocalOnly/Equipment/InventoryPreview/`. Generated art stays local; rebuilding
requires the preserved downloads and immutable `BeforeAssets` master.

Joint/outline checkpoint: `c61527b3` (pushed). Cloth and final validation checkpoint:
`fix: extend restrained cloth motion across base and blue outfits`.

## Evidence reviewed

All three `report.md` and `report.json` files were read. Screenshots and five
evenly spaced frames from each available recording were inspected. The third
report has a screenshot only. Captures were made from `2f157f1c` with the shared
working tree dirty, in Chamber of the First Weave. Each records zero runtime
errors, one Camera2D physics-interpolation warning, and no capture errors.
The warning does not explain the mesh joins or outline thickness change.

| Report | Capture and state | Finding |
| --- | --- | --- |
| `2026-11-07T21-37-30_30792_89854_2` | Base `[0,1,2]`; idle; 65 frames / 7.326 s; zoom 3.166 | Sword edge changes as it crosses and leaves the body; fingers visibly distort. |
| `2026-11-07T21-41-33_30792_332874_3` | Blue gloves with Base boots/outfit `[3,1,2]`; idle; 79 frames / 8.838 s; zoom 4.947 | Wrist/cuff deformation is conspicuous during the idle variation. |
| `2026-11-07T21-42-57_30792_417258_4` | Blue gloves/boots with Base outfit `[3,4,2]`; screenshot; zoom 4.947 | A mixed pants/boot join exposes a disconnected-looking edge. |

The first report's recording shows the sword both across the torso and outside
the combined silhouette. The body currently gets a three-world-pixel composite
alpha outline; the sword also gets its own nominal 1.25-world-pixel shell. The
composite expands the shell again when it leaves the body. Across the torso only
the sword shell supplies that edge. This explains the visible thickness change.
The requested replacement should use independent depth-tested object outlines
with consistent widths and remove the extra composite silhouette expansion.
These outlines still render with the animated meshes. Painting a line into the
base-color texture cannot maintain the silhouette across changing poses/views.

## Read-only asset measurements

`tools/art/inspect_equipment_feedback.py` imports all six fitted pieces and the
existing master rig without saving or replacing any model. Its JSON output is
`LocalOnly/Equipment/FeedbackReview2026_11_07/fit_diagnostics.json`.

- Both glove exports have identical shared hand geometry and named weights.
  Each has 17,491 exported hand vertices; 12,776 (73.0%) have multiple influences.
  Shared rest rotations match the master; translation differences are below
  0.001 mm, with no negative rest determinants. There is no separate flipped Blue
  hand rest rig in these exports. A rigid cuff beside the deforming shared wrist
  makes the break especially visible on Blue.
- Finger-region edges change length substantially in the sampled animations.
  In the first raw idle sample, roughly 12,000 of 26,380 sampled finger edges
  change by over 10%. This includes the intentionally blended joint region;
  the inspection does not infer brown/tan material boundaries from texture alone.
  The previous doll validator explicitly excluded blended finger joints from
  its rigid-edge guarantee. Passing those earlier checks did not validate these
  joints. The repair needs explicit articulated-part and flex-zone treatment.
- All four open boot/shin rings are at the same 0.415 m cut height. Matched Base
  and matched Blue rings coincide. Mixed rings have symmetric maximum nearest-
  point differences of 59.5 mm on one leg and 64.4 mm on the other. The builder
  applies the Blue ellipse profile to Blue's two pieces while preserving Base's
  imported shin/rim. Matching height alone therefore does not make the joins
  interchangeable.

The maximum ring distance measures geometric contour mismatch in the rest pose;
it is not a measured open gap of that size in every camera view.

## Completed sleeve adjustment

Chase likes the secondary-motion direction and requests slightly less motion.
The existing four sleeve chains now use stiffness 4.0 (previously 3.5), drag 0.86
(previously 0.8), and 20% less acceleration-driven force. Gravity, chain lengths,
collision radii, torso capsule and full collision influence remain unchanged.
This reduces follow-through without blending the cloth back through its collider.
It does not add ribbon or Base cloth bones.

Before and after Forward+ runs each pass all 287 existing checks over eight
loadouts. The revised run samples 612 simulated frames; it retains finite poses,
chain lengths, swap reuse, reset behavior and the existing collision tolerance.
Minimum sampled chain clearance is about 7.1 mm; sampled fabric penetration depth
into the torso proxy remains about 82% below the same rigid-sleeve poses. This is
a proxy test, not exact cloth-to-mesh collision or a visual acceptance claim.
The existing standalone texture-release warning reproduces at shutdown in both
runs. Before/after captures and logs are retained in the local review folder.

## Approved protected scope (reference)

1. Give the character, sword, shield and equipped pieces consistent independent
   mesh-based outlines with depth occlusion. Keep the approved outlined art
   direction and color grading. Avoid adding the composite outline outside them.
   Check smooth silhouette normals and sharp tips before applying it throughout.
2. Repair the shared hands once, then regenerate both glove variants. Brown hinge
   pieces should retain their shape; tan segments articulate with controlled
   blending at designated flex zones. Darken the hinge material modestly while
   preserving the existing wood texture. Refit each cuff around the same wrist
   connector, preserving bracer geometry and the forearm-mounted grapple/shield.
   Keep the existing skeleton rest transforms, clips and grip conventions.
3. Define a shared hidden shin connection and a short overlap for every pants/
   boot combination. Preserve the good Blue-on-Blue outer silhouette, mid-shin
   boot height and each outfit's visible trousers. Align both sides to the same
   connection contract; avoid solving one mixed loadout with a special-case shift.
4. Extend the existing spring method to Blue's loose ribbons/sash ends and Base's
   loose tunic/sash edges. Their attachment zones remain fixed. Base gets firmer,
   shorter motion; Blue can flow more. Keep limbs, wooden hinges, boots and stowed
   grapple hardware outside the cloth simulation. Reuse the swap/teleport/door
   resets and add appropriate body/hip/leg collision proxies for hanging fabric.

No combat timing, ability behavior, unlock rules, equipment slots or lore changes
are part of this scope. The head/chest item still includes the whole outfit, and
the grapple still belongs to Gloves.

### Files in the approved pass

Runtime and verification sources:

| File | Planned change |
| --- | --- |
| `Src/Characters/Player/player_live_3d_visual.gd` | Install consistent per-object outline passes when meshes load/change. |
| `Src/Characters/Player/player_live_3d_outline.gdshader` | Preserve color/alpha grading; remove combined silhouette expansion. |
| `Src/Characters/Player/player_mesh_outline.gdshader` (new) | Shared depth-tested mesh outline. |
| `Src/UI/GameMenu/inventory_character_preview.gd` | Match the new object outlines in the paused portrait. |
| `Src/Equipment/Visuals/equipment_cloth_motion.gd` | Support outfit-specific loose-cloth chains and restrained profiles. |
| `Src/Equipment/Visuals/player_equipment_visuals.gd` | Register approved cloth anchors and configure motion for either outfit. |
| `tools/art/repair_fitted_doll_hands.py` (new) | Reproducible shared hinge/flex-zone weights and material correction. |
| `tools/art/prepare_base_blue_equipment.py` | Shared wrist/shin connectors, overlap, and additional cloth weights/bones. |
| `tools/art/verify_fitted_equipment_joints.py` (new) | Measure articulated-part rigidity and all mixed seam combinations. |
| `tools/player_animation/verify_character_object_outlines.gd` (new) | Check weapon/body overlap, occlusion, tips and consistent outline widths. |
| `tools/player_animation/verify_base_blue_equipment.gd` | Extend moving seam and cloth/reset checks. |
| `tools/player_animation/verify_inventory_character_preview.gd` | Verify the revised appearance path during swaps and pause. |

Generated Godot UID metadata accompanies new shaders/scripts. Local art outputs
replaced under that approval:

- `Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_gloves.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_gloves.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_boots.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_boots.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_head_chest.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_head_chest.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_gloves_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_gloves_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_head_chest_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_head_chest_icon.png`
- `LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend` and its generated fit/pose
  reports and captures; new editable hand repair source under
  `LocalOnly/Equipment/FeedbackReview2026_11_07/Shared_Hands_Repair.blend`.

Documentation updates stay in this review, `docs/art/base_blue_equipment_test.md`,
`docs/art/blue_cloth_motion_proposal_2026_11_05.md`,
`docs/art/inventory_character_preview_2026_11_05.md`, and
`docs/project_status_and_worklist.md`. Generated artwork stays local and receives
before-pass backups. Source downloads, the current sword/shield models, mask
models, skeleton rest bases and the 48 authored clips are preserved.

### Acceptance checks for the proposed pass

Check all eight loadouts in rest, idle variations, running, crouching, jumping,
casting and grapple swinging, with both facing directions. Measure both shin
joins across all four pants/boot combinations and verify covered/overlapping
connections during bending. Measure rigid hinges separately from allowed flex
zones. Compare outlines inside/outside the body, behind it, at normal and close
zoom, and in the inventory. Verify Base/Blue cloth profiles, collisions, pause,
swaps and resets. Chase's appearance review remains the final visual acceptance.
