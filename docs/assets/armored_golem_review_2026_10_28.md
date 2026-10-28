# Armored Stone Golem — licensed boss-source review

October 28, 2026. Chase downloaded an armored golem and supplied Fab's license
text, asking whether it could be a good boss model. **Assessment delivered;
no boss installation, combat change, lore decision or art replacement.**

Matching listing: [Armored Stone Golem – Dark Fantasy Boss, Alexander Lenski](https://www.fab.com/listings/e40713f0-ebea-4f4d-ad9b-b577db4432d5).
The archive names, model parts and 25 named animation files match its description.
The public page does not establish Chase's actual transaction/tier; this review
applies the **Fab Standard terms Chase supplied**, not a verified purchase receipt.

## Recommendation

**Promising boss/large-guardian source if Chase chooses a licensed exception.**
The heavy shield/hammer silhouette, separate armor and useful existing motion
coverage could save substantial modeling, rigging and animation work. It is more
directly usable as an armored humanoid foundation than a creature donor with no
clips. This is source stock, not an approved new boss identity or encounter.

The current stone/metal surfaces are detailed and weathered. Threadbound needs a
gameplay-scale material/readability trial before acceptance: quiet the fine
texture, group slate/walnut/flax values, and consider visible cloth bindings or
thread bundles at joints/negative spaces. Keep the readable equipment silhouette.
A material-only swap will not automatically give it a woven identity. Any woven
adaptation, faction, location, motive and mechanics remain proposals.

Review at the actual game camera with the player before selecting scale. Imported
rest geometry is about **1.92 m high** in this Blender import; boss scale is not
intrinsic to the mesh. Its animations are visual source, not instructions to add
five attacks or impose lengthy shield/invulnerability phases. Preserve the
existing flow-first enemy philosophy and approve any later combat scope.

## License implications

Under the [Fab Standard summary](https://www.fab.com/eula?lang=en) and supplied
full EULA, commercial game use and modification are allowed, compatible tools
are not limited to Unreal, and publisher credit is not required. That supports
using a properly acquired Standard-licensed source in a commercial Godot game.
It is **not CC0** and is not added to the CC0-only retained-pack manifest.

The CC-BY heading on the general Fab license page describes an **alternative**
license; it does not make attribution mandatory for every Standard-licensed
asset. Confirm the actual acquired listing/license record and eligible tier;
save that record with the originals. Epic's [license/tier documentation](https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab?lang=en-US)
distinguishes the available license types and tiers.

The supplied EULA permits rendered images/video projects and private sharing
with project collaborators, while restricting standalone asset redistribution.
Therefore only review renders, scripts and metadata enter this checkpoint;
**no FBX, OBJ, TGA, Maya scene, Unity package or asset-containing Blender file
is committed or pushed**. Raw downloads remain in Downloads, unmodified.
The supplied license text's SHA-256 is recorded in the inventory for provenance.
The listing also marks AI usage as disallowed; no AI image generation, model training
or generative texture work was used for this review.

This is an explicitly requested assessment of a new non-CC0 candidate, not a
general relaxation of Chase's CC0-only collection policy or permission to
redistribute the source. Whether to retain/use it as an exception remains open.
The download has not been deleted under the earlier cleanup rule while Chase
is specifically evaluating it.

## What is actually downloaded

| Download | Archive size | Findings |
| --- | ---: | --- |
| `mesh.zip` | 10,735,378 bytes | 40 files: complete models, separate armor/body/hammer/shield FBXs, OBJ alternatives and Maya source |
| `animations.zip` | 8,025,642 bytes | 25 FBXs; skeleton/animation data without character mesh geometry |
| `textures.zip` | 801,321,049 bytes | **42 TGA maps, all 4096 × 4096**, including four albedo variants and alternative PBR map packings; ~2.62 GB expanded source data |
| `armored_stone_golem_unity.unitypackage` | 840,099,547 bytes | Size/hash recorded only; package not installed or executed; not needed for an FBX-based Godot trial |

[Original hashes and complete archive inventory](../../work/armored-golem-review-2026-10-28/source_inventory.json).
All three ZIPs passed full CRC reads. Originals were not moved or modified.
Only selected source files were expanded into the ignored task `temp/` directory.

Blender inspection of the actual full `StoneGolem.fbx`:

- **45,704 triangles** with hammer/shield; **31,772** body + armor and **13,932** equipment.
- **11 mesh objects**, three material families (body, armor, weapon), **90 named bones**.
- Armor is separable: belt, bracers, chest, greaves, hands, helmet, pauldrons and thighs.
- `SKM_StoneGolem.fbx` contains body/armor without the two equipment meshes.
- Three material families do not imply only three runtime draws across 11 meshes.
  No runtime batching, texture compression, LOD or frame-time claim is made.

For a later trial, choose one skin and required maps instead of installing all
42 source maps/engine alternatives. Inspect 1–2K texture derivatives at gameplay
scale before retaining 4K for a boss; actual runtime memory/performance needs
measurement. The current 2K review texture copies exist only in rendering memory.

## Motion coverage and compatibility

All 25 animation FBXs import with one 90-bone armature action at **30 FPS**:

| Group | Clips | Measured source duration |
| --- | --- | --- |
| Attacks | `attack1`–`attack5` | ~2.97, 2.50, 1.73, 2.93 and 4.40 s |
| Walk | `walkF/B/L/R` | ~1.13 s each |
| Jog | `jogF/B/L/R` | ~0.77 s each |
| Idle | `idle1`–`idle4` | 10, 5, ~6.67 and 13 s |
| Reactions | `gethit1`–`gethit3` | 1, 1.8 and 1.8 s |
| Death | `death1`–`death3` | 3.5, 2 and ~2.53 s |
| Other | `dodge`, `turn180` | ~1.23 and ~2.33 s |

FBX also imports numerous controller/helper actions. These are **not additional
gameplay clips**. Metadata records the armature action and helper count separately.
The publisher advertises UE5 Epic-skeleton compatibility; no Unreal or Godot
retargeting validation was performed. It is not assumed interchangeable with
the retained 65-joint Quaternius rig or current player/enemy rigs.

The animation FBXs' rest poses differ from the model FBX's bind pose, so assigning
the imported action directly failed the local compatibility check. For the
preview, `idle1` and `attack1` were converted by sampling the source bones' world
poses and calculating the model rig's local transforms through its own bind pose.
Those two clips render on the full mesh with both equipment pieces. This is a
tested local rendering route, not a finished Godot animation-import pipeline.
Other clips were metadata/import checked, not fully motion-reviewed or converted.
Root motion, loop seams, foot contact and collision/hit alignment still need a
later scoped test if the model is selected.

## Review artifacts and validation boundary

- [Two-view review board](../../work/armored-golem-review-2026-10-28/renders/golem_review.png).
- [Attack 1 motion preview](../../work/armored-golem-review-2026-10-28/renders/golem_attack1.gif).
- [FBX inspection](../../work/armored-golem-review-2026-10-28/blender_inspection.json).
- [Rendering setup/results](../../work/armored-golem-review-2026-10-28/render_inspection.json).
- [Verification record](../../work/armored-golem-review-2026-10-28/verification.json).

Review renders show the original first skin's albedo/roughness/metallic and body
emission, downsampled to 2K in memory, under neutral study lighting. Normal maps
are not applied; tangent/normal import is unvalidated. The side-view check is a
second Blender camera, not a capture in the game. Attack 1 has 36 rendered frames
over a three-second GIF; its source interval is ~2.97 seconds. The repeat is a
preview restart, not an assertion that an attack is a seamless looping animation.
Representative start/middle/end frames and the board were visually inspected.

No Unity package execution, Godot import, current-boss substitution, new mechanics,
new lore, source-asset publication, or acceptance of appearance/feel occurred.
The task-level `.gdignore` prevents Godot importing this review/cache. Reproducible
inspection/render/package scripts are under `tools/assets/inspect_armored_golem.py`
and `tools/art/*armored_golem*.py`; the four original downloads must still exist at
the recorded Downloads paths to rerun them.

Checkpoint: `docs: assess armored golem license and boss-source suitability`.
