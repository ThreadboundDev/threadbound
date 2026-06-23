extends Area2D

signal opened(save_point: Area2D)
signal closed(save_point: Area2D)
signal activated(save_point: Area2D, player: Node)

@export var save_point_id: StringName = &""
@export var open_animation := &"open_to_closed"
@export var interaction_message := "Save point activated."
@export var starts_closed := true
@export var close_when_player_leaves := true
@export var sprite_sheet: Texture2D
@export_range(1, 24, 1) var sheet_columns := 1
@export_range(1, 24, 1) var sheet_rows := 1
@export_range(1, 256, 1) var animation_frame_count := 1
@export_range(1.0, 30.0, 0.5) var animation_speed := 12.0

@onready var save_point_sprite: AnimatedSprite2D = $SavePointSprite as AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel as Label

var _nearby_player: Node
var _is_open := false

func _ready() -> void:
	add_to_group("save_points")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_sprite_frames_from_sheet()
	_apply_initial_state()

func interact(interacting_player: Node) -> void:
	activated.emit(self, interacting_player)
	print(interaction_message)

func is_open() -> bool:
	return _is_open

func _apply_initial_state() -> void:
	if prompt_label:
		prompt_label.visible = false
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
	if prompt_label:
		prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)

func _on_body_exited(body: Node) -> void:
	if body != _nearby_player:
		return

	if close_when_player_leaves:
		_close()
	if prompt_label:
		prompt_label.visible = false
	if body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_nearby_player = null
