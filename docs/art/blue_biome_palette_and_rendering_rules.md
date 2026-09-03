# Blue Biome Palette and Rendering Rules

The Blue Biome combines Ori-like saturation and color contrast with Hollow
Knight-like gameplay readability and Threadbound's clean graphic rendering.
It should not imitate Ori's soft painterly finish or Hollow Knight's cave-dark
palette.

## Palette Roles

| Role | Hex | Use |
| --- | --- | --- |
| Terrain void | `#071522` | Interior mass and deep foreground silhouettes |
| Deep structural shadow | `#10263D` | Rock recesses, roof undersides, dense supports |
| Indigo structure | `#1E3A5A` | Secondary stone and architectural shadow |
| Slate-blue stone | `#3D6380` | Primary gameplay terrain |
| Cool edge | `#86BFD2` | Thin walkable-edge and material-plane highlights |
| Open sky | `#74C7ED` | Primary open atmosphere |
| Lake cyan | `#31C6DD` | Water surface and reflected light |
| Living blue-green | `#2F8878` | Moss and biome foliage base |
| Leaf accent | `#71B56A` | Select living accents, never uniform coverage |
| Blossom pink | `#E78DB4` | Cherry blossoms and sparse natural punctuation |
| Walnut | `#6E4936` | Village wood and warm structural contrast |
| Parchment | `#D8C5A2` | Plaster, cloth, and restrained architecture |
| Lantern amber | `#F2A64A` | Architecture, safety, interiors, save points |
| Identity cyan-white | `#D9FBFF` | Identity magic and highest-priority effects only |

These values are anchors. Local variation is allowed, but every asset must
remain recognizably inside its role.

## Value and Contour Hierarchy

1. Gameplay-contact edges carry the sharpest contour and strongest local
   contrast.
2. Terrain interiors group into quiet navy masses. Do not fully render stones
   throughout every solid body.
3. Landmark detail clusters around traversal decisions, buildings, entrances,
   secrets, and save points.
4. Background contours soften and values compress with distance.
5. Foreground framing may approach the terrain-void value but must not hide
   required traversal information.

## Asset Rules

- Use clean, intentional silhouettes and controlled color shapes.
- Structural assets use neutral ambient material shading only.
- Do not bake sunlight, lantern pools, cast shadows, bloom, fog, or water
  reflections into reusable gameplay assets.
- Keep foliage, blossoms, mushrooms, lanterns, and distinctive roots separate
  unless they define a unique landmark.
- Provide simple overlap zones at connection seams.
- Preserve transparent negative space around non-background assets.
- Generate and approve albedo art before deriving a normal map.
- Normal maps support subtle material response; they do not repair unclear art.

## Saturation Budget

Saturation should be concentrated, not spread evenly. Sky and water establish
the broad cyan/blue field. Green and pink add life. Amber marks inhabited or
safe spaces. Cyan-white is reserved for identity and exceptional emphasis.
Quiet terrain keeps those colors readable.

## Generation Regions

`ArtGenerationRegion2D` polygons define one logical asset request at exact
world scale. Regions are planning guides only and disappear at runtime. Each
region records its layer, category, orientation, pixels-per-world-unit,
overlap padding, notes, world polygon, bounds, and target pixel dimensions.

Choose seams through quiet, simple material—not through houses, major roots,
doors, or recognizable landmarks. Adjacent regions should overlap enough to
permit masking or a small seam-cover asset.
