@tool
class_name BossHealthBar
extends Control

const ART_SIZE := Vector2(1472.0, 424.0)
const THREADLING_IDLE_COLUMNS := 6
const THREADLING_IDLE_ROWS := 6
const THREADLING_ICON_FRAME := 0
const THREADLING_ICON_INSET_RATIO := Rect2(
	Vector2(0.24, 0.27),
	Vector2(0.48, 0.46)
)

@export_group("Boss Bar Layout")
@export var health_fill_rect := Rect2(Vector2(284.0, 232.0), Vector2(904.0, 34.0)):
	set(value):
		health_fill_rect = value
		queue_redraw()
@export var stagger_fill_rect := Rect2(Vector2(358.0, 292.0), Vector2(756.0, 16.0)):
	set(value):
		stagger_fill_rect = value
		queue_redraw()
@export var title_rect := Rect2(Vector2(440.0, 20.0), Vector2(592.0, 64.0)):
	set(value):
		title_rect = value
		_sync_title_layout()
@export var left_orb_center := Vector2(164.0, 262.0):
	set(value):
		left_orb_center = value
		queue_redraw()
@export var right_orb_center := Vector2(1308.0, 262.0):
	set(value):
		right_orb_center = value
		queue_redraw()
@export var orb_radius := 91.0:
	set(value):
		orb_radius = value
		queue_redraw()
@export var threadling_icon_scale := Vector2(1.58, 1.3):
	set(value):
		threadling_icon_scale = value
		queue_redraw()
@export var threadling_icon_offset := Vector2(0.0, 3.0):
	set(value):
		threadling_icon_offset = value
		queue_redraw()
@export var boss_title := "PROTO-WEAVER":
	set(value):
		boss_title = value
		_sync_title()

@export_group("Editor Preview")
@export var editor_preview_alive_links := true:
	set(value):
		editor_preview_alive_links = value
		queue_redraw()
@export var editor_preview_armored_fill := false:
	set(value):
		editor_preview_armored_fill = value
		queue_redraw()

@export_group("Boss Bar Colors")
@export var unarmored_fill_tint := Color.WHITE:
	set(value):
		unarmored_fill_tint = value
		queue_redraw()
@export var armored_fill_tint := Color(0.72, 0.74, 0.76, 0.96):
	set(value):
		armored_fill_tint = value
		queue_redraw()
@export var armor_overlay_color := Color(0.94, 0.97, 1.0, 0.58):
	set(value):
		armor_overlay_color = value
		queue_redraw()
@export var leading_edge_color := Color(1.0, 0.86, 0.58, 0.94):
	set(value):
		leading_edge_color = value
		queue_redraw()
@export var stagger_fill_color := Color(0.95, 0.73, 0.2, 1.0):
	set(value):
		stagger_fill_color = value
		queue_redraw()
@export var stagger_ready_color := Color(1.0, 0.92, 0.52, 1.0):
	set(value):
		stagger_ready_color = value
		queue_redraw()

@export_group("Textures")
@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		queue_redraw()
@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		_rebuild_armor_overlay_texture()
		queue_redraw()
@export var threadling_icon_texture: Texture2D:
	set(value):
		threadling_icon_texture = value
		queue_redraw()

@export var max_health := 1000:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		queue_redraw()
@export var current_health := 1000:
	set(value):
		current_health = clampi(value, 0, max_health)
		queue_redraw()

@onready var boss_title_label := get_node_or_null("BossTitle") as Label

var _link_alive := [false, false]
var _link_respawn_remaining := [0.0, 0.0]
var _link_respawn_duration := [1.0, 1.0]
var _link_pulse_warning_time := 3.0
var _stagger_value := 0.0
var _stagger_max := 1.0
var _stagger_immunity_remaining := 0.0
var _stagger_immunity_duration := 1.0
var _armor_overlay_texture: ImageTexture
var _intro_rest_position := Vector2.ZERO
var _intro_tween: Tween

