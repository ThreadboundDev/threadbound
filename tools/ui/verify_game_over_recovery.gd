extends Node

const OVERLAY_SCENE := preload("res://Src/UI/game_over_overlay.tscn")

var _failures := PackedStringArray()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cycle in 2:
		var overlay := OVERLAY_SCENE.instantiate() as GameOverOverlay
		overlay.respawn_input_delay = 0.01
		add_child(overlay)
		await get_tree().create_timer(0.25, true, false, true).timeout
		_expect(overlay.is_in_group(&"game_over_overlay"), "Death cycle %d registers the overlay for orphan recovery." % (cycle + 1))
		_expect(overlay._waiting_for_continue, "Death cycle %d arms respawn before the reveal completes." % (cycle + 1))
		_expect(overlay.prompt_label.visible, "Death cycle %d shows its respawn prompt." % (cycle + 1))
		_expect("RESPAWN" in overlay.prompt_label.text, "Game-over prompt explicitly identifies the respawn action.")
		overlay._finish()
		await get_tree().process_frame
		_expect(not get_tree().paused, "Death cycle %d releases the paused tree." % (cycle + 1))
	await get_tree().process_frame
	if _failures.is_empty():
		print("Game-over recovery verification passed.")
	get_tree().quit(_failures.size())

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Game-over recovery verification failed: %s" % message)
