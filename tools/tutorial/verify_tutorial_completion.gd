extends Node

const TUTORIAL_CONTROLLER_SCRIPT := preload("res://Src/Environment/Tutorial/tutorial_controller.gd")

func _ready() -> void:
	var tutorial := TUTORIAL_CONTROLLER_SCRIPT.new()
	tutorial.tutorial_enabled = false
	tutorial.complete_prompt_seconds = 0.05
	add_child(tutorial)
	tutorial.tutorial_enabled = true
	tutorial.call("_set_step", tutorial.TutorialStep.COMPLETE)

	await get_tree().create_timer(0.1).timeout
	if tutorial.get("_step") != tutorial.TutorialStep.DONE:
		push_error("TUTORIAL_COMPLETION_VERIFY: completion prompt did not dismiss.")
		get_tree().quit(1)
		return

	print("TUTORIAL_COMPLETION_VERIFY: PASS")
	get_tree().quit(0)
