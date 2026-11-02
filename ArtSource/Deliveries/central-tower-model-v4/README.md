# Central tower v4 — roof polish

Open `CentralTower_Editable.blend` in Blender. Godot uses
`Assets/BlueBiome/Art/Lakeside3D/Models/central_tower_v4.glb` through the existing
tower wrapper. This source folder is intentionally excluded from Godot import.

The existing 3D tower is the chosen direction for platform/base-entry depth.
This revision smooths the roof's timber fascia, fixes tile projection and spacing,
and reduces the roof normal strength. All 12 non-roof meshes, physical platform
locations, cutaway clearance and original model bounds are preserved. Texture
pixels are unchanged. Prior source/model versions are retained.

Rebuild from repository root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/art/polish_central_tower.py
```

Validate with `tools/art/verify_central_tower_v4.py`, then the Godot fixture
`tools/environment/verify_central_tower_polish.gd`. Delivery notes and evidence:
`docs/art/central_tower_3d_polish_v4.md` and
`work/central-tower-polish-2026-10-24/`.
