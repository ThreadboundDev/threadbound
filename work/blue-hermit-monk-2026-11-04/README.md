# Blue Hermit monk concept

The bare front and back doll masters establish the blank stitched head, pale
wood, fingers, and joint positions. Chase's costume references supply the
wicker hat, brown leather, bell sleeves, and silk. The front, back, and turn
views are visual concepts for review. The master 3D skeleton is the fitting
authority for any generated mesh.

- `blue_hermit_front_dock_v2.png` and `blue_hermit_back_dock_v2.png` are the current
  turnaround pair. The front shows the empty socket and retaining strap on the
  left bracer. The back shows the strap and the ribbon anchors.
- `blue_hermit_front.png` and `blue_hermit_back.png` are the original concept views.
- `blue_hermit_turn.png` shows the two ribbons trailing during a balanced turn.
- `blue_grapple_dock_v2.png` compares the empty and stowed grapple on the bracer.
- `blue_grapple_ortho_top.png`, `blue_grapple_ortho_bottom.png`,
  `blue_grapple_ortho_side_a.png`, and `blue_grapple_ortho_side_b.png` are the
  current generation views. These use axial orthographic cameras at one scale
  on the same Blender reference model. The two side views look from opposite
  edges. The spool has a short centered metal pin directly under its lower
  flange to seat in the glove socket. The bottom and side views show this pin.
- `blue_grapple_ornate_front.png`, `blue_grapple_ornate_back.png`, and
  `blue_grapple_ornate_side.png` are the earlier ornate design studies. The
  crescent blades, short center point, blue stones, and dark slate-indigo
  ribbon with gold thread inform the orthographic set.
  `grapple_ornate_prompts.json` records the prompts.
- `blue_grapple_generation_front.png`, `blue_grapple_generation_back.png`, and
  `blue_grapple_generation_side.png` are the earlier simplified design studies.
- `generation_prompts.json` records the exact built-in ImageGen prompts.
  `grapple_dock_v2_prompts.json` records the dock and turnaround revision.
  `grapple_generation_prompts.json` records the isolated grapple views.

The character turnaround shows the empty keyed socket and retaining strap.
The spool pin seats directly in the socket on the elbow half of the bracer.
The strap holds the hook shank toward the wrist. Fit the pin, socket, strap,
and hook together in 3D before testing readability at the gameplay camera
distance. Keep the launchable hook and extending line separable.

The wide, shallow brim, fitted leather vest with flax toggles, clean bell
sleeves, and full tapered trousers establish the silhouette. Slim mid-shin
wraps and compact split-toe shoes finish it. Leave space under the brim to fit
a porcelain mask over the wood head.

| Surface | Appearance role |
| --- | --- |
| Collar, sash, and both ribbons | Primary Identity color |
| Sleeve cloth and lining, trouser panels, boot and bracer wraps | Secondary cloth color and trim |
| Wicker, leather, wood, and metal | Natural material finishes, with the shared original doll wood on exposed areas |
| Sleeve borders and front sash end | Reserved areas for optional Pattern embroidery |

The illustrations include ordinary construction stitches. Keep optional
embroidery separate when preparing the textures. Fit the game mesh to the
master, then test head/chest, glove, and boot joins with both Base and Blue.

The shoulder ribbon attaches behind the left collar. The shorter ribbon
attaches behind the right hip. The broad front sash panel stays close to the
body. Keep the two moving tails as separate geometry for rigging. Start by
testing three bones per tail with damped, limited swing. Check clearance around
the shield arm and legs through turning, landing, and grappling.
