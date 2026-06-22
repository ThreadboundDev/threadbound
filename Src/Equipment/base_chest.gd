class_name BaseChest
extends BaseEquipment

@export var dash_speed: float = 950.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.65

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: int = 1

func _init(_player = null):
	super(_player)
	slot_name = "Chest"

# Use the ActionState from BaseEquipment
func handle_secondary(delta: float, state: ActionState) -> void:
	if state == ActionState.PRESSED and not is_dashing:
		_start_dash()

func _start_dash() -> void:
	if is_dashing: return
	if player.has_method("spend_action_points") and not player.spend_action_points(1):
		return

	is_dashing = true
	dash_timer = dash_duration
	dash_direction = player.last_direction
	if player.has_method("start_dash_iframe"):
		player.start_dash_iframe(dash_duration)
	if player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Dash")
	player.start_ability_cooldown(dash_cooldown)
	print("Base Chest: Dash activated")

func process_passive(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		var speed_multiplier: float = player.get_momentum_dash_speed_multiplier() if player.has_method("get_momentum_dash_speed_multiplier") else 1.0
		player.velocity.x = dash_direction * dash_speed * speed_multiplier
		
		if dash_timer <= 0.0:
			is_dashing = false
