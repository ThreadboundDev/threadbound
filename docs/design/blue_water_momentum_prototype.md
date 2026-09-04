# Blue Water Momentum Prototype

The isolated test scene is `blue_water_playground.tscn`. Chamber Exit is not a
water-mechanics test room and should remain unchanged while this prototype is tuned.

## Current traversal rules

- Polygon water supports freely shaped test volumes.
- Directional input steers existing velocity instead of replacing it instantly.
- Releasing input applies light drag; striking terrain drains speed.
- An upward breach preserves velocity and applies a bounded launch multiplier.
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
