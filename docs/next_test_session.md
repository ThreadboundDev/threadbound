# Next hands-on test session

## Latest: T14 background wood depth — about 2 minutes

Run `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
with F6. The wood beams/pillars now have a separate cooler, quieter background
layer; Cave Walls and Under Cave Mouth remain together.

1. Use **Cave**, then look at exposed diagonal beams and upright timber
   supports. Before walking through one, does it already read as background?
2. Compare a support with the nearby playable rock edge and a timber walkway.
   The support should recede, while contact surfaces remain clear. Check for
   missing wood, doubled edges or seams where wood meets rock.
3. Use **Day / dusk** and repeat the comparison. Report keep/change for the
   filter strength. If it needs adjustment, give the nearest landmark.

The material is adjustable at `Geometry/TerrainArtwork/rear_supports > Material
> Shader Parameters`; source pixels, alpha, positions and collision are retained.
Map, 405 house-entry and 606 walkway checks pass; the shader validates in the
editor. Appearance acceptance remains open.
[Scope, defaults and validation](design/lakeside_rear_support_depth_proposal.md).
Save and **commit/push any manual changes before changing topics**.

## First: T01/T02 house doors and residents - about 5 minutes

Run `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
with F6, using the preferred keyboard/controller bindings.

1. Use **Fisher house**. Walk past the exterior: the player should remain in
   front, with no house platform/roof blocking movement and no automatic cutaway.
2. Stand at its door and press **Interact** at the **Enter** prompt. Check the
   cutaway, feet against the floor and ordinary movement/jumping inside. The loft
   has no collision for now. Greet the Net Mender, check turning and return to work.
3. Return to the inside door and press **Interact** at **Exit**. Confirm the
   outside position/facade/ground return correctly. Repeat once and try holding
   the button; one press should cause only one transition.
4. Repeat at **Workshop**. Walk right inside to reach the Boatwright. Check that
   the old floor float is gone and greeting works from both sides.
5. Use **Shore** while inside a house, then return and enter again. Report any
   leftover cutaway, missing ground, stuck prompt or wrong controller glyph.

**Net mender** and **Boatwright** landmark buttons also lead to their outside
doorways. Chase's building placements/art are retained. Visible layering, door
marker placement, feet and transition feel are the acceptance decisions; the
405 house, 51 NPC, map, 19 guardian and legacy art-prep checks pass headlessly.
[Delivery and exact scope](design/lakeside_house_entry_proposal.md).

Earlier October 21 [checkpoint results](checkpoint_2026_10_21.md) remain dated
evidence. Their house/NPC failures are superseded by the T01 results above.
The active runner is v2; retained Eave Runner v3 is not installed. GPU appearance,
frame time and hands-on acceptance remain open.

Current house delivery: `feature: add deliberate door entry to lakeside houses`
on top of `9abd15ff`, October 21, 2026. Status: **Awaiting hands-on review**.
Use Git history for the exact delivery commit. The separate lake
controls session below is T05 / H1 in the [current work list](project_status_and_worklist.md).
Check the current commit before playing. Earlier automated results remain dated
evidence and do not accept feel or visuals.

When Chase asks “what should I test?”, give the numbered list below directly in chat. Check the current revision and any intervening changes first; add a recent fix's short retest at the top when relevant. Do not ask Chase to reconstruct the list or replay all historical checks.

## T13: matching timber walkways — about 3 minutes

In the same Krita playtest, look at the bridge landings near Fisher house and
Workshop, then the longest railed span on the right. The nine old deck-edge
sprites now use the saved plank, veranda and engawa stamp art. No landings or
route gaps moved. The broken bridge is an unplaced library option; the
rock-attached landing was excluded.

1. Walk/jump onto narrow and wide spans. Check feet on the painted deck and
   railing behind the player; report floating, obscured feet or unexpected ends.
2. At normal camera zoom, compare post/brace scale and timber color beside the
   houses. Check the longest veranda for repeated-section seams or cut posts.
3. Compare daylight/dusk using the room's existing lighting controls. Give
   keep/change/untested for the match. Report the nearest landmark or Deck01–09.

The 606 headless walkway checks pass, including real player landing/walking on
all nine spans; map/house/NPC/encounter regressions pass too. Appearance remains
pending. [Delivery, exact positions and limitations](design/lakeside_walkway_stamp_proposal.md).
Save manual Godot/art edits, then **commit and push before changing topics**.

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

Save any editor changes before leaving the session. Record feedback and the
tested commit in the current work-list item, then commit and push those notes
(and any coherent authorized fix) before starting another direction. This is a
required Git checkpoint; no empty commit is needed if nothing changed.

Record the tested revision/device, keep/change/untested decisions and up to three prioritized issues in the main work list. Move investigation/fixes into the Away queue and any required feel decisions into the At-computer queue. Replace this sheet's next-session list with the highest ready retests/session; preserve dated results in the main list rather than leaving an old list marked “next.”