func _ready() -> void:
	_intro_rest_position = position
	_rebuild_armor_overlay_texture()
	if not resized.is_connected(_sync_title_layout):
		resized.connect(_sync_title_layout)
	_sync_title()
	_sync_title_layout()
	queue_redraw()

func prepare_intro() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_rest_position = position
	position = _intro_rest_position + Vector2(0.0, -18.0)
	modulate.a = 0.0
	visible = true

func reveal_intro(duration: float = 0.4) -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	visible = true
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.set_trans(Tween.TRANS_CUBIC)
	_intro_tween.set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		self,
		"position",
		_intro_rest_position,
		maxf(0.01, duration)
	)
	_intro_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		maxf(0.01, duration)
	)

func set_health(current: int, maximum: int) -> void:
	max_health = maximum
	current_health = current

func set_stagger(
	value: float,
	maximum: float,
	immunity_remaining: float,
	immunity_duration: float
) -> void:
	_stagger_max = maxf(1.0, maximum)
	_stagger_value = clampf(value, 0.0, _stagger_max)
	_stagger_immunity_remaining = maxf(0.0, immunity_remaining)
	_stagger_immunity_duration = maxf(0.01, immunity_duration)
	queue_redraw()

func set_armor_link_state(
	index: int,
	alive: bool,
	respawn_remaining: float,
	respawn_duration: float,
	pulse_warning_time: float
) -> void:
	if index < 0 or index >= _link_alive.size():
		return

	_link_alive[index] = alive
	_link_respawn_remaining[index] = maxf(0.0, respawn_remaining)
	_link_respawn_duration[index] = maxf(0.01, respawn_duration)
	_link_pulse_warning_time = maxf(0.01, pulse_warning_time)
	queue_redraw()

func _process(_delta: float) -> void:
	if _stagger_value > 0.0 or _stagger_immunity_remaining > 0.0:
		queue_redraw()
	for index in range(_link_alive.size()):
		if _is_link_alive_for_draw(index):
			queue_redraw()
			return
		if (
			_link_respawn_remaining[index] > 0.0
			and _link_respawn_remaining[index] <= _link_pulse_warning_time
		):
			queue_redraw()
			return

func _draw() -> void:
	if not frame_texture:
		return

	var geometry := _get_draw_geometry()
	var scale_factor := float(geometry["scale"])
	var draw_size: Vector2 = geometry["draw_size"]
	var offset: Vector2 = geometry["offset"]
	var health_ratio := float(current_health) / float(max_health)
	var is_armored := _is_armored()
	if Engine.is_editor_hint():
		is_armored = editor_preview_armored_fill

	_draw_orb(offset, scale_factor, 0, left_orb_center, false)
	_draw_orb(offset, scale_factor, 1, right_orb_center, true)
	draw_texture_rect(frame_texture, Rect2(offset, draw_size), false)
	_draw_health_fill(offset, scale_factor, health_ratio, is_armored)
	_draw_stagger_fill(offset, scale_factor, is_armored)

func _draw_health_fill(
	offset: Vector2,
	scale_factor: float,
	health_ratio: float,
	is_armored: bool
) -> void:
	if health_ratio <= 0.0:
		return

	var active_rect := _source_to_draw_rect(health_fill_rect, offset, scale_factor)
	active_rect.size.x *= health_ratio
	var tint := unarmored_fill_tint

	if fill_texture:
		var source_size := fill_texture.get_size()
		var source_rect := Rect2(
			Vector2.ZERO,
			Vector2(source_size.x * health_ratio, source_size.y)
		)
		draw_texture_rect_region(fill_texture, active_rect, source_rect, tint)
	else:
		draw_rect(active_rect, Color(0.74, 0.05, 0.06, 1.0))

	if is_armored:
		_draw_armor_health_overlay(active_rect, scale_factor, health_ratio)

	if health_ratio < 1.0 and active_rect.size.x > 5.0:
		var edge_x := active_rect.end.x - 1.0
		draw_line(
			Vector2(edge_x, active_rect.position.y + 2.0),
			Vector2(edge_x, active_rect.end.y - 2.0),
			leading_edge_color,
			maxf(1.0, 2.0 * scale_factor),
			true
		)

