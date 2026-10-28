# Threadbound current TODO list

Updated October 28, 2026. This is the single current priority list. The saved
recovery baseline remains `16b3bd3c`; dated evidence is in the
[October 21 checkpoint](checkpoint_2026_10_21.md).

**Current priority: T20 — accept the October 26 playtest corrections.**
Implementation is delivered on `threadbound/fix-lakeside-playtest-feedback`;
**awaiting Chase's appearance/feel review**.
[Feedback, screenshots, approval and validation](verification/lakeside_playtest_2026_10_26.md).
Use the [one current retest card](next_test_session.md), about 8–10 minutes.

**October 28 curated assets / separate 3D study (T25): Recommendations delivered; selection pending.**
Chase requested filtering the free-assets directory by usefulness and licensing,
and expressed interest in a separate stylized/low-poly 3D experiment. The
[ranked shortlist](assets/curated_asset_shortlist_2026_10_28.md) identifies five
first choices, eight optional additions/alternatives and three music candidates
with primary-page CC0 evidence; it also records reuse priorities and source
triage. New archive inspection, audio listening and engine import are unperformed.
The [small separate-project proposal](design/separate_3d_study_proposal_2026_10_28.md)
records art/camera/movement goals, later traversal questions and proposed files.
No assets downloaded/replaced and no experiment or conversion implemented.
Validation: primary listing/license review and documentation diff/link checks.
Checkpoint: `docs: curate asset shortlist and scope separate 3d study`.
T20 remains the production priority; asset picks and experiment scope await Chase.
Follow-up: Chase selected **full 3D movement with a third-person camera** for the
separate experiment. Direction recorded; no production conversion or prototype
implementation performed. Decision checkpoint:
`docs: record third-person direction for separate 3d study`.

**October 28 armored golem assessment (T24): Review delivered; selection pending.**
Chase explicitly requested review of a newly downloaded Fab golem and pasted
its license. [License, source inventory, stills and attack preview](assets/armored_golem_review_2026_10_28.md).
Measured 45,704 triangles with equipment, 90 bones, three material families and
25 animation FBXs. Three ZIP CRC passes; all mesh/animation FBXs inspected;
idle1/attack1 converted for local rendering after rest-pose mismatch was found.
Fab Standard permits intended commercial use without required attribution but
is not CC0. This is a separate licensed candidate; CC0 collection policy remains
unchanged, and using it as an exception is undecided. Raw source stays local in
Downloads; only renders/metadata/scripts are checkpointed. No boss/scene/lore
changes or runtime validation. Checkpoint:
`docs: assess armored golem license and boss-source suitability`.

**October 28 sound audition (T23): Awaiting Chase's listening review.**
Chase requested environmental SFX candidates and current-source comparisons.
[Local audition browser and use guide](assets/nox_sound_audition_2026_10_28.md):
60 starter candidates, all 1,644 NOX sounds and 27 current SFX sources; search,
surface/category filters, filename/duration sorting, playback, current-source
comparisons, favorites, notes and pick export. Original-level previews stream
from the external archive; no sounds installed or replaced. Focused catalog,
PCM and HTTP checks pass; browser interaction checked. Listening acceptance is
pending; choose sounds before a separate implementation task. Checkpoint:
`chore: add NOX sound audition browser and environment shortlist`.
T20 remains the implementation priority; this is a standalone review aid.

**October 28 CC0 reuse comparison (T22): Awaiting hands-on appearance/motion review.**
Chase authorized a side-by-side house/villager study and simple table-work motion
using the downloaded rig, clothes and animation stock. Delivered as isolated
[stills, motion loops and editable Blender source](art/cc0_house_villager_comparison_2026_10_28.md).
Existing painted workshop/villager on the left; CC0 modular house and clothed,
animated worker on the right. 97 saved-scene pose checks verify wrist targets,
planted feet, loop closure and packed images; both GIFs contain 48 frames / 4 s.
Checkpoint: `art: compare CC0 house and animated clothed villager`.
No game assets replaced; runtime import/performance remain untested. Chase's
keep/change decision is pending. Full 3D conversion remains undecided; after
this review delivery, T20 is still the implementation priority. NOX's 1,644 CC0
SFX files remain available; only the two custom-license music packs were removed.

