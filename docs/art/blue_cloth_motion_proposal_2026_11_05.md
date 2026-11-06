# Blue cloth motion proposal

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
swaps, and their strength should fade when Blue is unequipped.

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
The new skeleton and simulation integration require architectural approval
under AGENTS.md. This document records the proposal for that decision.
