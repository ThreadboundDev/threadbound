extends Node

signal threads_changed
signal checkpoint_changed
signal follower_dialogue_changed
signal demo_completion_changed(completed: bool)
signal lore_changed
signal lore_unlocked(lore_id: StringName)

const SAVE_PATH := "user://demo_save.cfg"
const TEMP_SAVE_PATH := "user://demo_save.tmp"
const BACKUP_SAVE_PATH := "user://demo_save.backup.cfg"
const SAVE_VERSION := 3

var _claimed_threads: Dictionary = {}
var _heard_follower_dialogue: Dictionary = {}
var _completed_world_events: Dictionary = {}
var _unlocked_lore: Dictionary = {&"threadbound": true}
var _read_lore: Dictionary = {}
var _checkpoint_scene_path := ""
var _checkpoint_id: StringName = &""
var _checkpoint_position := Vector2.ZERO
var _tutorial_completed := false
var _tutorial_completion_recorded := false
var _demo_completed := false
var _playtest_welcome_acknowledged := false
var _held_thread_knots := 0
var _recovery_thread_knots := 0
var _recovery_scene_path := ""
var _recovery_position := Vector2.ZERO

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

func unlock_lore(lore_id: StringName, notify := true) -> bool:
	if String(lore_id).is_empty() or _unlocked_lore.has(lore_id):
		return false
	_unlocked_lore[lore_id] = true
	_write_progress()
	lore_changed.emit()
	if notify:
		lore_unlocked.emit(lore_id)
	return true

func has_lore(lore_id: StringName) -> bool:
	return _unlocked_lore.has(lore_id)

func mark_lore_read(lore_id: StringName) -> void:
	if not has_lore(lore_id) or _read_lore.has(lore_id):
		return
	_read_lore[lore_id] = true
	_write_progress()
	lore_changed.emit()

func is_lore_read(lore_id: StringName) -> bool:
	return _read_lore.has(lore_id)

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
	_demo_completed = bool(config.get_value("progress", "demo_completed", false))
	_playtest_welcome_acknowledged = bool(config.get_value("progress", "playtest_welcome_acknowledged", false))
	_held_thread_knots = maxi(0, int(config.get_value("currency", "held_thread_knots", 0)))
	_recovery_thread_knots = maxi(0, int(config.get_value("currency", "recovery_thread_knots", 0)))
	_recovery_scene_path = str(config.get_value("currency", "recovery_scene_path", ""))
	_recovery_position = Vector2(
		float(config.get_value("currency", "recovery_position_x", 0.0)),
		float(config.get_value("currency", "recovery_position_y", 0.0))
	)
	if _recovery_thread_knots <= 0:
		_clear_recovery_thread_knots_in_memory()
	_claimed_threads.clear()
	for thread_id in config.get_value("progress", "claimed_threads", PackedStringArray()):
		_claimed_threads[StringName(str(thread_id))] = true
	_heard_follower_dialogue.clear()
	for dialogue_id in config.get_value("progress", "follower_dialogue", PackedStringArray()):
		_heard_follower_dialogue[StringName(str(dialogue_id))] = true
	_completed_world_events.clear()
	for event_id in config.get_value("world", "completed_events", PackedStringArray()):
		_completed_world_events[StringName(str(event_id))] = true
	_unlocked_lore.clear()
	for lore_id in config.get_value("lore", "unlocked", PackedStringArray(["threadbound"])):
		_unlocked_lore[StringName(str(lore_id))] = true
	_unlocked_lore[&"threadbound"] = true
	_read_lore.clear()
	for lore_id in config.get_value("lore", "read", PackedStringArray()):
		_read_lore[StringName(str(lore_id))] = true
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
	_demo_completed = false
	_playtest_welcome_acknowledged = false
	_held_thread_knots = 0
	_clear_recovery_thread_knots_in_memory()
	_claimed_threads.clear()
	_heard_follower_dialogue.clear()
	_completed_world_events.clear()
	_unlocked_lore = {&"threadbound": true}
	_read_lore.clear()
	var dir := DirAccess.open("user://")
	if dir:
		for path in [SAVE_PATH, TEMP_SAVE_PATH, BACKUP_SAVE_PATH]:
			if dir.file_exists(path.get_file()):
				dir.remove(path.get_file())
	checkpoint_changed.emit()
	threads_changed.emit()
	follower_dialogue_changed.emit()
	lore_changed.emit()
	demo_completion_changed.emit(false)

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

