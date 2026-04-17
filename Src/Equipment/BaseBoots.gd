class_name BaseBoots
extends BaseEquipment

@export var base_jump_force: float = 720.0

func _init(_player = null):
	super(_player)
	slot_name = "Boots"

func handle_primary(delta: float, state: BaseArchetype.ActionState) -> void:
	if state == BaseArchetype.ActionState.PRESSED:
		if player.is_on_floor() or player.coyote_timer > 0.0:
			player.velocity.y = -base_jump_force
			player.coyote_timer = 0.0
