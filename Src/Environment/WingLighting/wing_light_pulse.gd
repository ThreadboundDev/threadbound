@tool
extends Node2D

@export var light_paths: Array[NodePath] = []
@export var sprite_paths: Array[NodePath] = []
@export var animated_sprite_paths: Array[NodePath] = []

@export_range(0.0, 8.0, 0.01) var base_energy := 1.0
@export_range(0.0, 8.0, 0.01) var pulse_energy := 0.18
@export_range(0.01, 10.0, 0.01) var pulse_speed := 1.25
@export_range(0.0, 1.0, 0.01) var base_alpha := 0.62
@export_range(0.0, 1.0, 0.01) var pulse_alpha := 0.16
@export_range(0.0, 60.0, 0.1) var sprite_fps := 12.0

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	var pulse := (sin(_elapsed * TAU * pulse_speed) + 1.0) * 0.5
	var energy := base_energy + (pulse_energy * pulse)
	var alpha := clampf(base_alpha + (pulse_alpha * pulse), 0.0, 1.0)

	for path in light_paths:
		var light := get_node_or_null(path) as PointLight2D
		if light != null:
			light.energy = energy

	for path in sprite_paths:
		var item := get_node_or_null(path) as CanvasItem
		if item != null:
			var color := item.modulate
			color.a = alpha
			item.modulate = color

	if sprite_fps <= 0.0:
		return

	for path in animated_sprite_paths:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite == null:
			continue
		var frame_count: int = max(sprite.hframes * sprite.vframes, 1)
		sprite.frame = int(floor(_elapsed * sprite_fps)) % frame_count
