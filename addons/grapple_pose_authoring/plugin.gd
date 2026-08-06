@tool
extends EditorPlugin

const DOCK_SCENE := preload("res://addons/grapple_pose_authoring/grapple_pose_dock.tscn")
const PLAYER_SCENE_PATH := "res://Src/Characters/Player/player.tscn"
const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")
const RED_GLOVES_SCENE := preload("res://Src/Equipment/red_gloves.tscn")
const BLUE_GLOVES_SCENE := preload("res://Src/Equipment/blue_gloves.tscn")
const YELLOW_GLOVES_SCENE := preload("res://Src/Equipment/yellow_gloves.tscn")
const PREVIEW_SCENES: Array[PackedScene] = [
	BASE_GLOVES_SCENE,
	RED_GLOVES_SCENE,
	BLUE_GLOVES_SCENE,
	YELLOW_GLOVES_SCENE,
]
const PREVIEW_LABELS: Array[String] = ["Base", "Red", "Blue", "Yellow"]
const BASE_LIBRARY := preload("res://Src/Equipment/base_grapple_animation_library.tres")

const HAND_POSITION_PATH := NodePath("Equipment/RightHandAnchor:position")
const WRIST_ROTATION_PATH := NodePath("Equipment/RightHandAnchor/WristWrapPivot:rotation")
const WRIST_SCALE_PATH := NodePath("Equipment/RightHandAnchor/WristWrapPivot:scale")
const PREVIEW_NODE_NAME := &"__GrapplePosePreview"
const PREVIOUS_ONION_NAME := &"__GrapplePosePreviousOnion"
const NEXT_ONION_NAME := &"__GrapplePoseNextOnion"
const IDLE_CONTROL_FRAMES: Array[int] = [0, 5, 11, 20, 32]
const PREVIOUS_ONION_COLOR := Color(0.35, 0.65, 1.0, 0.28)
const NEXT_ONION_COLOR := Color(1.0, 0.45, 0.3, 0.28)

var dock: Control
var dock_button: Button
var preview_gloves: Node2D
var previous_onion: Node2D
var next_onion: Node2D
var player_sprite: AnimatedSprite2D
var pose_player: AnimationPlayer
var hand_anchor: Node2D
var wrist_pivot: Node2D
var current_variant := 0
var current_animation := &"Idle"
var current_frame := 0
var playback_accumulator := 0.0
var playing := false
var shortcuts_enabled := true
var onion_skin_enabled := true
var saved_pose: Array = []
var pending_pose: Array = []
var has_pending_changes := false
var applying_frame := false
var default_hand_rotation := 0.0
var default_hand_scale := Vector2.ONE
var default_wrist_position := Vector2.ZERO
var last_control_frame := -1
var last_control_values: Array = []
var interpolation_frames: Array[int] = []
var interpolation_start_frame := -1
var interpolation_start_values: Array = []


func _enter_tree() -> void:
	dock = DOCK_SCENE.instantiate()
	dock.call("setup", self)
	dock_button = add_control_to_bottom_panel(dock, "Grapple Poses")
	dock_button.toggled.connect(_on_dock_toggled)
	scene_changed.connect(_on_scene_changed)
	EditorInterface.get_inspector().property_edited.connect(_on_inspector_property_edited)
	set_process(true)


func _exit_tree() -> void:
	playing = false
	_remove_preview()
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if EditorInterface.get_inspector().property_edited.is_connected(_on_inspector_property_edited):
		EditorInterface.get_inspector().property_edited.disconnect(_on_inspector_property_edited)
	if is_instance_valid(dock_button) and dock_button.toggled.is_connected(_on_dock_toggled):
		dock_button.toggled.disconnect(_on_dock_toggled)
	if is_instance_valid(dock):
		remove_control_from_bottom_panel(dock)
		dock.queue_free()


