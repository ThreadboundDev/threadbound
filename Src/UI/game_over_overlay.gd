extends CanvasLayer
class_name GameOverOverlay

signal completed

const BLUR_SHADER := preload("res://Src/Environment/World/menu_blur.gdshader")

@export var world_fade_duration := 1.15
@export var prompt_fade_duration := 0.45
@export var blur_alpha := 1.0
@export var veil_alpha := 1.0

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var sprite_sheet_player: Control = $SpriteSheetPlayer as Control
@onready var veil_rect: ColorRect = $VeilRect as ColorRect
@onready var prompt_label: Label = $PromptLabel as Label

var _finished := false
var _hold_started := false
var _waiting_for_continue := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_game_over_music()
	get_tree().paused = true
	_configure_blur()
	_prepare_visuals()
	call_deferred("_run_game_over_sequence")

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return

	if _waiting_for_continue and _is_continue_input(event):
		get_viewport().set_input_as_handled()
		_finish()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and get_tree():
		get_tree().paused = false

func _configure_blur() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = BLUR_SHADER
	shader_material.set_shader_parameter("blur_amount", 5.8)
	shader_material.set_shader_parameter("blur_samples", 5.0)
	shader_material.set_shader_parameter("desaturation", 0.92)
	shader_material.set_shader_parameter("blue_tint_strength", 0.08)
	shader_material.set_shader_parameter("blue_tint_color", Color(0.78, 0.84, 1.0, 1.0))
	blur_rect.material = shader_material

func _prepare_visuals() -> void:
	blur_rect.modulate.a = 0.0
	veil_rect.modulate.a = 0.0
	sprite_sheet_player.modulate.a = 0.0
	sprite_sheet_player.visible = false
	prompt_label.modulate.a = 0.0
	prompt_label.visible = false

func _run_game_over_sequence() -> void:
	var fade_tween := _start_world_fade()
	if fade_tween:
		await fade_tween.finished
	if _finished:
		return

	_play_sprite_sheet()

func _start_world_fade() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", blur_alpha, world_fade_duration)
	tween.tween_property(veil_rect, "modulate:a", veil_alpha, world_fade_duration)
	return tween

func _play_sprite_sheet() -> void:
	if not sprite_sheet_player:
		_finish()
		return

	var finished_callable := Callable(self, "_on_sprite_sheet_finished")
	if sprite_sheet_player.has_signal("animation_finished") and not sprite_sheet_player.is_connected("animation_finished", finished_callable):
		sprite_sheet_player.connect("animation_finished", finished_callable)

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

	_waiting_for_continue = true
	_show_continue_prompt()

func _show_continue_prompt() -> void:
	prompt_label.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(prompt_label, "modulate:a", 1.0, prompt_fade_duration)

func _is_continue_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")

func _finish() -> void:
	if _finished:
		return

	if not get_tree():
		return

	_finished = true
	_waiting_for_continue = false
	if sprite_sheet_player:
		sprite_sheet_player.call("skip_to_last_frame")
	get_tree().paused = false
	completed.emit()
	queue_free()
