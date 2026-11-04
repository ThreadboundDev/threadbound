# Mask + Pattern

## Current design

One equipped porcelain mask supplies its own embroidery Pattern and one passive
effect. Selecting the mask selects both. A mask's effect can respond to the
equipped gear, while its motif stays visible on the cloth even when its effect
is inactive. A player can wear one mask at a time and can go barefaced.

| Layer | What it controls |
| --- | --- |
| Equipment | Tools, abilities, and silhouette |
| Identity | The palette earned through Absorb and Spare |
| Mask + Pattern | Porcelain face, matching embroidery motif, and one passive |

Identity dye can unify pieces from different sets. Gear alignment follows the
equipped item's family through recolors and stays independent of the mask's
paint. The mask is a separate cosmetic attachment on the shared head rig,
paired with its own motif and effect. Head / Chest still swaps as one gear item.

## Counting gear

Count **Gloves**, **Boots**, and **Head / Chest** once each. The weapon, mask,
and separate meshes within Head / Chest add no extra counts. The grapple is
part of Gloves, including its hardware and behavior. The 3D grapple model is
authored separately from the bracer and ships as part of the same glove item.
Each piece counts as Base/Neutral, Red/Power, Blue/Balance, or Yellow/Essence.

Monarch, Hermit, and Sage get a stronger version of their own effect for **each**
matching piece. Loomed follows the same rule for Base. The first balance pass
should use four visible tiers. Zero matches gives zero bonus, then one, two, and
three matches each increase it. A recolored Base piece remains Base. An active
mask counts only its own condition, so a full colored set can use either its
matching mask or Purist with different effects.

When the player swaps gear, show the new count and the active effect in the
Mask + Pattern slot. Apply the new tier to subsequent effect calculations.
Swapping supplies no instant AP, health, or Momentum and leaves a grapple
already in flight alone. The proposed passives need to support real-time swaps
and keep the base kit sufficient for progression.

## Ten concepts adapted to Threadbound

Effect directions are proposals. Exact values, thresholds, and acquisition are
open. Each concept starts with one effect so its role can be tested separately.

| Mask | Proposed effect | Matching embroidery |
| --- | --- | --- |
| **The Loomed** | Faster AP recharge per Base piece. Works with a mixed loadout and peaks with full Base. | Interlocking knots |
| **Monarch** | More direct weapon-hit damage per Red piece. Red armor supplies the bonus even when the player carries a weapon from another family. | Upright spires and branching red thread |
| **Hermit** | More Momentum earned from successful grapple actions per Blue piece. Use the existing Momentum rewards and leave swing physics alone for the first test. | Flowing wave repeat |
| **Sage** | Faster AP recharge per Yellow piece. This is the Essence counterpart to Loomed's Base recovery. Start with recharge before testing skill-cost changes. | Rings and radial stitches |
| **Reclaimer** | Lose less Momentum when hit. Use the existing damage-related loss as the first candidate for the sheet's idea of stability. | Broken pointed arches |
| **Weaver** | Gain more Momentum when chaining different action types. The bonus starts at two distinct armor families and grows at three. Base counts as a family, so Base + Blue is a valid hybrid. | Interwoven strands |
| **Frayed** | More direct weapon-hit damage while at low health. Test against the existing wounded state before setting a threshold. | Branching repair stitches |
| **Pale Ascendant** | Improve existing meditation healing within its current recovery ceiling. Candidate for a Spare-aligned mask. | Pale petals and fine gold borders |
| **Blackened Heir** | More direct weapon-hit damage while Flow is active. Candidate for an Absorb-aligned mask. Flow supplies a concrete combat condition for the sheet's empowered state. | Dark arcs and gold seams |
| **Purist** | Slow natural Momentum drain during Flow with all three armor pieces from the same colored family. Full Base has Loomed as its dedicated option. | Repeated narrow arches |

Crimson Weave, Flowing Weave, Scholar's Weave, and Trinity Weave were draft
Pattern examples. Their focused and mixed-loadout ideas carry into Monarch,
Hermit, Sage, and Weaver respectively. The current demo's **Follower's Knot**
is still a standalone Pattern in the runtime. It grants +10% AP recharge and
+10% Momentum generation with any gear. Its knotwork is a candidate for Loomed.
Whether existing ownership and saves eventually map to Loomed is a migration
decision, separate from testing its new Base-piece effect.

## Absorb and Spare

The [progression design](progression_and_choices.md) has Absorb grant the
Master's gear and color influence. Spare grants no gear from that Master and
moves Identity toward pale. Full absorption tends toward black. The demo
records claimed Threads and uses them for existing unlocks. An unclaimed
Thread can mean the player has yet to reach a choice, so it cannot establish a
Spare decision.

- **Absorb one or two Masters.** Matching masks can reward the pieces the
  player earns. Loomed still scales with any Base pieces they keep, and Weaver
  supports a mix of Base and an earned set.
- **Spare all Masters.** Full Base can reach Loomed's highest tier. Pale
  Ascendant is a candidate for a distinct recovery playstyle on this path.
- **Absorb all Masters.** Blackened Heir is a candidate for an alternate
  playstyle focused on sustaining Flow. The colored masks still work on their
  own equipment counts.
- **Reclaimer choice.** Leave Reclaimer mask acquisition, and any dependency
  of Pale Ascendant or Blackened Heir on the final choice, open. The existing
  [ending rules](../narrative/story/endings.md) evaluate the Master and Reclaimer
  decisions together. An equipped mask does not count as a route choice.

The first test can expose the masks through a development control. Acquisition,
permanent ownership, and the exact route checks belong in a later design pass.

## Visual direction and first test

Fit one close-fitting oval shell to the doll's eyes and head bone. Check it with
the Base cowl and Hermit brim. Start with the Loomed knot and Hermit wave as
finishes on the same mesh, plus plain ivory as a comparison swatch. One
off-center gold repair should join two visibly different ivory pieces. Use a
short branch, restrained glaze variation, and enough contrast for side view.
Frayed can push that repair further, and Reclaimer can explore a distinct shape
after the common shell is proven. These are art directions for the player's
mask catalog.

The equipped mask supplies a single motif on cloth. Start with Base waist wrap
and forearm cloth, and Hermit sash end and lower sleeve. Translate each motif
across materials, for example a broad painted wave on the face and a short
stitched wave repeat on the sash. Author separate areas for Identity dye and
embroidery, and keep leather, wood, wicker, grapple hardware, and repair metal
readable. The earlier [appearance lab](../../work/appearance-lab-2026-10-30/README.md)
used separate toggles to compare the two visuals at 0.83 zoom. Its broader
face markings were easier to read than fine lines at gameplay size.

Start with Loomed and Hermit and use the fitted Base/Blue equipment to exercise
every tier. Keep Blue gloves equipped for the Hermit action test and swap boots
and Head / Chest to compare tiers one through three on the same grapple. For
tier zero, use full Base and verify the inactive state. Also check full Base
Loomed, mixed gear with an Identity dye, and barefaced baseline. Inspect idle,
run, and grapple at gameplay zoom and the mask in the inventory close-up.

This design supersedes independent mask and embroidery selection. The current
inventory, demo Pattern resource, and gameplay stay as implemented until a
runtime scope is approved and tested.
