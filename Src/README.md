# Game scenes and code

Open `project.godot` in the repository root. The main entry is
`UI/MainMenu/main_menu.tscn`; the demo world is
`Environment/World/Chamber Of The First Weave.tscn`.

Folders name their game role: `Characters`, `Enemies`, `Equipment`, `Environment`,
`Components`, `Global`, `UI`, `VFX`, `Pickups`, and focused prototype/test content.
Do not move scenes or scripts in Explorer: Godot paths, UIDs and dynamic loads
must be audited together. This organization pass preserves runtime resource paths.

The current player is `Characters/Player/player.tscn`. Its folder guide explains
the active renderer and the legacy dependencies awaiting cleanup approval.
