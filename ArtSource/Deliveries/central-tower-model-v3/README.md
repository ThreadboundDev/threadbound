# Central tower v3 — clear interior roof edges

Open `CentralTower_Editable.blend`.

- The upper three roof tiers (02, 03 and 04) now stop past the interior wall faces when the facade is hidden.
- Their inward roof returns are separate `Roof_Tier##_Left/Right_Inner_Return_HideWithFacade` objects under `02_Facade_Removable`.
- The complete exterior retains those small sections, keeping the exterior roof continuous.
- The curved outside corners remain on the fixed left/right side roof sections.
- The bottom roof tier (01), wall geometry, platforms, basin and material images are unchanged.
- The asset still measures 4100 × 1200 gameplay px, with its existing proposed depth.

Hide `02_Facade_Removable` to view the corrected interior. Both GLBs follow the same split. Source material images are packed in the Blender file; runtime material maps are embedded in the GLBs.

`roof_clearance_verification.json` records the six roof cuts, measured clearance from the inner wall, matching combined exterior surface area, unchanged dimensions, and protected-mesh hashes. Prior model versions are retained. No game scene or camera controller was modified.
