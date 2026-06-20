extends CanvasLayer
class_name GameOverOverlay

signal completed

const BLUR_SHADER := preload("res://Src/Environment/World/menu_blur.gdshader")

@export var world_fade_duration := 1.15
@export var final_hold_duration := 2.25
@export var blur_alpha := 1.0
@export var veil_alpha := 1.0

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var start_frame_rect: TextureRect = $StartFrameRect as TextureRect
@onready var sprite_sheet_player: Control = $SpriteSheetPlayer as Control
@onready var veil_rect: ColorRect = $VeilRect as ColorRect

var _finished := false
var _hold_started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_configure_blur()
	_prepare_visuals()
	_start_world_fade()
	_play_sprite_sheet()

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
	sprite_sheet_player.modulate.a = 0.0
	sprite_sheet_player.visible = false

func _start_world_fade() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", blur_alpha, world_fade_duration)
	tween.tween_property(veil_rect, "modulate:a", veil_alpha, world_fade_duration)

func _play_sprite_sheet() -> void:
	if not sprite_sheet_player:
		_finish()
		return

	var finished_callable := Callable(self, "_on_sprite_sheet_finished")
	if sprite_sheet_player.has_signal("animation_finished") and not sprite_sheet_player.is_connected("animation_finished", finished_callable):
		sprite_sheet_player.connect("animation_finished", finished_callable)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(start_frame_rect, "modulate:a", 0.0, world_fade_duration * 0.35)
	sprite_sheet_player.call("play")

func _on_sprite_sheet_finished() -> void:
	_hold_final_frame()

func _hold_final_frame() -> void:
	if _hold_started:
		return

	_hold_started = true
	if _finished:
		return

	sprite_sheet_player.call("skip_to_last_frame")
	start_frame_rect.visible = false

	await get_tree().create_timer(final_hold_duration, true, false, true).timeout
	_finish()

func _finish() -> void:
	if _finished:
		return

	if not get_tree():
		return

	_finished = true
	if sprite_sheet_player:
		sprite_sheet_player.call("skip_to_last_frame")
	get_tree().paused = false
	completed.emit()
	queue_free()