func _process(delta: float) -> void:
	if not _preview_is_ready():
		return
	if not playing:
		_cache_live_pose()
		return
	var fps := get_current_fps()
	if fps <= 0.0:
		return
	playback_accumulator += delta
	var frame_duration := 1.0 / fps
	while playback_accumulator >= frame_duration:
		playback_accumulator -= frame_duration
		var next_frame := current_frame + 1
		var frame_count := get_current_frame_count()
		if next_frame >= frame_count:
			if player_sprite.sprite_frames.get_animation_loop(current_animation):
				next_frame = 0
			else:
				set_playing(false)
				next_frame = maxi(0, frame_count - 1)
		set_frame(next_frame)
		if not playing:
			break


func _input(event: InputEvent) -> void:
	if (
		not shortcuts_enabled
		or not dock
		or not dock.is_visible_in_tree()
		or not _preview_is_ready()
		or not event is InputEventMouseButton
	):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_XBUTTON1:
		capture_pose_and_advance()
		get_viewport().set_input_as_handled()


func _shortcut_input(event: InputEvent) -> void:
	if (
		not event is InputEventKey
		or not shortcuts_enabled
		or not dock
		or not dock.is_visible_in_tree()
		or not _preview_is_ready()
	):
		return
	var key_event := event as InputEventKey
	if (
		not key_event.pressed
		or key_event.echo
		or key_event.ctrl_pressed
		or key_event.alt_pressed
		or key_event.shift_pressed
		or key_event.meta_pressed
	):
		return
	var focused_control := dock.get_viewport().gui_get_focus_owner()
	if focused_control is LineEdit or focused_control is TextEdit:
		return
	var pressed_key := (
		key_event.physical_keycode
		if key_event.physical_keycode != KEY_NONE
		else key_event.keycode
	)
	match pressed_key:
		KEY_W:
			select_hand()
		KEY_E, KEY_R:
			select_wrist()


func set_shortcuts_enabled(enabled: bool) -> void:
	shortcuts_enabled = enabled
	if not enabled:
		set_playing(false)
	_set_status(
		"Authoring shortcuts enabled (W/E/R and Mouse 4)."
		if enabled
		else "Authoring shortcuts disabled.",
		false
	)


func _on_dock_toggled(open: bool) -> void:
	if open:
		open_authoring_view()
	else:
		set_playing(false)


func _on_scene_changed(scene_root: Node) -> void:
	_remove_preview()
	if scene_root and scene_root.scene_file_path == PLAYER_SCENE_PATH and dock_button.button_pressed:
		call_deferred("_build_preview")


func open_authoring_view() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != PLAYER_SCENE_PATH:
		EditorInterface.open_scene_from_path(PLAYER_SCENE_PATH)
		return
	_build_preview()


func refresh_preview() -> void:
	_build_preview()


func set_variant(variant_index: int) -> void:
	current_variant = clampi(variant_index, 0, PREVIEW_SCENES.size() - 1)
	_build_preview()


func get_animation_names() -> PackedStringArray:
	if not is_instance_valid(player_sprite) or player_sprite.sprite_frames == null:
		return PackedStringArray()
	var library := _get_library()
	var names := PackedStringArray()
	for animation_name in player_sprite.sprite_frames.get_animation_names():
		if library.has_animation(animation_name):
			names.append(animation_name)
	return names


func set_animation(animation_name: StringName) -> void:
	if not _preview_is_ready() or not _get_library().has_animation(animation_name):
		return
	current_animation = animation_name
	_clear_interpolation_state()
	current_frame = 0
	playback_accumulator = 0.0
	dock.call("set_animation_data", get_animation_names(), current_animation, get_current_frame_count())
	_apply_frame()


func set_frame(frame: int) -> void:
	var frame_count := get_current_frame_count()
	if frame_count <= 0:
		return
	current_frame = clampi(frame, 0, frame_count - 1)
	_apply_frame()
	dock.call("set_frame_display", current_frame, frame_count, get_current_fps())


func step_frame(direction: int) -> void:
	set_playing(false)
	var frame_count := get_current_frame_count()
	if frame_count > 0:
		set_frame(posmod(current_frame + direction, frame_count))


func set_onion_skin_enabled(enabled: bool) -> void:
	onion_skin_enabled = enabled
	_update_onion_skins()


