class_name BaseBoots
extends BaseEquipment

@export var base_jump_force: float = 1040.0
@export var air_jump_force: float = 680.0
@export var wall_jump_force: float = 700.0
@export var wall_jump_up_force: float = 840.0

func _init(_player = null):
	super(_player)
	slot_name = "Boots"

func handle_primary(delta: float, state: ActionState) -> void:
	if state == ActionState.PRESSED:
		if player.is_on_floor() or player.coyote_timer > 0.0:
			_perform_normal_jump()
		elif player.air_jump_available:
			_perform_air_jump()

func perform_wall_jump() -> void:
	var wall_normal = player.get_wall_normal()
	player.velocity.x = wall_normal.x * wall_jump_force
	player.velocity.y = -wall_jump_up_force
	
	player.has_wall_jumped = true
	player.air_jump_available = true
	player.is_wall_clinging = false
	player.wall_cling_timer = 0.0

func _perform_normal_jump() -> void:
	player.velocity.y = -base_jump_force
	player.coyote_timer = 0.0
	player.has_wall_jumped = false
	player.air_jump_available = true

func _perform_air_jump() -> void:
	player.velocity.y = -air_jump_force
	player.air_jump_available = false
	player.is_wall_clinging = false
	player.wall_cling_timer = 0.0
