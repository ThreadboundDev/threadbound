extends CanvasLayer
class_name GameOverOverlay

signal completed

const BLUR_SHADER := preload("res://Src/Environment/World/menu_blur.gdshader")

@export_file("*.mp4", "*.ogv", "*.webm") var video_path := "res://Assets/UI/Game Over Screen/game_over_video.mp4"
@export var world_fade_duration := 1.15
@export var video_fade_duration := 0.35
@export var final_hold_duration := 2.25
@export var fallback_video_duration := 2.0
@export var blur_alpha := 1.0
@export var veil_alpha := 1.0

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var start_frame_rect: TextureRect = $StartFrameRect as TextureRect
@onready var video_player: VideoStreamPlayer = $VideoPlayer as VideoStreamPlayer
@onready var end_frame_rect: TextureRect = $EndFrameRect as TextureRect
@onready var veil_rect: ColorRect = $VeilRect as ColorRect

var _finished := false
var _hold_started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_configure_blur()
	_prepare_visuals()
	_start_world_fade()
	_play_video()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and get_tree():
		get_tree().paused = false

func _configure_blur() -> void:
	var material := ShaderMaterial.new()
	material.shader = BLUR_SHADER
	material.set_shader_parameter("blur_amount", 5.8)
	material.set_shader_parameter("blur_samples", 5.0)
	material.set_shader_parameter("desaturation", 0.92)
	material.set_shader_parameter("blue_tint_strength", 0.08)
	material.set_shader_parameter("blue_tint_color", Color(0.78, 0.84, 1.0, 1.0))
	blur_rect.material = material

func _prepare_visuals() -> void:
	blur_rect.modulate.a = 0.0
	veil_rect.modulate.a = 0.0
	start_frame_rect.modulate.a = 1.0
	video_player.modulate.a = 0.0
	end_frame_rect.modulate.a = 0.0
	end_frame_rect.visible = false

func _start_world_fade() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", blur_alpha, world_fade_duration)
	tween.tween_property(veil_rect, "modulate:a", veil_alpha, world_fade_duration)

func _play_video() -> void:
	var stream := load(video_path) as VideoStream
	if not stream:
		push_warning("GameOverOverlay: Could not load video stream: %s. Showing final frame fallback." % video_path)
		_show_final_frame_after_delay(fallback_video_duration)
		return

	video_player.stream = stream
	if not video_player.finished.is_connected(_on_video_finished):
		video_player.finished.connect(_on_video_finished)

	video_player.play()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(video_player, "modulate:a", 1.0, video_fade_duration)
	tween.tween_property(start_frame_rect, "modulate:a", 0.0, video_fade_duration)

func _on_video_finished() -> void:
	_show_final_frame_after_delay(0.0)

func _show_final_frame_after_delay(delay: float) -> void:
	if _hold_started:
		return

	_hold_started = true
	if delay > 0.0:
		await get_tree().create_timer(delay, true, false, true).timeout
	if _finished:
		return

	end_frame_rect.visible = true
	end_frame_rect.modulate.a = 1.0
	video_player.visible = false
	start_frame_rect.visible = false

	await get_tree().create_timer(final_hold_duration, true, false, true).timeout
	_finish()

func _finish() -> void:
	if _finished:
		return

	if not get_tree():
		return

	_finished = true
	if video_player:
		video_player.stop()
	get_tree().paused = false
	completed.emit()
	queue_free()
