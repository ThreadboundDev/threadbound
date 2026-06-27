extends Node

signal threads_changed
signal checkpoint_changed

const SAVE_PATH := "user://demo_save.cfg"

var _claimed_threads: Dictionary = {}
var _checkpoint_scene_path := ""
var _checkpoint_id: StringName = &""
var _checkpoint_position := Vector2.ZERO

func _ready() -> void:
	load_checkpoint()

func claim_thread(thread_id: StringName) -> void:
	if String(thread_id).is_empty():
		return
	if _claimed_threads.has(thread_id):
		return

	_claimed_threads[thread_id] = true
	threads_changed.emit()

func has_thread(thread_id: StringName) -> bool:
	return _claimed_threads.has(thread_id)

func remaining_threads(required_threads: Array[StringName]) -> Array[StringName]:
	var remaining: Array[StringName] = []
	for thread_id in required_threads:
		if not has_thread(thread_id):
			remaining.append(thread_id)
	return remaining

func claimed_count(required_threads: Array[StringName]) -> int:
	return required_threads.size() - remaining_threads(required_threads).size()

func reset_demo_threads() -> void:
	_claimed_threads.clear()
	threads_changed.emit()

func save_checkpoint(checkpoint_id: StringName, scene_path: String, player_position: Vector2) -> void:
	_checkpoint_id = checkpoint_id
	_checkpoint_scene_path = scene_path
	_checkpoint_position = player_position

	var config := ConfigFile.new()
	config.set_value("checkpoint", "id", String(checkpoint_id))
	config.set_value("checkpoint", "scene_path", scene_path)
	config.set_value("checkpoint", "position_x", player_position.x)
	config.set_value("checkpoint", "position_y", player_position.y)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("DemoProgress could not save checkpoint: %s." % error_string(error))
	checkpoint_changed.emit()

func load_checkpoint() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return false

	_checkpoint_id = StringName(str(config.get_value("checkpoint", "id", "")))
	_checkpoint_scene_path = str(config.get_value("checkpoint", "scene_path", ""))
	_checkpoint_position = Vector2(
		float(config.get_value("checkpoint", "position_x", 0.0)),
		float(config.get_value("checkpoint", "position_y", 0.0))
	)
	checkpoint_changed.emit()
	return has_checkpoint()

func clear_checkpoint() -> void:
	_checkpoint_id = &""
	_checkpoint_scene_path = ""
	_checkpoint_position = Vector2.ZERO
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	checkpoint_changed.emit()

func has_checkpoint() -> bool:
	return not _checkpoint_scene_path.is_empty()

func get_checkpoint_scene_path() -> String:
	return _checkpoint_scene_path

func get_checkpoint_position() -> Vector2:
	return _checkpoint_position

func get_checkpoint_id() -> StringName:
	return _checkpoint_id
