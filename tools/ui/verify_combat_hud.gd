extends Node

const COMBAT_HUD_SCENE := preload("res://Src/UI/combat_hud.tscn")

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
	await _verify_thread_knot_counter(hud)
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
