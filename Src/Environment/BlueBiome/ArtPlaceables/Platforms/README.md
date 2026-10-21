# Timber walkway stamps (2D)

Instance `plank_crossing_2d.tscn`, `railed_veranda_2d.tscn`,
`engawa_balcony_2d.tscn` or `broken_timber_bridge_2d.tscn`. The root and its
`WalkPlane` marker are the **left end of the walking surface**. Set `span_width`
in world pixels; keep the instance scale at `(1, 1)`. `detail_scale` controls
the uniform scale of boards/posts (default 0.24). The artwork redraws in the
editor when these properties change.

These objects contain **no physics**. Align the origin to an existing collider's
top-left and its span to the collider width. The Krita room still owns its nine
one-way landing polygons. Adding an instance elsewhere does not create a
walkable bridge: author its collision explicitly in the room.

The three intact types draw original texture regions: fixed end caps and a
repeated/clipped middle, with equal horizontal/vertical pixel scale. Spans too
short to fit both caps shrink all details uniformly. Cuts meet along horizontal
deck/rail beams; inspect joins at normal camera zoom after changing a length.
The source walk lines are B04 y=126, J03 y=248 and A04 y=445, chosen along the
front portion of the perspective deck top. Rails sit behind actors. Prefab roots
default to z=-1; room instances use z=0 under the existing z=-1 landing group,
preserving the old artwork's effective depth.

The broken pair always fits the **whole original image uniformly**, including
its transparent gap; it never tiles a solid middle. It is available in the
library but deliberately unplaced in the current map. Future placement needs
separate collision for the left/right halves and an explicit gap review.

Four runtime PNGs are byte-identical to the saved Slate Library sources in
`ArtSource/BlueBiome/Placeables/WalkwayStamps/`; `provenance.json` records hashes.
Lossless imports retain alpha and generate mipmaps. Chase excluded the T01
rock-attached landing from the runtime options. The archived source catalog and
old deck/rope-bridge assets remain available as historical references.

Run `tools/environment/verify_lakeside_walkways.gd` headlessly for source hashes,
span/anchor/scale checks, original collision data and actual player landings and
walking on all nine platforms. Visible seams, feet on the painted deck,
layering beside houses and daylight/dusk appearance still require in-game review.
