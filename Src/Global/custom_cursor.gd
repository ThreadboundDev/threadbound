extends Node

const THREADBOUND_CURSOR_PATH := "res://Assets/UI/threadbound_cursor.png"
const CURSOR_HOTSPOT := Vector2(2.0, 2.0)

var _controller_is_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cursor_texture := load(THREADBOUND_CURSOR_PATH) as Texture2D
	if cursor_texture:
		Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

func _input(event: InputEvent) -> void:
	var was_controller_active := _controller_is_active
	if event is InputEventJoypadButton and event.pressed:
		_controller_is_active = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.25:
		_controller_is_active = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		_controller_is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if was_controller_active != _controller_is_active:
		get_tree().call_group("interaction_prompt_owners", "refresh_interaction_prompt")

func is_controller_active() -> bool:
	return _controller_is_active
