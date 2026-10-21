@tool
extends "res://Src/Environment/Greybox/greybox_block.gd"
## Solid greybox terrain that only a committed swordfish dash can fracture.

signal fractured
signal damaged(hits_taken: int, required_hits: int)

@export_range(1, 16, 1) var hits_to_break := 1
var hits_taken := 0
var _fractured := false
var _last_strikes: Dictionary = {}

func _ready() -> void:
	one_way = false
	super._ready()

func _draw() -> void:
	if _fractured:
		return
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color(0.24, 0.32, 0.38), true)
	draw_rect(rect, Color(0.5, 0.9, 1.0), false, 4.0)
	var crack := PackedVector2Array([
		Vector2(-0.12, -0.5) * size, Vector2(0.12, -0.23) * size,
		Vector2(-0.16, 0.02) * size, Vector2(0.13, 0.26) * size,
		Vector2(-0.06, 0.5) * size
	])
	draw_polyline(crack, Color(0.7, 0.95, 1.0), 5.0, true)
	draw_line(crack[2], Vector2(-size.x * 0.5, size.y * 0.18), Color(0.7, 0.95, 1.0), 3.0, true)
	if Engine.is_editor_hint():
		draw_string(ThemeDB.fallback_font, Vector2(-size.x * 0.5, size.y * 0.5 + 26.0),
			"SWORD FISH WALL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color.WHITE)

func fracture_from_swordfish(source: Node) -> bool:
	if Engine.is_editor_hint() or _fractured or not is_instance_valid(source):
		return false
	if not source.is_in_group("swordfish") or not source.has_method("can_fracture_terrain"):
		return false
	if not source.call("can_fracture_terrain"):
		return false
	# A dash probes terrain in small substeps. Count its activation once, rather
	# than counting every collision query as a separate hit on reinforced walls.
	if source.has_method("get_terrain_strike_id"):
		var source_id := source.get_instance_id()
		var strike_id: int = source.call("get_terrain_strike_id")
		if _last_strikes.get(source_id, -1) == strike_id:
			return false
		_last_strikes[source_id] = strike_id
	hits_taken += 1
	damaged.emit(hits_taken, hits_to_break)
	queue_redraw()
	if hits_taken < hits_to_break:
		return false # Still solid: this dash must stop and recover.
	_fractured = true
	# Release physics immediately so the same dash can travel through the opening.
	collision_layer = 0
	collision_mask = 0
	_spawn_fracture_effect(source)
	hide()
	fractured.emit()
	queue_free()
	return true

func _spawn_fracture_effect(_source: Node) -> void:
	pass
