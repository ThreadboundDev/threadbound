extends SceneTree
## Verify the actual paused inventory, independent idle and live gear/mask updates.

const OUTPUT := "res://LocalOnly/Equipment/InventoryPreview/"
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		for menu in get_nodes_in_group("game_menu"):
			menu._hide_inventory_tooltip()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT+name+".png")


func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	for frame in 6:
		await physics_frame
	player.set_physics_process(false)
	var source = player.get_node("Live3DVisual")
	source.set_process(false)
	source._play_action(&"run_1", &"", 0, true, 1, 0)
	source._animation_player.seek(.2, true)
	source._animation_player.pause()
	var position_before: Vector2 = player.position
	var animation_before: StringName = source._animation_player.current_animation
	var time_before: float = source._animation_player.current_animation_position
	var hand: int = source._skeleton.find_bone("hand.R")
	var hand_before: Transform3D = source._skeleton.get_bone_global_pose(hand)
	var menu = load("res://Src/UI/GameMenu/game_menu.tscn").instantiate()
	stage.add_child(menu)
	menu.open()
	menu._select_inventory_category(&"equipment")
	var preview = menu._inventory_character_preview
	check(preview != null, "Live inventory portrait initializes")
	if not preview:
		quit(1)
		return
	check(paused, "Gameplay stays paused while the inventory is open")
	check(not menu.inventory_player_portrait.visible, "Retired sprite portrait is hidden")
	check(preview.texture == preview.viewport.get_texture(), "Portrait displays the independent viewport")
	check(preview.skeleton != source._skeleton and preview.animation_player != source._animation_player,
		"Portrait has its own skeleton and animation clock")
	check(preview.viewport.find_world_3d() != source._viewport.find_world_3d(), "Portrait has its own 3D world")
	check(get_nodes_in_group("player").size() == 1, "Portrait does not create a second gameplay character")
	check(preview.animation_player.current_animation == source._clips[&"idle_4"], "Portrait uses the current upright idle")
	var idle_before: float = preview.animation_player.current_animation_position
	for frame in 20:
		await process_frame
	check(not is_equal_approx(idle_before, preview.animation_player.current_animation_position), "Idle animates while gameplay is paused")
	await capture("inventory_base_idle")
	var cells := {}
	for cell in menu.inventory_slots_root.get_children():
		var index: int = cell.get_meta("inventory_item", {}).get("equip_slot_idx", -1)
		if index >= 0 and index < 6:
			cells[index] = cell
	check(cells.size() == 6, "All six fitted gear items are available for preview")
	var manager := root.get_node("EquipManager")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	for combination in 8:
		for slot in 3:
			var index := slot+(3 if combination & (1 << slot) else 0)
			if manager.current_equip[slot] != index:
				cells[index].gui_input.emit(click)
			var name: StringName = PlayerEquipmentVisuals.SLOTS[slot]
			check(preview.equipment.equipped[name] == source.equipment_visuals.equipped[name], "Portrait mirrors inventory click for %s, loadout %d" % [name, combination])
		for mesh: MeshInstance3D in preview.equipment.find_children("*", "MeshInstance3D", true, false):
			check(mesh.get_node_or_null(mesh.skeleton) == preview.skeleton, "Preview gear binds to the preview skeleton")
		check(preview.equipment.equipped[&"weapon"] == source.equipment_visuals.equipped[&"weapon"], "Portrait preserves equipped weapons")
		var cloth: EquipmentClothMotion = preview.equipment.cloth_motion
		check(cloth != null and cloth != source.equipment_visuals.cloth_motion, "Portrait has an independent cloth simulation")
		if cloth:
			check(cloth.profile == (&"blue" if combination & 4 else &"base") and cloth.simulator.active, "Portrait selects the equipped cloth profile while paused")
		for mesh: MeshInstance3D in preview.equipment.find_children("*", "MeshInstance3D", true, false):
			if mesh.get_meta("outline_only",false):
				check((mesh.material_override as ShaderMaterial).shader == source.MESH_OUTLINE_SHADER,"Portrait uses the same object outline shader")
		if combination == 7:
			for frame in 20:
				await process_frame
			await capture("inventory_blue_idle")
	var base_slots := ["GlovesSlot", "BootsSlot", "ChestSlot"]
	var gameplay_hands := source._model_root.find_child("Doll_Covered_Hands", true, false) as MeshInstance3D
	var preview_hands := preview.model.find_child("Doll_Covered_Hands", true, false) as MeshInstance3D
	check(gameplay_hands != null and preview_hands != null and gameplay_hands.mesh == preview_hands.mesh,
		"Gameplay and inventory use the same repaired bare hands")
	if not gameplay_hands or not preview_hands:
		quit(1)
		return
	check(not gameplay_hands.visible and not preview_hands.visible, "Fitted gloves cover the bare hands")
	var abilities: Array[Node] = [player.current_boots, player.current_chest]
	for slot in base_slots.size():
		cells[slot].gui_input.emit(click)
		var gear_slot := menu.equipment_slots_root.get_node(base_slots[slot]) as Control
		if slot == 1:
			menu._set_inventory_focus(gear_slot)
			var accept := InputEventJoypadButton.new()
			accept.button_index = JOY_BUTTON_A
			accept.pressed = true
			check(menu._handle_inventory_controller_navigation(accept), "Controller confirms on equipped boots")
		else:
			gear_slot.gui_input.emit(click)
		var name: StringName = PlayerEquipmentVisuals.SLOTS[slot]
		check(manager.current_equip[slot] == manager.EMPTY_SLOT, "Inventory clears Base " + String(name))
		check(not source.equipment_visuals.equipped.has(name), "Gameplay removes Base " + String(name))
		check(not preview.equipment.equipped.has(name), "Preview removes Base " + String(name))
		check(gear_slot.get_node("Icon").texture == null, "Equipped icon clears for " + String(name))
	check(is_instance_valid(player.current_gloves) and player.current_gloves.scene_file_path == manager.BASE_GLOVES_SCENE.resource_path, "Empty gloves retain the Base grapple")
	check(player.current_boots == abilities[0] and player.current_chest == abilities[1], "Removing gear retains jump and dash")
	check(preview.equipment.equipped.has(&"weapon"), "Removing Base gear keeps the weapon")
	check(not preview.equipment.cloth_motion.simulator.active, "Removing head/chest stops its cloth simulation")
	check(gameplay_hands.visible and preview_hands.visible, "Removing gloves shows the repaired bare hands")
	await capture("inventory_unequipped")
	for slot in base_slots.size():
		cells[slot].gui_input.emit(click)
		var name: StringName = PlayerEquipmentVisuals.SLOTS[slot]
		check(manager.current_equip[slot] == slot and preview.equipment.equipped.has(name), "Base " + String(name) + " can be re-equipped from the bag")
	if PlayerEquipmentVisuals.mask_preview_available(&"hermit"):
		menu._try_equip_inventory_item({"mask_id": &"hermit"})
		check(preview.equipment.equipped.get(&"mask_preview") == source.equipment_visuals.equipped.get(&"mask_preview"), "Equipped mask appears on the portrait")
		await capture("inventory_blue_hermit_mask")
		menu._try_equip_inventory_item({"mask_id": &"hermit"})
		check(not preview.equipment.equipped.has(&"mask_preview"), "Removed mask disappears from the portrait")
	menu._select_tab(1, true)
	check(preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Hidden inventory stops rendering its portrait")
	var hidden_time: float = preview.animation_player.current_animation_position
	for frame in 10:
		await process_frame
	check(is_equal_approx(hidden_time, preview.animation_player.current_animation_position), "Hidden inventory stops advancing idle")
	menu._select_tab(0, true)
	check(preview.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "Returning to inventory resumes the portrait")
	check(player.position.is_equal_approx(position_before) and source._skeleton.get_bone_global_pose(hand).is_equal_approx(hand_before), "Preview leaves gameplay position and pose unchanged")
	check(source._animation_player.current_animation == animation_before
		and is_equal_approx(source._animation_player.current_animation_position, time_before), "Preview leaves gameplay animation unchanged")
	menu._close()
	await process_frame
	check(not paused and not is_instance_valid(preview), "Closing inventory resumes gameplay and frees the preview")
	# The legacy abilities are Nodes created outside the tree by the fixture player.
	for property: StringName in [&"current_boots", &"current_chest"]:
		var ability: Node = player.get(property)
		if is_instance_valid(ability) and ability.get_parent() == null:
			ability.free()
		player.set(property, null)
	var report := {"checks": checks, "failures": failures, "loadouts": 8}
	print("INVENTORY_PREVIEW ", JSON.stringify(report))
	var file := FileAccess.open(OUTPUT+"verification.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	stage.queue_free()
	await process_frame
	await process_frame
	call_deferred("quit", 0 if failures.is_empty() else 1)
