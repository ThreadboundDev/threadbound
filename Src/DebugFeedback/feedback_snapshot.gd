extends RefCounted
## Read-only, explicit property allowlists; no whole-object/save-file dumps.

static func properties(object: Object, names: Array) -> Dictionary:
	var result := {}
	if not is_instance_valid(object):
		return result
	var available := {}
	for item in object.get_property_list():
		available[item.name] = true
	for key in names:
		if available.has(key):
			result[key] = value(object.get(key))
	return result

static func value(item: Variant) -> Variant:
	if item is Object and not is_instance_valid(item):
		return null
	if item is Vector2 or item is Vector2i:
		return {"x": item.x, "y": item.y}
	if item is Vector3:
		return {"x": item.x, "y": item.y, "z": item.z}
	if item is StringName or item is NodePath:
		return str(item)
	if item is Resource:
		return {"resource": item.resource_path, "name": item.resource_name}
	if item is Node:
		var script: Script = item.get_script()
		return {"node": str(item.get_path()) if item.is_inside_tree() else str(item.name),
			"inside_tree": item.is_inside_tree(), "script": script.resource_path if script else ""}
	if item is Object:
		return item.get_class() if is_instance_valid(item) else null
	if item is Array or item is PackedInt32Array or item is PackedStringArray:
		var items: Array = []
		for child in item:
			items.append(value(child))
		return items
	return item

static func collect(tree: SceneTree, include_environment := true) -> Dictionary:
	var scene := tree.current_scene
	var player := tree.get_first_node_in_group("player")
	var result := {"utc": Time.get_datetime_string_from_system(true) + "Z",
		"ticks_msec": Time.get_ticks_msec(), "scene": scene.scene_file_path if scene else "",
		"scene_name": str(scene.name) if scene else "", "paused": tree.paused,
		"fps": Engine.get_frames_per_second(), "time_scale": Engine.time_scale,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"player": properties(player, ["global_position", "velocity", "last_direction",
			"is_attacking", "is_hurt", "is_dead", "is_blocking", "is_crouching",
			"is_wall_clinging", "is_ledge_hanging", "is_ledge_climbing", "is_meditating",
			"current_body_anim", "current_attack_body_anim", "current_attack_is_special",
			"current_attack_is_spin", "ground_combo_step", "water_combo_step", "momentum",
			"action_points", "current_action_points", "max_action_points", "thread_knot_count", "_flow_state_active",
			"god_mode_enabled", "_debug_no_clip_enabled", "house_door_transition_owner"])}
	if player:
		result.player["node"] = str(player.get_path())
		if player is CharacterBody2D:
			result.player["on_floor"] = player.is_on_floor()
			result.player["on_wall"] = player.is_on_wall()
		if player.has_method("is_in_prototype_water"):
			result.player["in_water"] = player.call("is_in_prototype_water")
		result.player["health"] = properties(player.get_node_or_null("HealthComponent"),
			["current_health", "max_health", "is_dead"])
	var progress := tree.root.get_node_or_null("DemoProgress")
	result["progress"] = {}
	if progress:
		result.progress["threads"] = {}
		for thread_id in [&"power", &"balance", &"essence"]:
			result.progress.threads[str(thread_id)] = progress.call("has_thread", thread_id)
		for method in ["get_checkpoint_scene_path", "get_checkpoint_id", "get_checkpoint_position",
				"is_tutorial_completed", "is_demo_completed", "get_held_thread_knots",
				"get_recovery_thread_knots", "get_recovery_scene_path", "get_recovery_position"]:
			if progress.has_method(method):
				result.progress[method.trim_prefix("get_")] = value(progress.call(method))
	result["equipment"] = properties(tree.root.get_node_or_null("EquipManager"),
		["current_equip", "current_gloves", "current_boots", "current_chest", "current_pattern"])
	# Scene-owned equipment can be active even when manager node references are null.
	result.equipment["player_slots"] = properties(player,
		["current_gloves", "current_boots", "current_chest", "current_pattern"])
	if player and result.equipment.player_slots.has("current_gloves"):
		result.equipment["grapple"] = properties(player.get("current_gloves"),
			["grapple_state", "grapple_attachment_state", "grapple_attached", "grapple_direction",
				"grapple_tip_position", "grapple_target", "grapple_attach_position", "grapple_strike_active"])
	var camera := tree.root.get_camera_2d()
	result["camera"] = properties(camera, ["global_position", "zoom", "offset", "enabled"])
	if camera and camera.has_meta("lakeside_focus_owner"):
		result.camera["interior_focus_owner"] = value(camera.get_meta("lakeside_focus_owner"))
	result["interiors"] = []
	for house in tree.get_nodes_in_group("lakeside_door_houses"):
		var interior := properties(house, ["_occupied", "_transition_locked", "inside_player", "global_position"])
		interior["node"] = str(house.get_path())
		result.interiors.append(interior)
	result["scene_settings"] = properties(scene, ["lighting_preset", "art_render_scale"])
	var actions: Array[String] = []
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			actions.append(str(action))
	result["held_actions"] = actions
	if include_environment:
		result["nearby_enemies"] = []
		if player is Node2D:
			var enemies := tree.get_nodes_in_group("enemies")
			enemies.sort_custom(func(a, b): return a is Node2D and b is Node2D and a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
			for enemy in enemies:
				if not enemy is Node2D or enemy.global_position.distance_to(player.global_position) > 1200:
					continue
				var state := properties(enemy, ["global_position", "velocity", "is_dead", "state", "current_state"])
				state["node"] = str(enemy.get_path())
				state["health"] = properties(enemy.get_node_or_null("HealthComponent"), ["current_health", "max_health", "is_dead"])
				result.nearby_enemies.append(state)
				if result.nearby_enemies.size() >= 12:
					break
		result["environment"] = {"game_version": ProjectSettings.get_setting("application/config/version", ""),
			"godot": Engine.get_version_info(), "os": OS.get_name(), "os_version": OS.get_version(),
			"renderer": RenderingServer.get_current_rendering_method(),
			"gpu": RenderingServer.get_video_adapter_name(), "window_size": value(tree.root.size),
			"viewport_size": value(tree.root.get_visible_rect().size),
			"max_fps": Engine.max_fps, "vsync": DisplayServer.window_get_vsync_mode(),
			"static_memory_bytes": OS.get_static_memory_usage(),
			"gameplay_settings": properties(tree.root.get_node_or_null("GameplaySettings"),
				["difficulty_index", "auto_save", "tutorial_hints", "vibration", "damage_numbers"]),
			"display_settings": properties(tree.root.get_node_or_null("DisplaySettings"),
				["resolution_index", "fullscreen", "vsync", "frame_rate_limit_index", "quality_preset_index", "brightness"])}
		var bindings := {}
		for action in InputMap.get_actions():
			if str(action).begins_with("ui_"):
				continue
			var events: Array[String] = []
			for event in InputMap.action_get_events(action):
				events.append(event.as_text())
			bindings[str(action)] = events
		result["input_bindings"] = bindings
	return result
