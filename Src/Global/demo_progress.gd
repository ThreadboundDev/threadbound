extends Node

signal threads_changed
signal checkpoint_changed

const SAVE_PATH := "user://demo_save.cfg"

var _claimed_threads: Dictionary = {}
var _checkpoint_scene_path := ""
var _checkpoint_id: StringName = &""
var _checkpoint_position := Vector2.ZERO
var _tutorial_completed := false
var _tutorial_completion_recorded := false

func _ready() -> void:
	load_checkpoint()

func claim_thread(thread_id: StringName) -> void:
	if String(thread_id).is_empty():
		return
	if _claimed_threads.has(thread_id):
		return

	_claimed_threads[thread_id] = true
	_write_progress()
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
	_write_progress()
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
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("progress", "claimed_threads", _get_claimed_thread_strings())
	_tutorial_completion_recorded = true
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
	_tutorial_completion_recorded = config.has_section_key("progress", "tutorial_completed")
	_tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))
	_claimed_threads.clear()
	for thread_id in config.get_value("progress", "claimed_threads", PackedStringArray()):
		_claimed_threads[StringName(str(thread_id))] = true
	checkpoint_changed.emit()
	return has_checkpoint()

func clear_checkpoint() -> void:
	_checkpoint_id = &""
	_checkpoint_scene_path = ""
	_checkpoint_position = Vector2.ZERO
	_tutorial_completed = false
	_tutorial_completion_recorded = false
	_claimed_threads.clear()
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

func mark_tutorial_completed() -> void:
	if _tutorial_completed:
		return
	_tutorial_completed = true
	_tutorial_completion_recorded = true
	_write_progress()

func is_tutorial_completed() -> bool:
	return _tutorial_completed

func has_tutorial_completion_record() -> bool:
	return _tutorial_completion_recorded

func _write_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("checkpoint", "id", String(_checkpoint_id))
	config.set_value("checkpoint", "scene_path", _checkpoint_scene_path)
	config.set_value("checkpoint", "position_x", _checkpoint_position.x)
	config.set_value("checkpoint", "position_y", _checkpoint_position.y)
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("progress", "claimed_threads", _get_claimed_thread_strings())
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("DemoProgress could not save progress: %s." % error_string(error))

func _get_claimed_thread_strings() -> PackedStringArray:
	var claimed := PackedStringArray()
	for thread_id in _claimed_threads:
		claimed.append(String(thread_id))
	return claimed
