# Connected terrain paintover

The full-map [line-art trace](Blue_Terrain_Line_Art.ora) sits at 1:1 Godot
scale on the same 6784 × 4096 canvas as the Blue painting. Canvas (1536,
2816) is world (0, 0). The terrain ink follows the outside of connected
solid shapes, and the one-way spans are on a separate layer. Turn on
**Exact authored collision** to compare all 502 saved tiles. The Chamber
line study, boundary guides, waterline, and route markers can be toggled.

- [Full-map trace preview](level-trace.jpg)
- [Chamber line art and paint side by side](chamber-comparison.jpg)
- [Layered Chamber proof](Chamber_Paint_Proof.ora)
- [Chamber line-art input](chamber-line-guide.png)
- [Native transparent Chamber paint](chamber-paint.png)
- [Built-in ImageGen prompt and validation](trace.json)

Sketch a connected wall and any shelf it supports as one silhouette.
Trace the front and rear edges of the standing surface before painting.
Use the line art as the paint guide and carry the same stone facets across
the joint.

The proof paints the Chamber mouth, wall, three upper terraces, and
lower landing together. Grass and near-lantern illumination are painted
into this visual test. The whole-map trace provides separate blank rock,
grass, and lighting layers for authoring. The proof has real transparency
through its doorway. Its registered silhouette covers 96% of the guide by
intersection over union. Art-to-collision fit is still a separate check.
