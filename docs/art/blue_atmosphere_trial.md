# Blue atmosphere trial — November 27, 2026

Chase authorized a first day/night and weather implementation in the current
Blue art-practice scene. This is a scene-local art trial awaiting hands-on
review. The existing painting, traversal collision, combat, equipment, and
Hermit water-state rules remain authoritative.

## Review

Open `Src/Environment/BlueBiome/blue_blockout.tscn` in Godot and play that scene
(F6). The lower-left atmosphere panel provides a time slider, weather choice,
and normal / 60x / paused clock.

- **Next Weather** steps through the six weather states immediately at the
  current hour. Select **Weather: automatic** to resume automatic changes.
- **Next Time** steps through dawn, noon, dusk, and midnight at the current
  weather and clock speed.
- The weather dropdown blends changes over roughly 45 seconds at 1x.
  **Apply Weather Now** jumps to the selected weather.

Pause the clock for side-by-side comparisons. Rain and cloud animation keep
running. Press **R** to return to the cave spawn.

The default starts clear at 10:00. A full day takes 2,400 seconds; sunrise is
around 05:00 and sunset around 19:00. Time pauses with the game. Reloading the
scene restarts this trial's clock; cross-room persistence is a later integration.

Weather uses six states: clear, gathering, overcast, rain, storm, clearing.
Each automatic state lasts a randomly chosen 6–15 minutes. Allowed transitions
follow those sequences, with occasional reversals and a storm branch during
rain. Rain ramps in and out. Storms have restrained cloud illumination and
delayed procedural thunder, with procedural rain ambience quieter under cover.
Audio is a placeholder for evaluating the atmosphere, not a finished sound kit.

## Presentation and shelter

The added `Atmosphere` child owns the clock, ambient/directional lighting,
soft procedural sun/moon discs, HDR bloom, cloud veil, rain and shaft shaders,
generated shadow occluders, three warm local light pools, and review controls.
It moves no existing scene nodes. The source is under
`Src/Environment/BlueBiome/Atmosphere/`.

Sky bodies have camera-independent horizontal sky positions and a gentle
vertical response to exploration. Their time-driven arcs supply the direction
for native scene light and decorative shafts. Both discs are deliberately
simple, softly edged, and glowing. Moon phases and eclipses are deferred.

The lower daytime ambient and directional light give cloud cover more room
to read. Dense clouds also dim the distant cliff and village art, sky, and
lake. Warm pools and clear-night fill keep nearby forms readable. The cloud
veil draws behind playable art. The player uses its existing 2D composite
light response, including lighting layer 2. Blue grades its two lake
presentation materials locally after the reflections are calculated.

Enabled full `CollisionPolygon2D` shapes and rectangle/convex/segment shapes
under static bodies in `Geometry` generate shadow occluders. One-way shapes
and disabled shapes are excluded. Rain and shaft masks use the same full
solids, sampled along their respective sky directions, including roofs above
the camera. The one-row mask has 2,048 samples across this test region, about
11 world pixels per sample. Rain stops at world Y=0 instead of continuing
underwater. Collision shapes, flags, and layers are never edited by the effect.

The current house roof and balcony are one-way, so they pass rain and shafts
under Chase's requested rule. Decorative artwork alone does not create shelter.
The warm pools are lighting placeholders at the cave entry, lookout, and east
house. Stained-glass windows and authored interior lights need later room art.

The source background includes painted sky and existing lighting. The sun and
moon draw above the far plate and behind nearer scenery. Precise sunset
occlusion by the far cliff silhouettes would need a separate authored mask or
separated sky/background art in a later approved art pass. No art is replaced
by this trial. There are no rain-driven lake waves, puddle gameplay, wet-footstep
changes, lunar mechanics, or global weather singleton.

## Validation and acceptance

Godot 4.7.2 passed 200 headless and 205 Forward+ checks for the revised
lighting and review controls. The tests cover the two cycle buttons, clock
duration and pause, 80 automatic weather transitions, gradual rain, collision
shelter, and both lake material passes. Rendered samples verify that noon
storms dim both open and sheltered surfaces, full roofs cast shadows, and
sheltered night scenes retain indirect light.

The initial reports and eight rendered views are in
[`work/blue-atmosphere-trial`](../../work/blue-atmosphere-trial/):
[day overview](../../work/blue-atmosphere-trial/blue_overview_day.png),
[night overview](../../work/blue-atmosphere-trial/blue_overview_night.png), and
[storm overview](../../work/blue-atmosphere-trial/blue_overview_storm.png).
The painted art and gameplay-scale night view still need Chase's acceptance.

The sandbox prevents shader-cache writes under `user://`; rendering continues.
Godot also reports shutdown resource/texture diagnostics after the rendered
test. A run of the pre-trial scene also reports shutdown resource leaks.
These diagnostics remain visible in command output and are not suppressed.

Re-run the fixture with the installed Godot executable:

```powershell
& $engine --headless --path . --script tools/environment/verify_blue_atmosphere.gd -- --scene
& $engine --path . --script tools/environment/verify_blue_atmosphere.gd -- --scene
```

Git checkpoint subject: `feature: add Blue day-night and weather trial`.
Delivery is implemented and verified; artistic acceptance remains open.
