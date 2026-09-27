# Blue enemy models — first pass

Built the approved A/Reedhook and D2/Tide Duelist directions as editable model studies. These are simple 3D interpretations, with substantially less painted detail than the concept illustrations. They are not yet playable enemies.

Update: both enemies now have separate animated exports and playable scenes; see [Tide Duelist behavior](tide_duelist_behavior.md) and [Reedhook behavior](reedhook_behavior.md). The original v1 studies described below are preserved.

| Model | Triangles | Bones | Material surfaces | Inspection animation |
| --- | ---: | ---: | ---: | --- |
| Reedhook | 10,132 | 17 | 7 | `idle_breathe` |
| Tide Duelist | 10,062 | 7 | 9 | `swim_idle` |

Counts are for the exported geometry, before any engine vertex splitting. Both models face +X; Blender uses Z up and GLB converts to Godot's Y up. Size and encounter scale still need gameplay review.

## Files

- Editable sources: `ArtSource/BlueBiome/Blender/Enemies/Reedhook_v1.blend` and `TideDuelist_v1.blend`.
- Godot assets: `Assets/BlueBiome/Enemies/Models/Reedhook_v1.glb` and `TideDuelist_v1.glb`.
- Actual model renders: `ArtSource/BlueBiome/Blender/Enemies/*_v1_preview.png` and `*_v1_side.png`.
- Geometry report and original 512-pixel material textures are beside the Blender sources.
- Rebuild script: `tools/art/build_blue_enemy_models.py`.

Blender sources retain named separate parts, packed albedo textures, armatures, and the inspection animation. GLBs combine the parts into one skinned mesh with separate material surfaces, embedded textures, and animation. Godot extracts the embedded textures into the model directory during import; retain those generated texture files and their import settings with the assets. Studio lights, cameras, and the review floor are excluded from the models.

Reedhook includes the long chipped mask, indigo hood and split coat, reed mantle, wrapped limbs, and boat hook. Tide Duelist includes the curved katana bill, kabuto crest, overlapping armor plates, simplified sleeve fins, and forked tail. Materials use original procedural pigment textures with mostly matte shading and restrained metal highlights.

The rigs demonstrate breathing and fin/tail motion. Most pieces have rigid bone weights; the fish body's tail transition blends weights. These are starting rigs, not finished deformation or combat rigs. Walk, attack, recoil, death, collision, AI, gameplay integration, and the player's contour shader are not included. Configure animation looping when integrating the models with an enemy controller.

## Validation

Rendered three-quarter and side views in Blender, then imported both GLBs in Godot 4.7.2. A headless check confirmed one skinned mesh per model, expected skeleton counts, nonempty geometry bounds, albedo textures on every material surface, and working imported clips. Sampling the clips moved two Reedhook bones and four Tide Duelist bones. Godot reported the existing environment log/certificate warnings; asset checks passed.

## Rebuild

Run from the repository root using Blender 5.2:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --threads 8 --python tools/art/build_blue_enemy_models.py
```

The script overwrites these v1 outputs. Save manual sculpting, painting, or rig changes as a new version before rebuilding.
