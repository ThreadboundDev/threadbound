extends Control
class_name GameOverSpriteSheetPlayer

signal animation_finished

@export var sprite_sheet_texture: Texture2D:
	set(value):
		sprite_sheet_texture = value
		queue_redraw()
@export_range(1, 16, 1) var columns := 6:
	set(value):
		columns = maxi(1, value)
		queue_redraw()
@export_range(1, 16, 1) var rows := 6:
	set(value):
		rows = maxi(1, value)
		queue_redraw()
@export_range(1, 256, 1) var frame_count := 36:
	set(value):
		frame_count = maxi(1, value)
		queue_redraw()
@export_range(1.0, 60.0, 0.5) var frames_per_second := 18.0
@export_range(1, 60, 1) var fade_in_frames := 12

var _elapsed := 0.0
var _current_frame := 0
var _playing := false
var _finished := false

func _ready() -> void:
	set_process(false)

func play() -> void:
	_elapsed = 0.0
	_current_frame = 0
	_playing = true
	_finished = false
	visible = true
	modulate.a = 0.0
	set_process(true)
	queue_redraw()

func skip_to_last_frame() -> void:
	_playing = false
	_finished = true
	_current_frame = max(0, frame_count - 1)
	modulate.a = 1.0
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	if not _playing:
		return

	_elapsed += delta
	var frame_duration := 1.0 / maxf(frames_per_second, 1.0)
	var next_frame := mini(floori(_elapsed / frame_duration), frame_count - 1)
	if next_frame != _current_frame:
		_current_frame = next_frame
		queue_redraw()

	modulate.a = clampf(float(_current_frame + 1) / float(maxi(fade_in_frames, 1)), 0.0, 1.0)
	if _current_frame >= frame_count - 1 and not _finished:
		_playing = false
		_finished = true
		set_process(false)
		animation_finished.emit()

func _draw() -> void:
	if not sprite_sheet_texture:
		return

	var texture_size := sprite_sheet_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var cell_size := Vector2(texture_size.x / float(columns), texture_size.y / float(rows))
	var frame := clampi(_current_frame, 0, max(0, frame_count - 1))
	var frame_column := frame % columns
	var frame_row := floori(float(frame) / float(columns))
	var source := Rect2(
		Vector2(float(frame_column), float(frame_row)) * cell_size,
		cell_size
	)
	var destination := _get_contain_rect(size, cell_size)
	draw_texture_rect_region(sprite_sheet_texture, destination, source)

func _get_contain_rect(target_size: Vector2, content_size: Vector2) -> Rect2:
	if target_size.x <= 0.0 or target_size.y <= 0.0 or content_size.x <= 0.0 or content_size.y <= 0.0:
		return Rect2(Vector2.ZERO, target_size)

	var scale_factor := minf(target_size.x / content_size.x, target_size.y / content_size.y)
	var draw_size := content_size * scale_factor
	return Rect2((target_size - draw_size) * 0.5, draw_size)