**October 28 asset-library audit (T21):** Chase requested an inventory and reuse
recommendations for the new free asset downloads. See the
[original 13-pack audit](assets/free_asset_inventory_2026_10_28.md) and the
[current CC0-only library/search plan](assets/cc0_library_and_search_plan.md).
Chase then requested CC0-only retention: Bestiary and both custom-license music
packs removed; ten packs with included CC0 notices retained. Low-poly is a
preferred look, but a full 3D conversion is undecided. Hybrid reuse and one later
workshop comparison are recommendations, not an implementation authorization.
Remaining original archives are staged outside the project in
`C:\Users\chase\Documents\Threadbound Asset Library`; raw assets remain local,
not part of the Git backup. No imports, art replacements, combat/equipment
changes or lore changes were made. T20 remains the implementation priority.

- [x] **T21 — asset inventory delivery.** Complete as an audit, not art acceptance.
  Checkpoint: `docs: inventory downloaded asset library and reuse candidates`.
  Validation: 13 ZIP CRC passes; 4,760 file entries; 531 glTF/GLB inspections;
  archived SHA-256 verification; bundled license/PDF review and creator-page
  checks. Found three missing P13 texture references, documented for a later
  working-copy import fix. Audio audition, Godot import/retargeting, appearance and any future
  installation remain untested/unapproved. Next: review shortlist, then scope
  one reuse trial after stabilization. Weapon upgrades/finds are proposals only.
  CC0 policy follow-up checkpoint:
  `docs: apply CC0-only asset policy and focus reuse searches`; verified retained
  hashes/counts and removal paths. No gameplay or visual acceptance is implied.

**October 27 follow-ups delivered:** house handoff, water-entry grapple/arm reset,
dolphin range, independent duplicate dolphin, and continuous water over the closed
tower exterior. Each implementation has its own verified commit/push. Chase approved
the [exterior-water plan](design/tower_water_exterior_proposal_2026_10_27.md) and
dolphin reparenting on October 27. Appearance/feel acceptance remains pending.
[Feedback and per-fix results](verification/lakeside_followups_2026_10_27.md).

House handoff correction delivered: `fix: ground house entry before releasing door animation`.
Checkpoint `8b6a0470`: 20 headless / 20 GPU handoff checks and 417 house checks pass. Both houses retain
floor contact at the exact release frame in painted/model modes. Retest entry's
last turn/walk-to-idle moment; appearance/feel awaits Chase's review.

Grapple water-entry correction delivered: `fix: cancel grapple and casting pose on water entry`.
Checkpoint `92c7e72d`: 122 headless / 122 GPU checks pass across all four gloves, and water combo passes.
The active rope and upper-body cast clear on wet entry; delayed pull/snap/release
state is cancelled without changing movement velocity. Retest throw-then-fall.
The legacy broad grapple fixture retains 20 identical failures on the prior
scripts and current fix; reconciliation remains T04.

Chase's saved duplicate-enemy placement edits were preserved in WIP checkpoint
`bd9c11bb`. The approved dolphin-only parenting correction is now delivered:
`9f09f306` (`fix: separate duplicated dolphin from parent movement`). It preserves `(349,2008)`
and makes the added dolphin a room sibling. 28 checks pass for independent motion,
walls, targeting, death, save reset and repeated F2/3D selection. The added heron's
nesting remains unchanged in this scoped correction. Hands-on review is pending.

Dolphin range adjustment delivered: `4bd9966d` (`fix: extend dolphin awareness and engagement range`).
Detection is 1,000 px and dash engagement is 850 px, retaining the outer tell
band and existing damage/speed/warning timing. 32 focused range/occlusion checks
and the existing Tide Duelist integration suite pass. Retest engagement distance;
the separate hierarchy correction is delivered above.

