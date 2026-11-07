# Late November 7 equipment surface review

Status: reviewed; the current appearance is **not accepted**. This report is
feedback, not authorization for another protected asset replacement. No runtime
mesh, material, scene or animation was changed during this review.

Source: `LocalOnly/Feedback/reports/2026-11-07T23-25-10_25380_149270_2` (the user
submitted the same path twice). Both `report.md` and the complete `report.json`
were read. The screenshot and recording frames 0, 42, 84, 126 and 168 were visually
inspected, including the changing idle hand pose. All 169 source JPEGs decode;
the AVI contains 189 intact, chronologically ordered source-JPEG packets after
constant-rate pacing. Its final timing slot uses the previous capture; frame 168
remains available as a JPEG. No media decode failure explains the geometry.

## Observations and captured state

Chase reports large leg bulges, bad Blue arm connections and increasingly jagged
fingers. He wants fingers to bend at their joints rather than stretch, even if
normal gameplay is less zoomed in. The report runs `617581fc`, the latest repair
checkpoint, with the shared checkout dirty. This is not a stale-build report.

The 18.852-second, 960 × 540 clip and 1920 × 1080 screenshot show Blue Gloves and
Boots with Base Head / Chest (`[3,4,2]`) in Chamber of the First Weave. Zoom is
4.947. Capture state is idle, grounded and unpaused, with no held inputs. The
preceding 30 seconds contain 59 idle samples and one ground-attack sample.
Captured diagnostics show zero errors, one Camera2D interpolation-mode warning,
and no capture errors. That warning does not explain the modeled edges. Earlier
unclosed sessions are not evidence of a crash in this report.

## Confirmed mesh defects

`tools/art/inspect_equipment_surface_feedback.py` only imports and measures assets
and renders temporary inspection scenes. SHA-256 checks confirm all 12 inspected
runtime/backup GLBs remain unchanged. Its measurements and seven native-material
close-ups are in `LocalOnly/Equipment/FeedbackReview2026_11_07_2325/`.

1. **The latest hand split introduced open, jagged boundaries.** Assigning whole
   triangles to the largest accumulated bone weight cuts irregular zigzags across
   the palm and phalanges. Those cut pieces were recentered and left uncapped.
   The round hinges do not cover all of the boundaries. With UV splits welded
   only for measurement, each current shared hand pair has 3,088 open edges
   (25.716 m summed boundary length), versus 430 edges / 2.266 m before the pass.
   Both glove variants use that same defective shared geometry. Open boundaries
   can be intentional at attachment cuts; these counts alone are not a rule that
   every boundary is a defect. The native close-ups directly show the exposed
   triangular teeth around the palm, thumb, fingertips and wrist.
2. **The new hinge UVs sample unrelated atlas regions.** The generated spheres
   have default sphere UVs spanning the whole character atlas, with a brown
   multiplier. They therefore pick up cloth/other surface colors rather than a
   consistent wood region. The gray/brown patchwork is visible without any game
   outline. Darkening that material further would not correct its UV mapping.
3. **The shin contract deforms the visible limb contour.**
   `align_shin_connections()` projects vertices toward a common ellipse through
   a 30 mm band and fades over another 52 mm on either side. This moves visible
   shin/hem geometry as well as the hidden join, and projects radial layers onto
   one target contour. Near 0.415 m (vertices within ±6 mm), Base Head / Chest's
   measured width changes from 114.3 to 131.3 mm and its depth-center moves from
   43.3 to 0.9 mm. The comparable Blue boot width changes from 145.8 to 131.8 mm.
   A matching cut ring and axial overlap can therefore coexist with a swollen or
   pinched transition. The Base-pants/Blue-boots close-up shows the abrupt rim and
   uneven surface above it.

These defects are visible in plain Blender materials, with the game outline
absent. No new animation service or wholesale animation regeneration is indicated
by this evidence. The Blue cuff needs a proper overlapping wrist seat around the
same articulated core, rather than another arbitrary whole-hand translation.

## Why the previous verification missed this

The existing native validator was rerun and still passes all 170 checks. It
checks rigid edge lengths, one-bone ownership, shared ring positions/weights and
animated overlap. Those guarantees are useful, but they do not check closed,
clean articulated surfaces, hinge UV coverage, palm-to-hinge gaps or the smoothness
of the visible transition away from a cut. The passing count did not establish
visual quality. Chase's new report supersedes the earlier “ready for review”
appearance status; it does not invalidate the functioning equipment swap path.

## Proposed protected repair — approval required

Keep the same doll proportions, original 62 animated rest bones, 48 clips, slots,
glove-owned grapples, forearm shield and current restrained cloth profiles.

- Rebuild the shared palm and phalanges as clean, closed rigid pieces aligned to
  the existing joint axes. Use explicit joint-plane cuts or locally rebuilt
  topology instead of dominant-weight triangle partitions. Keep caps tucked
  inside appropriately sized brown hinges and preserve the approved wooden look.
  Map those hinges to a verified wood region, with separate seam-safe UVs.
- Refit both bracer rims to the same wrist core with a concealed overlap through
  flexion. Clean residual cut triangles and inspect both arms in rest, grip and
  the idle variation before replacing any runtime candidate.
- Preserve the visible Base and Blue shin/boot contours. Use a shared hidden
  connector/underlap and clean local rim loops to cover mixed combinations;
  remove the broad radial projection of the visible limb. Keep the shared slot
  ownership/cut location and mid-shin height. Check front, back and side profiles,
  not only matching coordinates at a single plane.
- Extend verification to open boundaries on the closed rigid parts, degenerate
  triangles, hinge UV coverage, connector gaps under flexion and visible contour
  changes. Retain rigidity/overlap checks. Render close-ups with and without ink,
  at gameplay scale and close zoom, for all four pants/boots combinations and
  both glove variants. Human visual acceptance remains required.

### Exact source files for that repair

- `tools/art/repair_fitted_doll_hands.py`
- `tools/art/prepare_base_blue_equipment.py`
- `tools/art/verify_fitted_equipment_joints.py`
- `tools/art/inspect_equipment_surface_feedback.py`
- `tools/player_animation/verify_base_blue_equipment.gd`
- `docs/art/equipment_surface_review_2026_11_07_2325.md`
- `docs/art/equipment_feedback_2026_11_07.md`
- `docs/art/base_blue_equipment_test.md`
- `docs/project_status_and_worklist.md`

Runtime assets to replace only after approval (all stay local):

- `Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_gloves.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_gloves.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_boots.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_boots.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_head_chest.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_head_chest.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_gloves_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_gloves_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_boots_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_boots_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/base_head_chest_icon.png`
- `Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/blue_head_chest_icon.png`
- `LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend` and adjacent fit reports /
  captures, plus `LocalOnly/Equipment/FeedbackReview2026_11_07/Shared_Hands_Repair.blend`.

Candidate previews/backups will be saved before installation. Source downloads,
weapon/shield models, masks, gameplay code and outline rendering remain outside
this repair scope. Approval is needed because AGENTS.md lists **asset replacements**
as protected changes. This review checkpoint contains documentation and a
read-only inspection tool only.
