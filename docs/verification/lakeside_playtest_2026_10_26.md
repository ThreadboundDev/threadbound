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
