# Two small houses: deliberate door entry

**Approved by Chase on October 21, 2026; implemented, awaiting hands-on review.**
Delivery commit subject: `feature: add deliberate door entry to lakeside houses`.
The full intended behavior and file scope below remain the approval record.

Prepared October 21, 2026 after Chase confirmed the moved house placements,
requested lower floor collision and deferred Fisher house's loft. The layout
and shortcut fixes were committed separately as `9abd15ff`. Chase subsequently
approved the entry/collision proposal below.

## Delivery and verification

Both small houses in the Krita playtest now opt into deliberate Interact entry.
House and resident landmarks take the player to the correct outside door. Enter
opens the cutaway and places the player inside; Exit restores the recorded
outdoor position. Outdoor players ignore the two houses' collision bodies and
render in front of their facades. Indoor players use bounded house collision,
ignore painted terrain, and can greet that house's villager. Debug teleports,
death flags, player removal and house teardown clean up collision and prompts.

Interior-only boundaries use the otherwise unused physics layer 32. Only the
indoor player temporarily scans it; enemy masks and project input settings are
unchanged. The original player script, assets, building placements and disabled
loft are unchanged by this entry pass. Tower retains its automatic cutaway;
boat slip remains an open shelter. The separate art-prep room retains its
original automatic house-entry behavior.

Fresh Godot 4.7.2 headless results on `9abd15ff` plus this working change:

- `verify_lakeside_house_entry.gd`: **405 checks passed**, including real input,
  exterior platform sweep, held press, enter/exit, indoor movement/jumping,
  enemy masks, collision ownership, repeated use and cleanup paths. Physics
  foot-reference errors at the two interior floors are below **0.003px**.
- `verify_lakeside_villagers.gd`: **51 checks passed**, explicitly entering
  before greeting; includes actual input, both facings, greeting end/timeout,
  obstruction, leaving and furniture instances. Indoor greeting rays ignore
  the same outdoor terrain as the player, while still respecting added walls.
- `verify_lakeside_krita.gd`: **PASS**, now asserting a closed facade outside
  and Interact entry before indoor floor/cutaway assertions. Sampled terrain
  registration still has zero mismatches across 9,871 samples.
- `verify_woven_lakeside.gd`: **19 checks passed** for both authored encounters,
  player/HUD interaction and enemy replacement.
- `verify_lakeside_3d.gd`: **PASS**, covering the separate legacy art-prep room,
  shared stage, model registration/dimensions and automatic cutaways.

Runs used isolated `APPDATA` under ignored `tmp/house_entry/userdata`, dummy
audio and fixed 60fps; no graphical windows or normal save data were used.
Full logs and the 405-check report are under `tmp/house_entry/`. The legacy
art-prep report was retained there without replacing the previous delivery's
tracked report. Existing shutdown ObjectDB/resource diagnostics remain; a
verbose follow-up identifies the existing base equipment/boots/chest script
resources, not a clean shutdown. Ownership cleanup remains a separate T10 item.

These results establish the exercised runtime behavior, not GPU appearance,
frame time or final art/feel acceptance. The next visible test is documented
in `docs/next_test_session.md`.

## Intended behavior

- Outdoors, the player walks in front of Fisher house and Workshop. Their
  walls, interior floors and roofs do not block the outside player, and their
  facades render behind that player. Painted outdoor ground remains solid.
- At an editable door position, show **Enter** using the existing interaction
  prompt and `interact` action. Use the current keyboard/controller binding;
  no new input binding and no Up shortcut in this first pass.
- Press Interact once to enter. Open the existing cutaway, position the player
  on the aligned interior floor, activate the house's interior contact for that
  player and prevent outdoor rock collision from holding the player above it.
- While inside, the existing villagers can be greeted. Outside, their prompts
  cannot steal the door interaction or allow greeting through a closed facade.
- At the inside door, show **Exit**. Press Interact to return to the recorded
  safe outdoor doorway position and restore outdoor collision/appearance.
- Leaving through debug teleport, death/removal or scene teardown must clean up
  house state and collision exceptions. Rapid interaction must not bounce the
  player between inside and outside on one press or leave stale prompts.
