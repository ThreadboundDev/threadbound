# Blue Biome Direction

This document records the current Blue/Hermit direction. Details marked unresolved are design conversation, not locked implementation requirements.

The current macro-layout image is stored at `docs/design/references/blue_biome_macro_map.png`. It is the spatial reference for room silhouettes, relative placement, major routes, and vistas. It is not literal collision or a single runtime level.

## Region Route

```text
                              WATERFALL ASCENT
                                      ↑
                                HERMIT'S LAKE
                                  Hermit / Boat
                                      ↑
                                    Dock
                                      │
CHAMBER EXIT → UPPER VILLAGE → LAKESIDE VILLAGE → PEASANT FIELDS
                  ROOFTOPS        │       │              │
                              LOWER SHORE │       IRRIGATION / FARM
                                  │       │              │
                            WATER / SECRETS       SHRINE APPROACH
                                                         │
                                                     OLD SHRINE
                                                       ITEM
```

The Chamber enters through the Upper Village rooftops, which connect into the Lakeside Village. From the Village, the dock and Hermit's Lake branch upward toward the boss and waterfall ascent. The main overland route continues east into the Peasant Fields, then loops down through irrigation and farm spaces before climbing back toward the Old Shrine.

## Fields and Shrine Loop

From the Peasant Fields, the player should be able to look across water and clearly see the Old Shrine before they can reach it directly. The visible crossing establishes an understandable shortcut and makes the eventual swim ability feel spatially meaningful.

The initial route is deliberately indirect:

1. Reach the Peasant Fields and see the Shrine across the water.
2. Discover that the direct water crossing is not currently usable.
3. Travel down through irrigation and farm rooms.
4. Move east and climb back toward the Shrine Approach.
5. Enter the Old Shrine and acquire the unnamed Blue regional key item, potentially after a miniboss or another focused encounter.
6. Use the newly acquired swim ability to cross directly back to the Fields.

The exact Shrine encounter and item presentation remain unresolved. The important spatial promise is established: **see the destination, understand the blocked shortcut, earn the ability, then physically prove the shortcut now works.**

## Geographic Identity

Blue is an enormous, vibrant lakeside place rather than a sequence of disconnected rooms. Individual room backgrounds should maintain a consistent relationship to the central lake, Hermit's boat, distant cliffs, and enormous dry waterfall.

The Village may include cherry blossoms, grass and flowers, shoreline houses, NPCs, docks, warm wood, grey stone, and distant pale atmosphere. Blue remains the Thread accent; the natural world should remain lush and varied.

Guiding sentence: **a weaving machine mistaken for a peaceful lakeside village.** Favor curves, arches, circles, suspension, long horizontal forms, flowing roofs, balanced repetition, and hanging fabric without defaulting to generic Japanese fantasy.

Keep major materials to roughly three clear values or colors: dark/mid/light pink for blossoms, green for grass, slate for stone, and warm brown for wood. Avoid noisy near-duplicate color variation.

## Open-Air Background Direction

Blue is an exposed lakeside region, not a cave recolored blue. Its farthest
layer should feel light, spacious, and sky-cyan, with pale clouds and
atmospheric mountain depth. Avoid blanket navy filters or global opacity that
makes every layer equally dim and blue.

Build exterior scenes from back to front. Begin with a vertically complete sky
and distant landscape, then add separate cloud cutouts, distant architecture,
near silhouettes, gameplay artwork, and foreground framing. Background art
pieces should keep their painted pixels opaque and use genuine alpha only for
negative space such as open sky. Apply atmospheric separation with restrained
color/value materials rather than fading the entire sprite.

Clouds should move slowly on their own shallow parallax layer. The motion is an
ambient sign of an inhabited outdoor world, not a strong weather effect. Far
plates may repeat horizontally when their edges support it, but must never
repeat vertically.

## Stagnant Water

The lake is unnaturally still: no current, no waves, and boats no longer function normally. The great waterfall is dry. The Hermit is holding the water in forced equilibrium, expressing the failure state of Balance as stagnation and inaction.

