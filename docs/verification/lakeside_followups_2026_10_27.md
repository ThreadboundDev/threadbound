# Lakeside follow-ups — October 27, 2026

Chase requested these corrections while away:

1. A small jump immediately after the house entrance animation.
2. Throwing a grapple and falling into water can leave the arm holding an
   invisible grapple. Cancel the active grapple and reset its pose on water entry.
3. Longer dolphin (Tide Duelist) aggro range.
4. Duplicated dolphins synchronize; one can cross a wall. The added dolphin is
   currently a child of the original, inheriting movement outside its own sweep.
5. Reassess the tower's dry water cutout; the attached exterior/base screenshot
   still looks disconnected from the surrounding water.

These are requested corrections, not acceptance of earlier T20 visuals. Keep
each verified implementation as its own commit/push. The current branch is
`threadbound/fix-lakeside-playtest-feedback`; the starting checkpoint is
`d1fab6e6`.

The house, water-entry cancellation and dolphin range/independence corrections
are scoped to the reported bugs and explicitly requested behavior. Do not
change unrelated attacks, damage, equipment progression or enemy art.

The tower needs a choice about its dry interior. A concrete file-by-file
[proposal](../design/tower_water_exterior_proposal_2026_10_27.md) is prepared:
keep water over the closed exterior and reveal the existing dry mask only on
entry. Architectural implementation is awaiting approval under AGENTS.md.

Pre-existing worktree changes: the comparison scene contains Chase's added
Tide Duelist and Loom Heron, both nested under their originals, plus editor
metadata. Preserve it. Three previously committed verification scripts now have
editor-generated UID sidecars; record those without changing their script bodies.

Implementation results and focused retests will be appended below.

## House animation handoff

Baseline `d1fab6e6` reproduced two airborne frames immediately after releasing
the door lock in both houses, in painted and model modes. Projected sole movement
at that handoff reached 5.8–10.0 world pixels. Entry placed the capsule two pixels
above the interior floor, then held physics until the walk-to-idle transition;
the next ordinary movement tick had to rediscover its floor.

The existing house controller now resolves that placement clearance with a
three-pixel collision-checked downward step while the character is still hidden
behind the doorway. It establishes floor contact before control returns; the
same-door placement, camera, animation duration and collision geometry remain.

`verify_house_handoff.gd`: 20 headless and 20 Forward+ checks pass for both houses
in both presentation modes, with no airborne/falling-pose frames after release
and no visible sole jump. `verify_lakeside_house_entry.gd`: 417 checks pass.
Before/after per-frame body/sole traces: `work/house-handoff-2026-10-27/`.
GPU fixture uses a smaller scenery render scale beside the open editor/game;
the player's model resolution and world-space measurements are unchanged.
An initial full-size GPU run could not allocate a Vulkan swapchain; the smaller
run completed. Existing interpolation and engine resource/RID/ObjectDB teardown
diagnostics remain T04; final runs have no script errors. Hands-on feel is pending.

Checkpoint: `fix: ground house entry before releasing door animation`.

## Grapple cancellation on water entry

The cast owns a live 3D upper-body overlay. `finish_water_entry()` replaced its
`casting_2` animation without clearing that overlay; its completion signal could
then never release the held-arm pose. Base/blue/yellow gloves also retracted
gradually on water entry, while red's separate state loop did not block water.

Water entry now clears the cast overlay before starting its swim clip. The
shared glove loop cancels the active rope immediately once on entering wet
space and blocks fresh grapples while wet. Each variant clears its own delayed
action: blue swing-release buffer/momentum, red charge/tow/target state, yellow
pending snap. The existing rope reset clears attachment, target and needle/line
visuals. Cancellation preserves the player's movement velocity. Dry pockets
and dry throws after exit remain available. Chase explicitly requested this
temporary water-entry cancellation; no unrelated combat/equipment tuning changed.

`verify_water_entry_cancel.gd`: **122 headless and 122 Forward+ checks pass** with
the actual player and all four gloves. Cases include firing, attachment, retraction,
casting interruption, underwater input, sustained swim, subsequent dry throws,
red charge entry and dry pockets. The first baseline has 69 failures in 117
checks, reproducing the reported arm lock and delayed/variant rope state.
Evidence: `work/grapple-water-entry-2026-10-27/`. Existing water-combo regression
passes. Initial fixture startup/monitoring issues and a mistaken regression
script path were corrected before the final passing runs.

The older `verify_base_grapple.tscn` fixture still has **20 assertion failures**
for legacy animation libraries, coordinate expectations and impact/recovery
expectations. An isolated copy of the `8b6a0470` glove/visual scripts produces
the **identical 20 failures**; see `legacy_fixture_comparison.json`. This is
baseline-confirmed T04 work, not a passing broad grapple suite. Existing engine
resource/RID/ObjectDB shutdown diagnostics remain; final focused runs have no
script errors. Hands-on throw-then-fall feel still needs review.

Checkpoint: `fix: cancel grapple and casting pose on water entry`.

## Manual enemy placement checkpoint and parenting proposal

Save Chase's current comparison-scene edits as **WIP**, including the two added
enemies, their positions and editor metadata. The dolphin remains nested and
can inherit unchecked motion; the added heron is also nested. This checkpoint
preserves work, not accepted behavior. The exact dolphin-only reparenting fix
is [prepared for approval](../design/dolphin_parenting_proposal_2026_10_27.md).
AGENTS.md explicitly requires approval for scene tree restructuring, so that
scene edit remains pending. Longer dolphin detection is a separate requested
parameter adjustment and can proceed without changing the saved hierarchy.

Checkpoint: `level: checkpoint WIP duplicate enemy placements`.
