extends Node

const COMBAT_HUD_SCENE := preload("res://Src/UI/combat_hud.tscn")
const BOSS_HEALTH_BAR_SCENE := preload("res://Src/UI/boss_health_bar.tscn")
const BOSS_ARENA_LOCK_SCRIPT := preload(
	"res://Src/Environment/World/boss_arena_lock.gd"
)
const ROOM_HUE_GRADE_SCRIPT := preload(
	"res://Src/Environment/World/room_hue_grade.gd"
)

var _failures := PackedStringArray()

func _ready() -> void:
	var hud := COMBAT_HUD_SCENE.instantiate() as CombatHUD
	_expect(hud != null, "Combat HUD scene instantiates as CombatHUD.")
	if not hud:
		_finish()
		return

	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	_verify_scene_layers(hud)
	_verify_action_point_variants(hud)
	_verify_identity_and_pattern_hooks(hud)
	_verify_momentum_flow(hud)
	_verify_trial_timer(hud)
	await _verify_thread_knot_counter(hud)
	_verify_boss_health_bar()
	await _verify_boss_camera_zoom()
	await _verify_boss_room_grade_intro()
	_finish()

func _verify_scene_layers(hud: CombatHUD) -> void:
	_expect(hud.identity_base != null, "Identity base layer exists.")
	_expect(hud.pattern_overlay != null, "Pattern overlay layer exists.")
	_expect(
		hud.identity_base.size.is_equal_approx(hud.pattern_overlay.size),
		"Pattern overlay covers the full identity field."
	)
	_expect(hud.action_point_orbs.size() == 6, "Exactly six action-point controls exist.")
	_expect(hud.health_bar.track_texture != null, "Health has a visible empty track.")
	_expect(hud.health_bar.fill_texture != null, "Health uses the dedicated crimson fill.")
	_expect(hud.momentum_bar != null, "Momentum bar exists.")
	_expect(hud.momentum_bar.track_texture != null, "Momentum has a visible empty track.")
	_expect(hud.momentum_bar.fill_texture != null, "Momentum uses the ivory-to-gold fill.")
	_expect(hud.thread_knot_counter != null, "Thread Knot counter exists.")
	var frame := hud.get_node("HUDRoot/Frame") as TextureRect
	_expect(hud.health_bar.z_index > frame.z_index, "Health fill renders above the frame rail interior.")
	_expect(hud.momentum_bar.z_index > frame.z_index, "Momentum fill renders above the frame rail interior.")

func _verify_action_point_variants(hud: CombatHUD) -> void:
	var expected_types: Array[StringName] = [
		CombatHUD.ACTION_POINT_COLORLESS,
		CombatHUD.ACTION_POINT_COLORLESS,
		CombatHUD.ACTION_POINT_COLORLESS,
		CombatHUD.ACTION_POINT_COLORLESS,
		CombatHUD.ACTION_POINT_COLORLESS,
		CombatHUD.ACTION_POINT_COLORLESS,
	]
	for index in expected_types.size():
		_expect(
			hud.get_action_point_type(index) == expected_types[index],
			"Action point %d has the expected default type." % (index + 1)
		)
		_expect(hud.action_point_orbs[index].texture != null, "Action point %d has a texture." % (index + 1))
		_expect(
			hud.action_point_orbs[index].size.x >= 34.0,
			"Action point %d remains readable at HUD scale." % (index + 1)
		)

	hud.set_action_point_type(5, CombatHUD.ACTION_POINT_BLUE)
	_expect(hud.get_action_point_type(5) == CombatHUD.ACTION_POINT_BLUE, "Action-point type API updates a socket.")
	_expect(
		hud.action_point_orbs[5].texture == hud.action_point_blue_texture,
		"Action-point type API applies the matching color asset."
	)
	var texture_paths := {}
	for texture in [
		hud.action_point_red_texture,
		hud.action_point_blue_texture,
		hud.action_point_yellow_texture,
		hud.action_point_colorless_texture,
	]:
		if texture:
			texture_paths[texture.resource_path] = true
	_expect(texture_paths.size() == 4, "Red, blue, yellow, and colorless use distinct assets.")
	for texture in [
		hud.action_point_red_texture,
		hud.action_point_blue_texture,
		hud.action_point_yellow_texture,
		hud.action_point_colorless_texture,
	]:
		_expect(
			texture.resource_path.contains("/Hud/V4/action_point_disc_"),
			"Action point asset uses the V4 full-disc silhouette."
		)
		_expect(
			_texture_alpha_coverage(texture) >= 0.68,
			"Action point full-disc silhouette fills its gameplay socket."
		)

func _verify_identity_and_pattern_hooks(hud: CombatHUD) -> void:
	var test_identity_color := Color(0.35, 0.2, 0.62, 1.0)
	hud.set_identity_color(test_identity_color)
	_expect(
		hud.identity_base.modulate.is_equal_approx(test_identity_color),
		"Identity color API modulates the under-pattern field."
	)
	_expect(not hud.pattern_overlay.visible, "Proof pattern starts hidden.")
	hud.set_pattern_visible(true)
	_expect(hud.pattern_overlay.visible, "Pattern visibility API reveals the full-field overlay.")

