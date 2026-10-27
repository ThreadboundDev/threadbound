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
