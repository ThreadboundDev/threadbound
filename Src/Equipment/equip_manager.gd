## EquipManager (Autoload singleton)
extends Node

var current_equip: Array[int] = [0, 0, 0] # [gloves, boots, chest]

var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

signal equip_changed(slot_type: int, new_equip_index: int)

func _ready() -> void:
	print("✅ EquipManager loaded - scene-based gloves compatible")

func equip_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx > 8:
		return

	var slot_type := int(slot_idx / 3)
	current_equip[slot_type] = slot_idx

	_create_and_attach_equipment(slot_idx)
	equip_changed.emit(slot_type, slot_idx)

func _create_and_attach_equipment(slot_idx: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_error("EquipManager: Player not found in group 'player'")
		return

	var slot_type := int(slot_idx / 3)

	match slot_type:
		0:
			# Gloves are now scene-based.
			if player.has_method("equip_gloves") and player.base_gloves_scene:
				player.equip_gloves(player.base_gloves_scene)
				current_gloves = player.current_gloves
				print("✅ Equipped gloves scene")
			else:
				push_warning("EquipManager: No glove scene assigned on Player.")

		1:
			# Boots are still script-based for now.
			if current_boots:
				current_boots.on_unequipped()

			current_boots = BaseBoots.new(player)
			player.current_boots = current_boots
			current_boots.on_equipped()
			print("✅ Equipped base boots")

		2:
			# Chest is still script-based for now.
			if current_chest:
				current_chest.on_unequipped()

			current_chest = BaseChest.new(player)
			player.current_chest = current_chest
			current_chest.on_equipped()
			print("✅ Equipped base chest")

func unequip_slot(slot_type: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		return

	match slot_type:
		0:
			if player.has_method("unequip_gloves"):
				player.unequip_gloves()
			current_gloves = null

		1:
			if current_boots:
				current_boots.on_unequipped()
			current_boots = BaseBoots.new(player)
			player.current_boots = current_boots

		2:
			if current_chest:
				current_chest.on_unequipped()
			current_chest = BaseChest.new(player)
			player.current_chest = current_chest

	print("Unequipped slot ", slot_type, " → Base")

func unequip_all() -> void:
	unequip_slot(0)
	unequip_slot(1)
	unequip_slot(2)

func get_equip_name(slot_idx: int) -> String:
	match slot_idx:
		0: return "Sage Gloves"
		1: return "Sage Boots"
		2: return "Sage Chest"
		3: return "Hermit Gloves"
		4: return "Hermit Boots"
		5: return "Hermit Chest"
		6: return "Monarch Gloves"
		7: return "Monarch Boots"
		8: return "Monarch Chest"
		_: return "Unknown"
