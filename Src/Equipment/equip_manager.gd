## EquipManager (Autoload singleton)
## Uses Monarch / Hermit / Sage naming to match your radial menu

extends Node

# Current equipped indices (0-8) for compatibility with radial menu
var current_equip: Array[int] = [0, 0, 0]  # [gloves, boots, chest]

# Live equipment instances attached to the Player
var current_gloves: BaseEquipment = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

signal equip_changed(slot_type: int, new_equip_index: int)

# =============================================================
# Script paths using your exact naming (MonarchGloves, HermitBoots, etc.)
# =============================================================
const EQUIP_SCRIPTS = {
	# Sage (Yellow)
	0: "res://equipment/SageGloves.gd",      # slot 0
	1: "res://equipment/SageBoots.gd",       # slot 1
	2: "res://equipment/SageChest.gd",       # slot 2
	
	# Hermit (Blue)
	3: "res://equipment/HermitGloves.gd",    # slot 3
	4: "res://equipment/HermitBoots.gd",     # slot 4
	5: "res://equipment/HermitChest.gd",     # slot 5
	
	# Monarch (Red)
	6: "res://equipment/MonarchGloves.gd",   # slot 6
	7: "res://equipment/MonarchBoots.gd",    # slot 7
	8: "res://equipment/MonarchChest.gd"     # slot 8
}

func _ready() -> void:
	print("✅ EquipManager loaded - Monarch/Hermit/Sage naming active")
	_initialize_base_equipment()

# Called by keyboard shortcuts or radial menu
func equip_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx > 8:
		return
	
	var slot_type = slot_idx / 3
	current_equip[slot_type] = slot_idx
	
	_create_and_attach_equipment(slot_idx)
	equip_changed.emit(slot_type, slot_idx)
	
	print("✅ Equipped: ", get_equip_name(slot_idx))

func _create_and_attach_equipment(slot_idx: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_error("EquipManager: Player not found in group 'player'")
		return

	var new_equip: BaseEquipment = null
	var script_path = EQUIP_SCRIPTS.get(slot_idx, "")

	# Try to load real equipment script if it exists
	if script_path and ResourceLoader.exists(script_path):
		var script = load(script_path)
		if script:
			new_equip = script.new(player)

	# Fallback to base version until you create the real scripts
	if not new_equip:
		match slot_idx / 3:
			0: new_equip = BaseGloves.new(player)
			1: new_equip = BaseBoots.new(player)
			2: new_equip = BaseChest.new(player)

	# Remove old equipment and assign new one
	match slot_idx / 3:
		0: # Gloves
			if current_gloves: current_gloves.queue_free()
			current_gloves = new_equip
			player.current_gloves = current_gloves
		1: # Boots
			if current_boots: current_boots.queue_free()
			current_boots = new_equip
			player.current_boots = current_boots
		2: # Chest
			if current_chest: current_chest.queue_free()
			current_chest = new_equip
			player.current_chest = current_chest

	if new_equip:
		new_equip.on_equipped()

# Unequip helpers (great for testing)
func unequip_slot(slot_type: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player: return

	match slot_type:
		0:
			if current_gloves: current_gloves.queue_free()
			current_gloves = BaseGloves.new(player)
			player.current_gloves = current_gloves
		1:
			if current_boots: current_boots.queue_free()
			current_boots = BaseBoots.new(player)
			player.current_boots = current_boots
		2:
			if current_chest: current_chest.queue_free()
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

func _initialize_base_equipment() -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player: return

	current_gloves = BaseGloves.new(player)
	current_boots  = BaseBoots.new(player)
	current_chest  = BaseChest.new(player)

	player.current_gloves = current_gloves
	player.current_boots  = current_boots
	player.current_chest  = current_chest

	print("Base equipment attached to Player")
