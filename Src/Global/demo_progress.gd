extends Node

signal threads_changed
signal checkpoint_changed
signal follower_dialogue_changed

const SAVE_PATH := "user://demo_save.cfg"
const TEMP_SAVE_PATH := "user://demo_save.tmp"
const BACKUP_SAVE_PATH := "user://demo_save.backup.cfg"
const SAVE_VERSION := 1

var _claimed_threads: Dictionary = {}
var _heard_follower_dialogue: Dictionary = {}
var _completed_world_events: Dictionary = {}
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

func mark_follower_dialogue_heard(dialogue_id: StringName) -> void:
	if String(dialogue_id).is_empty() or _heard_follower_dialogue.has(dialogue_id):
		return
	_heard_follower_dialogue[dialogue_id] = true
	_write_progress()
	follower_dialogue_changed.emit()

func complete_world_event(event_id: StringName) -> void:
	if String(event_id).is_empty():
		push_warning("DemoProgress cannot save an empty world event ID.")
		return
	if _completed_world_events.has(event_id):
		return
	_completed_world_events[event_id] = true
	_write_progress()

func has_completed_world_event(event_id: StringName) -> bool:
	return not String(event_id).is_empty() and _completed_world_events.has(event_id)

func has_heard_follower_dialogue(dialogue_id: StringName) -> bool:
	return _heard_follower_dialogue.has(dialogue_id)

func reset_demo_threads() -> void:
	_claimed_threads.clear()
	_heard_follower_dialogue.clear()
	_write_progress()
	threads_changed.emit()
	follower_dialogue_changed.emit()

func save_checkpoint(checkpoint_id: StringName, scene_path: String, player_position: Vector2) -> void:
	_checkpoint_id = checkpoint_id
	_checkpoint_scene_path = scene_path
	_checkpoint_position = player_position

	_tutorial_completion_recorded = true
	_write_progress()
	checkpoint_changed.emit()

func load_checkpoint() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		error = config.load(BACKUP_SAVE_PATH)
		if error != OK:
			return false
		push_warning("DemoProgress recovered the run from its backup save.")

	var save_version := int(config.get_value("meta", "save_version", 0))
	if save_version > SAVE_VERSION:
		push_warning("DemoProgress save version %d is newer than supported version %d." % [save_version, SAVE_VERSION])
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
	_heard_follower_dialogue.clear()
	for dialogue_id in config.get_value("progress", "follower_dialogue", PackedStringArray()):
		_heard_follower_dialogue[StringName(str(dialogue_id))] = true
	_completed_world_events.clear()
	for event_id in config.get_value("world", "completed_events", PackedStringArray()):
		_completed_world_events[StringName(str(event_id))] = true
	checkpoint_changed.emit()
	return has_checkpoint()

func clear_checkpoint() -> void:
	clear_run()

func clear_run() -> void:
	_checkpoint_id = &""
	_checkpoint_scene_path = ""
	_checkpoint_position = Vector2.ZERO
	_tutorial_completed = false
	_tutorial_completion_recorded = false
	_claimed_threads.clear()
	_heard_follower_dialogue.clear()
	_completed_world_events.clear()
	var dir := DirAccess.open("user://")
	if dir:
		for path in [SAVE_PATH, TEMP_SAVE_PATH, BACKUP_SAVE_PATH]:
			if dir.file_exists(path.get_file()):
				dir.remove(path.get_file())
	checkpoint_changed.emit()
	threads_changed.emit()
	follower_dialogue_changed.emit()

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
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("checkpoint", "id", String(_checkpoint_id))
	config.set_value("checkpoint", "scene_path", _checkpoint_scene_path)
	config.set_value("checkpoint", "position_x", _checkpoint_position.x)
	config.set_value("checkpoint", "position_y", _checkpoint_position.y)
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("progress", "claimed_threads", _get_claimed_thread_strings())
	config.set_value("progress", "follower_dialogue", _get_follower_dialogue_strings())
	config.set_value("world", "completed_events", _get_completed_world_event_strings())
	var error := config.save(TEMP_SAVE_PATH)
	if error != OK:
		push_warning("DemoProgress could not save progress: %s." % error_string(error))
		return
	error = _replace_save_with_temp()
	if error != OK:
		push_warning("DemoProgress could not replace the current save: %s." % error_string(error))

func _replace_save_with_temp() -> Error:
	var dir := DirAccess.open("user://")
	if not dir:
		return ERR_CANT_OPEN
	var save_file := SAVE_PATH.get_file()
	var temp_file := TEMP_SAVE_PATH.get_file()
	var backup_file := BACKUP_SAVE_PATH.get_file()
	if dir.file_exists(backup_file):
		var remove_error := dir.remove(backup_file)
		if remove_error != OK:
			return remove_error
	if dir.file_exists(save_file):
		var backup_error := dir.rename(save_file, backup_file)
		if backup_error != OK:
			return backup_error
	var replace_error := dir.rename(temp_file, save_file)
	if replace_error != OK and dir.file_exists(backup_file):
		dir.rename(backup_file, save_file)
	return replace_error

func _get_claimed_thread_strings() -> PackedStringArray:
	var claimed := PackedStringArray()
	for thread_id in _claimed_threads:
		claimed.append(String(thread_id))
	return claimed

func _get_follower_dialogue_strings() -> PackedStringArray:
	var heard := PackedStringArray()
	for dialogue_id in _heard_follower_dialogue:
		heard.append(String(dialogue_id))
	return heard

func _get_completed_world_event_strings() -> PackedStringArray:
	var completed := PackedStringArray()
	for event_id in _completed_world_events:
		completed.append(String(event_id))
	return completed
