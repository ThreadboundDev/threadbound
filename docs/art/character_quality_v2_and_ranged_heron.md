# Character quality v2 and ranged Loom Heron

October 21: the bird alone now uses the [v3 craft rebuild](loom_heron_quality_v3.md).
The figures and bird source below describe the earlier v2 delivery. The other
three characters remain on v2.

Chase approved a ranged heron, more polygons and higher resolution for both
villagers and both guardians. Version 1 sources remain for comparison. The v2
models retain the approved identities, proportions, rigs and woven direction.

| Actor | Previous triangles | Current triangles | Rig |
| --- | ---: | ---: | ---: |
| Net Mender | 39,390 | 153,580 | 163 bones |
| Boatwright | 40,146 | 156,420 | 163 bones |
| Eave Runner | 66,052 | 264,312 | 60 bones |
| Loom Heron | 24,488 | 107,096 | 18 bones |

## Sources and surface detail

The existing prefabs now select the `_v2.glb` models. Packed editable sources:

- `ArtSource/BlueBiome/Villagers/LakesideVillagers_v2.blend`
- `ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v2.blend`
- `ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v2.blend`
- `ArtSource/BlueBiome/Characters/Character_Materials_v2.blend`

Material-aware subdivision refines faces, fingers, masks, cloth and cord. Cloth
has small physical fold relief; the heron's sail edges stay on their frames
with constrained billow between them. Deform weights are interpolated, trimmed
to four influences and normalized. Original clips and cloth-tail bones remain.
Villager belts fit the garment; cuff hoops were rebuilt as rolled hems with
sleeve skin weights. A stray throat bridge from the old garment crop was removed.

The native Blender material baker preserves the existing palette and adds
warp/weft, fibre and ceramic relief in 4096-square color, tangent normal and
roughness maps. Villager face/hand paint is baked into 4K skin UV maps with fine
surface normals. No new image-generation service was used. Provenance continues
from the v1 assets and CC0 human base.

New maps are under `Assets/BlueBiome/Characters/SharedTexturesV2/`. Existing walnut
and eye maps are reused through project-relative GLB paths. Keep those dependency
folders when moving a GLB; Blender source textures are packed. Imports use
mipmaps, high-quality VRAM compression and anisotropic filtering. Automatic mesh
LOD generation is disabled for these four models; instances favor full detail.

## Rendering and gameplay

Guardian render targets increased from 768-square to 1536-square with 4x MSAA,
four times the pixel count. Sprite scaling compensates, preserving world size,
feet placement and 2D collision. The shared village stage increased from 1.25 to
2.0 times screen resolution, about 2.56 times its previous pixel count. The
existing stage, lighting, foreground pass and interaction flow remain in place.
Inspector quality controls remain available. This increases GPU/texture cost;
a visible art/performance check remains for the next hands-on session.

The ranged heron holds above and beside the player. Its thread/tell builds for
0.85s and aim locks 0.18s before firing. One ceramic needle releases 0.10s into
the 0.35s firing clip, from the actual animated `beak_tip` bone projected through
its render camera. It travels straight at 520px/s, lasts at most two seconds,
and stops at terrain. Existing shield/hurtbox rules apply. Hurt before release
cancels the pending shot; reset/removal clears owned needles. Owner death expires
them. The active heron has no damaging body-contact or dive hitbox.

After shooting, it descends vertically into a low, vulnerable 1.1s recovery,
constrained by terrain and dry-air boundaries, then repositions during its 1.5s
cooldown. Initial tuning is 65 HP and 18 needle damage. New clips are `needle_aim`,
`needle_fire` and `low_recover`. Old dive clips are retained as source references.
The extra bone is a muzzle marker; the original seventeen deform bones remain.

## Review and verification

F6 on `blue_lakeside_krita_playtest.tscn`; use **Eave Runner**, **Loom Heron**,
**Net mender** and **Boatwright** buttons. F2 restores all five enemies. Villagers
still work, turn to greet, and return to their fixed stations. No player,
equipment or shared combat code changed in this pass.

Verifiers check saved geometry/weights/maps, animation bounds and loop joins,
imported triangles, 4K maps, render scaling, both muzzle facings, normals, LOD,
attack timing/interruption/occlusion, player damage/blocking, save/F2 reset and
villager work/interaction. Reports are in `work/character-quality-v2/`.

Review PNGs and the pose GIF are background Blender renders of the saved models,
not concept paintings or new in-game captures. Godot verification is headless;
no graphical test windows were launched. Existing shutdown cleanup diagnostics
are recorded separately from test failures/script errors.

Reproduce with `bake_character_materials_v2.py`, `refine_lakeside_characters.py`,
`fit_villager_bindings_v2.py`, `rebuild_villager_cuffs_v2.py`,
`finalize_character_exports_v2.py`, then the package/prepare/install modes of
`import_character_quality_v2.py`. Run fitting steps once on freshly generated
source. Use `--` before Blender scripts' custom arguments.

The GPU-only viewport/mipmap resize regression requires a real Forward+ renderer
and could not run under the headless dummy renderer. It is not counted as a
passing check. Current saved-source, imported-art, combat, map, villager and
Eave Runner animation checks pass; visible rendering/performance remains for
the next hands-on session.
