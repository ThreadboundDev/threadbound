extends Area2D

signal opened(save_point: Area2D)
signal closed(save_point: Area2D)
signal activated(save_point: Area2D, player: Node)

const SAVE_POINT_MENU_SCENE := preload("res://Src/UI/SavePointMenu/save_point_menu.tscn")

@export var save_point_id: StringName = &""
@export var open_animation := &"open_to_closed"
@export var interaction_message := "Save point activated."
@export var prompt_action_text := "Save"
@export var starts_closed := true
@export var close_when_player_leaves := true
@export var sprite_sheet: Texture2D
@export_range(1, 24, 1) var sheet_columns := 1
@export_range(1, 24, 1) var sheet_rows := 1
@export_range(1, 256, 1) var animation_frame_count := 1
@export_range(1.0, 30.0, 0.5) var animation_speed := 12.0
@export_group("Focus")
@export var camera_zoom := Vector2(1.65, 1.65)
@export var camera_tween_duration := 0.45
@export var focus_left_screen_position := Vector2(0.28, 0.56)
@export var focus_right_screen_position := Vector2(0.72, 0.56)
@export var player_sit_offset := Vector2(-32.0, -56.0)
@export_range(0.0, 4.0, 0.05) var meditation_light_energy := 1.35
@export_range(0.0, 2.0, 0.05) var meditation_light_fade_duration := 0.45

@onready var save_point_sprite: AnimatedSprite2D = $SavePointSprite as AnimatedSprite2D
@onready var meditation_light: PointLight2D = get_node_or_null("MeditationLight") as PointLight2D
@onready var editor_preview_sprite: Sprite2D = get_node_or_null("EditorPreviewSprite") as Sprite2D
@onready var prompt_label: Label = $PromptLabel as Label
@onready var interaction_area: Area2D = $InteractionArea as Area2D
@onready var sit_target: Marker2D = $SitTarget as Marker2D

var _nearby_player: Node
var _interactable_player: Node
var _is_open := false
var _active_player: Node
var _menu: Node
var _camera: Camera2D
var _camera_state := {}
var _remote_transform: RemoteTransform2D
var _remote_update_position := true
var _remote_path := NodePath("")

func _ready() -> void:
	if editor_preview_sprite:
		editor_preview_sprite.visible = false
	if meditation_light:
		meditation_light.visible = false
		meditation_light.energy = 0.0
	add_to_group("save_points")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	var input_manager := get_node_or_null("/root/InputBindingManager")
	if input_manager and input_manager.has_signal("bindings_changed"):
		input_manager.bindings_changed.connect(_refresh_prompt_label)
	_build_sprite_frames_from_sheet()
	_apply_initial_state()

func interact(interacting_player: Node) -> void:
	if _active_player:
		return
	if interacting_player != _interactable_player:
		return

	activated.emit(self, interacting_player)
	if interacting_player.has_method("begin_save_point_interaction"):
		var started: bool = interacting_player.begin_save_point_interaction(self, _get_player_sit_position())
		if not started:
			return
		_active_player = interacting_player
		var seated_callable := Callable(self, "_on_player_seated")
		if interacting_player.has_signal("save_point_seated") and not interacting_player.is_connected("save_point_seated", seated_callable):
			interacting_player.connect("save_point_seated", seated_callable)
		_disable_prompt()

func is_open() -> bool:
	return _is_open

func _apply_initial_state() -> void:
	if prompt_label:
		prompt_label.visible = false
		_refresh_prompt_label()
	if not save_point_sprite:
		return

	save_point_sprite.animation = open_animation
	save_point_sprite.stop()
	if starts_closed:
		save_point_sprite.frame = maxi(save_point_sprite.sprite_frames.get_frame_count(open_animation) - 1, 0)
		_is_open = false
	else:
		save_point_sprite.frame = 0
		_is_open = true

func _build_sprite_frames_from_sheet() -> void:
	if not save_point_sprite or not sprite_sheet:
		return

	var frame_width := sprite_sheet.get_width() / sheet_columns
	var frame_height := sprite_sheet.get_height() / sheet_rows
	var max_frames := sheet_columns * sheet_rows
	var used_frames := clampi(animation_frame_count, 1, max_frames)
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(open_animation)
	sprite_frames.set_animation_loop(open_animation, false)
	sprite_frames.set_animation_speed(open_animation, animation_speed)

	for frame_index in used_frames:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = sprite_sheet
		atlas_texture.region = Rect2(
			(frame_index % sheet_columns) * frame_width,
			(frame_index / sheet_columns) * frame_height,
			frame_width,
			frame_height
		)
		sprite_frames.add_frame(open_animation, atlas_texture)

	save_point_sprite.sprite_frames = sprite_frames

func _open() -> void:
	if _is_open or not save_point_sprite:
		return

	_is_open = true
	save_point_sprite.animation = open_animation
	save_point_sprite.play_backwards(open_animation)
	opened.emit(self)

func _close() -> void:
	if not _is_open or not save_point_sprite:
		return

	_is_open = false
	save_point_sprite.animation = open_animation
	save_point_sprite.play(open_animation)
	closed.emit(self)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	_open()

func _on_body_exited(body: Node) -> void:
	if body != _nearby_player:
		return

	if close_when_player_leaves:
		_close()
	_nearby_player = null

func _on_interaction_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or _active_player:
		return

	_interactable_player = body
	if prompt_label:
		_refresh_prompt_label()
		prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)