func _verify_momentum_flow(hud: CombatHUD) -> void:
	hud.set_momentum(100.0)
	hud.set_momentum_state(&"Flow", true)
	_expect(hud.momentum_bar.is_flow_active(), "Flow state enables momentum animation.")
	_expect(hud.momentum_bar.fill_rect.size.y <= 12.0, "Momentum remains a thin rail.")
	_expect(hud.momentum_bar.fill_rect.size.y >= 10.0, "Momentum fill remains clearly visible.")
	_expect(hud.health_bar.fill_rect.size.x >= 390.0, "Health rail uses the wider V4 layout.")
	_expect(hud.momentum_bar.fill_rect.size.x >= 374.0, "Momentum rail uses the wider V4 layout.")
	var rail_gap := hud.momentum_bar.fill_rect.position.y - hud.health_bar.fill_rect.end.y
	_expect(rail_gap <= 12.0, "Health and momentum rails remain visually grouped.")

func _verify_trial_timer(hud: CombatHUD) -> void:
	hud.set_trial_timer(43.0, true)
	var backing := hud.get_node("TrialTimer/Backing") as Control
	var title := hud.get_node("TrialTimer/Title") as Label
	var countdown := hud.get_node("TrialTimer/Countdown") as Label
	_expect(hud.trial_timer.visible, "Active Blue trial reveals its timer.")
	_expect(title.text == "TRIAL OF BALANCE", "Blue trial title remains explicit.")
	_expect(countdown.text == "00:43", "Blue trial countdown uses minute-second formatting.")
	_expect(backing.size.x >= 460.0, "Trial banner has enough width for both text fields.")
	_expect(title.position.x + title.size.x < countdown.position.x, "Trial title and countdown do not overlap.")
	_expect(backing.size.y <= 64.0, "Trial banner stays compact over gameplay.")
	hud.set_trial_timer(0.0, false)
	_expect(not hud.trial_timer.visible, "Inactive Blue trial hides its timer.")

func _verify_thread_knot_counter(hud: CombatHUD) -> void:
	hud.thread_knot_visible_seconds = 0.05
	hud.thread_knot_fade_seconds = 0.05
	hud.set_thread_knots(0)
	hud.set_thread_knots(12480)
	_expect(hud.thread_knot_counter.visible, "A Thread Knot increase reveals the counter.")
	_expect(hud.thread_knot_label.text == "× 12,480", "Thread Knot count uses an exact comma-formatted value.")
	_expect(hud.thread_knot_label.size.x >= 240.0, "Thread Knot label has room for high exact counts.")
	await get_tree().create_timer(0.4).timeout
	_expect(not hud.thread_knot_counter.visible, "Thread Knot counter hides after its pickup display window.")
	_expect(
		is_equal_approx(hud.thread_knot_counter.offset_right, -8.0),
		"Thread Knot counter uses the approved right-edge placement."
	)
	var knot_icon := hud.thread_knot_counter.get_node("KnotIcon") as TextureRect
	_expect(
		is_equal_approx(knot_icon.offset_left, 36.0),
		"Thread Knot icon sits completely inside the counter frame."
	)

func _verify_boss_health_bar() -> void:
	var boss_bar := BOSS_HEALTH_BAR_SCENE.instantiate() as BossHealthBar
	_expect(boss_bar != null, "Boss health bar scene instantiates as BossHealthBar.")
	if not boss_bar:
		return

	add_child(boss_bar)
	boss_bar.size = Vector2(1920.0, 220.0)
	var boss_geometry := boss_bar.call("_get_draw_geometry") as Dictionary
	var boss_draw_size := boss_geometry.get("draw_size", Vector2.ZERO) as Vector2
	var title := boss_bar.get_node_or_null("BossTitle") as Label
	_expect(title != null, "Boss health bar includes an editable title label.")
	_expect(title.text == "PROTO-WEAVER", "Proto-Weaver title is visible above the boss rail.")
	_expect(
		boss_draw_size.x <= 780.0 and boss_draw_size.y <= 220.0,
		"Boss HUD stays compact enough to preserve the arena view."
	)
	_expect(
		boss_bar.frame_texture.resource_path.ends_with("boss_health_frame_v4.png"),
		"Boss frame uses the player-HUD-matched V4 asset."
	)
	_expect(
		boss_bar.fill_texture.resource_path.ends_with("health_fill_v3.png"),
		"Boss health uses the same woven crimson fill as the player HUD."
	)
	_expect(
		boss_bar.health_fill_rect.size.x >= 900.0,
		"Boss health rail remains broad and readable."
	)
	_expect(
		boss_bar.left_orb_center.x < boss_bar.health_fill_rect.position.x,
		"Left add socket remains outside the health rail."
	)
	_expect(
		boss_bar.right_orb_center.x > boss_bar.health_fill_rect.end.x,
		"Right add socket remains outside the health rail."
	)
	_expect(
		boss_bar.title_rect.end.y < 96.0,
		"Boss title stays above the center ornament instead of overlapping it."
	)
	boss_bar.prepare_intro()
	_expect(
		boss_bar.visible and is_zero_approx(boss_bar.modulate.a),
		"Boss HUD can begin hidden while retaining its cinematic layout."
	)
	boss_bar.reveal_intro(0.01)
	_expect(
		boss_bar.visible,
		"Boss HUD exposes a cinematic name-and-health reveal."
	)
	boss_bar.set_armor_link_state(0, true, 0.0, 26.0, 3.0)
	boss_bar.set_armor_link_state(1, false, 13.0, 26.0, 3.0)
	_expect(
		bool(boss_bar.call("_is_armored")),
		"A living add still communicates the boss's armored state."
	)
	boss_bar.queue_free()

