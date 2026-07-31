extends Area2D

enum DoorKind {
	WING,
	BOSS
}

const MESSAGE_BOX_SCENE := preload("res://Src/UI/demo_message_box.tscn")

@export var door_kind := DoorKind.WING
@export var door_id: StringName = &""
@export var display_name := "Demo Door"
@export_multiline var message := ""
@export var open_after_message := true
@export var claim_thread_on_open := false
@export var interaction_enabled := true
@export var required_threads: Array[StringName] = [&"power", &"essence", &"balance"]
@export var door_color := Color(0.8, 0.6, 0.28, 1.0)
@export var fog_color := Color(0.015, 0.012, 0.018, 0.96)
@export var fog_panel_enabled := true
@export var closed := true
@export_group("Prompt")
@export var prompt_read_text := "Read"
@export var prompt_open_text := "Open"
@export_group("Message Box")
@export var message_box_rect := Rect2(-560.0, -190.0, 1120.0, 118.0)
@export var message_text_margins := Vector4(24.0, 18.0, 24.0, 18.0)
@export var message_display_time := 4.0
@export var message_fade_time := 0.18
@export var message_label_settings: LabelSettings
@export_group("Opening Animation")
@export var closed_animation := &"closed"
@export var opening_animation := &"open"
@export_group("Opened Split Layers")
@export var opened_low_texture: Texture2D
@export var opened_high_texture: Texture2D
@export var opened_low_z_index := 2
@export var opened_high_z_index := 6
@export_group("Doorway Depth")
@export var doorway_depth_enabled := true
@export var doorway_depth_only_when_open := true
@export var doorway_depth_use_open_high_sprite := true
@export var doorway_depth_padding := Vector2(0.0, 0.0)
@export var doorway_depth_area_position := Vector2(0.0, 18.0)
@export var doorway_depth_area_size := Vector2(340.0, 640.0)
@export var doorway_player_z_index := 3
@export var doorway_equipment_z_index := 4

@onready var door_sprite: AnimatedSprite2D = $DoorSprite as AnimatedSprite2D
@onready var opened_low_sprite: Sprite2D = get_node_or_null("OpenedLowSprite") as Sprite2D
@onready var opened_high_sprite: Sprite2D = get_node_or_null("OpenedHighSprite") as Sprite2D
@onready var fog_panel: Polygon2D = $FogPanel as Polygon2D
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D as CollisionShape2D
@onready var interact_shape: CollisionShape2D = $InteractionShape as CollisionShape2D
@onready var doorway_depth_area: Area2D = get_node_or_null("DoorwayDepthArea") as Area2D
@onready var doorway_depth_shape: CollisionShape2D = get_node_or_null("DoorwayDepthArea/CollisionShape2D") as CollisionShape2D
@onready var prompt_label: Label = $PromptLabel as Label

var _player: Node
var _is_opening := false
var _message_acknowledged := false
var _doorway_depth_originals: Dictionary = {}

func _ready() -> void:
	add_to_group("demo_doors")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if doorway_depth_area:
		doorway_depth_area.body_entered.connect(_on_doorway_depth_body_entered)
		doorway_depth_area.body_exited.connect(_on_doorway_depth_body_exited)
	var input_manager := get_node_or_null("/root/InputBindingManager")
	if input_manager and input_manager.has_signal("bindings_changed"):
		input_manager.bindings_changed.connect(_refresh_prompt_label)
	if prompt_label:
		prompt_label.z_as_relative = false
		prompt_label.z_index = 1000
	_configure_doorway_depth_area()
	_configure_opened_split_layers()
	_apply_visual_state()

func _exit_tree() -> void:
	_restore_all_doorway_depth()

func interact(_interacting_player: Node) -> void:
	if not interaction_enabled:
		return
	if _is_opening:
		return

	if door_kind == DoorKind.BOSS:
		_interact_with_boss_door()
		return

	if not _message_acknowledged:
		_show_message(message)
		_message_acknowledged = true
		_refresh_prompt_label()
		return

	if open_after_message:
		_open()