func _on_interaction_body_exited(body: Node) -> void:
	if body != _interactable_player:
		return

	_disable_prompt()
	if body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_interactable_player = null

func _on_player_seated(player: Node) -> void:
	if player != _active_player:
		return

	if player.has_signal("save_point_seated"):
		var seated_callable := Callable(self, "_on_player_seated")
		if player.is_connected("save_point_seated", seated_callable):
			player.disconnect("save_point_seated", seated_callable)

	_present_camera_and_menu(player)

func _get_sit_target_position() -> Vector2:
	if sit_target:
		var seat_guide := sit_target.get_node_or_null("SeatGuide") as Node2D
		if seat_guide:
			return seat_guide.global_position
		return sit_target.global_position
	return global_position

func _get_player_sit_position() -> Vector2:
	return _get_sit_target_position() + player_sit_offset

func _disable_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false

func _present_camera_and_menu(player: Node) -> void:
	_camera = get_viewport().get_camera_2d()
	_fade_meditation_light(true)
	if _camera:
		_camera_state = {
			"position": _camera.global_position,
			"zoom": _camera.zoom
		}

	_remote_transform = player.get_node_or_null("RemoteTransform2D") as RemoteTransform2D
	if _remote_transform:
		_remote_update_position = _remote_transform.update_position
		_remote_path = _remote_transform.remote_path
		_remote_transform.update_position = false

	var save_side := -1 if player.global_position.x <= global_position.x else 1
	var menu_side := -save_side
	var focus_position := _get_sit_target_position()
	if _camera:
		var focus_screen_position := focus_left_screen_position if menu_side >= 0 else focus_right_screen_position
		var viewport_size := get_viewport().get_visible_rect().size
		var screen_delta := (focus_screen_position - Vector2(0.5, 0.5)) * viewport_size
		var target_camera_position := focus_position - Vector2(screen_delta.x / camera_zoom.x, screen_delta.y / camera_zoom.y)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_camera, "global_position", target_camera_position, camera_tween_duration)
		tween.tween_property(_camera, "zoom", camera_zoom, camera_tween_duration)

	_menu = SAVE_POINT_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(_menu)
	if _menu.has_method("set_player"):
		_menu.set_player(player)
	if _menu.has_method("open"):
		_menu.open(menu_side)
	if _menu.has_signal("rise_requested"):
		_menu.rise_requested.connect(_on_rise_requested)
	if _menu.has_signal("option_selected"):
		_menu.option_selected.connect(_on_menu_option_selected)

func _on_menu_option_selected(option_name: StringName) -> void:
	if option_name == &"Reflect":
		_rest_at_save_point()

func _on_rise_requested() -> void:
	_end_save_point_interaction()

func _end_save_point_interaction() -> void:
	if _menu and is_instance_valid(_menu):
		if _menu.has_method("close"):
			await _menu.close()
		else:
			_menu.queue_free()
	_menu = null

	if _camera and is_instance_valid(_camera) and not _camera_state.is_empty():
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_camera, "global_position", _camera_state.get("position", _camera.global_position), camera_tween_duration)
		tween.tween_property(_camera, "zoom", _camera_state.get("zoom", _camera.zoom), camera_tween_duration)
		await tween.finished

	_fade_meditation_light(false)

	if _remote_transform and is_instance_valid(_remote_transform):
		_remote_transform.update_position = _remote_update_position
		_remote_transform.remote_path = _remote_path

	var finished_player := _active_player
	if finished_player and finished_player.has_method("end_save_point_interaction"):
		finished_player.end_save_point_interaction()
	_active_player = null
	_camera_state.clear()

	if finished_player and interaction_area and interaction_area.get_overlapping_bodies().has(finished_player):
		_interactable_player = finished_player
		if prompt_label:
			_refresh_prompt_label()
			prompt_label.visible = true
		if finished_player.has_method("_on_interactable_entered"):
			finished_player._on_interactable_entered(self)

func _reset_regular_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("reset_for_save_point"):
			enemy.reset_for_save_point()

func _fade_meditation_light(turn_on: bool) -> void:
	if not meditation_light:
		return

	if turn_on:
		meditation_light.visible = true
	var target_energy := meditation_light_energy if turn_on else 0.0
	var tween := create_tween()
	tween.tween_property(meditation_light, "energy", target_energy, meditation_light_fade_duration)
	if not turn_on:
		tween.tween_callback(func() -> void:
			if meditation_light:
				meditation_light.visible = false
		)

func _rest_at_save_point() -> void:
	if _active_player and _active_player.has_method("recover_at_save_point"):
		_active_player.recover_at_save_point()

	var scene_path := ""
	if get_tree().current_scene:
		scene_path = get_tree().current_scene.scene_file_path
	var checkpoint_id := save_point_id
	if String(checkpoint_id).is_empty():
		checkpoint_id = StringName(get_path())
	if _active_player is Node2D:
		DemoProgress.save_checkpoint(checkpoint_id, scene_path, (_active_player as Node2D).global_position)

	_reset_regular_enemies()

func _refresh_prompt_label() -> void:
	if not prompt_label:
		return

	var action_text := prompt_action_text
	if action_text.is_empty():
		action_text = InteractionPromptFormatter.prompt_action_from_text(prompt_label.text, "Save")
	prompt_label.text = InteractionPromptFormatter.format_interact_prompt(action_text)
