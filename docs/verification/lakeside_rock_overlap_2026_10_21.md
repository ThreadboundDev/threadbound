# Bridge and water-bulb rock overlap

October 21, 2026; baseline `0148efd5`. Chase requested that bridge ends and
water bulbs sit behind rock faces so they can be nestled into the terrain.
This is a draw-order bug fix: no scene restructuring or asset replacement.

The room's combined cave rocks previously drew at -6, in front of background
wood but behind the bridges at -1. Water-bulb runtime art forced absolute
z=30, ignoring the placed bulb's editor layer.

Current depth order, back to front:

| Artwork | Effective z |
|---|---:|
| Rear wood supports with depth filter | -7 |
| Four reusable walkway types and all nine placed decks | -6 |
| Water bulbs and release particles | -6 by default |
| Combined Cave Walls and Under Cave Mouth | -5 |
| Main terrain rock faces | 5 |

All four walkway prefabs use absolute depth, and the nine stale z=0 instance
overrides were removed. Their positions, lengths, anchors and collisions are
unchanged. The artwork generator retains the updated rock depth.

The shared bulb scene uses absolute z=-6 in the editor. Runtime art follows
the owner's effective draw layer instead of forcing the foreground, including
nested bulbs, later layer changes and reparented preview art. Release particles
use the same layer. Existing water tint/reflections still composite normally;
no water shader or opacity was changed.

Godot 4.7.2 Mono checks, with isolated save data and logs in ignored
`tmp/rock_overlap/`:

- Map passed: all four bulbs between background supports and rock, matching
  editor/runtime layers; 9,871 rock-physics samples, zero mismatches.
- Walkways: **606 checks**, including draw order and real player landings and
  movement on all nine unchanged collision spans.
- Walls/bulb art: **30 checks**, including pop/spent/refill/regeneration,
  nesting, layer changes, reparenting and release-particle depth.
- Bulb choices: **PASS**, including melee/dash/grapple activation and the three
  existing traversal routes. House-entry regression: **405 checks**, no failures.
- Explicit success markers were checked; no script/parse errors. Previously
  recorded shutdown equipment resource diagnostics remain for T04.
- Source audit: scene changes affect only z properties; texture files, collision
  scene and collision-mask hashes remain unchanged. Historical tracked reports
  are retained rather than overwritten by the current run.

Visible acceptance remains open: F6 the Krita room, check bridge ends and bulbs
overlapped by rock, pop a bulb, and compare Day / dusk. Save and checkpoint any
manual placement changes before switching tasks.

Commit subject: `fix: tuck bridges and water bulbs behind rock art`; exact hash
in Git history. Earlier T13/T14 delivery depths are superseded by this correction.
