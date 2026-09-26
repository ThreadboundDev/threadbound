# Water and attack feedback pass

The older wide house (`ArtSource/BlueBiome/Buildings/wide_house_source.png`) is the material reference: broad warm grain, dark structural seams, worn timber edges, muted blue-gray slate. Keep the approved 2D backgrounds and mixed 2D/3D direction. MaterialV3 is a separate twelve-piece study with broader grain, muted slate and per-object variation. It is not final house-style parity; irregular geometry and painted edge wear remain art refinements.

Preview: `Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_house_material_preview.tscn` (F6).

Bulb presentation now runs the contained-water loop at 40% speed. Shell release takes 0.125 seconds instead of 0.5 seconds, and an immediate 0.32-second droplet burst follows the launch direction. Dash includes the boost's upward component. Melee sprays opposite the strike. Remote pops scatter water without changing momentum. Regeneration timing is preserved.

Attack smears resolve the sword from its current bone pose, avoiding stale BoneAttachment transforms. Their center follows the blade and their size is bounded by blade length. Third-grounded-hit contact pixels align to collision feet in either facing direction. Existing damage windows and ground-combo timing are preserved.

Upward aerial input no longer becomes a horizontal strike. Up/down sword poses pivot the existing light attack's sword arm toward the requested direction; this is a runtime pose adaptation, not a new Blender-authored animation. Downward contact still uses the existing immediate pogo window and rebound behavior.

Checks: `tools/environment/verify_water_attack_feedback.gd` covers vertical input/pose alignment, pogo VFX availability, immediate directional release, idle/pop timing and ground alignment. `tools/environment/verify_bulb_choices.tscn` covers melee, dash, remote activations and the three traversal routes. Headless Godot still reports host certificate and existing shutdown-resource warnings.

Build V3 with Blender: `--background --factory-startup --threads 8 --python tools/art/refine_still_village_materials.py -- --house-study`. Editable procedural materials are saved in `ArtSource/BlueBiome/Blender/StillVillage/MaterialV3`; PNGs and manifest are in `Assets/BlueBiome/StillVillage/MaterialV3`. These shaders are not baked into a new GLB.
