# Fish, bulbs and room-authoring checks — October 10, 2026

Result: **six focused headless checks passed; no functional test failures or gameplay edits.** This is automated verification of the current local work, not hands-on acceptance or a release check.

## Tested state

- Base commit: `5f42ee0b` on `water-cleanup`, plus the current uncommitted runtime/tool changes and new breakable-wall files. These results do not describe the base commit alone.
- Engine: local official Godot `4.7.2.stable.mono.official.ed1daf0bf`, extracted from the existing downloaded archive into ignored `tmp/`.
- Execution: headless, one fresh process per check, frame-rate cap 120, safety limit `--quit-after 3600`. All checks emitted their success markers and exited 0 before that limit.
- Test user data: `tmp/focused_checks_2026_10_10/data/roaming/Godot/app_userdata/Threadbound`. A separate probe verified that the redirected `APPDATA` resolves `user://` here. The normal run save was not used.
- [Source fingerprints](../../tmp/focused_checks_2026_10_10/source_snapshot.json) and [relevant tracked diff](../../tmp/focused_checks_2026_10_10/tested_changes.patch) are local ignored artifacts. Rerun affected checks if those sources change; old results do not automatically cover later edits.

## Results

| Check | Result and coverage | Local log |
| --- | --- | --- |
| `tools/enemies/verify_tide_duelist.tscn` | PASS: station holding, awareness/eye tell, locked release, wall stopping, recovery, player damage, hurt interruption/recoil, narrow pocket/shore containment, clips, death/reset | [Fish](../../tmp/focused_checks_2026_10_10/logs/tide_duelist.log) |
| `tools/environment/verify_greybox_walls_and_bulb_art.tscn` | PASS: 26 checks, zero failures. Only an active committed swordfish dash fractures walls; successive walls release collision, solid terrain stops the dash, dry pockets block reaching walls. Bulb art exists, follows resizing/nesting, uses absolute depth and ready/pop/spent/refill/regeneration state | [Walls and bulb art](../../tmp/focused_checks_2026_10_10/logs/walls_bulb_art.log) |
| `tools/environment/verify_bulb_choices.tscn` | PASS: melee recoil, dash/remote responses and existing interaction checks; actual player reaches dash landing, downward-strike perch and upper chain | [Bulb routes](../../tmp/focused_checks_2026_10_10/logs/bulb_choices.log) |
| `tools/environment/verify_room_greybox.tscn` | `ROOM_GREYBOX_VERIFY_OK`: shared greybox primitives, collision/resource independence and existing room fixtures | [Greybox](../../tmp/focused_checks_2026_10_10/logs/room_greybox.log) |
| `tools/environment/verify_lake_authoring.gd` | PASS: stable polygon/dry-pocket fixture, controlled movement/boundaries, packing/reopening and independent volume sizes | [Authoring](../../tmp/focused_checks_2026_10_10/logs/lake_authoring.log) |
| `tools/environment/verify_lake_readability.gd` | PASS: dry-pocket precedence, wet edges, delayed overlap, wall-idle, wake clipping, pocket depth and sword-material configuration | [Readability state](../../tmp/focused_checks_2026_10_10/logs/lake_readability.log) |

No parse errors, script errors or assertion failures were reported. Readability checks inspect state/configuration; the headless renderer does not establish final on-screen appearance or performance.

## Remaining diagnostics and coverage limits

- Several runs report ObjectDB/resource-in-use warnings/errors at shutdown. This diagnostic category was already documented at the September checkpoint; the current runs are not clean shutdowns. These runs did not investigate ownership cleanup.
- Greybox and lake-readability runs print the existing legacy-glove `Missing glove anim: Swim_Idle` message. The live 3D presentation is a separate path; its visual correctness still needs review.
- Some scene checks report Camera2D being switched to physics processing because interpolation is enabled.
- The editor was not connected to the Godot AI bridge. `tests/test_greybox_editor.gd` (live dock reload/Breakable Wall button wiring) was not executed. Runtime/fixture authoring checks passed; editor placement/undo still needs a live-editor check.
- Water combo/special, Bellstriker, full demo, export and performance suites were outside this bounded pass. No conclusion about those unrun checks is implied.

## Next actions

No gameplay fix was justified by these results. Keep hands-on H1 ready and add the short current-change checks in [Next test session](../next_test_session.md): visible bulb art/pop/refill, committed fish-wall fracture, and editor wall placement/undo. No new system-design question is required to finish this verification pass.