func set_playing(enabled: bool) -> void:
	playing = enabled and _preview_is_ready()
	playback_accumulator = 0.0
	dock.call("set_playing_display", playing)


func select_hand() -> void:
	_select_preview_node(hand_anchor)


func select_wrist() -> void:
	_select_preview_node(wrist_pivot)


func capture_pose() -> bool:
	if not _preview_is_ready():
		_set_status("Open the Player authoring view first.", true)
		return false
	var library := _get_library()
	var animation := library.get_animation(current_animation)
	if animation == null:
		_set_status("The selected pose animation is missing.", true)
		return false
	_cache_live_pose()
	var new_values := (
		pending_pose.duplicate(true)
		if pending_pose.size() == 3
		else _read_live_pose()
	)
	var old_values := _get_frame_values(animation, current_animation, current_frame)
	if old_values.is_empty():
		_set_status("The current frame is missing one or more pose keys.", true)
		return false

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Capture %s grapple pose frame %d" % [current_animation, current_frame])
	undo_redo.add_do_method(self, "_write_frame_values", library, current_animation, current_frame, new_values)
	undo_redo.add_undo_method(self, "_write_frame_values", library, current_animation, current_frame, old_values)
	undo_redo.commit_action()
	_resolve_interpolation_span(current_frame, new_values)
	last_control_frame = current_frame
	last_control_values = new_values.duplicate(true)
	_set_status("Captured %s frame %d." % [current_animation, current_frame], false)
	return true


func capture_pose_and_advance() -> void:
	_cache_live_pose()
	if not has_pending_changes:
		_mark_frame_for_interpolation_and_advance(false)
		return
	if not capture_pose():
		return
	var captured_frame := current_frame
	set_frame(_get_next_capture_frame())
	_set_status(
		"Captured frame %d and advanced to frame %d." % [captured_frame, current_frame],
		false
	)


func reset_frame_to_interpolate() -> void:
	if not _preview_is_ready():
		_set_status("Open the Player authoring view first.", true)
		return
	_mark_frame_for_interpolation_and_advance(true)


func _mark_frame_for_interpolation_and_advance(force_current_frame: bool) -> void:
	var next_frame := _get_next_capture_frame()
	if interpolation_start_frame < 0:
		if last_control_frame >= 0 and last_control_values.size() == 3:
			interpolation_start_frame = last_control_frame
			interpolation_start_values = last_control_values.duplicate(true)
		elif current_frame > 0 or force_current_frame:
			interpolation_start_frame = maxi(0, current_frame - 1)
			interpolation_start_values = _get_frame_values(
				_get_library().get_animation(current_animation),
				current_animation,
				interpolation_start_frame
			)
		else:
			interpolation_start_frame = current_frame
			interpolation_start_values = saved_pose.duplicate(true)
			last_control_frame = current_frame
			last_control_values = saved_pose.duplicate(true)

	if force_current_frame or current_frame != interpolation_start_frame:
		_add_interpolation_frame(current_frame)
	# When Idle jumps between sparse control frames, include the frames between.
	if next_frame > current_frame:
		for skipped_frame in range(current_frame + 1, next_frame):
			_add_interpolation_frame(skipped_frame)
	var marked_frame := current_frame
	set_frame(next_frame)
	_set_status(
		"Frame %d marked for interpolation. Move and capture a later frame to complete the span."
		% marked_frame,
		false
	)


func _add_interpolation_frame(frame: int) -> void:
	if frame != interpolation_start_frame and frame not in interpolation_frames:
		interpolation_frames.append(frame)


