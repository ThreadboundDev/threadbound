# Blue regression layouts

These frozen layouts support existing automated checks. They are not game
levels and are hidden from Godot's normal filesystem/import/export scan.
Their tests and assertions were retained, rather than dropped for cleanup.

The single active Blue level is `Src/Environment/BlueBiome/blue_lakeside_test.tscn`.
Reuse runtime components from `Src/Environment/BlueBiome`, not these fixtures.
