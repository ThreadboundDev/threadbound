extends Node2D

const IDLE_SHEET := preload("res://Assets/chamber_of_first_weave/Follower/follower_wayfarers_loom_idle_sheet.png")
const FRAME_REGIONS := [
	Rect2(0.0, 0.0, 768.0, 512.0),
	Rect2(768.0, 0.0, 768.0, 512.0),
	Rect2(0.0, 512.0, 768.0, 512.0),
	Rect2(768.0, 512.0, 768.0, 512.0),
]
const FRAME_OFFSETS := [
	Vector2(0.0, -220.0),
	Vector2(32.0, -219.0),
	Vector2(0.0, -198.0),
	Vector2(32.0, -198.0),
]

@export_range(0.2, 2.0, 0.05) var frame_duration := 0.6
@export var autoplay := true

@onready var loom_sprite: Sprite2D = $LoomSprite as Sprite2D

var _frames: Array[AtlasTexture] = []
var _frame_index := 0
var _frame_timer := 0.0

func _ready() -> void:
	_build_frames()
	_apply_frame(0)
	set_process(autoplay)

func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer < frame_duration:
		return
	_frame_timer = fmod(_frame_timer, frame_duration)
	_apply_frame((_frame_index + 1) % _frames.size())

func set_animation_playing(is_playing: bool) -> void:
	autoplay = is_playing
	set_process(is_playing)

func _build_frames() -> void:
	_frames.clear()
	for region in FRAME_REGIONS:
		var frame := AtlasTexture.new()
		frame.atlas = IDLE_SHEET
		frame.region = region
		_frames.append(frame)

func _apply_frame(index: int) -> void:
	if not loom_sprite or _frames.is_empty():
		return
	_frame_index = wrapi(index, 0, _frames.size())
	loom_sprite.texture = _frames[_frame_index]
	loom_sprite.position = FRAME_OFFSETS[_frame_index]
