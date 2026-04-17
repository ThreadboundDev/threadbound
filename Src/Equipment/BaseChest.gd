class_name BaseChest
extends BaseEquipment

func _init(_player = null):
	super(_player)
	slot_name = "Chest"

# Base chest does almost nothing — future pieces add passives like better air control, slow fall, etc.
func process_passive(delta: float) -> void:
	pass
