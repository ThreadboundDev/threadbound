extends "res://Src/Environment/BlueBiome/References/blue_macro_reference.gd"
## Reference images live outside Godot's import scan after source organization.
## Load the original PNG directly for this hidden regression fixture.
func _ready() -> void:
	var image := Image.load_from_file("res://docs/design/references/blue_biome_macro_map.png")
	if image:
		texture = ImageTexture.create_from_image(image)
	super._ready()
