# Live inventory character — November 5, 2026

Chase requested an idle view of the actual equipped character and clearer glove
icons for morning testing. The inventory now creates its own 3D model, skeleton,
animation clock, and transparent viewport inside the existing character panel.
It shares the player's animation resources and current gear definitions. It
mirrors all three clothing slots, the equipped weapons, and mask equip/removal.

The preview loops the existing upright idle while gameplay is paused. It uses
a frontal camera, the gameplay material treatment, and the shared idle hand
clearance helper, with the blade biased away from the face for this camera.
It stops rendering/animating on other menu pages and is freed when the menu
closes. It does not instantiate another player or change the gameplay pose,
position, animation clock, abilities, unlock rules, or equipment slot semantics.
Menus without a ready 3D character retain the existing portrait fallback.

The Base and Blue glove icons now show the shield-arm bracer, shared wooden
hand, and attached coil/reel and hook. They are rendered from the fitted meshes
with consistent diagonal framing. Rebuild just these PNGs with Blender:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/art/render_fitted_glove_icons.py
```

The full gear builder calls the same icon renderer so rebuilding the suits
preserves this framing. Only the two local `*_gloves_icon.png` files are replaced;
the gear meshes and editable Blender source are preserved. Previous icons are
in `LocalOnly/Equipment/InventoryPreview/Before/`. Generated icons and review
captures remain local under the existing art policy.

## Verification

`tools/player_animation/verify_inventory_character_preview.gd` passes 290 checks
in headless and Forward+ rendered runs. It exercises the real inventory clicks
across all eight mixed loadouts; checks mask updates, isolated skeleton/world,
idle advancement during pause, hidden-tab suspension, menu cleanup, and unchanged
gameplay position, hand pose and animation. The existing Base/Blue equipment
regression also passes all 287 checks, including the sleeve motion test.

The Forward+ standalone verifier retains the previously reproduced texture
RID/CompressedTexture2D warning at engine shutdown after its checks pass.
It does not report a running preview script error.
The preview's headless run exits cleanly. The longer equipment regression also
reports the two previously observed music stream/playback resources on shutdown.

Reports, logs and the Base, Blue and Hermit-mask inventory screenshots are in
`LocalOnly/Equipment/InventoryPreview/`. Restart the game after Godot imports the
two updated icons, then open Inventory and swap gear normally. Hands-on visual
acceptance remains open.

Checkpoint: `feature: show live equipped character in inventory`.

November 7 repair follow-up: the portrait now uses the shared independent object
outline shader and an isolated Base/Blue cloth profile that follows Head / Chest
swaps. Its grading pass no longer expands the combined alpha silhouette. Updated
tests pass **786 checks** in headless and Forward+ over all eight combinations,
including cloth-profile isolation, object outlines, pause, masks and unchanged
gameplay animation/pose. Captures are refreshed in the same local folder. The
known Forward+ shutdown release warning and open hands-on appearance review
remain as described above. Joint/outline checkpoint: `c61527b3`; final cloth
checkpoint: `fix: extend restrained cloth motion across base and blue outfits`.