func _verify_boss_camera_zoom() -> void:
	var camera := Camera2D.new()
	camera.name = "BossTestCamera"
	camera.enabled = false
	add_child(camera)

	var arena_lock := Area2D.new()
	arena_lock.name = "BossTestArenaLock"
	arena_lock.set_script(BOSS_ARENA_LOCK_SCRIPT)
	arena_lock.set("boss_path", NodePath("../MissingBoss"))
	arena_lock.set("entrance_door_path", NodePath("../MissingDoor"))
	arena_lock.set("camera_path", NodePath("../BossTestCamera"))
	arena_lock.set("boss_camera_zoom", Vector2(0.72, 0.72))
	arena_lock.set("boss_zoom_duration", 0.05)
	arena_lock.set("cinematic_start_hold", 0.01)
	arena_lock.set("cinematic_pan_duration", 0.01)
	arena_lock.set("cinematic_hud_reveal_duration", 0.01)
	arena_lock.set("cinematic_boss_hold", 0.01)
	arena_lock.set("cinematic_return_duration", 0.01)
	add_child(arena_lock)
	await get_tree().process_frame

	var test_player := Node2D.new()
	test_player.add_to_group("player")
	test_player.set_process(true)
	test_player.set_physics_process(true)
	add_child(test_player)
	arena_lock.call("_on_body_entered", test_player)
	await get_tree().process_frame
	_expect(
		bool(arena_lock.call("is_intro_running"))
		and not test_player.is_processing()
		and not test_player.is_physics_processing(),
		"Boss introduction temporarily owns player control."
	)
	await get_tree().create_timer(0.12).timeout
	_expect(
		camera.zoom.is_equal_approx(Vector2(0.72, 0.72)),
		"Entering the boss arena smoothly selects the approved 0.72 camera zoom."
	)
	_expect(
		not bool(arena_lock.call("is_intro_running"))
		and test_player.is_processing()
		and test_player.is_physics_processing(),
		"Boss introduction restores player control before combat."
	)

	arena_lock.call("_on_boss_died", null)
	await get_tree().create_timer(0.12).timeout
	_expect(
		camera.zoom.is_equal_approx(Vector2.ONE),
		"Boss defeat restores the camera's original zoom."
	)
	test_player.queue_free()
	arena_lock.queue_free()
	camera.queue_free()

func _verify_boss_room_grade_intro() -> void:
	var room_grade := CanvasLayer.new()
	room_grade.set_script(ROOM_HUE_GRADE_SCRIPT)
	room_grade.set("sync_bounds_from_placeholders", false)
	room_grade.set("grass_recolor_enabled", false)
	add_child(room_grade)
	await get_tree().process_frame

	var boss_room_position := Vector2(2000.0, 3000.0)
	var before := room_grade.call(
		"_target_grade_for_position",
		boss_room_position
	) as Dictionary
	_expect(
		is_zero_approx(float(before.get("strength", -1.0))),
		"Boss-room grade stays neutral before the cinematic cue."
	)

	room_grade.call("start_boss_intro_grade", 0.01)
	await get_tree().create_timer(0.04).timeout
	var after := room_grade.call(
		"_target_grade_for_position",
		boss_room_position
	) as Dictionary
	_expect(
		float(room_grade.call("get_boss_intro_grade_blend")) >= 0.99
		and float(after.get("strength", 0.0)) > 0.0,
		"Boss-room grade fades in from the cinematic instead of a spatial hard cut."
	)
	room_grade.queue_free()

func _texture_alpha_coverage(texture: Texture2D) -> float:
	if not texture:
		return 0.0
	var image := texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	var visible_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.03:
				visible_pixels += 1
	return float(visible_pixels) / float(maxi(1, total_pixels))

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Combat HUD verification: " + message)

func _finish() -> void:
	if _failures.is_empty():
		print("Combat HUD verification passed.")
		get_tree().quit(0)
		return

	print("Combat HUD verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)
