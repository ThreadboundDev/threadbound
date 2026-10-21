# T01: lakeside floor and cutaway diagnosis

Inspected baseline `131577a0` on October 21, 2026. No runtime, scene or asset
changes were made. This report narrows the four floor/cutaway failures recorded
at the checkpoint; it does not accept visual registration or complete T01.

## Findings

**The house landmark destinations are outdated.** The authored scene has moved
the buildings, collision outlines and residents, while the `LANDMARKS` dictionary
in `lakeside_krita_playtest.gd` still uses the older house/NPC destinations.
`verify_lakeside_krita.gd` uses those same shortcuts. These are real playtest-button
defects and also misdirect the automated checks; the failures do not establish
that the current house floors or entry sensors are broken.

| Destination | Current shortcut player origin | Current floor-supported player origin, measured |
| --- | --- | --- |
| Fisher house | `(320, -197.245)` | Approximately `(-32, 231.742)` |
| Workshop | `(2688, -1093.245)` | Approximately `(3824, -1226.258)` |
| Tower control case | `(1472, 1037.955)` | Same destination; floor and cutaway pass |

The existing Net mender and Boatwright shortcuts are outdated too. The current
NPC feet anchors are `(111, 305)` and `(4038, -1181)` respectively. A safe player
origin must account for the player's foot offset and nearby floor, rather than
copying an NPC's feet coordinate directly.

**Fisher loft collision overlaps its ground-floor collision.** Runtime polygon
bounds are:

| Collision | World bounds | Top edge |
| --- | --- | ---: |
| FisherFloor | x `-305.92..241.92`, y `301..313` | 301 |
| FisherLoft | x `-269.16..235.16`, y `302..314` | 302 |
| WorkshopFloor | x `3422.08..4225.92`, y `-1157..-1145` | -1157 |

The two Fisher platforms are almost coincident. If the loft is intended to be
an accessible upper storey, its platform is misplaced. Chase needs to confirm
the intended upstairs route/height before a correction; do not blindly restore
an old coordinate or remove the platform.

## Controlled runtime evidence

Godot `4.7.2.stable.mono.official.ed1daf0bf`, headless, dummy audio,
`--fixed-fps 60 --quit-after 1800 --path .`; isolated `APPDATA` under
`tmp/t01_diagnosis/userdata`. A temporary probe inherited the existing map
verifier's setup, instantiated the actual room, and froze all five enemies to
isolate contact. No graphical window or normal save data was used.

- Existing house shortcuts reproduced the prior failures after 25 physics frames:
  player airborne and corresponding facade closed. Tower passed as before.
- Placing the real player above each current floor and settling for 60 physics
  frames produced `is_on_floor() == true`, the expected floor collider, and
  `is_cutaway == true` for both FisherHouse and Workshop.
- Placing the player 60px left of each current NPC on its current floor produced
  visible prompt, registered interaction and correct selector for both residents.
  This does not test the full greeting, turning, timeout or obstruction sequence;
  those remain T02.
- Existing ObjectDB/resource shutdown diagnostics remained. No new runtime
  script error occurred. Rendered floor/art alignment was not assessed.

Local probe, full log and raw report are in ignored `tmp/t01_diagnosis/`.
The coordinates above can also be checked directly in the saved room's building,
resident and `CollisionPolygon2D` transforms.

## Next actions

1. Correct house/NPC shortcut destinations to the current authored layout and
   rerun the existing floor/cutaway and villager fixtures. Prefer destinations
   tied to current scene anchors over another independent list of stale numbers.
   Keep that bug fix in its own commit.
2. Confirm whether Fisher house retains a playable upper loft; then align that
   collision with the intended visible platform and verify jump-through/landing.
3. Chase's visible retest: enter both houses, confirm the facade opens and feet
   meet the visible floor, leave to restore the facade, then check the loft route.

Proposed fix scope still needs to follow applicable project rules if it expands
into scene restructuring or an art/layout redesign. This diagnosis authorizes
neither redesign nor asset replacement.
