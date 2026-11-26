# Woven Blue wood and rope bridge

The 11 Krita presets use four tags in the Brush Presets docker.

- **Woven Blue - Wood Textures** has warm amber and damp cedar fields for
  clipping inside your own freehand outlines.
- **Woven Blue - Timber Supports** has a straight cedar post, cross-braced
  trestle, and forked pier with black contours.
- **Woven Blue - Rope Bridge Decks** has inked Start, Repeat, and End
  segments for the walkable plank deck.
- **Woven Blue - Rope Bridge Fronts** has matching Start, Repeat, and End
  segments for the near-side rope and posts.

- [Asset catalog](catalog.jpg)
- [Full-resolution transparent PNGs](stamps/)
- [Krita resource bundle](Threadbound_Woven_Blue_Wood_And_Bridge.bundle)
- [Editable bridge assembly](Rope_Bridge_Assembly.ora)
- [Built-in ImageGen prompts, native sizes, and join checks](manifest.json)

Place a **Start** pair, one or more **Repeat** pairs, then the **End** pair.
At native scale, each cap is 144 px wide and each repeat adds 744 px and
two bays. All six PNGs are 450 px tall. Place each matching deck and front
at the same coordinates. Advance by the full width of the previous piece,
including its transparent canvas. The standing line is 288 px below the
common top edge. Scale the assembled layers together to keep both passes
registered.

The OpenRaster example has three repeats and two caps, with a **Character
slot** between the deck and the foreground rope and posts. Export the deck
and fronts as separate passes to reproduce that order in Godot. Put the
walkable collision along the deck. The front pass supplies the overlap.

Both repeat joins match pixel for pixel. The temporary Godot trial used the
current player and Blue shoreline backdrop. The player reached the far cap
while grounded, and a live frame showed the front rope and posts occluding
the character as intended.
