class_name BaseChest
extends BaseEquipment

@export var dash_speed: float = 1150.0
@export var dash_duration: float = 0.30
@export var dash_cooldown: float = 0.65
@export var dash_iframe_grace: float = 0.06

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1

func _init(_player = null):
	super(_player)
	slot_name = "Chest"

# Use the ActionState from BaseEquipment
func handle_secondary(_delta: float, state: ActionState) -> void:
	if state == ActionState.PRESSED:
		_start_dash()

func _start_dash() -> bool:
	if not player or is_dashing or dash_cooldown_timer > 0.0:
		return false
	if player.has_method("can_start_dash") and not player.can_start_dash():
		return false
	if player.has_method("spend_action_points") and not player.spend_action_points(1):
		return false
	if player.has_method("prepare_for_dash"):
		player.prepare_for_dash()

	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = player.last_direction if player.last_direction != 0 else 1
	AudioManager.play_sfx(&"player_dash_evade")
	if player.has_method("start_dash_iframe"):
		player.start_dash_iframe(
			dash_duration + maxf(0.0, dash_iframe_grace),
			Vector2(float(dash_direction), 0.0)
		)
	if player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Dash")
	return true

func process_passive(delta: float) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	if is_dashing:
		dash_timer = maxf(0.0, dash_timer - delta)
		var speed_multiplier: float = player.get_momentum_dash_speed_multiplier() if player.has_method("get_momentum_dash_speed_multiplier") else 1.0
		player.velocity.x = dash_direction * dash_speed * speed_multiplier
		
		if dash_timer <= 0.0:
			is_dashing = false

func stop_dash_on_enemy_contact() -> void:
	if not is_dashing:
		return
	is_dashing = false
	dash_timer = 0.0
	if player:
		player.velocity.x = 0.0

func get_dash_cooldown_remaining() -> float:
	return dash_cooldown_timer

func is_dash_active() -> bool:
	return is_dashing
