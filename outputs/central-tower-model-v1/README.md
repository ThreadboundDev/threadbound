# Central tower — textured 3D model v1

A new editable mesh interpretation of the approved blue-roofed Japanese fishing-village tower. The approved cutaway/exterior illustrations and original gameplay shape are included under `references/` and packed as reference boards in the Blender file.

## Open these files

- `CentralTower_Editable.blend`: editable source with complete interior and exterior, UVs, all 4K source material maps packed, reference boards, neutral studio lights, and preview camera. Opens on the complete exterior.
- `CentralTower_Exterior.glb`: full building with embedded textures and a separately named removable front facade.
- `CentralTower_Cutaway.glb`: same building with that facade and its front-center roof sections omitted.
- `previews/CentralTower_3D_review.png`: renders of the actual model, not generated concept art.
- `previews/CentralTower_detail_review.png`: roof/joinery and open basin detail renders.

## Scale and construction

- 128 gameplay pixels per Blender unit, following the project's existing art convention.
- Actual exported height: **32.03125 units = 4100 px**.
- Actual exported maximum width: **9.375 units = 1200 px**.
- Actual depth: **6 units = 768 px**. Depth is a proposed dimension because the gameplay reference does not specify it.
- Origin: centered across the footprint, at the bottom of the asset. Blender uses Z up; the GLB exports use Y up.
- Full model: approximately 79,600 triangles in 15 mesh objects; cutaway approximately 70,500 triangles in 10 mesh objects. Exact counts and dimensions are in the verification reports.
- Stone basin is a perimeter ring with an opening through the underside. No floor or water mesh closes the hole.
- Interior platforms, main structure, blue roof sections and basin are separate named assemblies. Timber joints, brackets, lattice windows, tiled roof curvature, rope bindings and stone courses use real geometry.

## Reveal the cutaway

In the Blender Outliner, hide `02_Facade_Removable` in both viewport and render. This removes the front cladding, door/windows and the front-center roof strips together, leaving the side supports, exterior roof wings and interior visible. Show it again for the complete exterior.

The exterior GLB retains the same named assembly so it can be toggled after import. The separate cutaway GLB offers a ready-exported alternative.

## Materials

Four painted material families: aged walnut, warm cracked plaster, slate-blue roof tiles, and slate stone. Each has color, tangent-space OpenGL normal and roughness maps.

- Editable source: 4096 × 4096 PNG color, normal and roughness maps.
- GLB: 4096 × 4096 JPEG color maps and 2048 × 2048 lossless PNG normal/roughness maps, embedded in the file.
- Repeating UVs provide fine material detail across the tall structure. The 4K composite maps combine generated painted material artwork with native-resolution microvariation; the generated painted source itself is 627 px per material quadrant. This is not native 4K image-generation output.
- Materials and mesh geometry are authored from the approved images; the model is not a pixel-exact scan of the illustration. Illustrated surface variation is interpreted as reusable textures.
- Full source maps remain available in `textures/`; smaller runtime versions are in `textures/runtime/`.

## Verification

`verification.json` checks mesh bounds, UVs, triangle counts and upward ray probes through nine points in the basin opening. `glb_verification.json` independently reads both GLBs, checks geometry bounds, texture embedding and actual image dimensions, and verifies that the removable facade appears only in the exterior export. `blender_import_verification.json` confirms both GLBs reopen in Blender with the expected dimensions, loaded textures and correct facade visibility.

No existing scenes, approved assets, project settings, gameplay collision or runtime systems were changed. This package has no gameplay collision or automatic cutaway controller. The engine handles water, underwater rendering and the interior air bubble.

## Rebuild

With Python + Pillow + NumPy, run `source/prepare_textures.py`. Then run Blender 5.2 or compatible in background with `--factory-startup --threads 8 --python source/build_tower.py`. The script rebuilds this output package and its renders. `source/verify_glb.py` checks the GLB exports, and `source/package_previews.py` assembles the review images.

The original input atlas and its ImageGen prompt are preserved in `source/`.