func _resolve_interpolation_span(end_frame: int, end_values: Array) -> void:
	if (
		interpolation_start_frame < 0
		or interpolation_start_values.size() != 3
		or interpolation_frames.is_empty()
	):
		return
	var animation := _get_library().get_animation(current_animation)
	var old_values: Array = []
	for frame: int in interpolation_frames:
		old_values.append(_get_frame_values(animation, current_animation, frame))
	var undo_redo := get_undo_redo()
	undo_redo.create_action(
		"Interpolate %s grapple poses %d-%d"
		% [current_animation, interpolation_start_frame, end_frame]
	)
	undo_redo.add_do_method(
		self,
		"_write_interpolated_frames",
		_get_library(),
		current_animation,
		interpolation_start_frame,
		interpolation_start_values.duplicate(true),
		end_frame,
		end_values.duplicate(true),
		interpolation_frames.duplicate()
	)
	undo_redo.add_undo_method(
		self,
		"_restore_frame_values",
		_get_library(),
		current_animation,
		interpolation_frames.duplicate(),
		old_values
	)
	undo_redo.commit_action()
	_clear_pending_interpolation()


func _write_interpolated_frames(
	library: AnimationLibrary,
	animation_name: StringName,
	start_frame: int,
	start_values: Array,
	end_frame: int,
	end_values: Array,
	frames: Array[int]
) -> void:
	var frame_count := get_current_frame_count()
	var span := (end_frame - start_frame + frame_count) % frame_count
	if span <= 0:
		return
	for frame: int in frames:
		var offset := (frame - start_frame + frame_count) % frame_count
		if offset <= 0 or offset >= span:
			continue
		var weight := float(offset) / float(span)
		var values := [
			(start_values[0] as Vector2).lerp(end_values[0] as Vector2, weight),
			lerp_angle(float(start_values[1]), float(end_values[1]), weight),
			(start_values[2] as Vector2).lerp(end_values[2] as Vector2, weight),
		]
		_write_frame_values_without_save(library, animation_name, frame, values)
	ResourceSaver.save(library, library.resource_path)
	_apply_frame()


func _restore_frame_values(
	library: AnimationLibrary,
	animation_name: StringName,
	frames: Array[int],
	values: Array
) -> void:
	for index in frames.size():
		if values[index].size() == 3:
			_write_frame_values_without_save(library, animation_name, frames[index], values[index])
	ResourceSaver.save(library, library.resource_path)
	_apply_frame()


func _clear_pending_interpolation() -> void:
	interpolation_frames.clear()
	interpolation_start_frame = -1
	interpolation_start_values.clear()


func _clear_interpolation_state() -> void:
	_clear_pending_interpolation()
	last_control_frame = -1
	last_control_values.clear()


func _get_next_capture_frame() -> int:
	if current_animation != &"Idle":
		return current_frame + 1
	for control_frame: int in IDLE_CONTROL_FRAMES:
		if control_frame > current_frame:
			return control_frame
	return IDLE_CONTROL_FRAMES[0]


func revert_frame() -> void:
	set_playing(false)
	_apply_frame()
	_set_status("Restored the saved values for frame %d." % current_frame, false)


func get_current_frame_count() -> int:
	if not is_instance_valid(player_sprite) or player_sprite.sprite_frames == null:
		return 0
	if not player_sprite.sprite_frames.has_animation(current_animation):
		return 0
	return player_sprite.sprite_frames.get_frame_count(current_animation)


func get_current_fps() -> float:
	if not is_instance_valid(player_sprite) or player_sprite.sprite_frames == null:
		return 0.0
	if not player_sprite.sprite_frames.has_animation(current_animation):
		return 0.0
	return player_sprite.sprite_frames.get_animation_speed(current_animation)


