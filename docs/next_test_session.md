# Next hands-on test session

October 21 checkpoint update: [fresh results and known failures](checkpoint_2026_10_21.md).
Before relying on the lakeside NPC route, reproduce Fisher house/Workshop floor
contact and Net Mender/Boatwright greeting failures. Existing NPC interaction
checks currently fail. The active runner is v2; retained Eave Runner v3 is not
installed. Heron v3, guardian encounters, capsule contact and fish/wall/bulb checks
passed headlessly. GPU appearance, frame time and hands-on acceptance remain open.

Prepared October 5 and updated October 10, 2026 for `5f42ee0b` plus current uncommitted work. Status: **Ready; not yet played for this checklist.** Six [focused fish/bulb/room-authoring checks passed](verification/focused_checks_2026_10_10.md); that does not accept feel or visuals. Queue item: **H1** in [Project status and work list](project_status_and_worklist.md).

When Chase asks “what should I test?”, give the numbered list below directly in chat. Check the current revision and any intervening changes first; add a recent fix's short retest at the top when relevant. Do not ask Chase to reconstruct the list or replay all historical checks.

## Short checks for current changes — about 5 minutes

October 21: the **Loom Heron** landmark now uses the bird-only v3 art rebuild.
Check its ceramic face, layered wings and woven construction at normal playing
zoom, then watch flight, charge/fire and low recovery. Compare frame time with
the previous bird and use F2 to repeat. Source, imported-art and existing
combat/map fixtures pass; GPU appearance and art acceptance remain a hands-on
check. [Bird delivery](art/loom_heron_quality_v3.md).

October 20: in `blue_lakeside_krita_playtest.tscn`, use the **Eave Runner** and
**Loom Heron** landmark buttons. Bait the runner's wall leap, dodge its blade,
then check its return to a wall; its open-ground fallback throws one pin. Dodge
the heron's locked ranged needle and punish its low hover recovery. Check the
new v2 geometry, 4K maps and sharper rendering on both enemies and both villagers.
Compare scale and frame rate with the player. F2 restores all five enemies. Automated
combat/map checks pass; attack feel and visual acceptance still need Chase's
playtest. [Current delivery](art/woven_guardians_gameplay_v1.md).

Before H1, in the lake check that the Water Bulbs are visible above the water/backdrop, their art aligns with contact, and pop/spent/refill states match actual availability. Bait an existing fish into a marked breakable wall: it should open only during its damaging committed dash; ordinary terrain should still stop it. If that setup is inconvenient, leave it for H2 rather than consuming the controls session.

When using the editor, verify Room Greybox's **Breakable Wall** button creates a selectable/resizable wall and undo restores the room. The live-editor dock check could not run without a connected editor. Use a temporary room copy for this authoring check. Text feedback is sufficient; no need to repeat the passing automated fixtures manually in detail.

## H1: lake controls and player water combat — about 30 minutes

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` in Godot and press F6. Swimming is enabled in this test scene. Use the preferred input device; a complete keyboard/controller comparison belongs to H5. Start in a clear patch of water so an enemy attack does not obscure the first control checks.

1. **Swimming, about 5 minutes.** Start/stop, reverse quickly, travel up/down/diagonally, touch a wall. Does control stay predictable? Wall contact should not become underwater wall cling.
2. **Water boundaries, about 5 minutes.** Leave the surface slowly, then quickly; re-enter immediately. Enter/leave a dry pocket from multiple directions. Report stuck states, unexpected boosts, missing control or an obvious visual boundary mismatch.
3. **Basic combo, about 7 minutes.** Tap once, then tap again during each swing to reach all three hits. Compare holding Attack, both facings, swimming during the chain and turning between hits. Look for readable body/weapon motion, smooth handoffs and alignment between blade, effect and contact. Downward underwater hits should not pogo. Use the fish as a target if comfortable; enemy fairness is H2.
4. **Water specials, about 5 minutes.** Use Special with no horizontal input, then with left/right. Check AP spending, ability to steer and the spin against a wall. Cross the surface during an ability if practical: watch for a restarted effect/hit window or extra resource spending. These are current underwater abilities, not future features.
5. **Cancellation and dry comparison, about 5 minutes.** Dash during the basic combo and exit water during a swing; control should recover cleanly. On the starting dry platform compare ground attacks, air forward/up/down, downward pogo when a target is available, and neutral/directional Special. Record untested cases if the setup is inconvenient.
6. **Decisions, about 3 minutes.** Give keep/change/untested for swimming, boundaries, combo, specials and transitions. Choose at most three issues to work on next.

Stop once a serious loss of control, incorrect damage or blocked route is reproducible. Record the scene, exact input/setup, expected result and what happened; that is enough to begin investigation. A clip timestamp is helpful when available, but text feedback is sufficient.

Short feedback is fine: “combo: keep; turn between hit 1/2 snaps left; specials: untested.” We can turn that into the next Away tasks.

## Upcoming sessions, in order

| Session | Where | Focus |
| --- | --- | --- |
| H2: enemies, about 30 minutes | Lake, then `Src/Enemies/Bellstriker/bellstriker_test.tscn` if needed | Fish tell/locked release/recovery and boundaries; Reedhook commitment/reach/ledge; Bellstriker jab/cross/smash, interruption and amphibious leaps |
| H3: routes and scale, about 25 minutes | `Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn`, then representative Blue room | Melee recoil/dash lift/remote clear, missed launch and return route; baseline vs optional route; player/world framing |
| H4: environment, about 20 minutes | `Src/Environment/BlueBiome/Prototypes/Rooms/blue_pavilion_3d_playtest.tscn` and `blue_deck_2m.tscn` in that folder | Stairs/deck/roof contact, repeated seams, foreground visibility, scale and frame time |
| H5: candidate regression, separate longer session | Main menu/chamber, then exported candidate | New/continue, input, objectives, boss/ending, menus, repeated death, save/Knot recovery, restart and export behavior |

This sheet selects the next session; [full test cards](project_status_and_worklist.md#manual-test-cards) hold the wider coverage. Do not silently mark upcoming sessions passed because H1 goes well. Save-point behavior requires a scene with a save point and a disposable test save/profile.

## Handoff after the session

Record the tested revision/device, keep/change/untested decisions and up to three prioritized issues in the main work list. Move investigation/fixes into the Away queue and any required feel decisions into the At-computer queue. Replace this sheet's next-session list with the highest ready retests/session; preserve dated results in the main list rather than leaving an old list marked “next.”
