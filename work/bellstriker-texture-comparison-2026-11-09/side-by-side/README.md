# Bellstriker: Codex versus Tripo

November 9, 2026. Chase requested a visible side-by-side comparison of the locally
textured candidate and the newly downloaded Tripo textured model.

Open `Bellstriker_Codex_vs_Tripo.blend`. Codex is on the left, Tripo on the right.
Both texture images are packed into the Blender file. The comparison opens at
the angled view. Use the timeline's current-frame field or markers:

| Frame | View |
| --- | --- |
| 1 | Front |
| 40 | Angled |
| 80 | Back |
| 120 | Side |

The four `compare_*.png` files are labeled Blender renders of these views.
The source texture images are unchanged. Both comparison materials use the same
roughness (0.48), metallic (0), and specular IOR level (0.28). Shared world and
directional lighting, orthographic camera, scale, and rotations keep conditions
consistent across the two subjects. These are base-color comparisons; they do
not compare different PBR shader setups or animation.

`comparison_report.json` confirms both source bounds and triangle counts match,
both textures are 4096 by 4096, and the maximum nearest-vertex distance after
normalization is zero. Both models have 48,489 triangles.

The Tripo source was extracted from Chase's downloaded
`fantasy insect 3d model.zip`. Its FBX and JPG are retained in `tripo_source/`.
`build_comparison.py` reproduces this scene and renders using Blender 5.2.
It overwrites generated outputs; preserve any manual scene edits before rerunning.

No runtime assets changed. Appearance preference and future texturing workflow
remain for Chase's review. The pre-existing Blender thumbnail-cache warning and
small shutdown allocation warning do not prevent the saved scene or renders.