Tower exterior-water correction delivered: `fix: keep tower exterior submerged until cutaway opens`.
The closed tower no longer punches its dry pocket through the visible lake;
opening it restores the dry interior. Foreground facade/stone shares the lake's
immersion grade. Physical pocket geometry, platforms and entrance collision are
unchanged. 33 focused GPU, 97 water-room GPU, 6 reflection pixel and 16 surface
checks pass; actual player standing dry and swimming outside are verified.
Inspect the left exterior, base approach, dry interior and exit for appearance.

October 26 follow-up from Chase's brother: entry animation looks good; exit
repeats the entering motion, downhill movement loses smooth ground contact,
and upward water dash travels diagonally. See the follow-up section in the
linked report. Door/slope/water-dash corrections are **Awaiting hands-on review**.
User approved the scoped equipment dash correction October 26.
Feedback checkpoint: `1718dffa`.

Door exit correction delivered: `651b5ff0`;
91 Forward+ / 76 headless checks pass, entry/exit renders inspected. Awaiting
hands-on feel review. Local comparison-scene metadata errors remain T04.

Downhill contact correction delivered: `1bad5eef`;
61 focused checks (12 mirrored slope/speed cases), 49 capsule/ledge and 417
house-entry checks pass on Godot 4.7.2. Before/after evidence is linked from the
playtest report. Retest the brother's original sloped platform at normal speed;
its exact landmark remains unspecified. Do not mark T20 accepted from these
automated results.

Approved water-dash correction delivered: `fix: follow held swim direction for water dash`.
245 focused checks pass across eight directions, neutral-facing fallback,
Jump-as-up, both facings, input release/change, water exit, AP/cooldown/immunity,
wall contact and bulb cancellation. Existing bulb-route, water-combo and
water-special checks pass; combat-feedback assertions pass with unparented-actor
script errors (qualified result; T04). Retest Up alone underwater and through
the surface; diagonal input should remain diagonal. Land dash remains horizontal.

Water immersion follow-up delivered: `fix: keep lake steady and immerse swimmers`.
Entering water no longer fades the lake/reflections or exterior facade grade.
An independent foreground veil, faint currents and small rising bubbles put
submerged actors inside the water; dry pockets and foreground rocks stay clear.
10 focused GPU pixel checks, 6 reflection pixel checks, 16 surface checks and
94 room checks pass. Appearance remains **Awaiting hands-on review**. Screen-space
reflection fading when its source leaves the camera remains a known limitation;
this correction removes the additional observer-state fade. Evidence and the
current retest card are linked above.

Chase confirmed that house bouncing is fixed and the villagers' work/greet
interaction functions. The two villager poses are sufficient for now. Fisher's
loft remains deferred. Keep 3D enemies for now; retain painted alternatives for
comparison. The tower remains 3D. Chase approved the full
[door/focus/rim proposal](design/lakeside_entry_focus_proposal_2026_10_26.md).

| T20 delivered correction | Commit | Validation / acceptance |
| --- | --- | --- |
| Breakable stone, cracks and debris behind cave faces | `6c4f4ed6` | 12 GPU checks; overlap review pending |
| 3D enemy default; villagers selected independently | `92dcf437` | 166 comparison checks incl. F2; movement review pending |
| Exterior one-way roofs landable | `0a932de0` | 417 house checks incl. six exposed roof landings |
| Rendered player soles grounded | `ed560f63` | 14 GPU pixel checks; <0.79 px error; 49 ledge checks and water combo pass |
| Nine tower floors follow installed deck geometry | `56f69ef8` | 20 GPU checks; mesh/physics agree within 0.04 px; appearance pending |
| Visible water reflections restored | `d797f051` | 6 reflection pixel checks + 92 water checks; appearance/background pending |
| Living water currents/bubbles in painted bulbs | `c2b12563` | 13 GPU checks, fixed attachment and lifecycle; motion review pending |
| Workshop exterior table removed | `ed36e5e3` | Same RGBA canvas/world envelope; crop/contact/import checked |
| Same-door animated entry/exit, indoor focus and amber exit cue | `a30c4ca0` | 79 GPU + 417 house + 166 comparison checks; feel review pending |
| Tower front stone occludes swimmers during cutaway | `3e887e82` | 13 GPU checks; all 35 other meshes/data preserved; depth review pending |
| Fixtures follow door travel and explicit art selection | `ef396db3` | Map: 0/9,871 mask mismatches; 51 NPC / 166 comparison / 55 optional fish checks; water combo passes |

