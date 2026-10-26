# Threadbound current TODO list

Updated October 26, 2026. Saved recovery baseline: `16b3bd3c` on
`threadbound/chore-october-development-checkpoint`, committed and pushed.
This is the single current task order. The [checkpoint recap](checkpoint_2026_10_21.md)
is the evidence for the current state; older roadmaps and delivery reports do
not override its failures or imply hands-on acceptance.

**Milestone priority: T01, finish house contact and deliberate door entry.**
The layout fix is saved as `9abd15ff`. Chase approved the door change, which is
implemented and checked; [delivery and validation](design/lakeside_house_entry_proposal.md).
T01/T02 now await a short visible house/NPC review. Next independent background
task is T03 when Chase is unavailable to play.

Chase's subsequent scoped request is **T13: matching walkway stamp objects**.
Chase approved the [2D integration](design/lakeside_walkway_stamp_proposal.md),
excluding the rock-attached landing. Four reusable timber options and nine
fitted intact landing visuals are implemented and checked; visible review is
pending. This scoped correction does not approve broader art production or a
3D rebuild. T01/T02 house review remains pending too.

**Current visual correction: T14, background wood depth separation.** Chase
approved the [scoped correction](design/lakeside_rear_support_depth_proposal.md).
The original wood supports now have a separate background layer and tunable
depth filter; Cave Walls/Under Cave Mouth remain combined. Implementation and
focused checks are complete; **awaiting daylight/dusk visible review**. Gameplay
geometry and the latest house/walkway work are unchanged.

**Latest correction: T15, bridge/bulb rock overlap.** Bridge options and bulbs
now draw between background wood and rock faces; bulb runtime art/particles
follow the placed object's depth. Verification passes; visible overlap review
is pending. [Current depths and results](verification/lakeside_rock_overlap_2026_10_21.md).

**Latest scoped art delivery: T16, Eave Runner v4 installation.** Chase approved
the swap on October 22, accepting the current model for now while explicitly
calling it rough. Gameplay and the art-only scene now use v4. Import, wrapper,
guardian and authored lakeside/reset checks pass. Further polish and hands-on
gameplay-scale review remain open; do not describe this as final concept parity.
[Delivery, approval and validation](art/eave_runner_cleanup_v4.md).

**Latest implementation: T17, approved water/readability corrections delivered.**
Manual level edits are saved as `4130555b`; the shared surface/real controls as
`4ad653bc`, rock contact rims as `5428b96e`, and exterior/dry-interior compositing
as `fc40a9b2`, all pushed on `threadbound/fix-water-readability`. The waterline is
now y=411. Reflections sit behind actors, light immersion tint stays below front
contact art, and submerged facades no longer inherit the interior's dry mask.
All three pocket cues are consistent and quieter. Rock collision is unchanged.
Final Forward+ fixture: 92 checks pass; surface 14, house entry 405, walkways 606,
encounter/reset 19 and existing authoring/readability checks pass.
[Delivery and captured views](verification/lakeside_water_delivery_2026_10_22.md).
**Awaiting hands-on appearance acceptance and Chase's separate Krita background**;
T17 remains open. The original [water review](design/lakeside_water_review_2026_10_22.md)
and its temporary previews are historical diagnostics. Use the current delivery
and [test card](next_test_session.md) for this implementation.

## Milestone and working limits

**Current work: October 26 playtest corrections.** Chase confirms the house
bouncing fix and working villagers; the two villager poses are sufficient for
now. Water reflections, rendered boot/platform contact, roof landing, tower-base
occlusion, enemy frame jitter, static bulb idle, breakable-rock depth and the
blocked workshop door remain reported defects. Prefer current 3D enemies now.
[Exact feedback and screenshots](verification/lakeside_playtest_2026_10_26.md).
New door/indoor-camera/tower-entry architecture has a separate
[approval proposal](design/lakeside_entry_focus_proposal_2026_10_26.md).
Fix one coherent item at a time and commit/push each result. Previous visual
acceptance remains pending unless specifically confirmed above.