func _build_preview() -> void:
	set_playing(false)
	_clear_interpolation_state()
	_remove_preview()
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != PLAYER_SCENE_PATH:
		_set_status("Open the Player scene to start authoring.", true)
		return
	player_sprite = root.get_node_or_null("Player Animation") as AnimatedSprite2D
	if player_sprite == null:
		_set_status("Player Animation could not be found.", true)
		return

	var preview_scene := PREVIEW_SCENES[current_variant]
	preview_gloves = preview_scene.instantiate() as Node2D
	preview_gloves.name = PREVIEW_NODE_NAME
	preview_gloves.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(preview_gloves)
	root.set_editable_instance(preview_gloves, true)
	EditorInterface.set_main_screen_editor("2D")
	pose_player = preview_gloves.get_node("Equipment/AnimationPlayer") as AnimationPlayer
	hand_anchor = preview_gloves.get_node("Equipment/RightHandAnchor") as Node2D
	wrist_pivot = preview_gloves.get_node("Equipment/RightHandAnchor/WristWrapPivot") as Node2D
	default_hand_rotation = hand_anchor.rotation
	default_hand_scale = hand_anchor.scale
	default_wrist_position = wrist_pivot.position
	_create_onion_skins(root)

	var names := get_animation_names()
	if names.is_empty():
		_set_status("No matching player and grapple animations were found.", true)
		return
	if not current_animation in names:
		current_animation = names[0]
	var repaired_tracks := _repair_library_key_timing()
	current_frame = clampi(current_frame, 0, maxi(0, get_current_frame_count() - 1))
	dock.call("set_animation_data", names, current_animation, get_current_frame_count())
	_apply_frame()
	if repaired_tracks > 0:
		_set_status("Repaired %d pose tracks and restored exact frame timing." % repaired_tracks, false)
	else:
		_set_status(
			"Shared pose library ready (%s preview)." % PREVIEW_LABELS[current_variant],
			false
		)


func _remove_preview() -> void:
	_remove_onion_skins()
	if is_instance_valid(preview_gloves):
		preview_gloves.free()
	_remove_preview_reference()


func _remove_preview_reference() -> void:
	preview_gloves = null
	player_sprite = null
	pose_player = null
	hand_anchor = null
	wrist_pivot = null
	saved_pose.clear()
	pending_pose.clear()
	has_pending_changes = false


func _preview_is_ready() -> bool:
	return (
		is_instance_valid(player_sprite)
		and is_instance_valid(pose_player)
		and is_instance_valid(hand_anchor)
		and is_instance_valid(wrist_pivot)
	)


func _get_library() -> AnimationLibrary:
	return BASE_LIBRARY


func _apply_frame() -> void:
	if not _preview_is_ready():
		return
	var frame_count := get_current_frame_count()
	if frame_count <= 0:
		return
	current_frame = clampi(current_frame, 0, frame_count - 1)
	applying_frame = true
	player_sprite.animation = current_animation
	player_sprite.pause()
	player_sprite.set_frame_and_progress(current_frame, 0.0)
	# Do not activate AnimationPlayer while authoring. Godot's editor keying can
	# otherwise insert off-grid keys when a tracked node is moved in the viewport.
	pose_player.stop()
	# These properties are structural scene values, not animation tracks.
	hand_anchor.rotation = default_hand_rotation
	hand_anchor.scale = default_hand_scale
	wrist_pivot.position = default_wrist_position
	var animation := _get_library().get_animation(current_animation)
	var frame_values := _get_frame_values(animation, current_animation, current_frame)
	if frame_values.size() == 3:
		hand_anchor.position = frame_values[0]
		wrist_pivot.rotation = frame_values[1]
		wrist_pivot.scale = frame_values[2]
	saved_pose = _read_live_pose()
	pending_pose = saved_pose.duplicate(true)
	has_pending_changes = false
	applying_frame = false
	dock.call("set_frame_display", current_frame, frame_count, get_current_fps())
	_update_onion_skins()


func _create_onion_skins(root: Node) -> void:
	_remove_onion_skins()
	previous_onion = _create_onion_ghost(PREVIOUS_ONION_NAME, PREVIOUS_ONION_COLOR)
	next_onion = _create_onion_ghost(NEXT_ONION_NAME, NEXT_ONION_COLOR)
	root.add_child(previous_onion)
	root.add_child(next_onion)


func _create_onion_ghost(ghost_name: StringName, tint: Color) -> Node2D:
	var ghost := Node2D.new()
	ghost.name = ghost_name
	ghost.process_mode = Node.PROCESS_MODE_DISABLED
	ghost.z_index = -1
	var player_ghost := player_sprite.duplicate() as AnimatedSprite2D
	player_ghost.name = "Player Animation"
	player_ghost.modulate = tint
	ghost.add_child(player_ghost)
	var equipment_ghost := preview_gloves.get_node("Equipment").duplicate() as Node2D
	equipment_ghost.name = "Equipment"
	equipment_ghost.modulate = tint
	ghost.add_child(equipment_ghost)
	return ghost


