# Threadbound status and work list

October 21 checkpoint: [consolidated current recap](checkpoint_2026_10_21.md).
Fresh checks found unresolved lakeside floor/NPC interaction failures and stale
fixture expectations. Eave Runner v3 is retained but inactive; the runner and
villagers use v2, and the heron uses v3. Treat the earlier assessment below as
dated context; the checkpoint lists the current verification results and next work.

Reviewed October 5, 2026 against commit `5f42ee0b` on `water-cleanup`.

This is a repository and documentation review. No new gameplay tests, automated Godot checks, performance measurements, or export tests were run for this review. “Implemented” means current code/scenes exist; it does not mean accepted by playtest or ready for release. Older passing checks belong to their recorded revisions.

October 10 update: [six focused fish, bulb and room-authoring checks passed](verification/focused_checks_2026_10_10.md) on `5f42ee0b` plus current uncommitted work, using Godot 4.7.2 Mono and isolated test data. This includes the newly present swordfish-wall fracture and attached bulb-art prototypes. No functional failures were found and no gameplay edits were made. Live editor, feel/visual, broader combat, demo/export and performance review remain pending.

## Overall assessment

Threadbound has a substantial demo foundation and an active Blue-region prototype. The current work is at the integration and playtest stage: the live 3D player, water traversal, attacks, three enemy roles, bulbs, and environment experiments need to work together convincingly. Region production and release readiness are not established by the current checkpoint.

Recommended next milestone: **accept one representative Blue room for movement, combat, readability, and repeatable play.** Complete it with the existing kit, exercise an optional expressive route, recover from mistakes, and finish without losing control or encountering new gameplay errors. Compare player/world scale in that same room. Then extend the proven approach.

## Current status

| Area | Evidence in the current project | Next acceptance step |
| --- | --- | --- |
| Demo foundation | Main menu, chamber wing objectives, boss, save/death recovery, merchant, tutorial, ending, and feedback UI exist | Fresh-run and continue-run regression through the whole chamber |
| Player | Live 3D visual integrated into the 2D controller; movement, grapple, guard, Flow and action-point systems exist | Controller feel, action transitions, scale, and contact readability |
| Air attacks | Authored forward/up/down clips are integrated; later runtime timing updates exist | Both facings, blade/contact alignment, pogo and return to movement |
| Water combat | Three-hit tap-buffered combo plus neutral and directional specials exist | Normal-speed animation, swimming control, hit windows, cancellation, and surface transitions |
| Tide Duelist | Current dash is 1050 px/s; living hover/dash animation and water containment are implemented | Tell/lock readability, decisive release, punishable recovery, and boundary cases |
| Reedhook | Dry-platform windup/sweep, interruption, wall and ledge behavior exist | Fair reach and recovery, facing commitment, and edge cases |
| Bellstriker | Amphibious pursuit/leaps and boxing combo exist; current live model is v4 | Combo readability, land/water transitions, attached wrists, moving feet, hurt/reset |
| Water bulbs | Melee recoil, boosted dash, remote clear and regeneration exist; lake now also contains bulbs | Steering recovery, usefulness, return paths and combinations with enemies |
| Blue environment | Lake greybox, macro-room prototypes, painted terrain, village studies, pavilion V2 and deck module tests exist | Choose a coherent approach after route, scale, collision/art alignment and performance review |
| Enemy ecosystem | Current local work includes swordfish-fracturable walls; their integration check passed October 10. Friendly damage, elite variant and tortoise remain future work | Review barrier teaching/readability/return paths; scope the next ecosystem step after encounter decisions |
| Release | Project and Windows export preset still use `0.1.0-rc2`; no local tags identify the public build | Establish the public-build baseline and validate a new exported candidate before release claims |

## Two ways to keep moving

