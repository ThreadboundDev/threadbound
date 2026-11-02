# Editable art and delivered source

- `Player/`: character Blender sources, animation authoring and reference art.
- `BlueBiome/`: environment, enemy, villager, Krita and stamp sources.
- `Deliveries/`: retained model/review packages formerly in the vague `outputs/`
  folder. Use the current asset's source guide when several historical versions exist.
- `RecoveredLocal/`: consolidated local paintings, early editable tiles and original
  design references recovered from Desktop and Documents/Codex. These files stay
  local and retain their internal authoring layout; see the root `START_HERE.md`.
- `GrassMask/`, `VFX/`: source material for those effects.

Godot ignores this source tree. Runtime-ready exports belong in `Assets/`.
Duplicate Blender files in delivery packages were staged only when their SHA-256
matched a retained source. Affected packages have `SOURCE_LOCATIONS.md` pointers.
