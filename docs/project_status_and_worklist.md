# Threadbound current TODO list

Updated October 21, 2026. Saved game baseline: `16b3bd3c` on
`threadbound/chore-october-development-checkpoint`, committed and pushed.
This is the single current task order. The [checkpoint recap](checkpoint_2026_10_21.md)
is the evidence for the current state; older roadmaps and delivery reports do
not override its failures or imply hands-on acceptance.

**Next task: T01, correct stale house/NPC shortcuts and confirm the Fisher loft layout.**
Diagnosis is recorded below; no runtime fixes have been made. Protected gameplay,
scene, lore and asset changes still require their existing approval process.

## Milestone and working limits

Accept one existing representative Blue room: complete its baseline route with
the existing kit, use an optional expressive route, recover from a missed action,
read enemy tells/contact, restart reliably and observe frame time at normal
playing scale. Fix reproducible blockers before extending content production.

Keep one implementation task active and at most one prepared hands-on session.
If a task waits for Chase's playtest or approval, take the next independent ready
background task below. Park new ideas in the backlog. A new idea does not silently
replace the current task or bypass its Git checkpoint.

Active assets: Eave Runner v2, villagers v2 and Loom Heron v3. Eave Runner v3 is
retained unfinished work. Standalone tower v1-v3 deliveries are saved references,
not a newly accepted replacement in the game. Preserve the current direction.

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

- [ ] **T01 - House floors and cutaways.** Background task; ready; first priority.
  October 21 diagnosis at `131577a0`: [findings](verification/lakeside_floor_diagnosis_2026_10_21.md).
  The real floors and cutaways work at the houses' current positions; outdated
  landmark buttons misdirect both the player and existing fixtures. FisherLoft
  collision sits only 1px below FisherFloor; its intended upstairs use needs
  Chase's decision. Next: shortcut bug fix, then loft correction if appropriate.
  Reproduce the Fisher house and Workshop floor/contact/facade failures in
  `tools/environment/verify_lakeside_krita.gd` with the real player. Determine
  whether runtime geometry, spawn assumptions or fixture setup is wrong before
  changing it. Verify Tower and adjacent water/ledge behavior still work.
  Done when the exact failures pass for the correct reason and a short visible
  retest is queued; final feel/visual acceptance remains with Chase.
  Commit each actual fix as `fix: correct <specific house contact defect>`; if
  fixture setup alone was wrong, use `test: correct lakeside floor fixture setup`.

- [ ] **T02 - Villager interaction.** Background task; depends on T01 where floor
  contact affects the reproduction. Restore/verify Net Mender and Boatwright
  selection/prompt, real interact input, work-to-talk transition, facing, return
  to work and obstruction behavior. Diagnose the 12 failures in the current
  48-check fixture; do not assume all have the same cause.
  T01 probe: both prompts/selection work beside the current NPC positions; their
  landmark shortcuts are stale. Full greeting/turning/obstruction remains untested
  at corrected destinations, so no interaction rewrite is justified yet.
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
  actors and active v3 bird. Keep the Eave Runner v3 integration failure explicit
  as unfinished candidate work; do not install it or weaken checks to turn it
  green. Make Forward+ requirements and unsupported headless outcomes explicit,
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
  Bellstriker. Lakeside landmarks: Eave Runner v2 and ranged Loom Heron v3.
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
  Review retained Eave Runner v3/tower art separately; Chase must approve any
  replacement before it is installed. Done when current visuals have decisions,
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

## Parked until the current milestone is accepted

- Swordfish friendly damage/redirection, multi-dash elite, Stillwater Tortoise
  and additional ecosystem mechanics: scope and obtain required approval first.
- New enemy types, explosive bird/moth ideas and combat/equipment expansion.
- Broad Blue-room production, installing a new tower, or replacing current art.
- Eave Runner v3 installation: retained work needs review; its presence in Git
  is not approval. No more speculative quality passes before current acceptance.
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