func _interact_with_boss_door() -> void:
	var remaining := DemoProgress.remaining_threads(required_threads)
	if remaining.is_empty():
		if not _message_acknowledged:
			_show_message("The three threads answer. The way forward opens.")
			_message_acknowledged = true
			_refresh_prompt_label()
			return

		_open()
		return

	_message_acknowledged = false
	_refresh_prompt_label()
	var count := remaining.size()
	var noun := "thread remains" if count == 1 else "threads remain"
	_show_message("%s\n\n%d %s." % [message, count, noun])

func _open() -> void:
	if not closed:
		return

	closed = false
	_is_opening = true
	_message_acknowledged = false
	if claim_thread_on_open:
		DemoProgress.claim_thread(door_id)

	blocker_shape.set_deferred("disabled", true)
	interact_shape.set_deferred("disabled", true)
	if prompt_label:
		prompt_label.visible = false

	if door_sprite and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(opening_animation):
		door_sprite.visible = true
		door_sprite.modulate.a = 1.0
		_set_opened_split_visible(false)
		door_sprite.play(opening_animation)
		door_sprite.animation_finished.connect(func() -> void:
			_is_opening = false
			_show_opened_split_layers()
		, CONNECT_ONE_SHOT)
	else:
		_is_opening = false
		_show_opened_split_layers()

	if fog_panel and fog_panel_enabled:
		var tween := create_tween()
		tween.tween_property(fog_panel, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func() -> void:
			fog_panel.visible = false
		)
	elif fog_panel:
		fog_panel.visible = false

func open_silently() -> void:
	_message_acknowledged = false
	_open()

func debug_force_open() -> void:
	if not OS.is_debug_build():
		return
	closed = false
	_is_opening = false
	_message_acknowledged = false
	interaction_enabled = false
	if door_sprite:
		door_sprite.stop()
		door_sprite.visible = false
	if blocker_shape:
		blocker_shape.set_deferred("disabled", true)
	if interact_shape:
		interact_shape.set_deferred("disabled", true)
	if prompt_label:
		prompt_label.visible = false
	if fog_panel:
		fog_panel.visible = false
		fog_panel.modulate.a = 0.0
	_show_opened_split_layers()

func lock_closed_for_boss() -> void:
	interaction_enabled = false
	closed = true
	_is_opening = true
	_set_opened_split_visible(false)
	if blocker_shape:
		# Keep the blocker non-solid while the large closing artwork crosses the
		# doorway. The arena trigger is beyond the door, and collision becomes
		# authoritative only once the door is fully seated.
		blocker_shape.set_deferred("disabled", true)
	if interact_shape:
		interact_shape.set_deferred("disabled", true)
	if prompt_label:
		prompt_label.visible = false
	if fog_panel:
		fog_panel.visible = false

	if door_sprite and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(opening_animation):
		door_sprite.visible = true
		door_sprite.modulate.a = 1.0
		door_sprite.animation = opening_animation
		door_sprite.frame = maxi(door_sprite.sprite_frames.get_frame_count(opening_animation) - 1, 0)
		door_sprite.play_backwards(opening_animation)
		door_sprite.animation_finished.connect(func() -> void:
			_is_opening = false
			door_sprite.animation = closed_animation
			door_sprite.frame = 0
			if blocker_shape:
				blocker_shape.set_deferred("disabled", false)
		, CONNECT_ONE_SHOT)
	else:
		_is_opening = false
		if blocker_shape:
			blocker_shape.set_deferred("disabled", false)
		_apply_visual_state()

func _apply_visual_state() -> void:
	if door_sprite:
		door_sprite.self_modulate = door_color
		door_sprite.visible = closed or _is_opening or not _has_opened_split_layers()
		door_sprite.modulate.a = 1.0
		if closed and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(closed_animation):
			door_sprite.animation = closed_animation
			door_sprite.frame = 0
		elif not closed and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(opening_animation):
			door_sprite.animation = opening_animation
			door_sprite.frame = maxi(door_sprite.sprite_frames.get_frame_count(opening_animation) - 1, 0)
	if closed:
		_set_opened_split_visible(false)
	else:
		_show_opened_split_layers()
	if fog_panel:
		fog_panel.color = fog_color
		fog_panel.visible = fog_panel_enabled and closed
		fog_panel.modulate.a = 1.0 if fog_panel_enabled and closed else 0.0
	if blocker_shape:
		blocker_shape.disabled = not closed
	if interact_shape:
		interact_shape.disabled = not closed
	if prompt_label:
		prompt_label.visible = false
		_refresh_prompt_label()