October 26 breakable depth correction: stone, cracks and debris now sit at -6,
behind cave faces (-5). Twelve focused Forward+ checks pass, including actual
occlusion pixels at all damage stages. Gameplay is unchanged; manual overlap
review remains pending. See the linked playtest report for validation.

Enemy correction: the comparison defaults to the existing 3D enemies and keeps
painted villagers, with independent controls. 166 comparison checks pass,
including F2 preserving the selected model display; manual review is pending.

Roof landing correction: existing one-way roofs remain active outdoors; only
interior floors are ignored until entering. 417 house-entry checks pass,
including real player landings on six exposed roof locations. Rendered boot
contact remains a separate open correction, and appearance needs manual review.

Player boot registration: measured/rendered contact corrected to within 0.79
world pixels in idle/walk/crouch samples. 14 GPU contact and 49 ledge checks plus
water-combo regression pass. Tower front timber/collision alignment remains
open; this does not by itself close Chase's tower screenshot defect.

Tower contact correction: nine platforms now match the installed GLB deck
heights (7.29–26.54 px lower than the old source-derived values). Twenty GPU
checks pass against mesh vertices and actual player sweeps, with an in-room
boot/deck capture in the playtest report. Manual appearance review remains open.

Water correction: reflection coverage is independent of body translucency and
captures current scenery before water. Six actual reflection pixel checks and
92 existing GPU water checks pass; shore/swimmer views are in the playtest report.
Chase's water appearance acceptance and Krita background remain pending.

Bulb idle correction: living currents/bubbles move within the painted sac while
stem/petals/attachment stay fixed. 13 GPU checks and 166 comparison checks pass,
including grapple/spent/regeneration. Manual motion review remains pending.

**Current delivery: T19, retain the central tower in 3D and polish its roof.**
Chase authorized the medium choice and tower polish on October 24. Choose 3D
for platform/wall/base-entry depth. The tower now defaults to 3D independently
of the comparison's other categories, with a separate Tower checkbox for the
retained painted alternative. V4 smooths the timber fascia, fixes tile UV
projection/spacing and reduces tile normal strength. All 12 non-roof meshes,
original bounds, nine platforms and six cutaway clearances are preserved.
31 focused GPU / 149 comparison headless checks pass. **Roof appearance still
awaits Chase's review.** Implementation **`4716a96d`** is pushed on
`threadbound/art-central-tower-roof-polish`, including the editable source in LFS.
[Delivery and evidence](art/central_tower_3d_polish_v4.md).

**Current correction: T18 playtest reports collision mismatch and bouncing art.**
The painted pass reproduced 9–17 px camera drift; pushed fix `8f2c7f6d` measures
at most 0.71 px in 135 GPU samples at 30/90/144 FPS. House floor contacts and nine
tower platform heights now use per-surface registration; the tower cutaway's
horizontal crop offset is corrected. 13 contact-height assertions and the
existing 168 comparison checks pass; contact fixes are pushed as `ed0b4dd9`.
Added visual bob is removed. Swordfish now has a dedicated 12-frame swim loop
for hover/dash glide: 67 focused GPU checks and 148 broader headless checks pass.
Attack transitions still use comparison key poses. T19 chooses the tower's 3D
direction; other enemies' animation quality remains unreviewed.
Unchanged collision alone was insufficient validation.
[Playtest findings and fixes](verification/painted_registration_2026_10_22.md).

**T18, painted 2D comparison.** Delivered and pushed as
`6d23110c` on `threadbound/art-painted-2d-comparison`; source measurements are
`6e654911`, building sheets `f47c62fe`, LFS setup `9efac8e7`. Thirteen painted
sheets cover four buildings, lanterns, two villagers/workstations, five enemy
types and bulbs. The separate comparison scene retains the original player,
gameplay, scale and placements; F7 switches art, with independent category
controls for mixed choices. 168 focused checks, 405 house-entry and 19 authored
encounter/reset checks pass; 32 captured views are saved. This remains a review
experiment with pose-based animation, not permanent art-direction acceptance or
a performance benchmark. **Awaiting Chase's comparison when home.** T17 also
remains awaiting playtest and the new Krita background.
[Scope, source measurements and delivery](art/lakeside_painted_2d_comparison.md).

