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
	is_dashing = true
	dash_timer = dash_duration
	dash_direction = player.last_direction
	player.start_ability_cooldown(dash_cooldown)
	print("Base Chest: Dash activated")

func process_passive(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		player.velocity.x = dash_direction * dash_speed
		
		if dash_timer <= 0.0:
			is_dashing = false
