extends "res://Src/Enemies/EaveRunner/woven_pin.gd"
## Ivory spindle with a short blue thread tail; shares proven projectile physics.
func _ready() -> void:
	super._ready()
	add_to_group("heron_needles")

func _draw() -> void:
	draw_polyline(PackedVector2Array([Vector2(-45, 3), Vector2(-35, -2), Vector2(-26, 1), Vector2(-16, 0)]), Color(.28, .68, .9, .8), 1.8, true)
	draw_colored_polygon(PackedVector2Array([Vector2(23, 0), Vector2(-1, -4), Vector2(-20, -2), Vector2(-20, 2), Vector2(-1, 4)]), Color(.85, .83, .69))
	draw_line(Vector2(-16, -1), Vector2(11, -1), Color(.97, .97, .91), 1.2, true)
	for x in range(-19, -8, 3):
		draw_line(Vector2(x, -2.5), Vector2(x + 1, 2.5), Color(.12, .27, .34), 1.4, true)
