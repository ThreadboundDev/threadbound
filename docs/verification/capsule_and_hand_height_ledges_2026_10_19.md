# Capsule movement and hand-height ledge contact — October 19, 2026

The movement collider in `Src/Characters/Player/player.tscn` is a CapsuleShape2D
with radius 18.5px and full height 126.244995px. Its previous 37px width,
standing height, node position and bottom at player-local Y=69.244997px are
preserved. The 3D visual now derives its foot registration from the shape's
bounds, supporting both capsules and rectangles.

Crouching changes the capsule's height to 78.271897px, preserving its radius
and bottom position. The collision node is not nonuniformly scaled. Stance
capture duplicates each player's body shape and saves a separate full-height
capsule for standing-clearance queries. A blocked ceiling keeps crouch active;
round head corners use the actual capsule, avoiding a rectangular false block.
The existing rectangular hurtbox still resizes through the same stance path;
attack shapes, damage values and equipment logic are unchanged.

The old ledge test sampled near the torso and could accept tops far below the
3D hands. The replacement samples a narrow reach band at Y=-84px, with 12px
vertical tolerance, checks empty space above it and requires a valid top on
the same collider as the side face. Grapple-assisted reaches retain their
horizontal bonus while using the same vertical requirement. Ordinary wall
cling also requires a side surface at hand height, preventing hangs caused
only by a foot or knee touching a corner.

The 3D hand in hanging idle is substantially higher than the old 2D hang
offset. `PlayerLive3DVisual.get_ledge_grip_player_offset()` projects both hand
bones and picks the forward hand. The hanging player's position follows that
contact as the entry pose extends its arms and transitions into idle. The
legacy hang offset remains the fallback for the 2D visual. The capsule stays
outside/below the lip during entry; pull-over and jump retain their existing
movement arc and landing clearance.

Validation in Godot 4.7.2:

- `tools/environment/verify_capsule_ledge_contact.gd`: **49 checks passed**
  with headless and Forward+ rendering. Covers stance sizing, independent
  player instances, headroom, one-way upward passage/landing/drop, accepted
  hand-height ledges and rejected torso/knee/foot/full-wall candidates in
  both directions, grapple reach, wall cling, pull-over and ledge jump.
- The forward-hand-to-lip error after entering hanging idle was **under 0.1px**
  in each facing. The real controller also caught both ledges automatically
  during a falling approach; both rendered contact views were inspected.
- `Src/Tests/PlayerCombat/player_defense_test.tscn`: passed. Existing front/
  rear damage behavior is preserved, and crouch checks now use the capsule.
- `work/lakeside-quality/verify_walks.gd`: **14 ledge/roof routes passed**
  with a capsule matching the player. The deliberately steep underwater bed
  remains a jump/swim control rather than a walkable-floor expectation.
- `tools/environment/verify_lakeside_krita.gd`: passed, including actual
  player floor contact, cutaways, swimming, air pockets and art registration.

The full-project CLI continues to report its existing shutdown resource
diagnostics. No runtime errors occurred during the passing contact checks.
These automated and rendered checks support an in-game feel review; they do
not substitute for the player's judgment of timing and wall/ledge behavior.
