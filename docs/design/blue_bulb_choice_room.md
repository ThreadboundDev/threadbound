# Blue bulb choice room

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn`
and press F6. This is an isolated greybox, not a replacement for the region.
Use your existing movement, attack, dash, and grapple bindings.

## Behavior

- Attack: pop and recoil opposite the strike direction, including up/down.
- Dash: pop as contact begins, carry forward with 1.2 times incoming velocity,
  and add upward lift. Default lift is 1000 px/s. No teleport or speed check.
- Grapple/ranged: pop without altering the player's velocity.
- Ordinary contact: harmless ejection without consuming the bulb.
- Room bulbs reform after 2.5 seconds. Missing the upper route drops onto a
  continuous floor; one-way steps let you retry or return.

The first pass intentionally pops at dash contact rather than delaying until
the far edge. This avoids a short dash ending inside the bulb. The launch
preserves the captured incoming velocity before cancelling the dash controller.
Existing traversal control recovery then returns steering to the player.

## Route

1. From the starting deck, dash right through the first bulb. The boosted arc
   reaches the higher landing without holding Jump.
2. Jump above the next bulb and strike down to recoil toward the upper perch.
3. Use the high bulb to dash across or experiment with directional recoil.
4. On the final decks, clear the bulb with grapple, or dash through for lift.
5. Turn around and try the return route. The lower floor always stays open.

## Verification and tuning

Run `tools/environment/verify_bulb_choices.tscn` for four-direction melee recoil,
both dash directions, ranged/grapple velocity preservation, duplicate grapple
contact, regeneration, ordinary high-speed contact, independent collision sizes,
and all three raised landings using live player movement, the downward attack
hitbox, and physics overlaps.

The existing general greybox verifier now marks its synthetic melee hit with
`DamageData.is_melee`. New ranged hits should leave that field false, even when
their source is the player. This prevents a projectile from recoiling its owner.

Review by feel: whether dash lift feels excessive, how quickly steering returns,
whether the upper chain invites a second approach, and whether remote clearing
is useful. The automated checks establish behavior and reachability, not fun.
