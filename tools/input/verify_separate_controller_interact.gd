extends Node

func _ready() -> void:
	var jump_event := InputBindingManager.get_primary_controller_event(&"Jump")
	var interact_event := InputBindingManager.get_primary_controller_event(&"interact")
	var accept_event := InputBindingManager.get_primary_controller_event(&"ui_accept")

	assert(jump_event is InputEventJoypadButton, "Jump should remain a face button")
	assert(jump_event.button_index == JOY_BUTTON_A, "Jump should remain Cross/A")
	assert(accept_event is InputEventJoypadButton, "UI Confirm should remain a face button")
	assert(accept_event.button_index == JOY_BUTTON_A, "UI Confirm should share Cross/A with Jump")
	assert(interact_event is InputEventJoypadMotion, "Interact should use a trigger")
	assert(interact_event.axis == JOY_AXIS_TRIGGER_RIGHT, "Interact should use R2/Right Trigger")
	assert(interact_event.axis_value > 0.0, "Interact should use the pressed trigger direction")

	var jump_source := FileAccess.get_file_as_string("res://Src/Characters/Player/player.gd")
	var jump_guard_start := jump_source.find("func _can_process_jump_input")
	var jump_guard_end := jump_source.find("\nfunc ", jump_guard_start + 1)
	assert(jump_guard_start >= 0 and jump_guard_end > jump_guard_start, "Jump guard should be present")
	var jump_guard := jump_source.substr(jump_guard_start, jump_guard_end - jump_guard_start)
	assert(
		not jump_guard.contains("is_near_interactable"),
		"Nearby interactables must not disable jumping"
	)

	print("Separate controller Interact verification passed.")
	get_tree().quit(0)