Chase can often discuss ideas and make decisions while away from the computer. Treat that as productive development time. Hands-on playtesting is a separate queue, not a prerequisite for every task. Work on independent documentation, source reviews, reproducible fixes, automated checks and scoped design proposals while feel/visual acceptance waits for a play session.

When Chase says they are away, use the first ready item in the Away queue. When Chase asks for the test list, read [Next test session](next_test_session.md), check whether its target revision/scenes still match the current project, and give the short ordered checklist directly in chat. Chase should not have to assemble it from the documentation.

### Away queue: conversation and background work

Priority is top to bottom among items whose dependencies are ready. These tasks can happen during an active conversation/work session without Chase physically playing the game.

| ID | Priority | Task | Concrete output / status |
| --- | --- | --- | --- |
| A1 | First | Keep notes and test handoff aligned with current code | October 5 cleanup completed; maintain after each relevant change |
| A2 | Completed for focused scope | Fish, bulb and room-authoring verification | Six checks passed October 10; report links tested source state, existing diagnostics and pending editor/manual coverage. Run other checks only for a new relevant change or explicit broader task |
| A3 | Next | Discuss what makes fish tells, Bellstriker pressure and water combat successful | Small decision note: intended feel, what to preserve, edge cases, and what only playing can settle; ready for conversation |
| A4 | Then | Turn reported bugs into focused fixes | Reproduction, authorized fix, relevant verification, and a pending hands-on retest; waiting for a concrete bug/report |
| A5 | Then | Plan one representative Blue room using existing geography | Baseline route, optional route, recovery and encounter purpose on paper; ready for discussion, geometry acceptance waits for H3 |
| A6 | Later | Scope swordfish redirection and one barrier prototype | File-specific proposal, faction exception, teaching setup, edge cases and tests; planning can proceed, implementation follows applicable approval and encounter decisions |
| A7 | Later | Audit release/source references and prepare export verification | Public-build baseline evidence, current asset/source map and candidate checklist; can progress independently of feel review |

Systems discussion and planning can advance while playtest items wait. Do not broaden an unresolved feel change merely to fill away time. Approved implementation can proceed where its dependencies are ready; passing automated checks leaves hands-on acceptance pending.

### At-computer queue: Chase's hands-on decisions

| ID | Priority | Task | Decision / dependency |
| --- | --- | --- | --- |
| H1 | First | Lake movement and player water combat | Keep/change on control, combo/special motion and transitions; next session is prepared |
| H2 | Next | Fish, Reedhook and Bellstriker encounters | Keep/change on tells, commitment, reach, recoveries and interruption; use a separate session so H1 stays short |
| H3 | Then | Bulb routes, representative room and player/world scale | Accept baseline/expressive/recovery routes and framing; informs final room/art production |
| H4 | Then | Pavilion/deck rendering and performance | Accept collision/art agreement, foreground visibility and observed frame time |
| H5 | Before a playable candidate | Full chamber/controller/save/ending regression and exported build | Shared-system reliability and candidate acceptance; do not infer this from an F6 lake restart |

Each implementation item may have its own short retest that comes before these broad sessions. Keep the next-session sheet current so a new fix's reproduction can become the first check without restarting the entire list.

## Milestone backlog

### Now: close the playtest loop

- [ ] **Run focused lake playtests (H1/H2).** Record keep/change decisions for water movement, attacks, fish, Reedhook and Bellstriker. Capture short clips of specific problems. Independent Away work can continue between sessions.
- [ ] **Fix the largest reproducible blocker.** Prioritize lost control, wrong damage, stuck transitions and unreachable routes, then unclear tells/contact. Recheck the exact reproduction and the adjacent action after a fix.
- [ ] **Judge water-combo presentation.** The live combo now adapts the grounded `slash_2` segments with swimming legs; the separate manual water donor is historical. Review the runtime result before spending more time editing the older donor.
- [ ] **Accept enemy tells and recovery.** Fish dash speed has already changed since the September feedback. Decide whether the current version achieves the intended release; do not treat the old “speed change pending” note as proof that it remains unimplemented.
- [ ] **Compare player/world scale.** Use one room and fixed camera framing. Decide whether the concern is visual scale, camera framing or room proportions before changing movement/collision dimensions.
- [ ] **Run the relevant existing Godot checks on this revision.** Record commit, result and new warnings. A passing code check still needs the visual/feel review above.

