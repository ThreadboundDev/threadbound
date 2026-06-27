extends Node

const THREADBOUND_CURSOR_PATH := "res://Assets/UI/threadbound_cursor.png"
const CURSOR_HOTSPOT := Vector2(4.0, 4.0)


func _ready() -> void:
	var cursor_texture := load(THREADBOUND_CURSOR_PATH) as Texture2D
	if cursor_texture:
		Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