- Door markers, entry/exit placement and interior bounds remain editable in
  the house scenes. Preserve Chase's current building placement and art.
- Fisher loft collision remains disabled and retained for later. Broken-wall
  entrances are a later design option, not part of this implementation.

## Why this needs a behavior change

Current cutaways open on proximity/overlap alone; there is no explicit indoor
state. Both small houses share that automatic sensor behavior with other
building prefabs. The existing shared foreground pass also places their facade
in front of the player, and 2D house platforms are always solid. Those behaviors
do not express walking past outside and choosing to enter at a door.

The Workshop additionally overlaps painted rock collision. After aligning the
house floor with its source model, the real player can still stand roughly
4-6px above that floor on the rock body. Moving the house floor alone cannot
solve that contact. The proposed per-player indoor state separates the active
interior contact from the outdoor terrain while the player is inside.

## Implementation approach

Use a small house-specific controller extending the existing 2D building marker
and an Area2D door adapter for the player's existing interaction callbacks.
Opt the two instances in the Krita playtest into deliberate entry. Keep the
existing automatic behavior available to the separate art-prep room, Tower and
boat slip. Add optional facade layering to the shared 3D building script so
the two houses can render behind an outside player and hide their facade inside.

House collision is room-owned, so explicit exported references bind the two
houses to their current collision bodies. Use per-player collision exceptions
for outside house geometry and inside painted terrain, with bounded interior
contact and cleanup on every state exit. Do not disable the full map's collision
globally or change enemy collision. House/NPC access and interaction ownership
must be coordinated without changing the player's combat/controller code.

The house controllers own the new door/entry markers and necessary interior
boundaries. These are the scene/runtime structure changes covered by the
approval request. No door animation or new door asset is required: enter/exit
uses the current facade cutaway and a short position handoff in the same room.

## Files proposed for the door implementation

Paths are relative to the repository root. New script UID files are included.

1. `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_2d.gd` (new)
2. `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_2d.gd.uid` (new)
3. `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door.gd` (new)
4. `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door.gd.uid` (new)
5. `Src/Environment/BlueBiome/Buildings/Lakeside3D/fishers_house_2d.tscn`
6. `Src/Environment/BlueBiome/Buildings/Lakeside3D/net_workshop_2d.tscn`
7. `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_building_3d.gd`
8. `Src/Environment/BlueBiome/Buildings/Lakeside3D/README.md`
9. `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
10. `Src/Environment/BlueBiome/Prototypes/lakeside_krita_playtest.gd`
11. `Src/Environment/BlueBiome/Villagers/lakeside_worker_2d.gd`
12. `tools/environment/verify_lakeside_house_entry.gd` (new)
13. `tools/environment/verify_lakeside_house_entry.gd.uid` (new)
14. `tools/environment/verify_lakeside_krita.gd`
15. `tools/environment/verify_lakeside_villagers.gd`
16. `docs/design/lakeside_house_entry_proposal.md` (approval/delivery record)
17. `docs/verification/lakeside_floor_diagnosis_2026_10_21.md`
18. `docs/project_status_and_worklist.md`
19. `docs/next_test_session.md`
20. `work/krita-map-import/verification.json` (regenerated fixture report)
21. `work/lakeside-villagers/verification_headless.json` (regenerated fixture report)

If inspection shows that a different architecture or additional runtime files
are needed, update the proposal before expanding the implementation scope.

## Validation and commit checkpoint

Exercise the actual two houses and player: walk past outside with no house
contact; enter only after Interact at the door; land on the correct interior
floor without rock interference; greet the correct NPC only inside; exit and
recover outside collision; repeat; teleport away and reset/death safely. Verify
Tower/boat-slip cutaways, current house placements and guardian encounters.

Keep the existing tests meaningful by explicitly entering the houses before
asserting indoor floor/cutaway/greeting behavior. Check controller prompt/action
reuse and one press per transition. Visual confirmation of outside layering,
feet/floor alignment and doorway placement remains Chase's hands-on review.

Planned implementation commit: `feature: add deliberate door entry to lakeside houses`.
Commit the coherent runtime/scene/test change with its work-list and handoff
updates, push it, and verify remote HEAD before starting another task.
