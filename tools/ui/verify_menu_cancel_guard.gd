extends Node

const GUARD_META := &"pause_open_block_until_msec"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var failures: Array[String] = []
	var player_scene := load("res://Src/Characters/Player/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	add_child(player)
	get_tree().set_meta(GUARD_META, Time.get_ticks_msec() + 180)
	if not bool(player.call("_is_menu_close_input_guard_active")):
		failures.append("Player does not block gameplay actions immediately after a menu closes.")
	get_tree().remove_meta(GUARD_META)
	var pause_scene := load("res://Src/UI/PauseMenu/pause_menu.tscn") as PackedScene
	var pause_menu := pause_scene.instantiate()
	add_child(pause_menu)
	pause_menu.call("_resume_game")
	if not get_tree().has_meta(GUARD_META):
		failures.append("Pause menu does not arm the post-close gameplay input guard.")
	if failures.is_empty():
		print("Menu cancel gameplay guard verification passed.")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)
