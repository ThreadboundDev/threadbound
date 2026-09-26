# Supplied Tide Duelist paint pass

The supplied `model-v1.glb` is painted from `Fish.png` using a symmetric side projection baked into its original UV unwrap. Navy scales, ivory panels and brass details come from the supplied reference. This is a texture projection pass, not newly sculpted detail.

Files are in `ArtSource/BlueBiome/Blender/Enemies/TideDuelist_Painted_v2/`:

- `TideDuelist_Painted_v2.blend`: editable source and preview lighting.
- `TideDuelist_Painted_v2.glb`: textured export.
- `TideDuelist_BaseColor.png`: 2048-square baked UV atlas.
- `Fish_painted_side.png`, `Fish_painted_three_quarter.png`, `Fish_painted_reverse.png`: reviewed renders.
- `Fish_unpainted.glb` and `Fish_reference.png`: preserved inputs.

The painted input mesh has 35,961 triangles. Both sides and a three-quarter view were reviewed. Projection can stretch detail on edge-facing surfaces.

Generation script: `tools/art/paint_supplied_tide_duelist.py`. It overwrites these generated outputs; preserve any manual Blender edits before rebuilding.

## Still-water rig and game integration

`TideDuelist_Rigged_v2.blend` contains a six-bone rig, smooth body weights, rigid bill, and two skinned emissive pupils. Actions: `still`, `draw_curl`, `dash`, `recover`, `hurt`. Select the armature and choose an action in the Action Editor to edit. No patrol swimming animation is included; idle only has a very small tail flex.

`tools/art/rig_painted_tide_duelist.py` generates the rig, clips, previews and `Assets/BlueBiome/Enemies/Models/TideDuelist_Rigged_v2.glb`. Preserve manual edits before rerunning it. The original painted source and older enemy model remain available.

The existing Tide Duelist scene now uses this rig. It stays in place even after detecting a distant target. In attack range it locks its aim, curls for 0.733 seconds, and flashes amber-to-ivory during the final 0.12 seconds. A 0.20-second dash clip snaps the bill straight before swept damage and movement begin. Dash speed is 2200 px/s; recovery stops forward motion and returns to stillness. Hurt can interrupt the attack. Existing health, damage, cooldown, water boundaries and terrain checks remain in use.

Validation: Godot integration checks pass for stationary idle/awareness, both eye materials, harmless prestrike flash, locked aim, one hit per dash, hurt/recoil interruption, walls, narrow air pockets, death and reset. Reviewed imported Godot still/curl/dash captures and Blender deformation renders. Existing headless certificate/log and shutdown resource warnings remain. Playtest the final flash readability and dash reaction timing at normal gameplay zoom.
