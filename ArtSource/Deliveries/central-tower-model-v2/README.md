# Central tower v2 — roof corner correction

Open `CentralTower_Editable.blend`. This is a new version; the v1 Blender file is retained.

The four main eave tiers now use roof sections with shared angled edges and curved outside corners. The former crossing rectangular strips and fascia boards were removed.

## Find the parts

- `Roof_Tier##_Left_Side_With_Corners` and `Roof_Tier##_Right_Side_With_Corners`: front-to-back side sections. Each includes its front AND back curved corner returns and the matching curved wooden fascia.
- `Roof_Tier##_Front_Mitered`: shorter front-center roof strips, inside `02_Facade_Removable` with the front wall.
- `Roof_Tier##_Back_Mitered`: matching shorter back-center roof strips, inside `04_Fixed_Blue_Roofs`.
- `Roof_Crown_Caps__...`: existing top-prong caps.

Hide `02_Facade_Removable` to see the cutaway. The curved corner returns stay attached to the left and right sides. Both GLB exports follow that same division.

Dimensions remain **4100 px tall × 1200 px wide**, using 128 px per Blender unit. Proposed depth remains 768 px. The basin, wall and platform meshes retain their original geometry, and the material images are unchanged.

`roof_joint_verification.json` records the shared seam checks, zero roof-footprint overlap at the new joins, unchanged dimensions, and hashes for protected structure/interior/basin meshes. The source correction script is included under `source/`. It reads the v1 Blender file and writes this new output folder.

The Blender file contains its packed source material maps. The GLBs embed the runtime textures. No runtime camera or game scene has been edited.
