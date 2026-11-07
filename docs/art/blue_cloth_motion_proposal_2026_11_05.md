# Blue sleeve motion prototype

Approved by Chase on November 5, 2026. Implementation is delivered for hands-on
review; this does not accept the remaining equipment fit or appearance.

Chase reports the broad Blue sleeves entering the torso and wants cloth to
follow movement automatically. The current sleeves are weighted to the arm
and chest. They have no separate cloth chains or torso collision response.

Start with short chains on the hanging edge of each sleeve. The shoulder
portion follows the existing arm. Blend the lower cloth into two or three
extra bones. Godot's SpringBoneSimulator3D can add inertia, gravity, stiffness,
and damping after the authored pose, with a capsule collider following the
torso. Keep motion restrained enough that the sleeve holds its shape.
Check arm compression, running, grappling, and both facing directions.

This is a bone approximation of cloth. Broad fabric may still intersect
between chain points. Validate the sleeve before using the method for the
Hermit ribbons and sash. Cloth chains need resets after teleports and item
swaps, and disable when Blue is unequipped.

The proposed runtime and authoring scope is

- `tools/art/prepare_base_blue_equipment.py` to add and weight sleeve bones.
- `Src/Equipment/Visuals/player_equipment_visuals.gd` to register the cloth
  bones with the live skeleton as fitted gear loads.
- New `Src/Equipment/Visuals/equipment_cloth_motion.gd` for the spring chains,
  torso collision, swap cleanup, and resets.
- `Src/Characters/Player/player_live_3d_visual.gd` to connect cloth updates
  to the live pose and teleport lifecycle.
- `tools/player_animation/verify_base_blue_equipment.gd` for swap and reset
  verification and posed captures.
- Local fitted Blender source and Blue Head / Chest GLB.

Godot supports spring motion for cloth and collision objects through
[SpringBoneSimulator3D](https://docs.godotengine.org/en/stable/classes/class_springbonesimulator3d.html).
Chase approved the new skeleton and simulation integration under AGENTS.md
with “you can work on the sleeves as well.”

## Delivered scope and validation

The Blue Head / Chest mesh has four short chains, front and back on each sleeve,
with three simulated links and an endpoint per chain. Sixteen named bones append
to the existing live skeleton. Existing animation names, rest transforms, joint
cuts, and weapon bindings remain compatible. Upper sleeve weights blend into the
existing upper arms; the lower fabric follows the spring chains.

The simulator uses a chest-bound torso capsule, 5 cm joint collision radii,
stiffness 4.0, drag 0.86, and gravity 0.05. It runs in skeleton space, with a small
bounded force derived from player acceleration. Swaps reuse the added bones,
disable simulation for Base Head / Chest, and reset poses/inertia when reequipped.
Teleports, long frames, and door transitions also reset inertia. The editor keeps
the cloth in its rest pose.

The Godot inventory verification passes 287 checks across all eight Base/Blue
combinations. It checks live skin binding, both grapple launch anchors, mask
swaps, sleeve activation, chain lengths, finite poses, teleport/long-frame
resets, and repeated swaps without growing the skeleton. Dynamic samples cover
idle, running, casting, and grapple swinging with both facing directions.
Rendered comparison samples reduced summed fabric penetration depth into the
torso collision capsule by about 82% against the same poses with rigid sleeves.
This measures sampled sleeve vertices against a proxy capsule, not exact
cloth-to-mesh contact. Some fabric still enters the proxy between chain points;
the sampled chains stay within the test's 1.5 cm collision tolerance.
The headless run exits cleanly. Forward+ reports a texture RID/CompressedTexture2D
release error at engine shutdown, after the checks pass. The pre-sleeve verifier
reproduces that same shutdown error; it is not a running sleeve simulation error.

The editable rebuild is `LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend`;
the Blue runtime GLB is in the existing local `FittedSets` directory. Before-pass
copies are in `LocalOnly/Equipment/SleevePrototype/Before/`. Both paths are ignored
by Godot's source importer. Logs and `godot_sleeve_motion_report.json` plus
`blue_sleeve_*` comparison images are in the BaseBlue review directory. Generated
art stays local under the existing art policy. Ribbons and the sash keep their
existing animation weights; this prototype is limited to sleeves.

Checkpoint: `feature: add secondary motion to blue sleeves`.

November 7 follow-up: Chase likes the sleeve method and requests slightly less
motion. Increased stiffness from 3.5, drag from 0.8, and reduced acceleration force
by 20%; collision strength is retained. Before and after each pass 287 checks.
The proposed ribbon/Base cloth extension and shared seam/hand repairs await
approval in the [November 7 feedback review](equipment_feedback_2026_11_07.md).
