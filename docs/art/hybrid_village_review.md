# Hybrid village comparison

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_hybrid_preview.tscn` and run F6.

This optional room combines the earlier painted wooden platforms, wide house, tower house and roofed frames with the new two-layer background and rendered 3D water globes. Original house assets remain unchanged. Only their Artwork sprites are copied: the inherited room owns all platform collisions and bulb activation areas. Painted platform top edges align with the existing landing surfaces. This is a composition test, not a finished environment layout.

The wide house is now approximately 42% larger than the first hybrid preview (0.92 versus 0.65 source scale); the tower is also enlarged. A building-only water-contact shader submerges the bottom supports, tinting a short section and occluding the stone feet. Static, restrained contact rings mark the wide house's posts. This is visual lake contact, not new swimmable water or a change to the recovery floor. Platform runs combine the existing single-bracket and double-bracket artwork in unequal lengths with mirrored supports, varied bracket depth and occasional hanging cloth. Landing edges remain at their original heights and widths.

The second weapon stroke is a shorter, flatter horizontal cut. Its center stays in the forward half-plane even after the recovering sword moves behind the torso. The third stroke uses 1.45 times the attack radius for its extent and retains the measured ground-contact baseline. The first stroke is unchanged. Damage timing and hitboxes are unchanged.

PetalV2 tucks the petals closer around the water, adds a gentle idle pulse, spreads them on release, and closes them before the refill expands into a new globe. It preserves the existing water-current motion, lifecycle ranges, sprite dimensions and runtime pop speed. This is an animated flower-group deformation; the internal water remains the existing stylized procedural rotation.

Editable source: `ArtSource/BlueBiome/Blender/WaterBulb/PetalV2/WaterBulb_Petal_v2.blend`. Runtime atlas: `Assets/BlueBiome/StillVillage/Bulb/PetalV2/`. Original bulb assets are preserved. Rebuild using background Blender with `tools/art/refine_water_bulb_petals.py`, then Python/Pillow with `tools/art/package_water_bulb_petals.py`.

Actual room and combo captures are in `ArtSource/BlueBiome/Blender/StillVillage/MaterialV3/hybrid_*.png`; the four-stage petal review is in the PetalV2 source folder.

Validation: `tools/environment/verify_hybrid_preview.gd` passes for both facing directions, shortened second-stroke visibility, enlarged third-stroke size, PetalV2 loading and absence of extra art colliders. All 72 rendered petal frames are 360x480. Godot captures were reviewed for landing alignment and actual second/third combo poses. Existing host certificate/shutdown warnings are unrelated to these changes.
