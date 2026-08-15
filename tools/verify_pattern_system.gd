extends Node

class FakePlayer:
	extends Node
	var thread_knot_count := 20

	func can_weave_stat_upgrade(cost: int) -> bool:
		return thread_knot_count >= cost

var _failures := 0

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var pattern := load("res://Src/Equipment/Patterns/merchant_knot_pattern.tres") as EquipmentPattern
	_check(pattern != null, "Pattern resource loads")
	if not pattern:
		get_tree().quit(1)
		return
	_check(pattern.id == &"merchant_knot", "Pattern has a stable ID")
	_check(is_equal_approx(pattern.action_point_recharge_multiplier, 1.1), "Pattern grants 10% AP recharge")
	_check(is_equal_approx(pattern.momentum_generation_multiplier, 1.1), "Pattern grants 10% momentum generation")
	_check(pattern.inventory_icon != null and pattern.hud_overlay != null and pattern.textile_texture != null, "Pattern visual assets load")

	var previous_owned := EquipManager.owned_pattern_ids.duplicate()
	var previous_pattern := EquipManager.current_pattern
	EquipManager.owned_pattern_ids.clear()
	EquipManager.current_pattern = null

	var merchant_script := load("res://Src/Environment/Merchants/follower_merchant.gd") as Script
	var merchant := merchant_script.new() as FollowerMerchant
	var player := FakePlayer.new()
	_check(merchant.try_purchase(&"merchant_knot_pattern", player, 12, true), "Merchant sells the Pattern")
	_check(player.thread_knot_count == 8, "Pattern purchase spends 12 Thread Knots")
	_check(EquipManager.owns_pattern(&"merchant_knot"), "Purchase unlocks Pattern ownership")
	_check(merchant.has_purchased(&"merchant_knot_pattern"), "Purchased Pattern is sold out")
	_check(not merchant.try_purchase(&"merchant_knot_pattern", player, 12, true), "Pattern cannot be purchased twice")

	_check(EquipManager.equip_pattern(&"merchant_knot"), "Owned Pattern equips")
	_check(EquipManager.get_current_pattern() == pattern, "Equipped Pattern is tracked")
	_check(EquipManager.equip_pattern(&"merchant_knot"), "Selecting equipped Pattern unequips it")
	_check(EquipManager.get_current_pattern() == null, "Pattern slot supports unequip")
	EquipManager.equip_pattern(&"merchant_knot")
	var player_scene := load("res://Src/Characters/Player/player.tscn") as PackedScene
	var runtime_player := player_scene.instantiate()
	add_child(runtime_player)
	await get_tree().process_frame
	runtime_player.apply_equipment_pattern(pattern)
	var clothing_overlay := runtime_player.get_node_or_null("PatternClothingOverlay") as AnimatedSprite2D
	_check(clothing_overlay != null and clothing_overlay.visible, "Pattern creates a live clothing overlay")
	_check(is_equal_approx(runtime_player.get_pattern_action_point_recharge_multiplier(), 1.1), "Player exposes the Pattern AP modifier")
	_check(is_equal_approx(runtime_player.get_pattern_momentum_generation_multiplier(), 1.1), "Player exposes the Pattern momentum modifier")

	var hud_scene := load("res://Src/UI/combat_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate() as CombatHUD
	add_child(hud)
	await get_tree().process_frame
	hud.set_pattern_texture(pattern.hud_overlay, true)
	var hud_overlay := hud.get_node_or_null("HUDRoot/IdentityLayers/PatternOverlay") as TextureRect
	_check(hud_overlay != null and hud_overlay.visible, "Equipped Pattern appears on the HUD")
	var identity_base := hud.get_node("HUDRoot/IdentityLayers/IdentityBase") as TextureRect
	_check(identity_base.modulate == hud.default_identity_color, "HUD keeps the light identity weave beneath the Pattern")

	var menu_scene := load("res://Src/UI/GameMenu/game_menu.tscn") as PackedScene
	var menu := menu_scene.instantiate() as GameMenu
	add_child(menu)
	await get_tree().process_frame
	var inventory_pointer := menu.get_node_or_null(
		"MenuRoot/Pages/InventoryPage/InventorySlots/SelectionPointer"
	) as TextureRect
	_check(inventory_pointer != null, "Inventory creates the established menu selection pointer")
	if inventory_pointer:
		_check(inventory_pointer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Inventory pointer never blocks slot input")
		_check(inventory_pointer.flip_h, "Inventory pointer faces inward toward the selected slot")
		_check(inventory_pointer.size == Vector2(96.0, 64.0), "Inventory pointer uses its compact editor-authored size")
		var balance_slot := menu.get_node("MenuRoot/Pages/InventoryPage/InventorySlots/BalanceSlot") as Control
		menu._inventory_focused_slot = balance_slot
		menu._update_inventory_selection_pointer()
		var expected_tip := Vector2(
			balance_slot.global_position.x + menu.inventory_pointer_slot_offset.x,
			balance_slot.global_position.y + balance_slot.size.y * 0.5 + menu.inventory_pointer_slot_offset.y
		)
		var actual_tip := inventory_pointer.global_position + Vector2(
			inventory_pointer.size.x * menu.inventory_pointer_tip_x_ratio,
			inventory_pointer.size.y * menu.inventory_pointer_tip_y_ratio
		)
		_check(actual_tip.distance_to(expected_tip) <= 0.1, "Inventory pointer tip tracks the selected slot center")
	var pattern_slot := menu.get_node_or_null("MenuRoot/Pages/InventoryPage/EquipmentSlots/PatternSlot") as Control
	_check(pattern_slot != null, "Inventory has a Pattern equipment slot")
	if pattern_slot:
		_check(pattern_slot.size == Vector2(110.0, 110.0), "Pattern slot uses the compact portrait-safe layout")
		_check(pattern_slot.position.y == 40.0, "Pattern slot sits in the space above the portrait head")
		var frame := pattern_slot.get_node("Frame") as TextureRect
		var icon := pattern_slot.get_node("Icon") as TextureRect
		_check(absf(icon.get_rect().get_center().y - frame.get_rect().get_center().y) <= 1.0, "Pattern emblem is vertically centered in its frame")
	var portrait_pattern := menu.get_node_or_null("MenuRoot/Pages/InventoryPage/CharacterPanel/PatternPortraitOverlay") as AnimatedSprite2D
	_check(portrait_pattern != null and portrait_pattern.visible, "Inventory portrait displays the equipped Pattern")
	var visible_items: Array[Dictionary] = menu._get_visible_inventory_items()
	_check(visible_items.any(func(item: Dictionary) -> bool: return item.get("pattern_id", &"") == &"merchant_knot"), "Owned Pattern appears in equipment inventory")

	menu.queue_free()
	hud.queue_free()
	if runtime_player.current_boots:
		runtime_player.current_boots.free()
		runtime_player.current_boots = null
	if runtime_player.current_chest:
		runtime_player.current_chest.free()
		runtime_player.current_chest = null
	runtime_player.queue_free()
	merchant.free()
	player.free()
	await get_tree().process_frame
	EquipManager.owned_pattern_ids.assign(previous_owned)
	EquipManager.current_pattern = previous_pattern
	if _failures == 0:
		print("Pattern system verification passed.")
	get_tree().paused = false
	get_tree().quit(_failures)

func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Pattern system verification failed: %s" % label)
