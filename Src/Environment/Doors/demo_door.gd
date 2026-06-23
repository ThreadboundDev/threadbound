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
@export var required_threads: Array[StringName] = [&"power", &"essence", &"balance"]
@export var door_color := Color(0.8, 0.6, 0.28, 1.0)
@export var fog_color := Color(0.015, 0.012, 0.018, 0.96)
@export var closed := true
@export_group("Opening Animation")
@export var closed_animation := &"closed"
@export var opening_animation := &"open"
@export var opening_sprite_sheet: Texture2D
@export_range(1, 24, 1) var opening_sheet_columns := 6
@export_range(1, 24, 1) var opening_sheet_rows := 8
@export_range(1, 256, 1) var opening_animation_frame_count := 48
@export_range(1.0, 30.0, 0.5) var opening_animation_speed := 18.0
@export var use_opening_first_frame_for_closed := true

@onready var door_sprite: AnimatedSprite2D = $DoorSprite as AnimatedSprite2D
@onready var fog_panel: Polygon2D = $FogPanel as Polygon2D
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D as CollisionShape2D
@onready var interact_shape: CollisionShape2D = $InteractionShape as CollisionShape2D
@onready var prompt_label: Label = $PromptLabel as Label

var _player: Node
var _is_opening := false

func _ready() -> void:
	add_to_group("demo_doors")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_opening_animation_from_sheet()
	_apply_visual_state()

func interact(_interacting_player: Node) -> void:
	if _is_opening:
		return

	if door_kind == DoorKind.BOSS:
		_interact_with_boss_door()
		return

	_show_message(message)
	if open_after_message:
		_open()

func _interact_with_boss_door() -> void:
	var remaining := DemoProgress.remaining_threads(required_threads)
	if remaining.is_empty():
		_show_message("The three threads answer. The way forward opens.")
		_open()
		return

	var count := remaining.size()
	var noun := "thread remains" if count == 1 else "threads remain"
	_show_message("%s\n\n%d %s." % [message, count, noun])

func _open() -> void:
	if not closed:
		return

	closed = false
	_is_opening = true
	if claim_thread_on_open:
		DemoProgress.claim_thread(door_id)

	blocker_shape.set_deferred("disabled", true)
	interact_shape.set_deferred("disabled", true)
	if prompt_label:
		prompt_label.visible = false

	if door_sprite and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(opening_animation):
		door_sprite.visible = true
		door_sprite.modulate.a = 1.0
		door_sprite.play(opening_animation)
		door_sprite.animation_finished.connect(func() -> void:
			_is_opening = false
		, CONNECT_ONE_SHOT)
	else:
		_is_opening = false

	if fog_panel:
		var tween := create_tween()
		tween.tween_property(fog_panel, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func() -> void:
			fog_panel.visible = false
		)

func _build_opening_animation_from_sheet() -> void:
	if not door_sprite or not opening_sprite_sheet:
		return

	var sprite_frames := door_sprite.sprite_frames.duplicate(true) as SpriteFrames if door_sprite.sprite_frames else SpriteFrames.new()
	if sprite_frames.has_animation(opening_animation):
		sprite_frames.remove_animation(opening_animation)
	sprite_frames.add_animation(opening_animation)
	sprite_frames.set_animation_loop(opening_animation, false)
	sprite_frames.set_animation_speed(opening_animation, opening_animation_speed)

	var frame_width := opening_sprite_sheet.get_width() / opening_sheet_columns
	var frame_height := opening_sprite_sheet.get_height() / opening_sheet_rows
	var max_frames := opening_sheet_columns * opening_sheet_rows
	var used_frames := clampi(opening_animation_frame_count, 1, max_frames)

	if use_opening_first_frame_for_closed:
		if sprite_frames.has_animation(closed_animation):
			sprite_frames.remove_animation(closed_animation)
		sprite_frames.add_animation(closed_animation)
		sprite_frames.set_animation_loop(closed_animation, true)
		sprite_frames.add_frame(closed_animation, _atlas_frame_from_opening_sheet(0, frame_width, frame_height))

	for frame_index in used_frames:
		var atlas_texture := _atlas_frame_from_opening_sheet(frame_index, frame_width, frame_height)
		sprite_frames.add_frame(opening_animation, atlas_texture)

	door_sprite.sprite_frames = sprite_frames

func _atlas_frame_from_opening_sheet(frame_index: int, frame_width: float, frame_height: float) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = opening_sprite_sheet
	atlas_texture.region = Rect2(
		(frame_index % opening_sheet_columns) * frame_width,
		(frame_index / opening_sheet_columns) * frame_height,
		frame_width,
		frame_height
	)
	return atlas_texture

func _apply_visual_state() -> void:
	if door_sprite:
		door_sprite.self_modulate = door_color
		door_sprite.visible = true
		door_sprite.modulate.a = 1.0
		if closed and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(closed_animation):
			door_sprite.animation = closed_animation
			door_sprite.frame = 0
		elif not closed and door_sprite.sprite_frames and door_sprite.sprite_frames.has_animation(opening_animation):
			door_sprite.animation = opening_animation
			door_sprite.frame = maxi(door_sprite.sprite_frames.get_frame_count(opening_animation) - 1, 0)
	if fog_panel:
		fog_panel.color = fog_color
		fog_panel.visible = closed
		fog_panel.modulate.a = 1.0 if closed else 0.0
	if blocker_shape:
		blocker_shape.disabled = not closed
	if interact_shape:
		interact_shape.disabled = not closed
	if prompt_label:
		prompt_label.visible = false

func _show_message(text: String) -> void:
	var box := get_tree().get_first_node_in_group("demo_message_box")
	if not box:
		box = MESSAGE_BOX_SCENE.instantiate()
		get_tree().root.add_child(box)

	if box.has_method("show_message"):
		box.show_message(text)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	if prompt_label and closed:
		prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)

func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	if prompt_label:
		prompt_label.visible = false
	if body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_player = null
