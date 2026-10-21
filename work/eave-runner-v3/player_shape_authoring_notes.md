# Read-only player proportion study

The actual player mesh is `Threadborne_Character`: 664,040 triangles, 464,260 imported vertices, 1.80005 m tall. Its runtime mesh has one atlas material (`Threadborne_Costume_Material`) and one geometrically connected component after welding equal seam positions. Clothing is part of its sculpted surface; torso and trousers cannot be separated by material or disconnected island. The saved reference has no Armature modifier but retains all skin groups and its direct rig parent.

Use the player mesh itself as the fitting reference. It is practical to duplicate selected torso/trouser faces by height and deform-group region, preserve their existing folds, then finish the selected boundaries and author the ninja's indigo overlaps and sparse woven bindings on top. Do not extract each strongest-weight region as a separate garment: those boundaries follow joints rather than seams. Selecting whole polygons and keeping the original blended weights avoids torn boundaries.

## Main proportional corrections

- Raise the hip joints from 0.9576 m to 1.0350 m (+7.74 cm). The player's upper leg is 0.496 m versus the Eave Runner's approximately 0.437 m. Its shin is 0.410 m versus approximately 0.429 m. The player has longer upper legs and a higher, compact waist.
- Raise the shoulders from 1.4299 m to 1.4900 m (+6.01 cm), and narrow the shoulder joint span from 0.3849 m to 0.3600 m. The torso's body-to-leg ratio matters more than adding surface details.
- The player neck/head joints start at 1.500/1.610 m. The ninja's start at 1.530/1.639 m, with an additional oversized cowl reaching 1.902 m. Match the player's head surface region, which spans approximately z=1.608–1.800 m, width 0.189 m and depth 0.245 m. Keep the new ceramic mask and hood within a small allowance around that volume. The rejected mask alone was 0.252 m tall; that is already taller than the player's entire head region.
- Narrow the foot-center span from 0.3943 m to 0.2800 m. Keep actual feet planted near z=0; the player ankle joint is at 0.130 m, versus 0.0977 m on the ninja.
- The player upper arm and forearm are 0.3004/0.3003 m, versus approximately 0.260/0.269 m on the ninja. Preserve the slender player's limb cross-sections: upper arm roughly 0.147×0.135 m, forearm 0.135×0.117 m in its T pose. Their world-space widths are not directly comparable with the ninja's bent A pose.
- Player palms are about 0.074×0.117×0.062 m (L). Fingers already have individually modeled tapered geometry and proper three-joint chains. If borrowing the fitted hand surface as a guide, map thumb/index/middle/ring/pinky to the ninja's finger1/finger2/finger3/finger4/finger5 respectively and verify the source digit ordering before committing weights.

The JSON contains every rest bone head/tail, per-strongest-bone vertex count and bounds, material bounds, and horizontal slices for both assets. Head/neck/torso/trousers proportions should be judged side by side with the actual player. These measurements validate fit and do not constitute visual approval of a revised ninja.
