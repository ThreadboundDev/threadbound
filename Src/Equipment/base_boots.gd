class_name BaseBoots
extends BaseEquipment

@export var base_jump_force: float = 820.0
@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0

func _init(_player = null):
	super(_player)
	slot_name = "Boots"

func handle_primary(delta: float, state: ActionState) -> void:
	if state == ActionState.PRESSED:
		if player.is_on_floor() or player.coyote_timer > 0.0:
			_perform_normal_jump()

func perform_wall_jump() -> void:
	var wall_normal = player.get_wall_normal()
	player.velocity.x = wall_normal.x * wall_jump_force
	player.velocity.y = -wall_jump_up_force
	
	player.has_wall_jumped = true
	player.is_wall_clinging = false
	player.wall_cling_timer = 0.0

func _perform_normal_jump() -> void:
	player.velocity.y = -base_jump_force
	player.coyote_timer = 0.0
	player.has_wall_jumped = false