Done when: each reviewed item has a keep/change decision, blocking problems have reproducible fixes, and the relevant checks pass on the reviewed commit.

### Next: one coherent Blue slice

- [ ] Select one existing representative room and identify its safe baseline route, optional expressive route and recovery path.
- [ ] Test traversal alone, each encounter alone, then their combination. Make sure enemies and bulbs help the room's purpose instead of merely adding pressure.
- [ ] Review player/enemy silhouettes, foreground occlusion, terrain contact, water/air-pocket boundaries and sword feedback at normal speed.
- [ ] Compare pavilion/deck experiments against the same scale and collision standards. Test stairs, roof landings, repeated-module seams and near/far art layers before extending the kit.
- [ ] Measure frame time in the lake with the live player and enemies, then in the pavilion scene. Note hardware/settings and worst moments; there is no verified current performance baseline.
- [ ] Run the chamber regression before making a shared player/enemy change part of a broader playable candidate.

Done when: the room is repeatably completable, has useful optional expression and recovery, reads clearly, and has an observed performance baseline.

### Later: prove the ecosystem in small steps

- [ ] Prototype swordfish damage against other enemies. Current shared damage handling rejects same-faction damage unless explicitly allowed; the reviewed fish path does not establish that exception.
- [x] Current local work implements swordfish-fracturable greybox walls; the October 10 integration check passed for active-dash-only fracture, successive walls, solid terrain and dry pockets.
- [ ] Accept barrier readability and one natural teaching encounter by playing; a passing synthetic wall fixture does not establish the authored route or teaching quality.
- [ ] Test successive dash relocation and a usable return route; preserve base-kit completion and the current no-progression-gating rule.
- [ ] Consider the multi-dash elite only after the common fish is accepted.
- [ ] Prototype the Stillwater Tortoise shell interaction after redirection works in an ordinary room.
- [ ] Expand Blue room production and finish art after representative geometry, scale and rendering are accepted.

These are proposals to organize future work, not authorization to change combat, equipment, scene structure, lore or approved assets. Prepare the required file-specific approval proposal when implementing work covered by `AGENTS.md`.

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

The October 5 source review did not rerun checks. The October 10 [focused report](verification/focused_checks_2026_10_10.md) records the six fish/bulb/room-authoring checks now run; other checks in this table remain unrun for this pass. Run focused checks after relevant fixes; run the broader set before accepting a shared-system candidate. These tests vary in depth: some inspect source/configuration and others exercise live animations/physics. They do not collectively certify the full game.

| Change area | Existing checks |
| --- | --- |
| Water/air attacks | `tools/combat/verify_water_combo.gd`, `verify_water_specials.gd`, `verify_lake_attack_refresh.gd` in that folder |
| Enemies | `tools/enemies/verify_tide_duelist.tscn`, `verify_reedhook.tscn`, `verify_bellstriker.tscn`; `tools/enemies/verify_bellstriker_animation.gd` |
| Water/room authoring | `tools/environment/verify_lake_authoring.gd`, `verify_lake_readability.gd`; `tools/environment/verify_room_greybox.tscn`, `verify_bulb_choices.tscn` |
| Pavilion/deck | `tools/environment/verify_blue_pavilion_3d.gd`, `verify_blue_deck_2m.gd` |
| Defense/input/grapple | `Src/Tests/PlayerCombat/player_defense_test.tscn`; `tools/input/verify_separate_controller_interact.tscn`; `tools/grapple/verify_base_grapple.tscn`, `verify_controller_grapple_aim_assist.tscn` |
| Demo reliability | `tools/ui/verify_menu_cancel_guard.tscn`, `verify_game_over_recovery.tscn`; `tools/save/verify_thread_knot_recovery.tscn`; `tools/tutorial/verify_tutorial_completion.tscn`; `tools/boss_testing/verify_proto_weaver_boss.tscn`; `tools/demo_ending/verify_demo_ending.tscn`; `tools/playtest_support/verify_playtest_support.tscn` |

