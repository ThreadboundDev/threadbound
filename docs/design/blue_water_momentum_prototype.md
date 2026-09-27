# Blue Water Traversal Prototype

The isolated test scene is `blue_water_playground.tscn`. Chamber Exit is not a
water-mechanics test room and should remain unchanged while this prototype is tuned.

## Current traversal rules

- Polygon water supports freely shaped test volumes.
- Directional input bends the existing trajectory and adds propulsion. Acceleration
  grows with current speed until a high safety ceiling, so clean routes compound.
- Low-speed resistance makes the water feel thick at entry, then fades along a
  squared curve as momentum builds. Normal propulsion caps at the swim ceiling;
  water breaches use the higher breach ceiling. Bulbs use the action responses below.
- Releasing input coasts without stopping; striking terrain is the primary way to
  lose speed after the Hermit's water traversal item removes water resistance.
- Crossing any water boundary preserves the current trajectory and applies a
  bounded momentum multiplier. Upward steering at an edge therefore becomes a
  speed-scaled jump without replacing the velocity with a fixed jump value.
- A breach owns movement briefly after crossing the boundary, then blends normal
  air control back in. This prevents ordinary horizontal input from erasing the
  launch while still allowing double jump and grapple to redirect the route.
- Grapple retracts and cannot fire while the player is submerged. It is available
  immediately after a breach.
- Water bulbs no longer check impact speed. Melee attacks pop them and launch the
  player opposite the strike; dashes pop them on contact and carry the incoming
  velocity forward with a 1.2 multiplier and at least 1000 px/s upward lift.
- Grapple and ranged hits pop bulbs without changing player velocity. Direct
  melee DamageData explicitly sets `is_melee`; other damage defaults to remote.
- Ordinary contact gently ejects without consuming the bulb. Bulbs regenerate
  for retries and backtracking. Authored multi-hit bulbs count weapon hits;
  dash and grapple consume the bulb immediately.
- The isolated choice room is
  `Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn`.
  Its default one-hit bulbs demonstrate dash carry, downward-strike recoil,
  an optional upper chain, and remote clearing over a safe recovery floor.

## First tuning questions

1. Is low-speed steering responsive enough to recover from mistakes?
2. Are attack recoil, dash carry, and remote clearing distinct and useful choices?
3. Is wall speed loss noticeable without making a failed route feel dead?
4. Do high-speed breaches produce useful, controllable aerial arcs?
5. Does the water-to-grapple-to-water loop feel intentional and immediate?

## September 14 test-basin entry

The integrated test basin now has a bank-derived Dive prompt using the existing interact binding. Stand near either bank facing the water and press interact. The controller plays the existing dive clip above water, gives a collision-aware launch, and hands back to the existing momentum swimming on contact. Airborne falls still enter normally. No unlock policy or new progression gate was added.

Rectangular and polygon test water use a translucent blue tint (default alpha 0.34), preserving submerged-player visibility. The existing animated reflective treatment remains in `Src/Environment/BlueBiome/Water/blue_reflective_water.tscn`, used by `blue_chamber_exit_production.tscn`; it is separate from the flat test basin. Its shader currently outputs opaque color, so future underwater art work should explicitly revisit that treatment rather than assume it is already transparent.
