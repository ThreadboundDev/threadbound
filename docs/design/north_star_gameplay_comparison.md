# North-Star Gameplay Comparison

## Reference

The current presentation and combat north star is the
[Castlevania: Belmont's Curse gameplay trailer](https://www.youtube.com/watch?v=mRT4JE4BJ5o).
The goal is to study its decisions, not reproduce its assets, characters, or
exact mechanics.

## What the Reference Does Especially Well

### Layered, Inhabitable Spaces

Interior spaces remain side-on and immediately playable. Rear walls establish
the room, strong foreground pillars and arches place the character inside it,
and warm windows or lamps distinguish inhabited space from exterior atmosphere.
The building is a spatial composition rather than a flat facade pasted behind a
platform.

Threadbound should use the same layer logic: rear interior, simple gameplay
collision, player, then selective foreground structure. Exterior shells can
fade into cutaways when crossed instead of loading a visually unrelated room.

### Readability Under Spectacle

Large effects expand well beyond the character, but floors, enemies, and the
player silhouette stay legible. Bright attack shapes are brief and directional;
they do not permanently raise the entire scene to the same value.

Threadbound can support similarly bold moments by reserving the brightest
thread effects for action peaks. Passive environmental motion and Flow effects
should remain quieter so attacks still have visual headroom.

### Encounter Framing

Hazards, enemies, architecture, and vertical routes are composed together. The
room itself advertises the intended maneuver before an attack begins. Tall
shafts and narrow hazard channels make vertical movement readable at a glance.

Blue rooms should likewise establish grapple, pogo, swim, and momentum routes
through silhouette before relying on markers or tutorial text.

### Material and Temperature Contrast

Cool masonry and shadow are punctuated by warm windows, fire, and impact color.
This creates depth without turning every surface blue or black.

Blue Biome foregrounds should keep warm wood, cream plaster, green vegetation,
and pink blossoms against blue atmosphere and water. Interior amber belongs in
localized windows and lamps rather than as a full-screen grade.

## Where Threadbound Should Differ

### Movement Is the Primary Expression System

The reference presents rapid authored attacks and acrobatic traversal.
Threadbound's stronger identity is the continuity between momentum, grapple,
pogo, air control, weapon use, and AP decisions. Spectacle should communicate
the player's chosen movement line rather than interrupt it with frequent locked
animations.

### AP Makes Route Choice Tactical

Threadbound's Action Points connect combat and traversal. A grapple, air jump,
or weapon decision can change what remains available before landing. Rooms need
safe baseline paths plus tempting expressive paths where spending AP saves time,
creates height, or improves an engagement angle.

### Tools Must Preserve Expression

Key items may open regional routes, but ordinary rooms should not collapse into
single-solution tool checks. Red destruction, yellow passage, and blue swimming
should create new topology while grapple, pogo, momentum, and combat continue
to offer multiple lines through that topology.

### Water Is a Gameplay Surface

The Blue wing can distinguish itself through surface swimming, jump-outs,
combat at the waterline, and later swim-enabled shortcuts. Water should be
composed with rooftops and interiors rather than treated only as a damaging pit
or background plane.

## Prototype Rules Derived from the Comparison

1. A building cutaway uses four independently authored layers: interior,
   exterior shell, gameplay collision, and foreground frame.
2. Entering a building changes presentation, not player physics or camera rules.
3. Every combat room identifies at least one baseline route and one expressive
   movement route through silhouette alone.
4. Foreground occlusion frames the player but never hides an entire combat lane.
5. Environmental animation stays irregular and low amplitude until a gust or
   authored event creates contrast.
6. Major attack effects may be large, but their brightest values are brief and
   directional.
7. Interior warmth is local; the Blue Biome's cool atmospheric identity remains
   visible through openings and distant layers.
8. Regional hazards use unmistakable sharp silhouettes and contrast, but their
   material language belongs to the biome. Blue uses brittle Threadglass growth
   rather than importing generic castle spikes everywhere.
9. Architectural lights identify inhabitable pockets and traversal landmarks.
   They should be authored as localized illumination, not baked as one uniform
   warm grade across every building.