Environmental evidence should communicate this without exposition: dry irrigation, old water wheels, abandoned boats, water-carved rock, stagnant channels, and the visible waterfall face.

## Hazard Family — Threadglass Reeds

The Blue region should not default to ordinary metal or stone spikes. Its
primary reusable hazard family is provisionally called **Threadglass Reeds**:
water plants and irrigation growth arrested into rigid, glass-like blades by
the Hermit's forced stillness.

Their gameplay silhouette remains unmistakably dangerous:

- long triangular blades with hard inward hooks;
- a dense dark-indigo base separating them from safe green grass;
- pale cyan cutting edges and small coral-pink stress fractures, using warm
  contrast as a warning rather than turning the whole hazard generic red;
- sharp highlights that do not appear on ordinary foliage;
- a faint tense vibration while nearby, followed by a brittle snap response on
  impact or pogo.

The same family should support floor beds, wall growth, hanging irrigation
clusters, and partially submerged reeds through rotation and a few silhouette
variants. Pogoable instances need an especially clear bright crown or central
blade that reads as a deliberate strike target. Their collision and damage
continue to use the existing hazard system; the artwork is a regional skin, not
a separate damage mechanic.

Possible later variants include a round **Razor Lotus** for isolated waterline
hazards and shattered Threadglass fragments for gust-driven moving-water rooms.
These should remain members of the same material family rather than unrelated
blue enemies or generic spike traps.

## Village Lantern Lighting

Lanterns visible in house artwork should eventually emit real localized light.
Exterior lanterns use restrained amber pools with irregular low-amplitude
flicker; they guide doors, platforms, and inhabited routes without flattening
the cool nighttime atmosphere. Not every lantern should share the same radius,
energy, or flicker phase.

Interior lanterns are more important. A cutaway should raise warm interior
light as the exterior shell fades, with the strongest pools around the lower
playable room, ladder, door, or NPC. Cool ambient shadow must remain between
those pools so the room preserves depth and gameplay silhouettes. Lantern
sprites should receive a restrained emissive treatment, while PointLight2D
nodes provide nearby material response. Avoid full-room orange overlays and
rapid random flicker.

## Hermit Encounter

The Hermit remains on a tiny fishing boat. The current encounter concept is:

1. The player reaches the boat and has a brief conversation; the Hermit is reluctant to fight.
2. A boat phase uses the Hermit's fishing rod and may involve flung aquatic creatures or adds.
3. The player sinks or damages the boat enough to break the Hermit's restraint.
4. The Hermit responds with a restrained line in the spirit of, “You wish the water to move?” The exact dialogue is not final.
5. He stops holding the water back. The waterfall, lake waves, currents, streams, and water wheels return.
6. Moving-water combat leads into a short, gameplay-driven waterfall ascent.
7. A quiet shallow source pool and open sky frame the final confrontation.

The intended pacing is stillness → disruption → chaotic movement → quiet confrontation. The ascent should be a concise movement/combat exam, not a long scripted sequence.

## Regional Key Items — Unresolved Design Direction

Each wing may contain a key item that grants a regional world-interaction ability. These items are **not equipment** and should not create classes or permanent builds.

- Red: break cracked walls and floors. Current intent is optional exploration rather than critical-path gating.
- Yellow: pass through translucent shimmering walls. Progression gating is possible but unresolved.
- Blue: swim. Current route intent places it in the Old Shrine after the long irrigation loop. Its first clear payoff is opening the visible Shrine-to-Fields water shortcut and making earlier water explorable. Whether it also gates later critical progression remains unresolved.

Working names and fiction for the items are not yet established. They should feel grounded in each Thread Master's prior life rather than like generic magical keys.

This direction creates a pending design-doc question: distinguish optional equipment-based expression from deliberate story or regional key-item progression. The current “no hard gating” rule remains in force until that conversation is resolved and the core guidelines are intentionally revised.