- [ ] **T20 acceptance.** Review doors/camera/exit cues, visible boot contact,
  roof landings, tower approach, water, bulbs, breakables and default 3D enemies.
  Record keep/change/untested and fix any reproducible blocker as its own
  verified commit/push. Automated passes do not accept visuals or controls.
- [ ] **Next independent implementation: T03.** Reconcile authored breakable
  wall reset counts. The depth correction did not change durability/reset logic.
- [ ] **Then T04.** Reconcile obsolete fixtures and investigate existing
  rendering/resource teardown diagnostics. They remain open, not a clean run.

Current comparison default: painted houses/villagers/bulbs, 3D tower/enemies,
existing live 3D player. Tower v5 retains the v4 roof polish and adds only the
front-rim split. Eave Runner v4, villagers v2 and Loom Heron v3 remain active
model sources. Prior versions are retained references. Chase's separate Krita
water background remains pending; waterline registration is still y=411.

The milestone remains one reliable representative Blue room: complete the
baseline and optional expressive route, recover from a miss, read enemy tells,
restart reliably and observe frame time. Do not extend content production while
reproducible blockers remain. Keep one implementation task and one prepared
hands-on session active. Save manual Godot/Blender/Krita files and checkpoint
before changing topics.

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

- [ ] **T01 - House floors and cutaways.** Latest implementation and pending
  review are T20 above. Same-door animated entry, indoor focus and exit cues are
  delivered, with 417 house-entry / 79 focused GPU checks. Fisher loft remains
  disabled. Chase must accept the new transition/contact feel. Earlier
  [door delivery](design/lakeside_house_entry_proposal.md) and
  [floor diagnosis](verification/lakeside_floor_diagnosis_2026_10_21.md) are dated
  evidence; October 26 supersedes their immediate-teleport behavior.

- [x] **T02 - Core villager interaction.** Chase confirms both residents function
  in the October 26 playtest (`3c640e96` feedback checkpoint), and accepts two
  work/greet poses for now. After the new door travel, 51 interaction checks
  pass (`ef396db3`), including left/right greeting, return to work and obstruction.
  New entrance/exit prompt comfort is part of T20 acceptance; no additional
  villager idle animation is requested.
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
  Approved scope/provenance: [wood depth correction](design/lakeside_rear_support_depth_proposal.md).
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
  order, eight rendered views and remaining T04 diagnostics. The October 26
  reflection correction `d797f051` adds six rendered-pixel checks and restores
  visible coverage; use T20's [current card](next_test_session.md) for acceptance.
  Then integrate Chase's new Krita
  underwater-distance export as a separate asset checkpoint when supplied.
  Do not mark complete before that acceptance/integration is recorded.

- [ ] **T18 - Painted 2D versus current model comparison.** **Delivered; awaiting
  Chase's visual/motion decisions.** October 22 request explicitly authorizes this
  reversible comparison while Chase is away. Implementation `6d23110c` is pushed
  on `threadbound/art-painted-2d-comparison`. F6
  `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`; F7 and
  separate Buildings/Tower/Villagers/Enemies/Bulbs controls compare mixed choices.
  First playtest corrections: camera drift `8f2c7f6d`, house contacts and tower
  cutaway registration `ed0b4dd9`, followed by the 12-frame swordfish swim loop.
  October 26: Chase confirms house bouncing is fixed and NPC poses function;
  enemies now default to 3D because painted transitions still jitter. Bulb idle
  motion and door/focus corrections are delivered under T20; its current mixed
  default and acceptance card supersede the original comparison setup below.
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