func _draw_armor_health_overlay(
	active_rect: Rect2,
	_scale_factor: float,
	health_ratio: float
) -> void:
	if _armor_overlay_texture:
		var source_size := _armor_overlay_texture.get_size()
		var source_rect := Rect2(
			Vector2.ZERO,
			Vector2(source_size.x * clampf(health_ratio, 0.0, 1.0), source_size.y)
		)
		var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.5
		var tint := armor_overlay_color.lerp(Color(1.0, 1.0, 1.0, 0.76), pulse * 0.42)
		draw_texture_rect_region(_armor_overlay_texture, active_rect, source_rect, tint)
		return

	# Import-time fallback: remain inset inside the health-fill rectangle.
	draw_rect(active_rect.grow(-2.0), armor_overlay_color)

func _rebuild_armor_overlay_texture() -> void:
	_armor_overlay_texture = null
	if not fill_texture:
		return
	var source_image := fill_texture.get_image()
	if not source_image or source_image.is_empty():
		return
	var overlay_image := source_image.duplicate()
	overlay_image.convert(Image.FORMAT_RGBA8)
	for y in range(overlay_image.get_height()):
		for x in range(overlay_image.get_width()):
			var alpha: float = overlay_image.get_pixel(x, y).a
			overlay_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_armor_overlay_texture = ImageTexture.create_from_image(overlay_image)

func _draw_stagger_fill(offset: Vector2, scale_factor: float, is_armored: bool) -> void:
	var bar_rect := _source_to_draw_rect(stagger_fill_rect, offset, scale_factor)
	var border_width := maxf(1.0, 2.0 * scale_factor)
	draw_rect(bar_rect.grow(border_width), Color(0.025, 0.02, 0.018, 0.92))
	draw_rect(bar_rect, Color(0.11, 0.09, 0.075, 0.94))

	if is_armored:
		_draw_stagger_segments(bar_rect, scale_factor, Color(0.42, 0.46, 0.5, 0.72))
		return

	if _stagger_immunity_remaining > 0.0:
		var recovery_ratio := 1.0 - clampf(
			_stagger_immunity_remaining / _stagger_immunity_duration,
			0.0,
			1.0
		)
		var recovery_rect := bar_rect
		recovery_rect.size.x *= recovery_ratio
		draw_rect(recovery_rect, Color(0.35, 0.39, 0.43, 0.9))
		_draw_stagger_segments(bar_rect, scale_factor, Color(0.66, 0.7, 0.73, 0.7))
		return

	var stagger_ratio := clampf(_stagger_value / _stagger_max, 0.0, 1.0)
	if stagger_ratio > 0.0:
		var active_rect := bar_rect
		active_rect.size.x *= stagger_ratio
		var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.012) * 0.5
		var fill_color := stagger_fill_color.lerp(
			stagger_ready_color,
			pulse * smoothstep(0.72, 1.0, stagger_ratio)
		)
		draw_rect(active_rect, fill_color)
	_draw_stagger_segments(bar_rect, scale_factor, Color(0.94, 0.78, 0.38, 0.55))

func _draw_stagger_segments(rect: Rect2, scale_factor: float, color: Color) -> void:
	for segment in range(1, 6):
		var x := rect.position.x + rect.size.x * (float(segment) / 6.0)
		draw_line(
			Vector2(x, rect.position.y + 1.0),
			Vector2(x, rect.end.y - 1.0),
			color,
			maxf(1.0, scale_factor),
			true
		)

func _draw_orb(
	offset: Vector2,
	scale_factor: float,
	index: int,
	center: Vector2,
	flip_icon: bool
) -> void:
	var orb_center := offset + center * scale_factor
	var radius := orb_radius * scale_factor
	var alive := _is_link_alive_for_draw(index)
	var backing_color := Color(0.035, 0.028, 0.026, 0.98)

	if alive:
		var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.006 + float(index) * PI) * 0.5
		backing_color = Color(0.11, 0.025, 0.022, 1.0)
		draw_circle(
			orb_center,
			radius * lerpf(1.02, 1.14, pulse),
			Color(0.88, 0.08, 0.035, lerpf(0.08, 0.2, pulse))
		)

	draw_circle(orb_center, radius, backing_color)
	_draw_threadling_icon(orb_center, radius, alive, flip_icon)
	if not alive:
		_draw_armor_respawn_wedge(orb_center, radius, index)

