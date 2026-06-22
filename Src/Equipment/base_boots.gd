class_name BaseBoots
extends BaseEquipment

@export var base_jump_force: float = 1040.0
@export var air_jump_force: float = 680.0
@export var wall_jump_force: float = 700.0
@export var wall_jump_up_force: float = 840.0

func _init(_player = null):
	super(_player)
	slot_name = "Boots"

func handle_primary(_delta: float, state: ActionState) -> void:
	if state == ActionState.PRESSED:
		if player.is_on_floor() or player.coyote_timer > 0.0:
			_perform_normal_jump()
		elif player.air_jump_available:
			_perform_air_jump()

func perform_wall_jump() -> void:
	var wall_normal: Vector2 = player.get_wall_normal()
	var jump_multiplier: float = player.get_momentum_jump_multiplier() if player.has_method("get_momentum_jump_multiplier") else 1.0
	player.velocity.x = wall_normal.x * wall_jump_force
	player.velocity.y = -wall_jump_up_force * jump_multiplier
	
	player.has_wall_jumped = true
	player.air_jump_available = true
	player.is_wall_clinging = false
	player.wall_cling_timer = 0.0
	if player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Jump", 0.7)

func _perform_normal_jump() -> void:
	var jump_multiplier: float = player.get_momentum_jump_multiplier() if player.has_method("get_momentum_jump_multiplier") else 1.0
	player.velocity.y = -base_jump_force * jump_multiplier
	player.coyote_timer = 0.0
	player.has_wall_jumped = false
	player.air_jump_available = true
	if player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Jump", 0.55)

func _perform_air_jump() -> void:
	if player.has_method("spend_action_points") and not player.spend_action_points(1):
		return

	var jump_multiplier: float = player.get_momentum_jump_multiplier() if player.has_method("get_momentum_jump_multiplier") else 1.0
	player.velocity.y = -air_jump_force * jump_multiplier
	player.air_jump_available = false
	player.is_wall_clinging = false
	player.wall_cling_timer = 0.0
	if player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Jump", 1.35)