Accept one existing representative Blue room: complete its baseline route with
the existing kit, use an optional expressive route, recover from a missed action,
read enemy tells/contact, restart reliably and observe frame time at normal
playing scale. Fix reproducible blockers before extending content production.

Keep one implementation task active and at most one prepared hands-on session.
If a task waits for Chase's playtest or approval, take the next independent ready
background task below. Park new ideas in the backlog. A new idea does not silently
replace the current task or bypass its Git checkpoint.

Active assets: Eave Runner v4, villagers v2 and Loom Heron v3. Eave Runner v2/v3
are retained historical sources/exports. The central tower now uses the scoped
v4 roof polish from its existing 3D source; v1–v3 remain historical references.
Roof appearance acceptance remains pending. Preserve the current direction.

## Required commit rhythm

1. Start with `git status --short --branch`, inspect recent history and select one
   task. State what its next commit will preserve.
2. Finish one coherent result. Run relevant checks; distinguish automated passes,
   observed failures, unsupported checks and hands-on decisions.
3. **Git checkpoint before changing topics:** save editor/art files, stage explicit
   paths, inspect the staged diff, run `git diff --cached --check`, commit and push.
4. Record the task result, tested revision and next retest in this list or its
   linked report. End with branch, latest commit, remote status and remaining edits.

Review status about every 30-45 minutes during longer work. Commit a useful unit
when ready; do not wait for an entire phase or manufacture empty commits. Each
independent bug fix gets its own commit. A playtest with feedback gets a notes
commit; any resulting code fix is a separate coherent commit. Preserve interrupted
work as a clearly described WIP checkpoint with its known failures if needed.

The assistant handles routine commits/pushes and calls out **Git checkpoint due**
before another direction starts. Chase's manual Godot/Blender/Krita changes must
be saved too. If Chase wants to run Git, provide exact commands and verify the
result. Full rules: [Git workflow](development_git_workflow.md) and `../AGENTS.md`.

Stay on the current stabilization branch for related fixes. After review and
integration, create focused `threadbound/<type>-<description>` branches from the
accepted base. Do not silently move back to an older branch. Saving/pushing does
not authorize merging, publishing a build or protected implementation changes.

## Phase 1 - establish reliable current behavior

- [ ] **T01 - House floors and cutaways.** Partially complete; first priority.
  Current state: **Awaiting hands-on review**. Layout/shortcut fix: `9abd15ff`.
  Approved Interact doors are implemented: walk past outdoors, enter/exit at the
  door, stand on the aligned floor with no outdoor rock interference, and greet
  residents only inside. Fisher loft remains disabled. The 405-check house,
  51-check NPC, map, 19-check guardian and legacy art-prep fixtures pass.
  [Approved scope and results](design/lakeside_house_entry_proposal.md).
  [Dated diagnosis and fix results](verification/lakeside_floor_diagnosis_2026_10_21.md)
  retain the original failures and current limitations. Done when approved
  entry/exit behavior and indoor contact pass focused checks and Chase's visible
  retest. Implementation commit subject:
  `feature: add deliberate door entry to lakeside houses`.

- [ ] **T02 - Villager interaction.** Awaiting hands-on review; depends on T01's
  entry behavior for final acceptance. Verify Net Mender and Boatwright
  selection/prompt, real interact input, work-to-talk transition, facing, return
  to work and obstruction behavior. The original checkpoint recorded 12 failures;
  after the approved door delivery, all 51 headless checks now pass,
  including greeting, facing, obstruction and range exit. Hands-on acceptance
  is still pending; the fixture explicitly enters each house before greeting.
  Done when the corrected scenarios pass and both NPCs have an exact hands-on
  greeting retest. Commit each coherent defect as
  `fix: restore <specific lakeside interaction behavior>`.

