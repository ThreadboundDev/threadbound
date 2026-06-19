extends CanvasLayer
class_name GameOverOverlay

signal completed

const BLUR_SHADER := preload("res://Src/Environment/World/menu_blur.gdshader")
const FRAME_TEXTURES := [
	preload("res://Assets/UI/Game Over Gif/game_over_gif_1.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_2.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_3.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_4.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_5.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_6.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_7.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_8.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_9.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_10.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_11.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_12.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_13.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_14.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_15.png"),
	preload("res://Assets/UI/Game Over Gif/game_over_gif_16.png"),
]

@export var frame_time := 0.16
@export var opening_frame_time := 0.24
@export var opening_frame_count := 4
@export var fade_in_duration := 0.9
@export var end_hold_duration := 0.85

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var veil_rect: ColorRect = $VeilRect as ColorRect
@onready var frame_rect: TextureRect = $FrameRect as TextureRect

var _frames: Array[Texture2D] = []
var _frame_index := 0
var _elapsed := 0.0
var _hold_started := false
var _finished := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build_frames()
	_configure_blur()
	_show_frame(0)
	_fade_in()

func _process(delta: float) -> void:
	if _finished or _hold_started:
		return

	_elapsed += delta
	if _elapsed < _current_frame_time():
		return

	_elapsed = 0.0
	_frame_index += 1
	if _frame_index >= _frames.size():
		_finish_after_hold()
		return

	_show_frame(_frame_index)

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and get_tree():
		get_tree().paused = false

func _build_frames() -> void:
	_frames.clear()

	for texture: Texture2D in FRAME_TEXTURES:
		_frames.append(texture)

func _configure_blur() -> void:
	var material := ShaderMaterial.new()
	material.shader = BLUR_SHADER
	material.set_shader_parameter("blur_amount", 5.25)
	material.set_shader_parameter("blur_samples", 5.0)
	material.set_shader_parameter("desaturation", 0.86)
	material.set_shader_parameter("blue_tint_strength", 0.18)
	material.set_shader_parameter("blue_tint_color", Color(0.78, 0.84, 1.0, 1.0))
	blur_rect.material = material

func _show_frame(index: int) -> void:
	if index < 0 or index >= _frames.size():
		return

	frame_rect.texture = _frames[index]

func _current_frame_time() -> float:
	if _frame_index < opening_frame_count:
		return opening_frame_time

	return frame_time

func _fade_in() -> void:
	blur_rect.modulate.a = 0.0
	veil_rect.modulate.a = 0.0
	frame_rect.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(veil_rect, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(frame_rect, "modulate:a", 1.0, fade_in_duration)

func _finish_after_hold() -> void:
	if _hold_started:
		return

	_hold_started = true
	var timer: SceneTreeTimer = get_tree().create_timer(end_hold_duration, true, false, true)
	await timer.timeout
	_finish()

func _finish() -> void:
	if _finished:
		return

	if not get_tree():
		return

	_finished = true
	get_tree().paused = false
	completed.emit()
	queue_free()
