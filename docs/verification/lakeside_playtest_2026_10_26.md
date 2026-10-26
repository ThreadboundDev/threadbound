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

## Living water inside painted bulbs

The painted ready sac now has circulating water/highlights and rising bubbles.
Its stem, petals, outline, attachment and interaction volumes remain stationary;
spent/pop/refill use their existing lifecycle drawings without the idle effect.
Thirteen GPU checks pass: 102,124 water-pixel changes across three idle comparisons,
zero stem/petal-pixel changes, unchanged transforms/collision and correct spent
state after actual grapple activation. The broader 166 comparison checks pass,
including regeneration. See `bulb_idle_0.png`, `bulb_idle_1.png` and
`bulb_current.json` in the evidence folder. Chase's idle-motion review is pending.

## Clear workshop doorway

The comparison loads `Assets/BlueBiome/Art/PaintedComparison/workshop_v2.png`;
the original sheet is retained. Built-in imagegen removed the exterior table
and bowl, restoring the door planks/threshold. The interior worktable remains.
The RGBA canvas remains 1572×1001; alpha crops are remeasured and both floor
contacts refitted to the existing geometry. The sheet imports successfully.
Generated pixels outside the requested region vary slightly; no claim of
pixel-identical preservation. Original world envelopes remain unchanged.

Built-in edit prompt: “Remove ONLY the small wooden table and tiny bowl that
obstruct the exterior door in the LEFT building, approximately x=176..358 and
y=687..789. Reconstruct the same vertical timber door planks and lower door
threshold behind that table so this exterior doorway is completely clear.
Preserve the door's frame, exact x center and height; this is a functional door
for entering. Preserve the RIGHT cutaway interior including its own worktable,
untouched. Preserve everything else: both building silhouettes, existing canvas
dimensions/transparent margins, blue roof tiles, floor at y786, stone step,
wall decorations, window, barrel, palette, hand-painted style and two-frame
positions. Do not move, crop, scale or redraw the buildings. Retain real
transparency. The single requested change is removing the LEFT exterior
table/bowl from in front of the door.” Target: original transparent 1572×1001
workshop sheet; use case precise-object-edit. Awaiting Chase's in-game review.

## Approved animated doors and indoor focus

Chase approved the full entrance proposal on October 26. Both houses now use a
0.72-second owned transition: approach the actual door center, turn the live 3D
player away, open panels and walk in visually, reveal the cutaway while the
player is behind the doorway, and resume at the same door x. Exit reverses it.
The old offset InsideSpawn markers are retained but no longer used. Vertical
floor reconciliation occurs while the character is occluded. Brief input locks
cannot begin during hurt/attacks/save-point interaction and release on death,
debug teleport or house removal.

The occupied house gets a smooth, capped camera zoom/center with room limits;
scenery outside the room dims/desaturates. HUD remains above the focus layer.
Outdoor camera position/zoom/limits restore exactly. A quiet amber interior
door outline, handle and floor glow mark the exit at the active door/floor.
Tower camera/traversal is unchanged. No new equipment or combat system.

`verify_lakeside_entry_focus.gd`: 79 Forward+ checks pass in both painted and 3D
house modes, including actual Interact, turn/open states, blocked movement/jump,
same-door position, health, visible exterior dimming/HUD preservation, resize,
camera restoration, death/teleport and mid-entry house removal. Captures/report
are under `work/lakeside-entry-focus-2026-10-26/`. Existing house-entry checks:
417 pass; comparison checks: 166 pass. The comparison also now drops bindings
for a removed house safely. No runtime script errors remain in this fixture;
pre-existing interpolation, missing glove Death animation and rendering/resource
teardown warnings remain. Chase's visible/feel acceptance is pending.

## Tower entrance foreground stone

Tower v5 splits the original basin into 288 front triangles and 672 rear
triangles, retaining all 960 original triangles exactly once. The front stone
uses the existing foreground pass even during a cutaway; rear stone stays in
the background. All original runtime buffer bytes, 35 other meshes, materials,
texture paths, roofs and deck positions are preserved exactly. The editable
v5 Blender source is delivered with the corresponding split and packed textures.
No new geometry or collision is added.

Thirteen Forward+ checks pass, including actual player silhouette occlusion
(9,392 exposed pixels become 401 within the stone footprint), facade reveal
behind the lip and clear swimming after the existing authored breakable is
fractured through its swordfish API. The uncleared breakable still blocks as
authored; this change adds/removes no gating. Three approach/inside captures,
geometry and render reports are in `work/lakeside-entry-focus-2026-10-26/`.
The standalone geometry verifier confirms byte-exact preservation. Blender
saved the editable source despite an unavailable thumbnail-cache path. Existing
Godot interpolation, missing glove Swim_Idle and teardown diagnostics remain.
Chase's visible entrance-depth acceptance remains pending.