- [ ] **T03 - Breakable wall restoration.** Background task; can proceed
  independently of NPC review. Reproduce the authored hit-count restoration
  mismatch in `verify_lakeside_hud_and_breakables.gd`. Confirm the intended counts
  from the authored instances, active-dash-only fracture, repeat F2 restoration
  and ordinary terrain blocking. Preserve five enemy identities and spawn points.
  Done when wall/reset behavior agrees with authored data and the focused
  fish/wall/bulb and guardian reset checks pass.
  Commit: `fix: preserve authored breakable wall state on reset`, or a precisely
  named `test:` commit if the defect is exclusively in the fixture.

- [ ] **T04 - Bring verification up to current content.** Background task; finish
  after T01-T03; investigation can start independently. Replace obsolete
  three-enemy/v2-heron assumptions with assertions about the actual authored
  actors and active v3 bird. Eave Runner v4 is now installed under T16; the old
  v3-specific integration fixture remains historical and is not a current v4
  pass. Use the dedicated v4 runtime check; do not install v3 or weaken checks
  to turn it green. Make Forward+ requirements and unsupported headless outcomes explicit,
  rather than trusting exit code 0 alone. Record new results with revision/engine
  and isolated save data. Scope any shutdown-resource investigation separately
  if it affects repeatability; existing warnings are not proof of harmlessness.
  Done when active-content suites pass, every remaining failure/unsupported check
  has a specific reason and next step, and historical results remain dated.
  Commit by fixture/topic: `test: align <fixture> with current lakeside content`.

## Phase 2 - play, decide, fix, commit

