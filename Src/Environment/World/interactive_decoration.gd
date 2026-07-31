class_name InteractiveDecoration
extends Sprite2D

## Adds subtle per-instance scale variation to decorative props and, when enabled,
## a lightweight player-triggered sway with a quiet synthesized brush rustle.

const PLAYER_BODY_COLLISION_LAYER := 1
const SCALE_VARIATION := 0.04
const SWAY_ANGLE := 0.055
const SOUND_COOLDOWN_MS := 140

@export var reacts_to_player := false

static var _brush_stream: AudioStreamWAV
static var _last_brush_sound_ms := -SOUND_COOLDOWN_MS

var _rest_position: Vector2
var _rest_rotation: float
var _sway_tween: Tween


func _ready() -> void:
	_apply_scale_variation()
	_rest_position = position
	_rest_rotation = rotation
	if reacts_to_player:
		_create_reaction_area()


func _apply_scale_variation() -> void:
	var random := RandomNumberGenerator.new()
	var stable_key := "%s|%s" % [String(get_path()), texture.resource_path if texture else ""]
	random.seed = abs(stable_key.hash())
	var scale_multiplier := random.randf_range(1.0 - SCALE_VARIATION, 1.0 + SCALE_VARIATION)
	scale *= scale_multiplier


func _create_reaction_area() -> void:
	var area := Area2D.new()
	area.name = "FoliageReactionArea"
	area.collision_layer = 0
	area.collision_mask = PLAYER_BODY_COLLISION_LAYER
	area.monitorable = false
	area.body_entered.connect(_on_body_entered)

	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	var texture_size := texture.get_size() if texture else Vector2(128.0, 192.0)
	shape.size = Vector2(
		clampf(texture_size.x * 0.42, 64.0, 120.0),
		clampf(texture_size.y * 0.68, 96.0, 180.0)
	)
	shape_node.position.y = minf(texture_size.y * 0.12, 28.0)
	shape_node.shape = shape
	area.add_child(shape_node)
	add_child(area)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return

	var sway_direction := signf(body.global_position.x - global_position.x)
	var body_velocity: Variant = body.get("velocity")
	if body_velocity is Vector2 and absf(body_velocity.x) > 1.0:
		sway_direction = signf(body_velocity.x)
	if is_zero_approx(sway_direction):
		sway_direction = 1.0

	_sway(sway_direction)
	_play_brush_sound()


func _sway(direction: float) -> void:
	if _sway_tween:
		_sway_tween.kill()
	position = _rest_position
	rotation = _rest_rotation

	var first_angle := SWAY_ANGLE * direction
	var rebound_angle := -SWAY_ANGLE * 0.32 * direction
	_sway_tween = create_tween()
	_sway_tween.set_trans(Tween.TRANS_SINE)
	_sway_tween.set_ease(Tween.EASE_OUT)
	_sway_tween.tween_property(self, "rotation", _rest_rotation + first_angle, 0.09)
	_sway_tween.parallel().tween_property(self, "position", _anchored_position(first_angle), 0.09)
	_sway_tween.tween_property(self, "rotation", _rest_rotation + rebound_angle, 0.14)
	_sway_tween.parallel().tween_property(self, "position", _anchored_position(rebound_angle), 0.14)
	_sway_tween.tween_property(self, "rotation", _rest_rotation, 0.24)
	_sway_tween.parallel().tween_property(self, "position", _rest_position, 0.24)


func _anchored_position(angle_delta: float) -> Vector2:
	var texture_height: float = texture.get_height() if texture else 192.0
	var bottom_anchor := Vector2(0.0, texture_height * 0.42 * absf(scale.y))
	var resting_anchor := bottom_anchor.rotated(_rest_rotation)
	var rotated_anchor := bottom_anchor.rotated(_rest_rotation + angle_delta)
	return _rest_position + resting_anchor - rotated_anchor


func _play_brush_sound() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_brush_sound_ms < SOUND_COOLDOWN_MS:
		return
	_last_brush_sound_ms = now

	var player := AudioStreamPlayer.new()
	player.name = "BrushRustle"
	player.bus = &"SFX"
	player.stream = _get_brush_stream()
	player.volume_db = -4.0
	player.pitch_scale = randf_range(0.92, 1.08)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


static func _get_brush_stream() -> AudioStreamWAV:
	if _brush_stream:
		return _brush_stream

	const MIX_RATE := 22050
	const DURATION := 0.18
	var frame_count := int(MIX_RATE * DURATION)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 0xB125
	var filtered_noise := 0.0
	for frame in frame_count:
		var progress := float(frame) / float(frame_count)
		var envelope := minf(progress / 0.025, 1.0) * pow(1.0 - progress, 1.7)
		var white_noise := random.randf_range(-1.0, 1.0)
		filtered_noise = lerpf(filtered_noise, white_noise, 0.34)
		var leaf_texture := filtered_noise * 0.78 + white_noise * 0.22
		var sample := int(clampf(leaf_texture * envelope * 23500.0, -32768.0, 32767.0))
		samples.encode_s16(frame * 2, sample)

	_brush_stream = AudioStreamWAV.new()
	_brush_stream.format = AudioStreamWAV.FORMAT_16_BITS
	_brush_stream.mix_rate = MIX_RATE
	_brush_stream.stereo = false
	_brush_stream.data = samples
	return _brush_stream
