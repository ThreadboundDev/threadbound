class_name Tensioner
extends EnemyBase

@export var walk_texture: Texture2D
@export var walk_columns := 6
@export var walk_rows := 4
@export var walk_frame_count := 24
@export var walk_fps := 8.0
@export var chase_fps_multiplier := 1.35

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _animation_timer := 0.0
var _current_frame := 0

func _ready() -> void:
	super._ready()
	add_to_group("tensioners")

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite and walk_texture:
		sprite.texture = walk_texture
		sprite.hframes = max(1, walk_columns)
		sprite.vframes = max(1, walk_rows)
		sprite.frame = 0

func _process(delta: float) -> void:
	_update_walk_animation(delta)

func begin_attack() -> void:
	super.begin_attack()
	_update_walk_animation(0.0)

func end_attack() -> void:
	super.end_attack()
	_update_walk_animation(0.0)

func _update_walk_animation(delta: float) -> void:
	if not sprite:
		return

	var frame_count := clampi(walk_frame_count, 1, max(1, sprite.hframes * sprite.vframes))
	var fps := _get_walk_fps()
	if fps <= 0.0:
		return

	_animation_timer += delta
	_current_frame = int(floor(_animation_timer * fps)) % frame_count
	sprite.frame = _current_frame

func _get_walk_fps() -> float:
	if state_machine and state_machine.current_state_name == &"Chase":
		return walk_fps * chase_fps_multiplier
	return walk_fps