func _configure_opened_split_layers() -> void:
	_configure_opened_split_sprite(opened_low_sprite, opened_low_texture, opened_low_z_index)
	_configure_opened_split_sprite(opened_high_sprite, opened_high_texture, opened_high_z_index)
	_set_opened_split_visible(false)

func _configure_doorway_depth_area() -> void:
	if doorway_depth_area:
		doorway_depth_area.monitoring = doorway_depth_enabled
		doorway_depth_area.monitorable = doorway_depth_enabled
	if not doorway_depth_shape:
		return

	var depth_position := doorway_depth_area_position
	var depth_size := doorway_depth_area_size
	if doorway_depth_use_open_high_sprite:
		var sprite_bounds := _get_open_high_sprite_local_bounds()
		if sprite_bounds.size != Vector2.ZERO:
			depth_position = sprite_bounds.get_center()
			depth_size = sprite_bounds.size + doorway_depth_padding

	doorway_depth_shape.position = depth_position
	if doorway_depth_shape.shape is RectangleShape2D:
		var rectangle := doorway_depth_shape.shape.duplicate() as RectangleShape2D
		rectangle.size = depth_size.abs()
		doorway_depth_shape.shape = rectangle

func _get_open_high_sprite_local_bounds() -> Rect2:
	if not opened_high_sprite or not opened_high_sprite.texture:
		return Rect2()

	var texture_size := opened_high_sprite.texture.get_size()
	var local_position := opened_high_sprite.position
	if opened_high_sprite.centered:
		local_position -= texture_size * opened_high_sprite.scale * 0.5
	local_position += opened_high_sprite.offset * opened_high_sprite.scale

	var local_size := texture_size * opened_high_sprite.scale
	var min_x := minf(local_position.x, local_position.x + local_size.x)
	var min_y := minf(local_position.y, local_position.y + local_size.y)
	return Rect2(Vector2(min_x, min_y), local_size.abs())

func _configure_opened_split_sprite(sprite: Sprite2D, texture: Texture2D, target_z_index: int) -> void:
	if not sprite:
		return

	if texture:
		sprite.texture = texture
	sprite.z_index = target_z_index
	sprite.visible = false

func _has_opened_split_layers() -> bool:
	return _opened_split_sprite_has_texture(opened_low_sprite) or _opened_split_sprite_has_texture(opened_high_sprite)

func _opened_split_sprite_has_texture(sprite: Sprite2D) -> bool:
	return sprite != null and sprite.texture != null

func _show_opened_split_layers() -> void:
	if not _has_opened_split_layers():
		return

	if door_sprite:
		door_sprite.visible = false
	_set_opened_split_visible(true)
	_apply_depth_to_bodies_inside_doorway()

func _set_opened_split_visible(is_visible: bool) -> void:
	if opened_low_sprite:
		opened_low_sprite.visible = is_visible and opened_low_sprite.texture != null
	if opened_high_sprite:
		opened_high_sprite.visible = is_visible and opened_high_sprite.texture != null

func _apply_depth_to_bodies_inside_doorway() -> void:
	if not doorway_depth_area:
		return

	for body in doorway_depth_area.get_overlapping_bodies():
		_try_apply_doorway_depth(body)

func _try_apply_doorway_depth(body: Node) -> void:
	if not doorway_depth_enabled:
		return
	if doorway_depth_only_when_open and closed:
		return
	if not body or not body.is_in_group("player"):
		return

	var instance_id := body.get_instance_id()
	if _doorway_depth_originals.has(instance_id):
		return

	var records: Array[Dictionary] = []
	var seen := {}
	var equipment_mount := body.get_node_or_null("EquipmentMount")
	_collect_player_depth_items(body, equipment_mount, records, seen)
	_collect_equipment_depth_items(equipment_mount, records, seen)
	_collect_runtime_equipment_depth_items(body, equipment_mount, records, seen)
	if records.is_empty():
		return

	_doorway_depth_originals[instance_id] = {
		"body": body,
		"records": records,
	}

