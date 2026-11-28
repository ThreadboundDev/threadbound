extends Sprite2D
## Deliberate entry for the two-story painted house in Blue Blockout.

const INDOOR_LAYER := 32
const TRANSITION_DURATION := 0.72
const HANDOFF := 0.61
const DOOR_REACH := Vector2(84.0, 42.0)
const HOUSE_META := &"lakeside_house_interior"

@export var entry_rect := Rect2(390, 105, 701, 337)
@export var workbench: CollisionShape2D
var use_door_entry := true
var inside_player: CharacterBody2D

@onready var _door: Area2D = $Door
@onready var _glow: Sprite2D = $Door/Glow
@onready var _interior: Node2D = $Interior
@onready var _focus = $InteriorFocus

var _actor: CharacterBody2D
var _elapsed := 0.0
var _entering := false
var _start_x := 0.0
var _expected_position := Vector2.ZERO
var _cooldown := 0.0
var _saved_indoor_mask := false


func _ready() -> void:
	add_to_group("lakeside_door_houses")
	# Keep the interaction prompt and light at room scale as the house art is stretched.
	_door.scale = Vector2.ONE / global_scale
	_set_cutaway(0.0)


func is_player_inside(player: Node2D) -> bool:
	return is_instance_valid(inside_player) and inside_player == player


func can_use_door(player: CharacterBody2D) -> bool:
	if is_instance_valid(_actor) or _cooldown > 0.0 or not player.is_on_floor() or player.is_dead \
			or player.is_attacking or player.is_hurt or player.save_point_interaction_active:
		return false
	var collider := player.get_node("CollisionShape2D") as CollisionShape2D
	var foot := collider.to_global(Vector2(0.0, collider.shape.get_rect().end.y))
	var offset := (foot - _door.global_position).abs()
	return offset.x <= DOOR_REACH.x and offset.y <= DOOR_REACH.y


func request_door(player: CharacterBody2D) -> void:
	if not can_use_door(player) or not player.begin_house_door_transition(self):
		return
	_actor = player
	_entering = not is_player_inside(player)
	_elapsed = 0.0
	_start_x = player.global_position.x
	_expected_position = player.global_position
	if player.live_3d_visual:
		player.live_3d_visual.begin_house_door_transition(_entering)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _focus.occupied and (not is_instance_valid(inside_player) or inside_player.is_dead \
			or not (global_transform * entry_rect).grow(100.0).has_point(inside_player.global_position)):
		reset_entry()
	if not is_instance_valid(_actor):
		if Input.is_action_just_pressed(&"move_up"):
			var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
			if player:
				request_door(player)
		return
	if _actor.is_dead or _actor.global_position.distance_to(_expected_position) > 96.0:
		reset_entry()
		return

	_elapsed += delta
	var progress := minf(_elapsed / TRANSITION_DURATION, 1.0)
	if progress < HANDOFF:
		_actor.global_position.x = lerpf(_start_x, _door.global_position.x, smoothstep(0.0, 0.25, progress))
	elif _entering != is_player_inside(_actor):
		_set_occupant(_actor if _entering else null)
	var fade := smoothstep(0.25, 0.90, progress)
	_set_cutaway(fade if _entering else 1.0 - fade)
	if _actor.live_3d_visual:
		_actor.live_3d_visual.set_house_door_progress(progress)
	_expected_position = _actor.global_position
	if progress >= 1.0:
		_end_transition()


func _set_cutaway(weight: float) -> void:
	# Crossfade the wall through the cutaway overlay so the surrounding roof and deck remain visible.
	_interior.visible = weight > 0.0
	_interior.modulate.a = weight
	_glow.modulate.a = lerpf(1.0, 0.32, weight)


func _set_occupant(player: CharacterBody2D) -> void:
	if is_instance_valid(inside_player):
		inside_player.set_collision_mask_value(INDOOR_LAYER, _saved_indoor_mask)
		if inside_player.has_meta(HOUSE_META) and inside_player.get_meta(HOUSE_META) == self:
			inside_player.remove_meta(HOUSE_META)
	inside_player = player
	workbench.set_deferred(&"disabled", player == null)
	if player:
		_saved_indoor_mask = player.get_collision_mask_value(INDOOR_LAYER)
		player.set_collision_mask_value(INDOOR_LAYER, true)
		player.set_meta(HOUSE_META, self)
		_focus.enter(player)
	else:
		_focus.leave()


func _end_transition() -> void:
	if is_instance_valid(_actor):
		_actor.end_house_door_transition(self)
	_actor = null
	_cooldown = 0.25


func reset_entry() -> void:
	if is_instance_valid(_actor) or is_instance_valid(inside_player) or _interior.visible:
		_end_transition()
		_set_occupant(null)
		_focus.leave(true)
		_set_cutaway(0.0)


func _exit_tree() -> void:
	if is_instance_valid(_actor) and _actor.is_inside_tree():
		_actor.end_house_door_transition(self)
	if is_instance_valid(inside_player):
		inside_player.set_collision_mask_value(INDOOR_LAYER, _saved_indoor_mask)
		if inside_player.has_meta(HOUSE_META) and inside_player.get_meta(HOUSE_META) == self:
			inside_player.remove_meta(HOUSE_META)
	if is_instance_valid(workbench):
		workbench.set_deferred(&"disabled", true)
