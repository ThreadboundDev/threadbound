# Current playtest builds

Chase requested separate Windows exports of the demo and Blue levels on
November 9, 2026, and delivery to E31 Games. Threadbound builds belong in
the server's [#current-builds channel](https://discord.com/channels/1539990451447136327/1569539052145877102),
under the Threadbound category.

## Export inputs

- Demo: `Src/Environment/World/Chamber Of The First Weave.tscn`.
- Blue: `Src/Environment/BlueBiome/blue_lakeside_test.tscn`.
- Export the current saved working tree, including its existing uncommitted
  runtime changes; do not label the result as a clean-commit release.
- Each executable starts its level directly and uses a separate user-data
  directory. No scene or gameplay edits are required for packaging.
- Snapshot runtime inputs into ignored `Builds/` before exporting. Private
  local records, art sources, recordings, and the Godot AI bridge stay out.

## Build procedure

`tools/export_playtest_builds.ps1` takes an explicit Godot console executable
and a unique build identifier. Use an engine with matching Windows x64 export
templates installed. November 9 uses Godot 4.7.1 stable Mono and matching
4.7.1 templates; the development editor is 4.7.2.

The snapshot removes the local AI autoload and editor plugins, replaces the
PhantomCamera autoload UID with its equivalent file path, and changes only
the application name and startup scene for each variant. The live project
configuration is preserved. Shader baking is disabled for the headless export;
the game compiles shaders normally at runtime.

Before delivery, launch both exported executables, inspect logs and the actual
level, package the complete executable/data pair, and verify each archive.
Build artifacts and local source-status receipts stay in ignored `Builds/`.

## November 9 delivery

Base commit: `48af30e9`, plus the saved working-tree runtime changes.
Both packaged executables pass a 120-frame headless startup check and a
rendered two-frame capture. The demo shows its opening chamber and welcome
overlay; Blue shows the equipped player, tower exterior, sky, and review controls.
This is startup validation, not a complete gameplay regression.

Blue retains two scene-instance ancestry errors and a JSON parse warning after
loading; its player and level render successfully. No missing-resource or
script-compilation errors remain in the final startup logs.

Local packages are under `Builds/current-2026-11-09/`:

- `Threadbound_Demo_2026-11-09.zip`: 1,036,472,987 bytes.
- `Threadbound_Blue_2026-11-09.zip`: 1,770,535,000 bytes.

Chase authorized GitHub hosting. Both ZIPs are published on the
[Latest Builds prerelease](https://github.com/ThreadboundDev/threadbound/releases/tag/latest-builds).
GitHub reports both assets uploaded, with SHA-256 digests matching the local
archives. The reusable release tag points to export checkpoint `4186da31`.
The Discord announcement is drafted in Chrome's E31 `#current-builds` tab.
Automatic UI input could fill the message but could not focus/send it; Chase
was asked to click the composer and press Enter. Delivery verification is pending.
Local logs, render captures, archive verification, and SHA-256 receipts are
kept alongside the packages. The resource selector includes global script
classes, string-based loads, and external/shared model textures.