func _remove_onion_skins() -> void:
	if is_instance_valid(previous_onion):
		previous_onion.free()
	if is_instance_valid(next_onion):
		next_onion.free()
	previous_onion = null
	next_onion = null


func _update_onion_skins() -> void:
	if not is_instance_valid(previous_onion) or not is_instance_valid(next_onion):
		return
	previous_onion.visible = onion_skin_enabled
	next_onion.visible = onion_skin_enabled
	if not onion_skin_enabled:
		return
	var frame_count := get_current_frame_count()
	if frame_count <= 0:
		return
	_apply_onion_frame(previous_onion, posmod(current_frame - 1, frame_count))
	_apply_onion_frame(next_onion, posmod(current_frame + 1, frame_count))


func _apply_onion_frame(ghost: Node2D, frame: int) -> void:
	var ghost_player := ghost.get_node("Player Animation") as AnimatedSprite2D
	ghost_player.animation = current_animation
	ghost_player.pause()
	ghost_player.set_frame_and_progress(frame, 0.0)
	var animation := _get_library().get_animation(current_animation)
	var values := _get_frame_values(animation, current_animation, frame)
	if values.size() != 3:
		return
	var ghost_hand := ghost.get_node("Equipment/RightHandAnchor") as Node2D
	var ghost_wrist := ghost.get_node(
		"Equipment/RightHandAnchor/WristWrapPivot"
	) as Node2D
	ghost_hand.position = values[0]
	ghost_hand.rotation = default_hand_rotation
	ghost_hand.scale = default_hand_scale
	ghost_wrist.position = default_wrist_position
	ghost_wrist.rotation = values[1]
	ghost_wrist.scale = values[2]


func _read_live_pose() -> Array:
	if not _preview_is_ready():
		return []
	return [hand_anchor.position, wrist_pivot.rotation, wrist_pivot.scale]


func _cache_live_pose() -> void:
	if applying_frame or not _preview_is_ready() or saved_pose.size() != 3:
		return
	var live_pose := _read_live_pose()
	if pending_pose.size() != 3:
		pending_pose = saved_pose.duplicate(true)
	var changed := false
	for value_index in 3:
		if _pose_value_is_equal(live_pose[value_index], saved_pose[value_index]):
			continue
		pending_pose[value_index] = live_pose[value_index]
		changed = true
	if changed:
		has_pending_changes = true
		_set_status("Viewport pose changed—Capture Pose to save frame %d." % current_frame, false)


func _pose_value_is_equal(first: Variant, second: Variant) -> bool:
	if first is Vector2 and second is Vector2:
		return (first as Vector2).is_equal_approx(second as Vector2)
	if first is float and second is float:
		return is_equal_approx(float(first), float(second))
	return first == second


func _on_inspector_property_edited(property: StringName) -> void:
	var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
	var selected_node: Node = selected_nodes[0] if not selected_nodes.is_empty() else null
	if selected_node == hand_anchor and property in [&"rotation", &"scale"]:
		_set_status("Hand only keys position. Use Select Wrist for rotation or scale.", true)
		return
	if selected_node == wrist_pivot and property == &"position":
		_set_status("Wrist position is not keyed. Use Select Hand to move the grapple and rope origin.", true)
		return
	if property in [&"position", &"rotation", &"scale"]:
		_cache_live_pose()


func _get_frame_values(
	animation: Animation,
	animation_name: StringName,
	frame: int
) -> Array:
	var values: Array = []
	var fps := _get_animation_fps(animation_name)
	var key_time := float(frame) / maxf(fps, 0.001)
	for path in [HAND_POSITION_PATH, WRIST_ROTATION_PATH, WRIST_SCALE_PATH]:
		var track := animation.find_track(path, Animation.TYPE_VALUE)
		if track < 0:
			return []
		var key_index := animation.track_find_key(track, key_time, Animation.FIND_MODE_APPROX)
		if key_index < 0:
			values.append(animation.value_track_interpolate(track, key_time))
		else:
			values.append(animation.track_get_key_value(track, key_index))
	return values


