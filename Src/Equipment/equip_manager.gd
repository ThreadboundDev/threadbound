## EquipManager (Autoload singleton)
extends Node

const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")
const BLUE_GLOVES_SCENE := preload("res://Src/Equipment/blue_gloves.tscn")
const RED_GLOVES_SCENE := preload("res://Src/Equipment/red_gloves.tscn")
const YELLOW_GLOVES_SCENE := preload("res://Src/Equipment/yellow_gloves.tscn")
const BLUE_GLOVES_SLOT := 3
const RED_GLOVES_SLOT := 6
const YELLOW_GLOVES_SLOT := 9
const ALLOWED_GLOVE_SLOTS := [0, BLUE_GLOVES_SLOT, RED_GLOVES_SLOT, YELLOW_GLOVES_SLOT]

var current_equip: Array[int] = [0, 0, 0] # [gloves, boots, chest]

var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

signal equip_changed(slot_type: int, new_equip_index: int)

func _ready() -> void:
	print("EquipManager loaded - scene-based gloves compatible")

func equip_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx > YELLOW_GLOVES_SLOT:
		return
	if not ALLOWED_GLOVE_SLOTS.has(slot_idx):
		return
	if not is_slot_unlocked(slot_idx):
		push_warning("EquipManager: %s is still locked." % get_equip_name(slot_idx))
		return

	var slot_type := slot_idx % 3
	if current_equip[slot_type] == slot_idx and slot_idx != slot_type:
		unequip_slot(slot_type)
		equip_changed.emit(slot_type, current_equip[slot_type])
		return

	current_equip[slot_type] = slot_idx

	_create_and_attach_equipment(slot_idx)
	equip_changed.emit(slot_type, slot_idx)

func is_slot_unlocked(slot_idx: int) -> bool:
	match slot_idx:
		0:
			return true
		BLUE_GLOVES_SLOT:
			return DemoProgress.has_thread(&"balance")
		RED_GLOVES_SLOT:
			return DemoProgress.has_thread(&"power")
		YELLOW_GLOVES_SLOT:
			return DemoProgress.has_thread(&"essence")
		_:
			return false

func _create_and_attach_equipment(slot_idx: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_error("EquipManager: Player not found in group 'player'")
		return

	var slot_type := slot_idx % 3

	match slot_type:
		0:
			if player.has_method("equip_gloves"):
				player.equip_gloves(_get_glove_scene(slot_idx, player))
				current_gloves = player.current_gloves
				print("Equipped gloves scene: ", get_equip_name(slot_idx))
			else:
				push_warning("EquipManager: Player cannot equip glove scenes.")

		1:
			if current_boots:
				current_boots.on_unequipped()

			current_boots = BaseBoots.new(player)
			player.current_boots = current_boots
			current_boots.on_equipped()
			print("Equipped base boots")

		2:
			if current_chest:
				current_chest.on_unequipped()

			current_chest = BaseChest.new(player)
			player.current_chest = current_chest
			current_chest.on_equipped()
			print("Equipped base chest")

func unequip_slot(slot_type: int) -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		return

	match slot_type:
		0:
			if player.has_method("equip_gloves"):
				player.equip_gloves(_get_glove_scene(0, player))
				current_gloves = player.current_gloves

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

	current_equip[slot_type] = slot_type
	print("Unequipped slot ", slot_type, " -> Base")

func unequip_all() -> void:
	unequip_slot(0)
	unequip_slot(1)
	unequip_slot(2)

func _get_glove_scene(slot_idx: int, player: Node) -> PackedScene:
	if slot_idx == BLUE_GLOVES_SLOT:
		return BLUE_GLOVES_SCENE
	if slot_idx == RED_GLOVES_SLOT:
		return RED_GLOVES_SCENE
	if slot_idx == YELLOW_GLOVES_SLOT:
		return YELLOW_GLOVES_SCENE
	var player_base_scene = player.get("base_gloves_scene") if player else null
	if player_base_scene:
		return player_base_scene
	return BASE_GLOVES_SCENE

func get_equip_name(slot_idx: int) -> String:
	match slot_idx:
		0: return "Base Gloves"
		1: return "Base Boots"
		2: return "Base Chest"
		3: return "Hermit Gloves"
		4: return "Hermit Boots"
		5: return "Hermit Chest"
		6: return "Monarch Gloves"
		7: return "Monarch Boots"
		8: return "Monarch Chest"
		9: return "Sage Gloves"
		_: return "Unknown"