func _collect_player_depth_items(root: Node, equipment_mount: Node, records: Array[Dictionary], seen: Dictionary) -> void:
	if not root:
		return
	if root == equipment_mount:
		return

	if root is CanvasItem:
		_apply_depth_to_canvas_item(root as CanvasItem, doorway_player_z_index, records, seen)

	for child in root.get_children():
		_collect_player_depth_items(child, equipment_mount, records, seen)

func _collect_equipment_depth_items(root: Node, records: Array[Dictionary], seen: Dictionary) -> void:
	if not root:
		return

	if root is CanvasItem:
		_apply_depth_to_canvas_item(root as CanvasItem, doorway_equipment_z_index, records, seen)

func _collect_runtime_equipment_depth_items(body: Node, equipment_mount: Node, records: Array[Dictionary], seen: Dictionary) -> void:
	for property_name in [&"current_gloves", &"current_boots", &"current_chest"]:
		var item = body.get(property_name)
		if item is Node:
			if equipment_mount and equipment_mount.is_ancestor_of(item):
				continue
			_collect_equipment_depth_items(item as Node, records, seen)

func _apply_depth_to_canvas_item(item: CanvasItem, target_z_index: int, records: Array[Dictionary], seen: Dictionary) -> void:
	var instance_id := item.get_instance_id()
	if seen.has(instance_id):
		return

	seen[instance_id] = true
	records.append({
		"item": item,
		"z_index": item.z_index,
		"z_as_relative": item.z_as_relative,
	})
	item.z_as_relative = false
	item.z_index = target_z_index

func _restore_doorway_depth(body: Node) -> void:
	if not body:
		return

	var instance_id := body.get_instance_id()
	if not _doorway_depth_originals.has(instance_id):
		return

	var depth_state: Dictionary = _doorway_depth_originals[instance_id]
	for record in depth_state.get("records", []):
		var item = record.get("item")
		if not is_instance_valid(item):
			continue
		item.z_index = int(record.get("z_index", 0))
		item.z_as_relative = bool(record.get("z_as_relative", true))
	_doorway_depth_originals.erase(instance_id)

func _restore_all_doorway_depth() -> void:
	var states := _doorway_depth_originals.values()
	for depth_state in states:
		var body = depth_state.get("body")
		if is_instance_valid(body):
			_restore_doorway_depth(body)

func _show_message(text: String) -> void:
	var box := get_tree().get_first_node_in_group("demo_message_box")
	if not box:
		box = MESSAGE_BOX_SCENE.instantiate()
		get_tree().root.add_child(box)

	if box.has_method("configure_layout"):
		box.configure_layout({
			"panel_rect": message_box_rect,
			"text_margins": message_text_margins,
			"display_time": message_display_time,
			"fade_time": message_fade_time,
			"label_settings": message_label_settings,
		})

	if box.has_method("show_message"):
		box.show_message(text)

func _refresh_prompt_label() -> void:
	if not prompt_label:
		return

	var raw_text := prompt_open_text if _message_acknowledged else prompt_read_text
	var fallback := "Open" if _message_acknowledged else "Read"
	var action_text := InteractionPromptFormatter.prompt_action_from_text(raw_text, fallback)
	prompt_label.text = InteractionPromptFormatter.format_interact_prompt(action_text)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	if prompt_label and closed and interaction_enabled:
		_refresh_prompt_label()
		prompt_label.visible = true
	if interaction_enabled and body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)

func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	if prompt_label:
		prompt_label.visible = false
	_message_acknowledged = false
	_refresh_prompt_label()
	if interaction_enabled and body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_player = null

func _on_doorway_depth_body_entered(body: Node) -> void:
	_try_apply_doorway_depth(body)

func _on_doorway_depth_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		_restore_doorway_depth(body)
