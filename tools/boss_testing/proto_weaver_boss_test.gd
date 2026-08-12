extends Node2D

const TEST_PATTERN_ID := &"merchant_knot"

var _boss: ProtoWeaver
var _attack_label: Label
var _hud_refresh_elapsed := 0.0


func _ready() -> void:
	_equip_demo_pattern()
	_create_attack_lab_hud()
	call_deferred("_setup_attack_lab")
	print(
		"Proto-Weaver test loadout: 4 Health, 4 Attack, 4 Resistance, "
		+ "3 Skill Damage, 3 AP Recharge, 3 Momentum, Follower's Knot"
	)
	print(
		"Attack Lab starts on Blue VFX: 1 Red, 2 Blue, 3 Yellow, 4 Stab, "
		+ "5 Wall I, 6 Wall II, 7 Center Finale, 0 Normal"
	)


func _process(delta: float) -> void:
	_hud_refresh_elapsed += delta
	if _hud_refresh_elapsed < 0.1:
		return
	_hud_refresh_elapsed = 0.0
	_update_attack_lab_hud()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not key_event or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_select_lab_attack(ProtoWeaver.AttackMode.THREADBURST)
		KEY_2:
			_select_lab_attack(ProtoWeaver.AttackMode.GROUND_SWEEP)
		KEY_3:
			_select_lab_attack(ProtoWeaver.AttackMode.ESSENCE_ECHO)
		KEY_4:
			_select_lab_attack(ProtoWeaver.AttackMode.STAB)
		KEY_5:
			_trigger_hanging_phase(0)
		KEY_6:
			_trigger_hanging_phase(1)
		KEY_7:
			_trigger_hanging_phase(2)
		KEY_0:
			_disable_attack_lab()


func _setup_attack_lab() -> void:
	_boss = get_tree().get_first_node_in_group("proto_weaver") as ProtoWeaver
	if not _boss:
		push_warning("Proto-Weaver Attack Lab could not find the boss.")
		return
	if _boss.stats:
		_boss.stats = _boss.stats.duplicate(true) as EnemyStats
		_boss.stats.attack_cooldown = 0.2
	# Start on the attack whose VFX is actively being reviewed. Red remains
	# one key away, while wall-phase keys present the tri-color laser.
	_select_lab_attack(ProtoWeaver.AttackMode.GROUND_SWEEP)


func _select_lab_attack(attack_mode: int) -> void:
	if not is_instance_valid(_boss):
		return
	_boss.configure_debug_attack_lab(attack_mode)
	_update_attack_lab_hud()
	print("Attack Lab selected: %s" % _boss.get_debug_attack_lab_name())


func _disable_attack_lab() -> void:
	if not is_instance_valid(_boss):
		return
	_boss.disable_debug_attack_lab()
	_update_attack_lab_hud()
	print("Attack Lab disabled: normal encounter restored")


func _trigger_hanging_phase(phase_index: int) -> void:
	if not is_instance_valid(_boss):
		return
	_boss.trigger_debug_hanging_phase(phase_index)
	_update_attack_lab_hud()
	print("Attack Lab triggered hanging phase %d" % (phase_index + 1))


func _create_attack_lab_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "AttackLabHUD"
	layer.layer = 30
	add_child(layer)
	_attack_label = Label.new()
	_attack_label.position = Vector2(18.0, 112.0)
	_attack_label.add_theme_font_size_override("font_size", 18)
	_attack_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	_attack_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.03, 0.96))
	_attack_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_attack_label)
	_update_attack_lab_hud()


func _update_attack_lab_hud() -> void:
	if not _attack_label:
		return
	var selected := "Loading boss..."
	var combat_status := "Boss status unavailable"
	var wall_status := "Wall phase: inactive"
	if is_instance_valid(_boss):
		selected = _boss.get_debug_attack_lab_name()
		if _boss.health_component:
			combat_status = "Boss HP: %d/%d  |  Stagger: %.0f/%.0f" % [
				_boss.health_component.current_health,
				_boss.health_component.max_health,
				float(_boss.get("_stagger_value")),
				float(_boss.call("_get_current_stagger_threshold")),
			]
		if bool(_boss.get("_wall_hanging")):
			var phase_number := int(_boss.get("_active_hanging_phase")) + 1
			wall_status = "Wall phase %d: %.1f/%.1fs  |  Break: %.0f/%.0f" % [
				phase_number,
				float(_boss.get("_wall_phase_elapsed")),
				float(_boss.call("_get_wall_phase_max_duration")),
				float(_boss.get("_wall_break_damage")),
				float(_boss.call("_get_wall_break_damage_threshold")),
			]
	_attack_label.text = (
		"ATTACK LAB: %s\n"
		+ "%s\n"
		+ "%s\n"
		+ "VFX REVIEW: [2] Blue Wave  |  [5/6/7] Tri-Color Laser\n"
		+ "[1] Red  [3] Yellow  [4] Stab  [0] Normal\n"
		+ "[5] Wall I  [6] Wall II  [7] Final Wall Enrage"
	) % [selected, combat_status, wall_status]


func _equip_demo_pattern() -> void:
	if not EquipManager:
		return

	if not EquipManager.owns_pattern(TEST_PATTERN_ID):
		EquipManager.unlock_pattern(TEST_PATTERN_ID)

	var equipped_pattern: EquipmentPattern = EquipManager.get_current_pattern()
	if not equipped_pattern or equipped_pattern.id != TEST_PATTERN_ID:
		EquipManager.equip_pattern(TEST_PATTERN_ID)
	else:
		EquipManager.apply_current_pattern_to_player()
