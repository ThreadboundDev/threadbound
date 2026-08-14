extends Node

const TUTORIAL_CONTROLLER_SCRIPT := preload("res://Src/Environment/Tutorial/tutorial_controller.gd")

func _ready() -> void:
	var tutorial := TUTORIAL_CONTROLLER_SCRIPT.new()
	tutorial.tutorial_enabled = false
	tutorial.complete_prompt_seconds = 0.05
	add_child(tutorial)
	tutorial.tutorial_enabled = true
	tutorial.call("_set_step", tutorial.TutorialStep.COMPLETE)
	get_tree().paused = true

	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().paused = false
	if tutorial.get("_step") != tutorial.TutorialStep.DONE:
		push_error("TUTORIAL_COMPLETION_VERIFY: completion prompt did not dismiss.")
		get_tree().quit(1)
		return
	if tutorial.tutorial_enabled or not String(tutorial.get("_current_prompt_text")).is_empty():
		push_error("TUTORIAL_COMPLETION_VERIFY: completion prompt remained eligible to reappear after input changed.")
		get_tree().quit(1)
		return

	print("TUTORIAL_COMPLETION_VERIFY: PASS")
	get_tree().quit(0)