For listed `.gd` scripts that extend `SceneTree`, use Godot's `--headless --path . --script res://<path>`. Run listed `.tscn` checks as scenes so their autoload-dependent setup initializes. Use an isolated user-data directory for checks that could persist settings/progress. Record new script errors separately from the historically documented log/certificate and shutdown warnings; do not assume all warnings are harmless.

## Documentation and release housekeeping

- [x] Refresh the September 25 lake checklist for the October 5 runtime: combos/specials, authored air integration, current fish release, three enemies and lake bulbs.
- [x] Distinguish current runtime from historical sections in `docs/art/air_water_and_spin_combat.md`, `manual_aerial_animation_guide.md`, `water_combo_v1.md` and `bellstriker_v1.md`. Historical source work is preserved.
- [x] Refresh the Blue roadmap's current priorities and availability split. Common fish and Bellstriker are implemented prototypes; ecosystem interactions remain separate work. Update acceptance after the next playtest.
- [ ] For future work, use `threadbound/<type>-<description>`. The current branch is `water-cleanup`; it was left unchanged during this review.
- [ ] Identify the actual public-demo commit/build. A clean working tree and a checkpoint commit establish saved source state, not a tested release.
- [ ] Before sharing a new build, verify fresh launch, saves, controller, feedback/ending flow and performance from the exported executable; record its commit/version and intended scope.

## A manageable session rhythm

Keep at most **one Away implementation/planning task and one hands-on review session** active. Park additional ideas in the backlog. “Waiting for Chase to play” is a dependency on that item, not a freeze on independent work.

1. **Away session:** take the highest ready A item. Discuss decisions, review source, run relevant checks or fix a concrete issue within authorized scope. Write the result and any exact hands-on retest into the handoff.
2. **At-computer session:** use the prepared short list, starting with retests from recent fixes. Complete H1 in about 30 minutes; split enemy/bulb/environment/demo review into later sessions. Record keep/change or untested for each item.
3. **After feedback:** turn observations into up to three prioritized actions, route code/investigation back to Away and feel/visual decisions to At-computer, and refresh the next-session sheet. Close an item only when its own acceptance conditions are met.

Planning states: **Ready**, **In progress**, **Waiting on decision/approval**, **Awaiting hands-on review**, **Accepted**. For each active item record availability, priority, dependency, revision, result and next action. Do not turn “implemented” or “automated pass” into “Accepted” without the required review. Reprioritize reproducible blockers ahead of polish.

Use this entry format for feedback:

`Area | keep/change | scene + input/setup | observed | expected | clip timestamp | severity | next action`

Severity: **P0** prevents play or recovery; **P1** breaks control, damage or an intended route; **P2** harms readability/feel; **P3** is polish. Unreviewed items are not confirmed bugs. Mark an item complete only after its observed result satisfies the acceptance step.

## References

- [Blue roadmap](design/blue_biome_development_roadmap.md)
- [September lake feedback](design/lake_playtest_2026_09_25.md)
- [Current water combo and specials](art/water_combo_v1.md)
- [Authored air attacks and later runtime notes](art/manual_aerial_animation_guide.md)
- [Current Tide Duelist](art/tide_duelist_behavior.md)
- [Bellstriker revisions](art/bellstriker_v1.md)
- [Approved ecosystem prototype direction](design/blue_swordfish_ecosystem_and_environmental_combat.md)
- [September checkpoint validation](checkpoint_2026_09_26.md)