func _write_frame_values(
	library: AnimationLibrary,
	animation_name: StringName,
	frame: int,
	values: Array
) -> void:
	_write_frame_values_without_save(library, animation_name, frame, values)
	ResourceSaver.save(library, library.resource_path)
	if animation_name == current_animation and frame == current_frame:
		_apply_frame()


func _write_frame_values_without_save(
	library: AnimationLibrary,
	animation_name: StringName,
	frame: int,
	values: Array
) -> void:
	var animation := library.get_animation(animation_name)
	if animation == null or values.size() != 3:
		return
	var key_time := float(frame) / maxf(_get_animation_fps(animation_name), 0.001)
	var paths := [HAND_POSITION_PATH, WRIST_ROTATION_PATH, WRIST_SCALE_PATH]
	for track_index in paths.size():
		var track := animation.find_track(paths[track_index], Animation.TYPE_VALUE)
		if track < 0:
			continue
		var key_index := animation.track_find_key(track, key_time, Animation.FIND_MODE_APPROX)
		if key_index < 0:
			key_index = animation.track_insert_key(track, key_time, values[track_index])
		else:
			animation.track_set_key_value(track, key_index, values[track_index])


func _get_animation_fps(animation_name: StringName) -> float:
	if (
		is_instance_valid(player_sprite)
		and player_sprite.sprite_frames
		and player_sprite.sprite_frames.has_animation(animation_name)
	):
		return player_sprite.sprite_frames.get_animation_speed(animation_name)
	return 1.0


func _repair_library_key_timing() -> int:
	if not is_instance_valid(player_sprite) or player_sprite.sprite_frames == null:
		return 0
	var library := _get_library()
	var repaired_tracks := 0
	for animation_name in library.get_animation_list():
		if not player_sprite.sprite_frames.has_animation(animation_name):
			continue
		# Idle intentionally uses a few control poses and interpolates between them.
		# Requiring one key per sprite frame recreates the visible per-frame wobble.
		if animation_name == &"Idle":
			continue
		var animation := library.get_animation(animation_name)
		var frame_count := player_sprite.sprite_frames.get_frame_count(animation_name)
		var fps := player_sprite.sprite_frames.get_animation_speed(animation_name)
		for path in [HAND_POSITION_PATH, WRIST_ROTATION_PATH, WRIST_SCALE_PATH]:
			var track := animation.find_track(path, Animation.TYPE_VALUE)
			if track < 0:
				continue
			var timing_is_valid := animation.track_get_key_count(track) == frame_count
			if timing_is_valid:
				for frame_index in frame_count:
					var expected_time := float(frame_index) / maxf(fps, 0.001)
					if not is_equal_approx(animation.track_get_key_time(track, frame_index), expected_time):
						timing_is_valid = false
						break
			if timing_is_valid:
				continue
			var repaired_values: Array = []
			for frame_index in frame_count:
				var expected_time := float(frame_index) / maxf(fps, 0.001)
				repaired_values.append(animation.value_track_interpolate(track, expected_time))
			while animation.track_get_key_count(track) > 0:
				animation.track_remove_key(track, 0)
			for frame_index in frame_count:
				animation.track_insert_key(
					track,
					float(frame_index) / maxf(fps, 0.001),
					repaired_values[frame_index]
				)
			_configure_track_playback(animation_name, animation, track)
			repaired_tracks += 1
	if repaired_tracks > 0:
		ResourceSaver.save(library, library.resource_path)
	return repaired_tracks


func _configure_track_playback(
	_animation_name: StringName,
	animation: Animation,
	track: int
) -> void:
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)


func _select_preview_node(node: Node) -> void:
	if not is_instance_valid(node):
		_set_status("The preview is not ready.", true)
		return
	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)
	EditorInterface.set_main_screen_editor("2D")


func _set_status(message: String, is_error: bool) -> void:
	if is_instance_valid(dock):
		dock.call("set_status", message, is_error)
