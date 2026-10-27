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
