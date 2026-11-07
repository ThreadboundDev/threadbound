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
	for strap_name in ["Shield_elbow_strap", "Shield_wrist_strap"]:
		var strap := weapon.find_child(strap_name, true, false) as MeshInstance3D
		check(strap != null, "Shield has " + strap_name)
		if strap:
			check(strap.get_node_or_null(strap.skeleton) == visual._skeleton, "Strap uses the live rig")
			var weighted_bones: Dictionary = {}
			for surface in strap.mesh.get_surface_count():
				var arrays := strap.mesh.surface_get_arrays(surface)
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				for index in weights.size():
					if weights[index] > 0.0:
						weighted_bones[strap.skin.get_bind_name(bones[index])] = true
			check(weighted_bones.size() == 1 and weighted_bones.has(&"forearm.L"), "Strap follows the forearm through hand motion")
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
		if equipment.cloth_motion:
			check(equipment.cloth_motion.simulator.active and equipment.cloth_motion.profile == (&"blue" if combination & 4 else &"base"), "Cloth profile follows Head / Chest selection")
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
		for facing in [1,-1]:
			player.last_direction = facing
			visual._display.flip_h = facing < 0
			for action in [&"idle_4", &"idle_2", &"run_1", &"casting_2", &"crouch_idle_1", &"jump_1", &"slash_2", &"grapple_swinging_1"]:
				visual._play_action(action, &"", 0, true, 1, 0)
				var animation: AnimationPlayer = visual._animation_player
				var clip := animation.current_animation
				check(not clip.is_empty(), "Loaded pose for %s" % action)
				if not clip.is_empty():
					animation.seek(animation.get_animation(clip).length * .36, true)
					animation.advance(0)
					animation.pause()
				check(visual.get_grapple_origin_player_offset().is_finite(), "Fitted launch anchor during %s" % action)
				check(visual._skeleton.get_bone_global_pose(visual._skeleton.find_bone("hand.L")).is_finite(), "Finite mixed-loadout pose")
				if facing == 1 and combination in [0,5,7] and action in [&"idle_4",&"run_1",&"casting_2"]:
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
	await verify_sleeve_motion(player,visual,manager)
	var report := {"checks": checks, "failures": failures, "combinations": 8}
	print("BASE_BLUE_EQUIPMENT ", JSON.stringify(report))
	var file := FileAccess.open(OUTPUT + "godot_swap_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	# These legacy ability objects are created outside the tree by the player.
	# Release the fixture's instances before exiting the standalone test.
	for property: StringName in [&"current_boots",&"current_chest"]:
		var ability: Node = player.get(property)
		if is_instance_valid(ability) and ability.get_parent() == null:
			ability.free()
		player.set(property,null)
	stage.queue_free()
	await process_frame
	await process_frame
	call_deferred("quit",0 if failures.is_empty() else 1)


func verify_sleeve_motion(player: Node2D, visual: Node, manager: Node) -> void:
	paused = false
	for slot in 3:
		if manager.current_equip[slot] != slot+3:
			manager.equip_item(slot+3)
	var cloth: EquipmentClothMotion = visual.equipment_visuals.cloth_motion
	check(cloth != null, "Blue equips the cloth motion prototype")
	if not cloth:
		return
	var bone_count: int = visual._skeleton.get_bone_count()
	check(cloth.simulator.setting_count == 8, "Four sleeve and four hanging cloth chains are installed")
	var probes: Array[Dictionary] = []
	for mesh: MeshInstance3D in visual.equipment_visuals._roots[&"head_chest"].find_children("*","MeshInstance3D",true,false):
		if mesh.get_meta("outline_only",false):
			continue
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			for vertex in range(0,vertices.size(),8):
				var influences: Array[Dictionary] = []
				var cloth_weight := 0.0
				for influence in 4:
					var weight := weights[vertex*4+influence]
					if weight <= 0.0:
						continue
					var bind := bones[vertex*4+influence]
					var bone := cloth.skeleton.find_bone(mesh.skin.get_bind_name(bind))
					if String(cloth.skeleton.get_bone_name(bone)).begins_with("cloth_sleeve_"):
						cloth_weight += weight
					influences.append({"bone":bone,"bind":mesh.skin.get_bind_pose(bind),"weight":weight})
				if cloth_weight > .5:
					probes.append({"point":vertices[vertex],"influences":influences})
	check(probes.size()>0,"Sleeve fabric has spring bone weights")
	var samples := {"frames":0, "max_offset":0.0, "max_link_error":0.0, "finite":true, "min_clearance":INF,
		"fabric_penetration":0.0,"rigid_penetration":0.0}
	var callback := func() -> void:
		if not cloth.simulator.active or cloth.warming_up:
			return
		samples.frames += 1
		var capsule := cloth.simulator.get_node("SleeveTorsoCollider") as SpringBoneCollisionCapsule3D
		var rigid_poses := {}
		for bone: int in cloth._bones:
			if not String(cloth.skeleton.get_bone_name(bone)).begins_with("cloth_sleeve_"):
				continue
			var pose := cloth.skeleton.get_bone_global_pose(bone)
			samples.finite = samples.finite and pose.origin.is_finite() and pose.basis.is_finite()
			var rest := cloth.skeleton.get_bone_rest(bone)
			var parent := cloth.skeleton.get_bone_parent(bone)
			while String(cloth.skeleton.get_bone_name(parent)).begins_with("cloth_sleeve_"):
				rest = cloth.skeleton.get_bone_rest(parent)*rest
				parent = cloth.skeleton.get_bone_parent(parent)
			rest = cloth.skeleton.get_bone_global_pose(parent)*rest
			rigid_poses[bone] = rest
			samples.max_offset = maxf(samples.max_offset,pose.origin.distance_to(rest.origin))
			if String(cloth.skeleton.get_bone_name(bone)).ends_with("_0"):
				continue
			var link := pose.origin.distance_to(cloth.skeleton.get_bone_global_pose(cloth.skeleton.get_bone_parent(bone)).origin)
			samples.max_link_error = maxf(samples.max_link_error,absf(link-cloth.skeleton.get_bone_rest(bone).origin.length()))
			var local := capsule.to_local(cloth.skeleton.to_global(pose.origin))
			var half_segment := capsule.mid_height*.5
			var nearest := Vector3(0,clampf(local.y,-half_segment,half_segment),0)
			var clearance := local.distance_to(nearest)-capsule.radius
			if clearance < samples.min_clearance:
				samples.min_clearance = clearance
				samples.worst_bone = cloth.skeleton.get_bone_name(bone)
				samples.worst_action = visual._current_action
		for probe in probes:
			var point := Vector3.ZERO
			var rigid := Vector3.ZERO
			for influence in probe.influences:
				var pose := cloth.skeleton.get_bone_global_pose(influence.bone)
				point += (pose*influence.bind*probe.point)*influence.weight
				rigid += (rigid_poses.get(influence.bone,pose)*influence.bind*probe.point)*influence.weight
			samples.fabric_penetration += capsule_penetration(capsule,cloth.skeleton.to_global(point))
			samples.rigid_penetration += capsule_penetration(capsule,cloth.skeleton.to_global(rigid))
	cloth.simulator.modification_processed.connect(callback)
	visual.set_process(true)
	for facing in [1,-1]:
		player.last_direction = facing
		for action: StringName in [&"idle_4",&"run_1",&"casting_2",&"grapple_swinging_1"]:
			visual._logical_animation = &"Run" if action == &"run_1" else &"Idle"
			visual._play_action(action,&"",0,true,1,0)
			for frame in 60:
				player.velocity.x = facing*300.0*sin(frame*.1)
				await physics_frame
			await capture(visual._viewport,"blue_sleeve_%s_%d" % [action,facing])
			if facing == 1:
				# Freeze one pose for a direct comparison of sleeve deformation.
				visual.set_process(false)
				visual._animation_player.pause()
				cloth.set_equipped(false)
				await capture(visual._viewport,"blue_sleeve_rigid_"+String(action))
				cloth.set_equipped(true)
				for frame in 30:
					await physics_frame
				await capture(visual._viewport,"blue_sleeve_settled_"+String(action))
				visual.set_process(true)
	check(samples.frames > 0, "Sleeve simulator runs on the live rig")
	# Three 8 cm links can displace a tip by at most twice their total length.
	check(samples.finite and samples.max_offset > .0001 and samples.max_offset < .481
		and samples.max_link_error < .001, "Sleeve motion is finite and preserves chain lengths")
	check(samples.min_clearance > -.015, "Sleeve tips stay within the 1.5 cm collision tolerance")
	check(samples.fabric_penetration < samples.rigid_penetration, "Moving sleeve fabric penetrates torso less than rigid sleeves")
	var resets := cloth.reset_count
	player.position += Vector2(600,0)
	visual._process(1.0/60.0)
	check(cloth.reset_count > resets, "Teleport resets sleeve inertia")
	resets = cloth.reset_count
	visual._process(.25)
	check(cloth.reset_count > resets, "Long frame resets sleeve inertia")
	manager.equip_item(2)
	check(cloth.simulator.active and cloth.profile == &"base" and cloth.simulator.setting_count == 4, "Base Head / Chest selects firmer hem motion")
	manager.equip_item(5)
	check(cloth.simulator.active and cloth.profile == &"blue" and cloth.simulator.setting_count == 8, "Blue Head / Chest restores all flowing cloth")
	check(visual._skeleton.get_bone_count() == bone_count, "Repeated swaps reuse cloth bones")
	print("BLUE_SLEEVE_MOTION ", JSON.stringify(samples))
	var report := FileAccess.open(OUTPUT+"godot_sleeve_motion_report.json",FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify(samples,"\t"))
	cloth.simulator.modification_processed.disconnect(callback)
	await verify_hanging_motion(player,visual,manager)
	visual.set_process(false)


func verify_hanging_motion(player: Node2D, visual: Node, manager: Node) -> void:
	var cloth: EquipmentClothMotion = visual.equipment_visuals.cloth_motion
	var results := {}
	for item in [2,5]:
		manager.equip_item(item)
		var profile := String(cloth.profile)
		var expected := 4 if item == 2 else 8
		check(cloth.simulator.setting_count == expected, profile+" has the intended chain count")
		var weighted := {}
		for mesh: MeshInstance3D in visual.equipment_visuals._roots[&"head_chest"].find_children("*","MeshInstance3D",true,false):
			if mesh.get_meta("outline_only",false):
				continue
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				for index in weights.size():
					var name := mesh.skin.get_bind_name(bones[index])
					if weights[index] > .01 and String(name).begins_with("cloth_"):
						weighted[name] = true
		for setting in expected:
			var name := String(cloth.simulator.get_root_bone_name(setting))
			check(weighted.has(StringName(name)) or weighted.has(StringName(name.left(-1)+"1")), profile+" chain actually weights fabric: "+name)
		var samples := {"frames":0,"finite":true,"link_error":0.0,"max_offset":0.0,"max_tip_ratio":0.0,"root_error":0.0}
		var callback := func() -> void:
			if cloth.warming_up:
				return
			samples.frames += 1
			for bone in cloth._bones:
				var name := String(cloth.skeleton.get_bone_name(bone))
				if name.begins_with("cloth_sleeve_"):
					continue
				var pose := cloth.skeleton.get_bone_global_pose(bone)
				samples.finite = samples.finite and pose.origin.is_finite() and pose.basis.is_finite()
				var rest := cloth.skeleton.get_bone_rest(bone)
				var parent := cloth.skeleton.get_bone_parent(bone)
				var cursor := bone
				var length := 0.0
				if not name.ends_with("_0"):
					var link := pose.origin.distance_to(cloth.skeleton.get_bone_global_pose(parent).origin)
					samples.link_error = maxf(samples.link_error,absf(link-rest.origin.length()))
				while String(cloth.skeleton.get_bone_name(parent)).begins_with("cloth_"):
					length += cloth.skeleton.get_bone_rest(cursor).origin.length()
					rest = cloth.skeleton.get_bone_rest(parent)*rest
					cursor = parent
					parent = cloth.skeleton.get_bone_parent(parent)
				rest = cloth.skeleton.get_bone_global_pose(parent)*rest
				var offset := pose.origin.distance_to(rest.origin)
				if name.ends_with("_0"):
					samples.root_error = maxf(samples.root_error,offset)
				if offset > samples.max_offset:
					samples.worst_action = visual._current_action
					samples.worst_bone = name
				samples.max_offset = maxf(samples.max_offset,offset)
				if length > .001:
					samples.max_tip_ratio = maxf(samples.max_tip_ratio,offset/(2*length))
		cloth.simulator.modification_processed.connect(callback)
		for facing in [1,-1]:
			player.last_direction = facing
			for action: StringName in [&"idle_4",&"idle_2",&"run_1",&"crouch_idle_1",&"jump_1",&"casting_2",&"slash_2",&"grapple_swinging_1"]:
				visual._logical_animation = &"Run" if action == &"run_1" else &"Idle"
				visual._play_action(action,&"",0,true,1,0)
				for frame in 24:
					player.velocity.x = facing*280.0*sin(frame*.15)
					await physics_frame
				if action in [&"run_1",&"casting_2",&"grapple_swinging_1"]:
					await capture(visual._viewport,"%s_cloth_%s_%d" % [profile,action,facing])
		cloth.simulator.modification_processed.disconnect(callback)
		check(samples.frames > 0 and samples.finite and samples.max_offset > .0001,profile+" hanging cloth simulates finite motion")
		check(samples.link_error < .001 and samples.max_tip_ratio <= 1.001,profile+" hanging cloth preserves link lengths")
		check(samples.root_error < .0001,profile+" hanging cloth keeps its attachment fixed")
		results[profile] = samples
		cloth.reset()
		check(cloth.simulator.external_force == Vector3.ZERO,profile+" reset clears inherited acceleration")
	var report := FileAccess.open(OUTPUT+"godot_hanging_cloth_report.json",FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify(results,"\t"))
	print("HANGING_CLOTH ",JSON.stringify(results))


func capsule_penetration(capsule: SpringBoneCollisionCapsule3D, point: Vector3) -> float:
	var local := capsule.to_local(point)
	var nearest := Vector3(0,clampf(local.y,-capsule.mid_height*.5,capsule.mid_height*.5),0)
	return maxf(0.0,capsule.radius-local.distance_to(nearest))
