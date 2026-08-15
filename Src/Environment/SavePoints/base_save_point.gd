extends Area2D

signal opened(save_point: Area2D)
signal closed(save_point: Area2D)
signal activated(save_point: Area2D, player: Node)
signal menu_opened(menu: Node)
signal rested(save_point: Area2D, player: Node)

const SAVE_POINT_MENU_SCENE := preload("res://Src/UI/SavePointMenu/save_point_menu.tscn")
const BLOSSOM_SOUND_MIX_RATE := 22050
const BLOSSOM_SOUND_DURATION := 0.95

static var _blossom_open_stream: AudioStreamWAV

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
@export_range(0.0, 4.0, 0.05) var meditation_light_energy := 1.65
@export_range(0.0, 2.0, 0.05) var meditation_light_fade_duration := 0.45
@export_group("Tutorial Refresh")
@export var tutorial_refresh_proximity_distance := 760.0
@export var tutorial_refresh_interaction_distance := 460.0

@onready var save_point_sprite: AnimatedSprite2D = $SavePointSprite as AnimatedSprite2D
@onready var meditation_light: PointLight2D = get_node_or_null("MeditationLight") as PointLight2D
@onready var editor_preview_sprite: Sprite2D = get_node_or_null("EditorPreviewSprite") as Sprite2D
@onready var prompt_label: Label = $PromptLabel as Label
@onready var interaction_area: Area2D = $InteractionArea as Area2D
@onready var sit_target: Marker2D = $SitTarget as Marker2D

var _nearby_player: Node
var _interactable_player: Node
var _is_open := false
var _open_sound_armed := true
var _active_player: Node
var _menu: Node
var _camera: Camera2D
var _camera_state := {}
var _remote_transform: RemoteTransform2D
var _remote_update_position := true
var _remote_path := NodePath("")

func _ready() -> void:
	add_to_group("interaction_prompt_owners")
	if editor_preview_sprite:
		editor_preview_sprite.visible = false
	if prompt_label:
		prompt_label.z_as_relative = false
		prompt_label.z_index = 1000
	if meditation_light:
		meditation_light.visible = false
		meditation_light.energy = 0.0
	add_to_group("save_points")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	if save_point_sprite:
		save_point_sprite.animation_finished.connect(_on_save_point_animation_finished)
	var input_manager := get_node_or_null("/root/InputBindingManager")
	if input_manager and input_manager.has_signal("bindings_changed"):
		input_manager.bindings_changed.connect(_refresh_prompt_label)
	_build_sprite_frames_from_sheet()
	_apply_initial_state()

func refresh_current_player_overlap(preferred_player: Node = null) -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return

	var found_proximity := false
	var found_interaction := false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			found_proximity = true
			break

	if interaction_area:
		for body in interaction_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				_on_interaction_body_entered(body)
				found_interaction = true
				break

	var player_node: Node = preferred_player
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")
	var player_2d: Node2D = player_node as Node2D
	if not player_2d:
		return

	var distance_to_player := global_position.distance_to(player_2d.global_position)
	if not found_proximity and distance_to_player <= tutorial_refresh_proximity_distance:
		_on_body_entered(player_node)
	if not found_interaction and distance_to_player <= tutorial_refresh_interaction_distance:
		_on_interaction_body_entered(player_node)

func prepare_for_tutorial_reveal() -> void:
	_nearby_player = null
	_interactable_player = null
	_active_player = null
	_disable_prompt()
	_apply_initial_state()

func interact(interacting_player: Node) -> void:
	if _active_player:
		return
	if interacting_player != _interactable_player:
		return
	DemoProgress.unlock_lore(&"blossom")

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
	if _open_sound_armed:
		_open_sound_armed = false
		_play_open_sound()
	opened.emit(self)

func _on_save_point_animation_finished() -> void:
	if not _is_open and save_point_sprite.animation == open_animation:
		_open_sound_armed = true

func _play_open_sound() -> void:
	var player := AudioStreamPlayer.new()
	player.name = "BlossomOpenSound"
	player.bus = &"SFX"
	player.volume_db = -2.0
	player.pitch_scale = randf_range(0.98, 1.02)
	player.stream = _get_blossom_open_stream()
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

static func _get_blossom_open_stream() -> AudioStreamWAV:
	if _blossom_open_stream:
		return _blossom_open_stream

	var frame_count := int(BLOSSOM_SOUND_MIX_RATE * BLOSSOM_SOUND_DURATION)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 0xE7D0
	var soft_noise := 0.0
	for frame in frame_count:
		var time := float(frame) / float(BLOSSOM_SOUND_MIX_RATE)
		var progress := time / BLOSSOM_SOUND_DURATION
		var opening_envelope := minf(time / 0.055, 1.0) * pow(1.0 - progress, 1.75)

		var root_tone := sin(TAU * 392.0 * time) * opening_envelope * 0.38
		var middle_time := maxf(time - 0.12, 0.0)
		var middle_envelope := minf(middle_time / 0.045, 1.0) * exp(-middle_time * 3.1)
		var middle_tone := sin(TAU * 523.25 * middle_time) * middle_envelope * 0.28
		var high_time := maxf(time - 0.27, 0.0)
		var high_envelope := minf(high_time / 0.04, 1.0) * exp(-high_time * 3.8)
		var high_tone := sin(TAU * 783.99 * high_time) * high_envelope * 0.2

		soft_noise = lerpf(soft_noise, random.randf_range(-1.0, 1.0), 0.16)
		var petal_rustle := soft_noise * opening_envelope * 0.13
		var combined := root_tone + middle_tone + high_tone + petal_rustle
		var sample := int(clampf(combined * 25000.0, -32768.0, 32767.0))
		samples.encode_s16(frame * 2, sample)

	_blossom_open_stream = AudioStreamWAV.new()
	_blossom_open_stream.format = AudioStreamWAV.FORMAT_16_BITS
	_blossom_open_stream.mix_rate = BLOSSOM_SOUND_MIX_RATE
	_blossom_open_stream.stereo = false
	_blossom_open_stream.data = samples
	return _blossom_open_stream

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
	menu_opened.emit(_menu)

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
	rested.emit(self, _active_player)

func _refresh_prompt_label() -> void:
	if not prompt_label:
		return

	var action_text := prompt_action_text
	if action_text.is_empty():
		action_text = InteractionPromptFormatter.prompt_action_from_text(prompt_label.text, "Save")
	InteractionPromptFormatter.apply_interact_prompt(prompt_label, action_text)

func refresh_interaction_prompt() -> void:
	_refresh_prompt_label()
