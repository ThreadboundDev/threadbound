# Blue Water Momentum Prototype

The isolated test scene is `blue_water_playground.tscn`. Chamber Exit is not a
water-mechanics test room and should remain unchanged while this prototype is tuned.

## Current traversal rules

- Polygon water supports freely shaped test volumes.
- Directional input bends the existing trajectory and adds propulsion. Acceleration
  grows with current speed until a high safety ceiling, so clean routes compound.
- Low-speed resistance makes the water feel thick at entry, then fades along a
  squared curve as momentum builds. Normal propulsion caps at the swim ceiling;
  bulb boosts use the higher breach ceiling and can exceed that baseline cap.
- Releasing input coasts without stopping; striking terrain is the primary way to
  lose speed after the Hermit's water traversal item removes water resistance.
- Crossing any water boundary preserves the current trajectory and applies a
  bounded momentum multiplier. Upward steering at an edge therefore becomes a
  speed-scaled jump without replacing the velocity with a fixed jump value.
- Grapple retracts and cannot fire while the player is submerged. It is available
  immediately after a breach.
- Water bulbs are momentum gates. Their displayed number is the required impact
  speed. A failed check rebounds the player; a successful check breaks the bulb,
  preserves direction, and multiplies speed.
- Weapon damage and grapple do not bypass a bulb's momentum requirement.

## First tuning questions

1. Is low-speed steering responsive enough to recover from mistakes?
2. Does each successful bulb make the next threshold readable and achievable?
3. Is wall speed loss noticeable without making a failed route feel dead?
4. Do high-speed breaches produce useful, controllable aerial arcs?
5. Does the water-to-grapple-to-water loop feel intentional and immediate?
