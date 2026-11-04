extends SceneTree
## Exercise the real inventory click path with every Base/Blue combination.

const PLAYER := "res://Src/Characters/Player/player.tscn"
const MENU := "res://Src/UI/GameMenu/game_menu.tscn"
const SLOTS := [&"gloves", &"boots", &"head_chest"]
const PANEL_NAMES := ["GlovesSlot", "BootsSlot", "ChestSlot"]
const OUTPUT := "res://LocalOnly/Equipment/BaseBlue/"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func capture(viewport: Viewport, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(OUTPUT + name + ".png")


func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load(PLAYER).instantiate()
	stage.add_child(player)
	for frame in 6:
		await physics_frame
	player.set_physics_process(false)
	var visual = player.get_node("Live3DVisual")
	visual.set_process(false)
	var equipment: PlayerEquipmentVisuals = visual.equipment_visuals
	check(equipment != null and PlayerEquipmentVisuals.fitted_outfits_available(), "All six fitted pieces and player rig load")
	if not equipment:
		quit(1)
		return
	var manager := root.get_node("EquipManager")
	var menu = load(MENU).instantiate()
	stage.add_child(menu)
	menu.open()
	menu._select_inventory_category(&"equipment")
	var item_cells := {}
	for cell in menu.inventory_slots_root.get_children():
		var entry: Dictionary = cell.get_meta("inventory_item", {})
		var index := int(entry.get("equip_slot_idx", -1))
		if index >= 0 and index < 6:
			item_cells[index] = cell
			var icon := cell.get_node_or_null("Icon") as TextureRect
			check(icon != null and icon.is_visible_in_tree() and icon.texture != null and icon.texture.resource_path.contains("/FittedSets/"),
				"Fitted icon in inventory for item %d" % index)
	check(item_cells.size() == 6, "Base and Blue gloves, boots and head/chest are selectable")
	if item_cells.size() < 6:
		quit(1)
		return
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var weapon = equipment._roots[&"weapon"]
	var previous := [0, 1, 2]
	for combination in 8:
		for slot_type in 3:
			var index := slot_type + (3 if combination & (1 << slot_type) else 0)
			if previous[slot_type] != index:
				item_cells[index].gui_input.emit(click)
			previous[slot_type] = index
			check(int(manager.current_equip[slot_type]) == index, "Inventory sets correct index %d" % index)
			var slot: StringName = SLOTS[slot_type]
			var item: EquipmentVisualDefinition = equipment.equipped.get(slot)
			var prefix := "blue" if index >= 3 else "base"
			check(item != null and item.item_id == StringName(prefix + "_fitted_" + slot), "Correct visible item for " + String(slot))
			var panel = menu.equipment_slots_root.get_node(PANEL_NAMES[slot_type])
			check(int(panel.get_meta("inventory_item", {}).get("equip_slot_idx", -1)) == index, "Equipped panel follows " + String(slot))
			for mesh in equipment._roots[slot].find_children("*", "MeshInstance3D", true, false):
				check(mesh.get_node_or_null(mesh.skeleton) == visual._skeleton, "Mesh bound to the live rig")
		check(equipment._roots[&"weapon"] == weapon, "Clothing swaps preserve sword and shield")
		check(equipment._roots[&"head_chest"].find_child("Shared_Wooden_Head", true, false) != null,
			"Head / Chest includes the master wooden head")
		check(equipment._roots[&"gloves"].find_child("Shared_Wooden_Hands", true, false) != null,
			"Glove pair includes the master wooden hands")
		for mesh in visual._model_root.find_children("Doll_Covered_*", "MeshInstance3D", true, false):
			check(not mesh.visible, "Legacy body section hidden under fitted outfits")
		var legacy := visual._model_root.find_child("Threadborne_Doll", true, false) as MeshInstance3D
		check(legacy != null and not legacy.visible, "Legacy exposed body hidden")
		check(equipment.get_grapple_origin().is_finite(), "Glove selection supplies a live grapple origin")
		equipment.set_grapple_stowed(false)
		var hook = equipment._roots[&"gloves"].find_child("Grapple_Needle_*", true, false)
		check(hook != null and not hook.visible, "Only the stowed hook retracts during launch")
		equipment.set_grapple_stowed(true)
		check(hook != null and hook.visible, "Hook returns to the bracer")
		if combination in [0, 5, 7]:
			for action in [&"idle_4", &"run_1", &"casting_2"]:
				visual._play_action(action, &"", 0, true, 1, 0)
				var animation: AnimationPlayer = visual._animation_player
				var clip := animation.current_animation
				check(not clip.is_empty(), "Loaded pose for %s" % action)
				if not clip.is_empty():
					animation.seek(animation.get_animation(clip).length * .36, true)
					animation.advance(0)
					animation.pause()
				check(visual.get_grapple_origin_player_offset().is_finite(), "Fitted launch anchor during %s" % action)
				await capture(visual._viewport, "swap_%d_%s" % [combination, action])
		if combination in [0, 7]:
			var gloves = player.current_gloves
			var launch: Vector2 = player.to_global(visual.get_grapple_origin_player_offset())
			gloves._start_grapple_fire()
			check(gloves.grapple_start_position.distance_to(launch) < .01, "Actual cast launches from fitted glove anchor")
			visual._process(0.0)
			check(not hook.visible, "Actual cast hides stowed hook")
			gloves._reset_active_grapple_visuals()
			visual._process(0.0)
			check(hook.visible, "Actual cast reset restores stowed hook")
		await process_frame
	menu._hide_inventory_tooltip()
	await capture(root, "inventory_blue")
	if PlayerEquipmentVisuals.mask_preview_available(&"loomed") and PlayerEquipmentVisuals.mask_preview_available(&"hermit"):
		var mask_cells := {}
		for cell in menu.inventory_slots_root.get_children():
			var entry: Dictionary = cell.get_meta("inventory_item", {})
			if entry.has("mask_id"):
				mask_cells[entry["mask_id"]] = cell
				var icon := cell.get_node_or_null("Icon") as TextureRect
				check(icon != null and icon.is_visible_in_tree() and icon.texture != null, "Mask inventory icon is visible")
		check(mask_cells.size() == 2, "Both masks are selectable")
		if mask_cells.size() == 2:
			for id in PlayerEquipmentVisuals.MASK_TEST_IDS:
				mask_cells[id].gui_input.emit(click)
				var mask := equipment.equipped.get(&"mask_preview") as EquipmentVisualDefinition
				check(mask != null and mask.item_id == id, "Equips mask " + String(id))
				if mask:
					for mesh in equipment._roots[&"mask_preview"].find_children("*", "MeshInstance3D", true, false):
						check(mesh.get_node_or_null(mesh.skeleton) == visual._skeleton, "Mask mesh follows live rig")
					await capture(visual._viewport, "shared_head_blue_%s" % id)
			item_cells[2].gui_input.emit(click)
			check(equipment.equipped.has(&"mask_preview"), "Head / Chest swap keeps the mask")
			await capture(visual._viewport, "shared_head_base_hermit")
			mask_cells[&"hermit"].gui_input.emit(click)
			check(not equipment.equipped.has(&"mask_preview"), "Click again removes the mask")
	var report := {"checks": checks, "failures": failures, "combinations": 8}
	print("BASE_BLUE_EQUIPMENT ", JSON.stringify(report))
	var file := FileAccess.open(OUTPUT + "godot_swap_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	stage.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
