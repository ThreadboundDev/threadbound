extends Node2D

@onready var rope_line: Line2D = $DanglingRopeLine
@onready var needle: Sprite2D = $DanglingNeedleSprite
@onready var needle_attach_point: Marker2D = $DanglingNeedleSprite/NeedleAttachPoint

@export var segment_count := 6
@export var segment_length := 8.0
@export var gravity := Vector2(0, 900)
@export var constraint_iterations := 8
@export var damping := 0.985
@export var flipped_attach_correction := Vector2(0, -6)

var points: Array[Vector2] = []
var previous_points: Array[Vector2] = []

func _ready() -> void:
	reset_rope()

func _physics_process(delta: float) -> void:
	if points.is_empty():
		return

	points[0] = global_position
	previous_points[0] = global_position

	for i in range(1, points.size()):
		var current := points[i]
		var velocity := (points[i] - previous_points[i]) * damping
		previous_points[i] = current
		points[i] += velocity + gravity * delta * delta

	for iteration in range(constraint_iterations):
		points[0] = global_position

		for i in range(points.size() - 1):
			var p1 := points[i]
			var p2 := points[i + 1]
			var delta_vec := p2 - p1
			var distance := delta_vec.length()

			if distance == 0:
				continue

			var difference := (distance - segment_length) / distance
			var correction := delta_vec * difference

			if i == 0:
				points[i + 1] -= correction
			else:
				points[i] += correction * 0.5
				points[i + 1] -= correction * 0.5

	_update_rope_visual()
	_place_needle_at_rope_end(points[points.size() - 1])

func reset_rope() -> void:
	points.clear()
	previous_points.clear()

	for i in range(segment_count):
		var point := global_position + Vector2(0, i * segment_length)
		points.append(point)
		previous_points.append(point)

	_update_rope_visual()

	if not points.is_empty():
		_place_needle_at_rope_end(points[points.size() - 1])

func _update_rope_visual() -> void:
	var line_points := PackedVector2Array()

	for p in points:
		line_points.append(rope_line.to_local(p))

	rope_line.points = line_points

func _place_needle_at_rope_end(rope_end_global: Vector2) -> void:
	if not needle or not needle_attach_point:
		return

	var last_index := points.size() - 1
	if last_index <= 0:
		return

	var rope_end_local := to_local(points[last_index])
	var rope_prev_local := to_local(points[last_index - 1])
	var rope_direction_local := rope_end_local - rope_prev_local

	# Let parent flipping happen naturally.
	needle.flip_h = false
	needle.flip_v = false

	# Rotate needle locally to match rope.
	needle.rotation = rope_direction_local.angle() - PI / 2.0

	# First place roughly at rope end.
	needle.position = rope_end_local

	# Then correct so NeedleAttachPoint lands exactly on rope end.
	var attach_point_local := to_local(needle_attach_point.global_position)
	var correction := rope_end_local - attach_point_local
	needle.position += correction