func mark_demo_completed() -> void:
	if _demo_completed:
		return
	_demo_completed = true
	_write_progress()
	demo_completion_changed.emit(true)

func is_demo_completed() -> bool:
	return _demo_completed

func acknowledge_playtest_welcome() -> void:
	if _playtest_welcome_acknowledged:
		return
	_playtest_welcome_acknowledged = true
	_write_progress()

func has_acknowledged_playtest_welcome() -> bool:
	return _playtest_welcome_acknowledged

func set_held_thread_knots(amount: int) -> void:
	var normalized_amount := maxi(0, amount)
	if _held_thread_knots == normalized_amount:
		return
	_held_thread_knots = normalized_amount
	_write_progress()

func get_held_thread_knots() -> int:
	return _held_thread_knots

func drop_thread_knots(amount: int, scene_path: String, drop_position: Vector2) -> void:
	_held_thread_knots = 0
	_recovery_thread_knots = maxi(0, amount)
	if _recovery_thread_knots > 0 and not scene_path.is_empty():
		_recovery_scene_path = scene_path
		_recovery_position = drop_position
	else:
		_clear_recovery_thread_knots_in_memory()
	_write_progress()

func has_recovery_thread_knots(scene_path: String = "") -> bool:
	if _recovery_thread_knots <= 0 or _recovery_scene_path.is_empty():
		return false
	return scene_path.is_empty() or scene_path == _recovery_scene_path

func get_recovery_thread_knots() -> int:
	return _recovery_thread_knots

func get_recovery_scene_path() -> String:
	return _recovery_scene_path

func get_recovery_position() -> Vector2:
	return _recovery_position

func claim_recovery_thread_knots() -> int:
	if _recovery_thread_knots <= 0:
		return 0
	var recovered_amount := _recovery_thread_knots
	_held_thread_knots += recovered_amount
	_clear_recovery_thread_knots_in_memory()
	_write_progress()
	return recovered_amount

func _clear_recovery_thread_knots_in_memory() -> void:
	_recovery_thread_knots = 0
	_recovery_scene_path = ""
	_recovery_position = Vector2.ZERO

func _write_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("checkpoint", "id", String(_checkpoint_id))
	config.set_value("checkpoint", "scene_path", _checkpoint_scene_path)
	config.set_value("checkpoint", "position_x", _checkpoint_position.x)
	config.set_value("checkpoint", "position_y", _checkpoint_position.y)
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("progress", "demo_completed", _demo_completed)
	config.set_value("progress", "playtest_welcome_acknowledged", _playtest_welcome_acknowledged)
	config.set_value("progress", "claimed_threads", _get_claimed_thread_strings())
	config.set_value("currency", "held_thread_knots", _held_thread_knots)
	config.set_value("currency", "recovery_thread_knots", _recovery_thread_knots)
	config.set_value("currency", "recovery_scene_path", _recovery_scene_path)
	config.set_value("currency", "recovery_position_x", _recovery_position.x)
	config.set_value("currency", "recovery_position_y", _recovery_position.y)
	config.set_value("progress", "follower_dialogue", _get_follower_dialogue_strings())
	config.set_value("world", "completed_events", _get_completed_world_event_strings())
	config.set_value("lore", "unlocked", _get_lore_strings(_unlocked_lore))
	config.set_value("lore", "read", _get_lore_strings(_read_lore))
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

func _get_lore_strings(source: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for lore_id in source:
		result.append(String(lore_id))
	return result
