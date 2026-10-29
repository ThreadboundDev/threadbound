# T31 combat checkpoint — October 29

Chase authorized Souls-style commitment/pressure and Crimson Desert-style contact
weight for the separate 3D trial, then approved an overnight slice expansion.
The 2D game, lore and production assets remain unchanged. The invented "Ruin"
label is removed from active UI and the active model is `player_3d_demo.glb`.

## Combat checkpoint

- Holding jump no longer selects upward air attack. Normal jump attacks go
  forward; X / D-pad Left explicitly selects up, C selects down/pogo.
- Existing Mixamo strafes and `impact_2` were retargeted from the retained player
  animation library. The accepted run cleanup is preserved. Guard movement uses
  the existing shield walk; lock-on uses side strafes and backward shield steps.
- Committed attacks cannot be cancelled instantly with dodge or hookshot.
  Follow-through pauses during recovery rather than bleeding into another slash.
  Contact has stronger local hit pause, camera reaction and sound; armored
  enemies keep moving through resisted light hits.
- Dodge has vulnerable startup/tail and a short middle invulnerability window.
  Locked combat dodges use shorter movement and turn the existing roll toward
  travel. AP cost/recharge and the original movement/special kit are retained.
- A visibly plated swordsman and guardian absorb frontal damage, resist light
  flinch and build stance pressure. Heavy hits/finishers break stance; rear hits
  bypass frontal absorption. No inflated health pool was needed.
- Enemies close faster, use shorter readable windups and committed tracking,
  and runners/armored enemies can follow up. Recovery remains a punish window.
- F2 opens normal/armored/runner/guardian practice in the existing clearing.
  Other opponents are hidden, noncolliding and excluded from avoidance/targeting.
  Restart/death resets the bout; leaving restores the exploration roster.

## Evidence

Source: 61 level/asset, 60 combat, 20 movement, 46 demo and 23 new combat checks:
**210 passing**. A fixed scripted light-spam duel dies with the armored enemy
still alive; a defensive policy wins with two dodges, two parries and counters.
These scenarios establish available counterplay, not human acceptance of feel.
GPU checks inspect the reused strafes, heavy reaction, forward air pose and plate
materials. The source run report still proves unchanged non-leg run curves.

## References and limits

The user-provided [design discussion](https://www.reddit.com/r/gamedesign/comments/1f6blbz/what_makes_a_combat_system_a_souls_like/)
emphasizes action commitment, spacing and punishable recovery. The linked
[Unreal University video](https://www.youtube.com/watch?v=VNrH5gUke34) page/title
and public player metadata were retrieved; its advertised English caption track
returned an empty body. Its step-by-step video content was not accessible, so no
claim is made that every tutorial step was reviewed or reproduced.