- [ ] **T05 / H1 - Player controls and water combat.** Chase at computer; independent
  of the lakeside NPC fixes when using `blue_lake_greybox.tscn`. Use the
  [30-minute controls checklist](next_test_session.md#h1-lake-controls-and-player-water-combat--about-30-minutes).
  Check swimming, surfaces/dry pockets, all combo taps, specials/AP, both facings,
  cancellations, air attacks/pogo and capsule wall/ledge contact. Also retest
  the previously reported swim-idle sword arm, Flow afterimage jitter and taking
  hits underwater; these are questions to verify, not newly confirmed bugs.
  Done when each area is keep/change/untested with exact reproductions for up to
  three priorities. Commit: `docs: record H1 controls and combat playtest`.
  Each resulting authorized fix gets its own `fix:` commit and focused retest.

- [ ] **T06 / H2 - Enemy readability and fairness.** Chase at computer; follows H1
  unless a separate enemy session is more practical. Lake: Tide Duelist, Reedhook,
  Bellstriker. Lakeside landmarks: Eave Runner v4 and ranged Loom Heron v3.
  Judge tells, aim commitment, dodges/blocking, interruption, recovery, contact,
  terrain boundaries and repeated F2/reset behavior at normal speed.
  Done when each actor has a keep/change/untested decision and blocking defects
  have reproducible follow-ups. Commit: `docs: record Blue enemy encounter review`.
  Combat-system/tuning proposals still follow the existing approval rules.

- [ ] **T07 / H3 - Bulbs, barriers and return paths.** Chase at computer; use the
  bulb-choice room and the representative existing route after T03. Check melee
  recoil, dash lift, remote clear, visible ready/spent/refill states, a missed
  launch, fish fracture teaching and a usable return path. Complete the baseline
  with the existing kit; optional expression must not become progression gating.
  Done when route purpose, recovery and unclear cues have explicit decisions.
  Commit: `docs: record bulb and barrier route acceptance`; implement approved
  corrections in separate focused commits.

- [ ] **T08 / H4 - Visual scale and measured performance.** Chase at computer;
  background source review may proceed independently. Compare player/enemy/NPC
  scale, hand/blade contact, heron silhouette, foreground occlusion, cutaways,
  pavilion/deck seams and resize/mipmap behavior in real Forward+ rendering.
  Record hardware, resolution/settings, repeatable scene/setup and typical/worst
  observed frame times before proposing changes. No verified performance budget
  exists yet; agree on one from the target experience and measurements.
  Review current Eave Runner v4 at normal playing scale; Chase provisionally
  accepted its installation while noting remaining roughness. Review retained
  tower art separately; replacements still need approval. Done when current visuals have decisions,
  performance has a reproducible baseline and any optimization has a measured
  target. Commit: `docs: record Blue visual and performance baseline`.

## Phase 3 - accept the slice and check the candidate

- [ ] **T09 - Accept one representative Blue room.** Chase plus background fixes;
  depends on relevant T01-T08 outcomes. Choose an existing room, document baseline,
  optional and recovery routes, then test traversal alone, encounters alone and
  the combined room through repeated completion and reset. Resolve blocking
  findings before broader region/art production. Scene restructuring requires
  the file-specific approval proposal before editing.
  Done when the milestone above is observed on a recorded revision and remaining
  polish is clearly separate. Commit: `docs: accept representative Blue room at <revision>`
  only after acceptance; use a review-results title while acceptance is pending.

- [ ] **T10 / H5 - Shared-system and full-demo regression.** Background checks plus
  Chase's hands-on session after shared fixes are ready. Use disposable save data.
  Cover new/continue, keyboard/controller, menu cancel vs dash, grapple/guard/AP,
  all objectives/doors, tutorial, boss/ending, Keep Exploring, repeated death,
  save/Knot recovery and reload. Investigate new script errors and resource
  ownership diagnostics rather than carrying them forward without a disposition.
  Done when the candidate's exercised paths pass and all untested/blocking cases
  are stated. Commit: `test: record candidate demo and input regression`;
  each discovered defect gets a separate focused `fix:` commit.

- [ ] **T11 - Review and integrate the saved work.** Git review; prepare the
  checkpoint/stabilization PR with what changed, why, exact validation and current
  limitations. Review the diff and active asset references. Keep WIP candidates
  identifiable; open-source inputs retain provenance/licenses. Merge only after
  review/authorization. Earlier PR preparation can proceed while playtests wait.
  Done when the agreed integration base is recorded and subsequent work starts
  from it. Existing topic commits supply the PR; no empty commit for opening it.

- [ ] **T12 - Exported candidate and release evidence.** Background provenance
  audit can start now; export acceptance follows T09-T11. Identify the actual
  public demo baseline, record candidate commit/version/engine/export settings,
  and test the exported executable for fresh launch, saves, controller, endings
  and performance. Keep generated builds outside source control. Do not publish
  or tag a release as part of routine checkpointing.
  Done when an exported candidate has a reproducible report and a separate
  release decision. Commit: `docs: record exported candidate verification`.

## Scoped visual corrections

- [ ] **T13 - Matching bridge/balcony stamp objects.** **Awaiting visible review**.
  Existing current-library PNGs and catalog are saved with source hashes under
  `ArtSource/BlueBiome/Placeables/WalkwayStamps/` (`6d4122b3`). Approved 2D
  crossing, veranda, engawa and broken-pair prefabs are available; rock-attached
  T01 is excluded from runtime. Nine intact visuals now fit original landing
  collisions with route positions/gaps unchanged. The broken option is unplaced.
  **606 walkway checks**, map, **405 house**, **51 NPC** and **19 encounter**
  checks pass headlessly; existing shutdown diagnostics remain for T04.
  Implementation: `art: integrate matching village walkway stamps` (see Git log
  for hash). Scope, collision audit and results are in the linked proposal.
  Done when Chase accepts seams, feet, rail depth and match beside the houses
  at normal playing scale in daylight/dusk. Commit that review before another
  art direction.

- [ ] **T14 - Background wood depth separation.** **Awaiting visible review**.
  Approved scope/provenance and delivery are in the linked correction above.
  Original `STAMP REAR SUPPORTS`: 15 independent wood chunks behind 32 combined
  rock chunks, with reduced saturation/contrast and a cool haze shader. Layout,
  collision and unrelated artwork are unchanged. Unfiltered recomposition
  differs by at most one channel value; repeat import is byte-identical. Map,
  **405 house** and **606 walkway** checks pass; editor shader validation passes
  with no warnings/errors. Existing shutdown diagnostics remain for T04.
  Commit: `fix: separate background timber from lakeside rock art` (see Git log
  for hash). Done when Chase accepts the wood as clearly non-solid background
  in daylight/dusk while playable rock/timber edges remain clear. Record any
  material tweaks and checkpoint before switching art direction.

- [ ] **T15 - Nest bridges and bulbs into rock.** **Awaiting visible review**.
  All four reusable walkway types and nine placed decks use absolute z=-6;
  combined cave rocks use z=-5, behind the player and ahead of the walkways.
  Bulbs default to z=-6; runtime art/particles follow their editor depth,
  including nested/reparented art. Geometry and source textures are unchanged.
  Map, **606 walkway**, **30 bulb-art**, bulb-choice traversal and **405 house**
  checks pass. [Delivery and current depth order](verification/lakeside_rock_overlap_2026_10_21.md).
  Commit: `fix: tuck bridges and water bulbs behind rock art`. Done when bridge
  ends, bulb bases and pop effects sit correctly against overlapping rocks.

- [ ] **T16 - Eave Runner model cleanup.** **Installed; provisional acceptance / hands-on review pending**.
  Chase requested a substantial correction toward the original saved ninja
  concept. Rebuilt hood, torso/wrap, scarf, shoulders, trousers and waist tabs;
  fitted bracers/bindings and removed malformed cropped clothing geometry.
  Preserved the sixty-bone rig and twelve named action durations. Native source,
  self-contained GLB, fresh before/after/pose renders and validation reports are
  saved under the linked delivery. **1,279 Blender and 127 isolated Godot checks
  pass**; 372,508 triangles import with matching topology, rig and clips. Native
  previews were inspected; in-game GPU appearance and acceptance remain pending.
  Candidate checkpoint:
  `art: refine Eave Runner toward saved concept` on
  `threadbound/art-eave-runner-cleanup`, based on `96b2c039`.
  Chase approved the live swap October 22: accepted for now, still rough.
  Both active scene references now use v4; old v2/v3 sources/exports are retained.
  Runtime model/wrapper and encounter/reset validation are recorded in the
  delivery. Installation checkpoint: `asset: install approved Eave Runner v4`.
  Remaining acceptance: normal-scale in-game appearance and any specific polish
  follow-up Chase chooses. Do not extend this task into another speculative art
  pass; checkpoint the approved installation before changing topics.

- [ ] **T17 - Water presentation and terrain contact.** **Approved implementation
  delivered; visible acceptance/background pending.** October 22: surface and
  opacity controls `4ad653bc`, front rock contact `5428b96e`, wet exterior/dry
  cutaway and consistent pockets `fc40a9b2`. All pushed. Manual placement edits
  are preserved in `4130555b`; rock collision and original painted pixels remain
  unchanged. Final 92-check Forward+ fixture and 14 surface / 405 house / 606
  walkway / 19 encounter-reset checks pass, plus authoring/readability fixtures.
  See the [delivery](verification/lakeside_water_delivery_2026_10_22.md) for draw
  order, eight rendered views and remaining T04 diagnostics. Next: the short
  [hands-on card](next_test_session.md), then integrate Chase's new Krita
  underwater-distance export as a separate asset checkpoint when supplied.
  Do not mark complete before that acceptance/integration is recorded.

- [ ] **T18 - Painted 2D versus current model comparison.** **Delivered; awaiting
  Chase's visual/motion decisions.** October 22 request explicitly authorizes this
  reversible comparison while Chase is away. Implementation `6d23110c` is pushed
  on `threadbound/art-painted-2d-comparison`. F6
  `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`; F7 and
  separate Buildings/Actors/Bulbs controls compare all painted or mixed choices.
  First playtest corrections: camera drift `8f2c7f6d`, house contacts and tower
  cutaway registration `ed0b4dd9`, followed by the 12-frame swordfish swim loop.
  Fourteen RGBA sheets / 62 atlas frames; 148 headless comparison and 67 swordfish
  GPU checks pass. Earlier registration checkpoint: 168 comparison GPU checks;
  original delivery: 405 house-entry and 19 encounter/reset checks. Original gameplay/layout source
  matches `4448c06f`. Review [delivery and image pairs](art/lakeside_painted_2d_comparison.md)
  and [test card](next_test_session.md). Six enemy key poses, two NPC character
  poses and six bulb lifecycle poses are comparison animation; swordfish hover
  and dash glide use the added 12-frame cycle. Its attack transitions remain key
  poses. Full production
  animation, tower-resolution polish and any permanent replacements follow a
  recorded choice. T04 diagnostics remain open. Do not mark accepted until
  Chase's preferred categories and remaining polish are recorded.

## Parked until the current milestone is accepted

T19 delivery checkpoint: retain the central tower's 3D direction; roof-polish
implementation and automated verification are complete. Hands-on appearance
acceptance remains unchecked in the [T19 delivery](art/central_tower_3d_polish_v4.md).

- Swordfish friendly damage/redirection, multi-dash elite, Stillwater Tortoise
  and additional ecosystem mechanics: scope and obtain required approval first.
- New enemy types, explosive bird/moth ideas and combat/equipment expansion.
- Broad Blue-room production, installing a new tower, or replacing current art.
- Eave Runner v3 installation: superseded as the review target by Chase's T16
  request and installed v4. Retain v3 as historical source. Further v4 art polish
  is deferred; Chase accepted the current rough iteration for now.
- Lore/faction proposals remain documented proposals until explicitly approved.

These items are saved ideas, not an instruction to implement them now.

## Progress record and completion rules

- [x] Recovery baseline: `16b3bd3c`, committed and pushed; all pending source work
  saved. [Fresh verification](checkpoint_2026_10_21.md) records seven passing
  suites, five failing suites and one graphical-only unsupported check.
- [x] G00: write this ordered plan and persist the required Git checkpoints in
  `AGENTS.md`. Commit subject: `docs: establish focused todo list and required git checkpoints`.
  Use this document's Git history for its exact commit; no gameplay changes or
  new game tests are part of this planning task.

For each task add: `ID | state | tested commit | checks/results | Chase decision
or pending review | task commit | next action`. An exact commit subject can
identify a result in the same commit; add its hash on the next work-list update
instead of creating a second commit only to record the first commit's hash.

States: **Ready**, **In progress**, **Waiting on approval**, **Awaiting hands-on
review**, **Accepted**. A checked item needs its own acceptance evidence; a code
pass alone does not accept controls/art. New reports should record scene,
input/setup, observed vs expected behavior and severity. Prioritize lost control,
wrong damage, blocked routes and broken recovery before cosmetic polish.

## Manual test cards

Open the named scene in Godot and press F6 for focused room tests. Use F5/the main menu for the complete demo flow.

| Test card | Scene | What to exercise |
| --- | --- | --- |
| Lake movement | `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` | Rest-to-swim, reversal, release input, up/down/diagonal travel, wall contact, slow/fast breach, immediate re-entry, dry pockets from each side; no stuck wet/dry state or underwater wall cling |
| Water combat | Same lake | Single tap, tap-buffered full chain, hold input, both facings, turning between strikes, swimming during attacks, floor contact, dash cancellation and surface exit; no unwanted pogo, repeated hits or body jumps |
| Water specials | Same lake | Neutral, left/right spin, low AP, movement during windup/recovery, wall stopping and water/land transitions; no extra AP spend or restarted damage windows on transition |
| Enemy encounters | Same lake | Fish tell/locked dash/recovery, hurt interruption, shoreline/pocket/wall containment; Reedhook dodge-behind, reach and ledges; Bellstriker combo spacing, escape and interruption; no idle-contact damage |
| Bellstriker focus | `Src/Enemies/Bellstriker/bellstriker_test.tscn` | Water-to-land leaps, land-to-water return, upright guard, jab/cross/smash, both facings, wrists/feet, harmless gaps, walls and reset |
| Air/ground regression | Lake or an appropriate dry test space | Ground combo 1/2/3, neutral/spin special, air forward/up/down and pogo; blade, VFX and actual hits agree; normal movement resumes cleanly |
| Bulb routes | `Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn` | Four-direction melee recoil, dash lift both ways, remote pop without velocity change, ordinary contact, regeneration, upper chain, missed launch and return route |
| Environment experiment | `Src/Environment/BlueBiome/Prototypes/Rooms/blue_pavilion_3d_playtest.tscn`, plus `blue_deck_2m.tscn` in the same folder | Stairs, roof/deck contact, module seams, foreground occlusion, scale and frame time |
| Demo regression | Main menu -> Chamber of the First Weave | New/continue, tutorial, all three objectives/doors, boss/ending, Keep Exploring, pause/options/merchant/save camera recovery, repeated death, Knot recovery and reload |
| Input regression | Appropriate lake/chamber scenes | Keyboard and controller jump/dash/grapple/block/interact; switching input glyphs; menu cancel without triggering dash; AP recovery and Flow presentation |

Judge new attacks and tells at normal speed first. Slow motion helps locate a problem but cannot establish feel. Test save/reset in a scene that actually has a save point; restarting the lake is a different check. Use a disposable test save/profile for the demo regression.

## Existing automated checks to use

The October 21 checkpoint records the current passing, failing and unsupported checks. Use T04 to reconcile obsolete fixtures; do not treat the inventory below as a current pass report. Run relevant checks after a fix and broader checks for T10, keeping automated evidence separate from hands-on acceptance.

| Change area | Existing checks |
| --- | --- |
| Water/air attacks | `tools/combat/verify_water_combo.gd`, `verify_water_specials.gd`, `verify_lake_attack_refresh.gd` in that folder |
| Enemies | `tools/enemies/verify_tide_duelist.tscn`, `verify_reedhook.tscn`, `verify_bellstriker.tscn`; `tools/enemies/verify_bellstriker_animation.gd` |
| Water/room authoring | `tools/environment/verify_lake_authoring.gd`, `verify_lake_readability.gd`; `tools/environment/verify_room_greybox.tscn`, `verify_bulb_choices.tscn` |
| Pavilion/deck | `tools/environment/verify_blue_pavilion_3d.gd`, `verify_blue_deck_2m.gd` |
| Defense/input/grapple | `Src/Tests/PlayerCombat/player_defense_test.tscn`; `tools/input/verify_separate_controller_interact.tscn`; `tools/grapple/verify_base_grapple.tscn`, `verify_controller_grapple_aim_assist.tscn` |
| Demo reliability | `tools/ui/verify_menu_cancel_guard.tscn`, `verify_game_over_recovery.tscn`; `tools/save/verify_thread_knot_recovery.tscn`; `tools/tutorial/verify_tutorial_completion.tscn`; `tools/boss_testing/verify_proto_weaver_boss.tscn`; `tools/demo_ending/verify_demo_ending.tscn`; `tools/playtest_support/verify_playtest_support.tscn` |

For listed `.gd` scripts that extend `SceneTree`, use Godot's `--headless --path . --script res://<path>`. Run listed `.tscn` checks as scenes so their autoload-dependent setup initializes. Use an isolated user-data directory for checks that could persist settings/progress. Record new script errors separately from the historically documented log/certificate and shutdown warnings; do not assume all warnings are harmless.

## References

- [Blue roadmap](design/blue_biome_development_roadmap.md)
- [September lake feedback](design/lake_playtest_2026_09_25.md)
- [Current water combo and specials](art/water_combo_v1.md)
- [Authored air attacks and later runtime notes](art/manual_aerial_animation_guide.md)
- [Current Tide Duelist](art/tide_duelist_behavior.md)
- [Bellstriker revisions](art/bellstriker_v1.md)
- [Approved ecosystem prototype direction](design/blue_swordfish_ecosystem_and_environmental_combat.md)
- [September checkpoint validation](checkpoint_2026_09_26.md)
