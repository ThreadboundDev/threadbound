# Lakeside villagers, 20 October 2026

Blender 5.2.1 LTS source reopening confirms both review scenes, separate stations,
rigged characters and packed file textures (50,558,106 bytes of packed images).
The compressed source is approximately 55MB. The body/cloth meshes retain their
material slots, skin vertex colors, named deform weights and 163-bone rigs.

`tools/environment/verify_lakeside_villagers.gd` passes 48 headless checks and
83 checks using the actual Vulkan Forward+ viewport on the Radeon RX 6800 XT.
It exercises actual player interaction input, imported animation tracks, both
facing directions, station transforms, second-press/timeout/range-exit returns,
wall obstruction, optional station visibility, furniture-only prefabs and the
shared stage placement count. It checks skin vertex-color use and the exported
dark trouser material, following the material mismatch found during review.

Actual viewport captures show both furnished houses and a net-mender sequence
from work through greeting and back to work. Blender studio renders are also
included in the review output. The NPCs were fitted against the visible player
art, and their interaction prompts sit above their heads.

The existing Krita-map verifier also passed after the additive integration;
the shared stage now has ten placements. Existing house scenes, cutaway behavior,
terrain collision, combat and player physics were not changed by this pass.

The Godot run still reports the existing physics-interpolation camera warning
and resource/texture cleanup diagnostics at application shutdown. Neither is a
passing gameplay assertion, and the verification reports do not claim a clean
shutdown. No runtime script errors occurred in the successful capture runs.

This is a first modeled art pass. Character face, hair and clothing refinement
can continue from the packed Blender source. Wall-hunter cloth remains a design
proposal, not an implemented enemy system.
