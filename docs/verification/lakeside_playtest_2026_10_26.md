# Chase's lakeside playtest — October 26, 2026

Tested branch at report time: `threadbound/art-central-tower-roof-polish`,
`be51659f`. Chase tested the default presentation, without F7 comparisons.

Confirmed by Chase: house bouncing is fixed; villager interaction works. Two
work/greet poses are sufficient for now; no new villager idle animation requested.

Reported defects / requests:

- House roof edges cannot be landed on; revisit exterior roof collision.
- Player visibly floats above tower platforms. Previous collision-foot checks
  verified physics only, not the rendered boots relative to the platform.
- Tower front stone base draws behind the swimmer approaching from below; entry
  needs a foreground rim and a believable facade reveal.
- Water lost the visible reflections and reads as a blue depth filter. The cyan
  strip is gone, but water appearance has NOT been accepted.
- Painted enemies still jitter between poses. Prefer the original 3D enemies
  now; keep painted alternatives available for later comparison.
- Painted bulbs are static at idle; water inside must look alive/energetic.
- Breakable stone should sit behind regular cave art, with breakability shown
  by its existing crack animation; do not let glows float through solid rocks.
- Workshop facade has a table across the door. Clear that entrance artwork.
- Small houses need interior camera focus / exterior de-emphasis.
- Door entry currently snaps to an offset indoor destination. Prefer an animated
  turn-away / walk-in at the actual door and an obvious interior exit cue.

Screenshots: workshop door obstruction, tower base occlusion, and floating boots
on a tower platform. Stored under `work/lakeside-playtest-2026-10-26/`.

Do not mark previous visual items complete from automated passes alone. Address
contact against actual rendered frames. Keep each coherent correction in its
own verified commit/push. Architectural house focus/door/tower-layer changes
have a separate proposal: `docs/design/lakeside_entry_focus_proposal_2026_10_26.md`.

## Breakable cave depth correction

Stone is now absolute depth -6, immediately behind cave faces at -5. Crack
strokes inherit the stone depth; spawned debris also retains -6 regardless of
its parent's depth. Collision, durability and fracture behavior are unchanged.
`verify_breakable_cave_depth.gd`: 12 Forward+ checks pass, including pixel checks
that cave art occludes stone/cracks at all four damage stages. Existing engine
texture teardown warnings remain. Awaiting Chase's in-room overlap review.

## Enemy presentation correction

The comparison room now defaults to existing 3D enemies while preserving the
accepted painted villagers. Villagers and Enemies have separate controls; F7
still compares all categories except the independently selected tower. AI,
animation, bone anchors and collision are unchanged. The broader comparison
fixture passes 166 headless checks, including default viewport updates, F2
respawn in 3D, painted alternatives, house entry and bulb regeneration. Existing
ObjectDB/resource teardown warnings remain. Awaiting Chase's movement review.

## Exterior roof landing correction

Door-controlled houses now ignore only interior floor/loft collision outdoors;
their existing one-way roof outlines remain landable. No geometry was moved.
The expanded real-player entry fixture passes 417 headless checks, including
landings on exposed left slope/ridge/right slope of both houses, plus interior
walls, entry/exit, death, teleport and teardown restoration. All roof segments
are checked against accidental collision exceptions. The very outer eaves are
embedded in cave terrain, so landing tests use exposed segments 5/10/15.
Existing Camera2D/interpolated Camera3D and teardown warnings remain. Rendered
boot contact is a separate open issue; these are physical landing checks.

## Rendered boot registration

The live player's fixed crop left idle soles 5.5 world pixels above the capsule
foot. The crop now derives from the camera's projection of the model ground
plane. Heel/toe probes keep planted/crouched poses grounded; run/roll/jump flight
phases and the swimming crop remain authored. Four phases each of idle, walk
and crouch render within 0.79 world pixels of the physical floor. Fourteen
Forward+ checks pass, 49 capsule/ledge checks pass (hands within 0.1 px of lip),
and the water-combo regression passes. Captures and pixel measurements are in
`work/lakeside-playtest-2026-10-26/boot_contact.json` and `grounded_*.png`.
Tower front timber/floor alignment remains a separate correction.

## Tower floor alignment

The installed tower's final normalized deck heights differ from the earlier
source values used for collision. All nine physical platforms now use the
installed GLB deck surfaces, lowering them by 7.29–26.54 world pixels without
changing width or one-way behavior. Twenty Forward+ checks pass: imported mesh
vertices agree within 0.04 px, actual player sweeps contact every platform, and
the live grounded player is captured on the visible deck. This corrects the
remaining screenshot gap after boot registration. See `tower_floor_contact.png`
and its JSON under the playtest evidence folder. Chase's visual review remains
pending. Earlier T19 assertions verified physics against itself and missed the
delivered-model normalization; they did not prove visible contact.

## Visible water reflections

Reflection coverage no longer gets multiplied by the body's translucency a
second time. Its dry/wet surface coverage is now separate from immersion tint,
with quieter band variation and a fresh scenery capture immediately before
water. The six rendered-pixel checks prove that reflected source color remains
visible in both observer states and follows moved scenery even after an earlier
screen-reading effect. All 92 existing Forward+ water checks pass, including
dry pockets, exterior wet facades and rock-contact layering. The shore capture
shows bridge/post/background reflections without the old cyan gap. Captures and
reports are `water_shore.png`, `water_swimmer.png`, `water_room.json` and
`visible_reflection.json` in the playtest evidence folder. Deep underwater views
still fade screen-space reflections when their source is offscreen. Chase's
appearance acceptance and separate Krita background remain pending.
