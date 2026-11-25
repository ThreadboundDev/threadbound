# Editable woven shoreline — November 21, 2026

Chase approved turning the chunk audition into an editable shore between the
chamber and the Blue rooftops. Run
`res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn` with F6. It is open in
the editor for review. This first pass provides a physical chamber-mouth
blockout and handoff markers; production room routing remains a later step.

## Play

- Start at the dry `ChamberMouth/ChamberEntrySpawn` and walk right onto Ground A.
- 1 / 2 / 3 move to the island review positions. R returns to the chamber entry.
- Use the existing movement/swimming controls; Up or held Jump swims upward.
  Swim up onto a recovery stone, then jump left back onto the island.
- O compares outlines (thin material is default), V compares the middle foliage
  base, and C shows the actual collider caps.
- `RooftopApproach` on the right is the future handoff target. The upper stepping
  route is retained, including its existing double-jump entry.

## Edit

| Saved node | What to adjust |
| --- | --- |
| `Backdrop` | Parallax scales and sky/cliff/lake/village sprite placement |
| `ShoreWater/Lake` | Position and polygon points; initial waterline Y=900 |
| `ShoreWater/BasinFloor` | Invisible sandbox floor, currently Y=1344 at its top |
| `Geometry` | Three islands, six upper platforms and two recovery stones |
| `ChamberMouth` | Dry entry floor, ceiling, existing-art framing and spawn |
| `ReviewDaylight` | The actor-only daylight used by the previous audition |
| `Player` / `Camera2D` | Exactly one authored player/camera; local camera limits |
| `RooftopApproach` | Future exit toward the rooftops |

Select the Lake instance and enable Editable Children if needed, then edit its
`CollisionPolygon2D` points with the polygon toolbar. The existing @tool water
component syncs the collision and preview. Its editor label and collision guides
are editing aids. Native saved sprites make the scenery visible before F6.
Keep the water beyond the camera's horizontal bounds to avoid exposed cuts.

The recovery stones are at Y=948, just below the initial waterline. Their depth
lets the current swim breach reach them while the player's center is dry when
standing. Move them with any major waterline/layout changes and retest getting
out. The basin floor and camera limits keep the original chunk undersides out
of the playable view. `recovery_y` on the level root defaults to 1600.

`preview_swimming` enables the existing swimming flag only on this scene's player
instance. This is a local audition setting, not a new progression rule. Player,
combat, equipment and shared water implementation remain unchanged. The water
reuses the quiet reflective/painted surface and underwater reveal already in the
project. Geometry draws after its rear reflection capture, avoiding reflected
copies of the island faces across the underwater rock.

Chase's decoration placement and ground collider adjustments are preserved.
Ground caps are 4 / 5 / 15 px below their original nominal root datum. Shadows
and collision overlays read the actual shapes. The 12 px ground-art registration,
integrated Bridge A platform and default irregular foliage are now saved scene
properties rather than hidden runtime artwork changes. Wider foliage color/
detail matching and final entrance art remain for visual review.

## Verification

- 179 headless checks and 201 Forward+ checks passed. These cover all twelve
  receiving caps, original land/upper routes, chamber-to-island walk, both water
  gaps, swim ascent, shelf footing, jump recovery, dry island caps, deep-water
  reveal, camera/basin coverage and the prior shadow/outline checks.
- The original tile-review fallback still passes 37 checks after shared lighting
  startup was changed to reuse an authored light.
- Eighteen actual 1920 x 1080 game captures include entry, three island views,
  both water gaps, submerged view, rooftop approach, grounding details, collision
  overlay and six matched outline views. `editor_overview.png` is the actual
  1200 px Godot 2D editor capture, not a concept rendering.
- All six save/settings CFG hashes remain unchanged. The three user-adjusted
  collider files are byte-identical to their pre-pass versions.

Reports: `headless_checks.json`, `gpu_checks.json`, `base_review_checks.json` and
`user_data_checks.json`. `outline_review/metrics.json` retains the actor-only
render measurements. The full approved scope is in
`docs/design/woven_shore_transition_proposal_2026_11_21.md`.

Godot still reports the existing shader-cache permission and shutdown texture/
RID/ObjectDB/resource diagnostics. Its legacy glove animation helper prints
`Missing glove anim: Swim_Idle`; the actual modular player swims and all movement
assertions pass. These diagnostics are recorded, not repaired by this level pass.
Hands-on composition, water appearance and route acceptance remain with Chase.
