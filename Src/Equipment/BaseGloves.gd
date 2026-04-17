class_name BaseGloves
extends BaseEquipment

func _init(_player = null):
	super(_player)
	slot_name = "Gloves"

# Base grapple = short universal raycast thread (always available, weak)
func thread_mechanic(delta: float) -> void:
	# TODO: Simple short-range grapple hook for traversal
	# Will be heavily overridden by color-specific gloves
	if Input.is_action_just_pressed("Traversal"):
		print("Base Gloves: weak universal thread tether")
		# placeholder raycast logic here later
	pass
