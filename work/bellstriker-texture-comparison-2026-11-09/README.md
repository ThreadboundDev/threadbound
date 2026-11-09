# Bellstriker texture comparison candidate

November 9, 2026. Chase supplied `bellstriker no texture.fbx` and requested a
textured copy matching the front/back references, to compare with Tripo texturing.
This is a new comparison asset; no runtime Bellstriker asset is replaced.

## Open these files

- `Bellstriker_Painted_v1.glb`: portable model with embedded 4K base-color texture.
- `Bellstriker_Painted_v1.blend`: editable mesh, UVs, packed texture, and review lighting.
- `Bellstriker_BaseColor_4K.png`: standalone texture atlas.
- `preview_front.png`, `preview_back.png`, `preview_three_quarter.png`,
  `preview_side.png`: actual Blender renders of the textured mesh.
- `preview_exported_glb.png`: render after importing the exported GLB afresh.

## Method and scope

The supplied FBX has 25,661 vertices, 48,489 triangles, no UV map, and no rig.
The script applies the import transform without changing world-space geometry,
creates a Smart UV unwrap, projects the matching front/back concept colors, and
bakes them into one 4096-square UV atlas. It pads source silhouette colors and
blends front/rear colors around the local thickness of each limb. A generated
side paint guide improves side-facing surfaces using visibility-weighted blending.
The result is reference-projected texture painting, not a claim of hand-painted
brushwork or a Tripo-generated texture.

The side guide was created with built-in image_gen from a neutral side render
and the front/back references. Its full prompt is in `side_paint_prompt.txt`.
It is color guidance only: generated anatomy details in that image are not
authoritative and never alter the actual supplied mesh.

## Comparison limits

The reference images contain shading/highlights, some of which remain in the
base color. This is not a fully de-lit PBR material set. Roughness and specular
are uniform material values, not separate authored maps. Small shell boundaries,
undersides, hidden surfaces and transitions between views can retain projection
distortion. The model is unrigged; this task does not establish animation quality.

Compare the same exported mesh under the same camera, lighting and material
settings against Tripo's textured version. Inspect the side views and small
limbs as well as the front. Appearance acceptance and the choice of future
texturing workflow remain open until Chase reviews both results.

## Reproduction and validation

`texture_bellstriker.py` rebuilds this candidate from `source_untextured.fbx`,
the committed front/back reference folder, and `side_paint_guide.png`, using
Blender 5.2. It overwrites this generated candidate; preserve manual edits first.
`validation.json` records source identity, geometry preservation, UV/texture
details and fresh-export inspection. Source geometry and triangle count are
preserved; UV seams can increase the GLB's exported vertex count.

Blender reported an OS thumbnail-cache write warning while saving the first
draft; model/texture saving and export completed. This does not affect the GLB.