func _draw_threadling_icon(
	center: Vector2,
	radius: float,
	alive: bool,
	flip_icon: bool
) -> void:
	if not threadling_icon_texture:
		return

	var cell_size := Vector2(
		float(threadling_icon_texture.get_width()) / float(THREADLING_IDLE_COLUMNS),
		float(threadling_icon_texture.get_height()) / float(THREADLING_IDLE_ROWS)
	)
	var frame_column := THREADLING_ICON_FRAME % THREADLING_IDLE_COLUMNS
	var frame_row := floori(float(THREADLING_ICON_FRAME) / float(THREADLING_IDLE_COLUMNS))
	var source_rect := Rect2(
		(
			Vector2(frame_column, frame_row) * cell_size
			+ THREADLING_ICON_INSET_RATIO.position * cell_size
		),
		THREADLING_ICON_INSET_RATIO.size * cell_size
	)
	var icon_size := Vector2(
		radius * threadling_icon_scale.x,
		radius * threadling_icon_scale.y
	)
	var local_rect := Rect2(-icon_size * 0.5 + threadling_icon_offset, icon_size)
	var tint := (
		Color(1.0, 0.96, 0.88, 1.0)
		if alive
		else Color(0.28, 0.28, 0.28, 0.82)
	)

	draw_set_transform(
		center,
		0.0,
		Vector2(-1.0, 1.0) if flip_icon else Vector2.ONE
	)
	draw_texture_rect_region(threadling_icon_texture, local_rect, source_rect, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_armor_respawn_wedge(center: Vector2, radius: float, index: int) -> void:
	var duration := maxf(0.01, float(_link_respawn_duration[index]))
	var remaining_ratio := clampf(
		float(_link_respawn_remaining[index]) / duration,
		0.0,
		1.0
	)
	if remaining_ratio <= 0.0:
		return

	var points := PackedVector2Array([center])
	var start_angle := -PI * 0.5
	var arc_angle := TAU * remaining_ratio
	var steps := maxi(4, ceili(36.0 * remaining_ratio))
	for step in range(steps + 1):
		var angle := start_angle + arc_angle * (float(step) / float(steps))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(points, Color(0.025, 0.025, 0.028, 0.72))

func _is_armored() -> bool:
	for index in range(_link_alive.size()):
		if _is_link_alive_for_draw(index):
			return true
	return false

func _is_link_alive_for_draw(index: int) -> bool:
	if Engine.is_editor_hint() and editor_preview_alive_links:
		return true
	return bool(_link_alive[index])

func _get_draw_geometry() -> Dictionary:
	var scale_factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var draw_size := ART_SIZE * scale_factor
	return {
		"scale": scale_factor,
		"draw_size": draw_size,
		"offset": (size - draw_size) * 0.5,
	}

func _source_to_draw_rect(
	source_rect: Rect2,
	offset: Vector2,
	scale_factor: float
) -> Rect2:
	return Rect2(
		offset + source_rect.position * scale_factor,
		source_rect.size * scale_factor
	)

func _sync_title() -> void:
	if not is_instance_valid(boss_title_label):
		return
	boss_title_label.text = boss_title

func _sync_title_layout() -> void:
	if not is_instance_valid(boss_title_label) or size.x <= 0.0 or size.y <= 0.0:
		return
	var geometry := _get_draw_geometry()
	var geometry_offset: Vector2 = geometry["offset"]
	var rect := _source_to_draw_rect(
		title_rect,
		geometry_offset,
		float(geometry["scale"])
	)
	boss_title_label.position = rect.position
	boss_title_label.size = rect.size
