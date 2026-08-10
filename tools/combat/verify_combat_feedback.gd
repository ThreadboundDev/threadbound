extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const ENEMY_BASE_SCENE := preload("res://Src/Enemies/EnemyBase/enemy_base.tscn")
const THREADLING_STATS := preload("res://Src/Enemies/Threadling/threadling_stats.tres")
const LOOMKIN_STATS := preload("res://Src/Enemies/Loomkin/loomkin_stats.tres")
const TENSIONER_STATS := preload("res://Src/Enemies/Tensioner/tensioner_stats.tres")
const ENEMY_HEALTH_BAR_SCENE := preload("res://Src/UI/enemy_health_bar.tscn")

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run_verification")

func _run_verification() -> void:
	_verify_player_attack_profiles()
	_verify_backpedal_chain_lock()
	_verify_flow_attack_multipliers()
	_verify_meditation_flow_presentation()
	_verify_player_resistance_metadata()
	_verify_neutral_special_contract()
	_verify_dash_contract()
	await _verify_dash_collision_runtime()
	_verify_enemy_receiver_profiles()
	_verify_enemy_health_bar_contract()
	_verify_per_target_damage_hook()
	_verify_enemy_hitstun()
	await _verify_attack_overlap_retry()
	await _verify_coalesced_feedback()
	_finish()

func _verify_player_attack_profiles() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for attack-profile verification.")
	if player == null:
		return

	var player_stats := player.get("player_stats") as PlayerStats
	_expect(player_stats != null, "Player attack profiles have a PlayerStats resource.")
	if player_stats:
		_expect(
			player_stats.attack_damage == 25,
			"Attack-profile verification uses the intended 25-damage baseline."
		)
		_expect(
			is_equal_approx(player_stats.knockback_strength, 260.0),
			"Attack-profile verification uses the intended 260-knockback baseline."
		)

	var cases: Array[Dictionary] = [
		{
			"label": "moving opener",
			"ground": true,
			"air": false,
			"mode": &"moving",
			"step": 0,
			"strike": 0,
			"expected": _attack_profile(25.0, 0.16, 260.0, 0.040, 2.25),
		},
		{
			"label": "moving finisher first",
			"ground": true,
			"air": false,
			"mode": &"moving",
			"step": 1,
			"strike": 0,
			"expected": _attack_profile(18.0, 0.14, 220.0, 0.030, 1.8),
		},
		{
			"label": "moving finisher second",
			"ground": true,
			"air": false,
			"mode": &"moving",
			"step": 1,
			"strike": 1,
			"expected": _attack_profile(25.0, 0.20, 300.0, 0.045, 3.0),
		},
		{
			"label": "stationary first",
			"ground": true,
			"air": false,
			"mode": &"stationary",
			"step": 1,
			"strike": 0,
			"expected": _attack_profile(23.0, 0.18, 270.0, 0.040, 2.2),
		},
		{
			"label": "stationary second",
			"ground": true,
			"air": false,
			"mode": &"stationary",
			"step": 1,
			"strike": 1,
			"expected": _attack_profile(30.0, 0.25, 340.0, 0.055, 3.5),
		},
		{
			"label": "backpedal opener",
			"ground": true,
			"air": false,
			"mode": &"backpedal",
			"step": 0,
			"strike": 0,
			"expected": _attack_profile(21.0, 0.18, 290.0, 0.040, 2.4),
		},
		{
			"label": "backpedal finisher first",
			"ground": true,
			"air": false,
			"mode": &"backpedal",
			"step": 1,
			"strike": 0,
			"expected": _attack_profile(17.0, 0.14, 235.0, 0.030, 2.4),
		},
		{
			"label": "backpedal finisher second",
			"ground": true,
			"air": false,
			"mode": &"backpedal",
			"step": 1,
			"strike": 1,
			"expected": _attack_profile(23.0, 0.20, 310.0, 0.045, 2.4),
		},
		{
			"label": "air first",
			"ground": false,
			"air": true,
			"mode": &"moving",
			"step": 0,
			"strike": 0,
			"expected": _attack_profile(16.0, 0.14, 210.0, 0.030, 1.6),
		},
		{
			"label": "air second",
			"ground": false,
			"air": true,
			"mode": &"moving",
			"step": 0,
			"strike": 1,
			"expected": _attack_profile(21.0, 0.18, 275.0, 0.040, 2.4),
		},
	]

	for test_case in cases:
		player.set("current_attack_is_special", false)
		player.set("current_attack_uses_ground_combo", bool(test_case["ground"]))
		player.set("current_attack_uses_air_double", bool(test_case["air"]))
		player.set("ground_attack_visual_mode", test_case["mode"])
		player.set("ground_combo_step", int(test_case["step"]))
		player.set("ground_combo_active_strike", int(test_case["strike"]))
		player.set("air_attack_active_strike", int(test_case["strike"]))
		player.set("attack_direction", Vector2.RIGHT)

		var label := String(test_case["label"])
		var expected: Dictionary = test_case["expected"]
		var actual: Dictionary = player.call("_get_current_attack_profile")
		_verify_attack_profile_values(actual, expected, label)

		var built_damage := player.call("_build_attack_damage") as DamageData
		_expect(built_damage != null, "%s builds DamageData." % label)
		if built_damage:
			_expect(
				built_damage.amount == roundi(float(expected["damage"])),
				"%s uses its exact damage." % label
			)
			_expect(
				is_equal_approx(built_damage.hitstun, float(expected["hitstun"])),
				"%s uses its exact hitstun." % label
			)
			_expect(
				is_equal_approx(built_damage.knockback.length(), float(expected["knockback"])),
				"%s uses its exact knockback." % label
			)
			_expect(
				is_equal_approx(built_damage.hit_pause, float(expected["hit_pause"])),
				"%s uses its exact hit pause." % label
			)
			_expect(
				is_equal_approx(
					built_damage.screen_shake_strength,
					float(expected["screen_shake"])
				),
				"%s owns its exact screen shake." % label
			)
			_expect(
				not built_damage.use_receiver_screen_shake_fallback,
				"%s disables receiver-owned screen-shake fallback." % label
			)

	var legacy_damage := DamageData.new()
	_expect(
		legacy_damage.use_receiver_screen_shake_fallback,
		"Legacy DamageData keeps receiver-owned screen-shake fallback by default."
	)
	player.free()

func _verify_backpedal_chain_lock() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for backpedal-chain verification.")
	if player == null:
		return

	add_child(player)
	player.set_physics_process(false)
	player.last_direction = 1
	player.set("ground_attack_locked_facing", 1)
	player.call("_begin_ground_combo_attack", &"forward", &"backpedal")
	player.set("ground_combo_queued", true)
	player.set("ground_combo_queued_family", &"forward")
	# Simulate an external movement-facing write between the opener and finisher.
	player.last_direction = -1
	player.call("_finish_ground_combo_attack")
	_expect(
		StringName(player.get("ground_attack_visual_mode")) == &"backpedal"
		and int(player.get("ground_combo_step")) == 1,
		"A queued backpedal opener retains the backpedal finisher profile."
	)
	_expect(
		player.last_direction == 1,
		"Backpedal finisher retains the opener's committed attack facing."
	)
	player.free()

func _attack_profile(
	damage: float,
	hitstun: float,
	knockback: float,
	hit_pause: float,
	screen_shake: float
) -> Dictionary:
	return {
		"damage": damage,
		"hitstun": hitstun,
		"knockback": knockback,
		"hit_pause": hit_pause,
		"screen_shake": screen_shake,
	}

func _verify_attack_profile_values(
	actual: Dictionary,
	expected: Dictionary,
	label: String
) -> void:
	for field in expected:
		_expect(
			actual.has(StringName(field)),
			"%s exposes its %s profile field." % [label, field]
		)
		if not actual.has(StringName(field)):
			continue
		_expect(
			is_equal_approx(
				float(actual[StringName(field)]),
				float(expected[field])
			),
			"%s has the approved %s value." % [label, field]
		)

func _verify_flow_attack_multipliers() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for Flow multiplier verification.")
	if player == null:
		return

	player.set("_flow_state_active", false)
	player.set("momentum", float(player.get("momentum_high_threshold")))
	_expect(
		is_equal_approx(float(player.call("get_momentum_attack_speed_multiplier")), 1.10),
		"Entering High momentum immediately grants 1.10 attack speed."
	)
	_expect(
		is_equal_approx(float(player.call("get_momentum_attack_damage_multiplier")), 1.05),
		"Entering High momentum immediately grants 1.05 attack damage."
	)

	player.set("_flow_state_active", true)
	_expect(
		is_equal_approx(float(player.call("get_momentum_attack_speed_multiplier")), 1.15),
		"Flow grants 1.15 attack speed."
	)
	_expect(
		is_equal_approx(float(player.call("get_momentum_attack_damage_multiplier")), 1.10),
		"Flow grants 1.10 attack damage."
	)
	player.free()

func _verify_meditation_flow_presentation() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(
		player != null,
		"Player scene instantiates for meditation Flow-presentation verification."
	)
	if player == null:
		return

	_expect(
		is_equal_approx(float(player.get("meditation_flow_audio_pitch")), 0.78),
		"Meditation uses the approved lower-pitched Flow-entry sound."
	)
	_expect(
		is_equal_approx(float(player.get("meditation_flow_audio_volume_db")), -4.0),
		"Meditation keeps its Flow-attempt sound quieter than full ignition."
	)
	player.free()

func _verify_player_resistance_metadata() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for resistance verification.")
	if player == null:
		return

	var test_stats := (player.get("player_stats") as PlayerStats).duplicate(true) as PlayerStats
	test_stats.resistance = 50
	player.set("player_stats", test_stats)
	var source := Node2D.new()
	var incoming := DamageData.new()
	incoming.amount = 20
	incoming.source = source
	incoming.hit_position = Vector2(18.0, -32.0)
	var modified := player.call("modify_incoming_health_damage", incoming) as DamageData
	_expect(
		modified != null and modified.amount < incoming.amount,
		"Player resistance mitigates incoming damage."
	)
	_expect(
		modified != null
		and modified.source == source
		and modified.hit_position == incoming.hit_position,
		"Player resistance preserves source and hit-position metadata."
	)
	source.free()
	player.free()

func _verify_neutral_special_contract() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for neutral-special verification.")
	if player == null:
		return

	_expect(
		not bool(player.call("can_start_attack", true)),
		"Neutral smash cannot begin without grounded floor contact."
	)
	_expect(
		not bool(player.call("_can_process_jump_input", true)),
		"Same-frame attack input takes priority over jump input."
	)
	player.set("current_attack_is_special", true)
	player.set("is_attacking", true)
	player.set("attack_active_finished", false)
	_expect(
		bool(player.call("_is_attack_movement_committed")),
		"Neutral smash keeps movement and jumping committed until impact."
	)
	_expect(
		not bool(player.call("_can_process_jump_input", false)),
		"Committed neutral smash blocks later jump input through impact."
	)
	player.set("is_attacking", false)
	var player_stats := player.get("player_stats") as PlayerStats
	_expect(player_stats != null, "Neutral special has a PlayerStats resource.")
	_expect(
		int(player.get("neutral_special_action_point_cost")) == 2,
		"Neutral special costs two action points."
	)
	var polygon: PackedVector2Array = player.call(
		"_build_circle_hitbox_polygon",
		float(player.get("neutral_special_aoe_radius"))
	)
	_expect(polygon.size() == 16, "Neutral special builds a stable 16-point radial hitbox.")
	for point in polygon:
		_expect(
			is_equal_approx(point.length(), float(player.get("neutral_special_aoe_radius"))),
			"Every neutral-special hitbox point uses the configured AOE radius."
		)

	var damage := player.call("_build_attack_damage") as DamageData
	_expect(damage != null, "Neutral special builds DamageData.")
	if damage:
		_expect(damage.amount == 70, "Neutral special deals 70 base damage.")
		_expect(
			is_equal_approx(damage.hitstun, float(player.get("neutral_special_hitstun"))),
			"Neutral special applies its dedicated hitstun."
		)
		_expect(
			is_equal_approx(damage.hit_pause, float(player.get("neutral_special_hit_pause"))),
			"Neutral special applies one dedicated hit-pause request."
		)
		_expect(
			not damage.use_receiver_screen_shake_fallback,
			"Neutral special disables receiver-owned screen-shake fallback."
		)

	_expect(
		is_equal_approx(float(player.get("neutral_special_aoe_radius")), 220.0),
		"Neutral special uses a 220-pixel radius."
	)
	var full_force_radius := (
		float(player.get("neutral_special_aoe_radius"))
		* float(player.get("neutral_special_full_force_radius_ratio"))
	)
	_expect(
		is_equal_approx(full_force_radius, 99.0),
		"Neutral special keeps full force through 99 pixels."
	)
	_expect(
		is_equal_approx(float(player.get("neutral_special_hitstun")), 0.30)
		and is_equal_approx(float(player.get("neutral_special_edge_hitstun")), 0.24),
		"Neutral-special hitstun falls from 0.30 to 0.24."
	)
	_expect(
		float(player.get("neutral_special_edge_knockback_ratio")) >= 0.75,
		"Neutral-special edge knockback retains at least 75 percent force."
	)
	_expect(
		float(player.get("neutral_special_screen_shake_strength")) > 0.0
		and float(player.get("neutral_special_screen_shake_duration")) > 0.0,
		"Neutral-special impact owns one explicit screen-shake request."
	)

	if damage:
		var full_force_damage := _build_radial_damage(player, damage, full_force_radius)
		_expect(full_force_damage != null, "Neutral special returns full-force per-target damage.")
		if full_force_damage:
			_expect(
				full_force_damage.amount == 70,
				"Neutral special still deals 70 damage at the 99-pixel full-force boundary."
			)
			_expect(
				is_equal_approx(full_force_damage.hitstun, 0.30),
				"Neutral special retains 0.30 hitstun inside the full-force radius."
			)

		var quarter_falloff_distance := lerpf(
			full_force_radius,
			float(player.get("neutral_special_aoe_radius")),
			0.25
		)
		var quarter_damage := _build_radial_damage(
			player,
			damage,
			quarter_falloff_distance
		)
		_expect(quarter_damage != null, "Neutral special returns smooth-falloff damage.")
		if quarter_damage:
			_expect(
				quarter_damage.amount == 65,
				"Neutral-special damage uses smoothstep rather than linear quarter falloff."
			)
			_expect(
				is_equal_approx(quarter_damage.hitstun, 0.290625),
				"Neutral-special hitstun follows the same smooth falloff."
			)

		var edge_damage := _build_radial_damage(
			player,
			damage,
			float(player.get("neutral_special_aoe_radius"))
		)
		_expect(edge_damage != null, "Neutral special returns edge per-target damage.")
		if edge_damage:
			_expect(edge_damage.amount == 39, "Neutral special deals about 39 damage at its edge.")
			_expect(
				is_equal_approx(edge_damage.hitstun, 0.24),
				"Neutral special applies 0.24 hitstun at its edge."
			)
			if player_stats:
				var full_knockback := (
					float(player_stats.knockback_strength)
					* float(player.get("neutral_special_knockback_multiplier"))
				)
				_expect(
					edge_damage.knockback.length() >= full_knockback * 0.75 - 0.001,
					"Neutral special retains at least 75 percent knockback at its edge."
				)
			_expect(
				edge_damage.knockback.x > 0.0 and edge_damage.knockback.y < 0.0,
				"Neutral-special knockback moves each target outward with upward lift."
			)
	player.free()

func _build_radial_damage(
	player: Node,
	base_damage: DamageData,
	target_distance: float
) -> DamageData:
	var target_owner := Node2D.new()
	var target_hurtbox := HurtboxComponent.new()
	var impact_position: Vector2 = player.call(
		"_get_neutral_special_ground_contact_position"
	)
	target_owner.position = impact_position + Vector2.RIGHT * target_distance
	target_hurtbox.hurtbox_owner = target_owner
	var radial_damage := player.call(
		"modify_outgoing_hit_damage",
		base_damage.duplicate(true),
		target_hurtbox
	) as DamageData
	target_hurtbox.free()
	target_owner.free()
	return radial_damage

func _verify_dash_contract() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for dash verification.")
	if player == null:
		return

	var chest := BaseChest.new(player)
	player.set("current_chest", chest)
	_expect(is_equal_approx(chest.dash_speed, 1150.0), "Dash speed is 1150 pixels per second.")
	_expect(is_equal_approx(chest.dash_duration, 0.30), "Dash movement lasts 0.30 seconds.")
	_expect(is_equal_approx(chest.dash_cooldown, 0.65), "Dash cooldown is 0.65 seconds.")
	_expect(
		is_equal_approx(chest.dash_duration + chest.dash_iframe_grace, 0.36),
		"Dash immunity covers movement plus grace for 0.36 seconds."
	)
	_expect(
		chest.dash_speed * player.momentum_dash_speed_low * chest.dash_duration
		>= 325.0,
		"Low-momentum dash clears the widest current enemy with a safety margin."
	)
	_expect(
		not bool(player.call("should_ignore_health_damage", DamageData.new())),
		"Player is damageable before a dash starts."
	)
	_expect(
		not bool(player.call("should_ignore_enemy_contact")),
		"Player collides with enemy contact before a dash starts."
	)
	player.set("is_attacking", true)
	player.set("current_attack_is_special", true)
	player.set("attack_timer", 0.12)
	player.set("attack_active_started", false)
	player.set("attack_active_finished", false)
	_expect(
		bool(player.call("can_start_dash")),
		"Dash can correct a committed special during its pre-impact windup."
	)
	player.set("attack_timer", 0.52)
	player.set("attack_active_started", true)
	_expect(
		not bool(player.call("can_start_dash")),
		"Dash cannot erase a special while its damaging frames are active."
	)
	player.set("attack_timer", 1.04)
	player.set("attack_active_finished", true)
	_expect(
		bool(player.call("can_start_dash")),
		"Dash can escape the authored end of special recovery."
	)
	player.set("is_attacking", false)
	player.set("current_attack_is_special", false)
	player.set("attack_active_started", false)
	player.set("attack_active_finished", false)
	player.last_direction = 1
	player.set("_dash_direction_intent", -1)
	player.set("_dash_direction_intent_timer", 0.18)
	_expect(
		int(player.call("get_dash_direction_intent")) == -1,
		"A recent opposite movement input overrides attack-locked facing for dash."
	)

	var started := bool(chest.call("_start_dash"))
	_expect(started, "A ready chest starts a dash deterministically.")
	_expect(chest.dash_direction == -1, "Dash uses the buffered opposite direction instead of attack facing.")
	_expect(player.last_direction == -1, "A direction-controlled dash turns the player toward its escape route.")
	_expect(
		not bool(player.call("can_start_attack", false)),
		"An active dash blocks attacks from overriding dash-owned movement."
	)
	_expect(is_equal_approx(chest.dash_timer, 0.30), "Started dash receives its full movement time.")
	_expect(
		is_equal_approx(chest.get_dash_cooldown_remaining(), 0.65),
		"Started dash receives its full actual cooldown."
	)
	_expect(
		is_equal_approx(float(player.get("_dash_iframe_timer")), 0.36),
		"Started dash receives exactly 0.36 seconds of immunity."
	)
	_expect(
		bool(player.call("should_ignore_health_damage", DamageData.new())),
		"Dash immunity rejects authored health damage."
	)
	_expect(
		bool(player.call("should_ignore_enemy_contact")),
		"Dash immunity rejects enemy contact before separation."
	)
	_expect(
		bool(player.call("is_dash_contact_phasing")),
		"Dash enables temporary contact handling."
	)
	var contact_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	var player_hurtbox := HurtboxComponent.new()
	contact_enemy.stats = THREADLING_STATS
	contact_enemy.position = Vector2(24.0, 0.0)
	contact_enemy.velocity = Vector2(37.0, 0.0)
	player.add_to_group("player")
	player_hurtbox.hurtbox_owner = player
	var enemy_position_before := contact_enemy.position
	var enemy_velocity_before := contact_enemy.velocity
	_expect(
		bool(contact_enemy.call("_try_contact_hurtbox", player_hurtbox)),
		"Enemy contact recognizes an invulnerable dashing player."
	)
	_expect(
		not chest.is_dash_active()
		and contact_enemy.position == enemy_position_before
		and contact_enemy.velocity == enemy_velocity_before,
		"Dash contact stops the player without pushing the enemy."
	)
	player_hurtbox.free()
	contact_enemy.free()

	var blocking_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	var blocking_hurtbox := HurtboxComponent.new()
	blocking_enemy.stats = THREADLING_STATS
	blocking_enemy.position = Vector2(24.0, 0.0)
	blocking_enemy.velocity = Vector2(37.0, 0.0)
	blocking_hurtbox.hurtbox_owner = player
	player.position = Vector2(12.0, 0.0)
	player.set("_position_before_movement", Vector2(7.0, 0.0))
	var lingering_contact_hits := [0]
	blocking_hurtbox.hit_received.connect(
		func(_damage: DamageData) -> void:
			lingering_contact_hits[0] += 1
	)
	var blocking_position_before := blocking_enemy.position
	var blocking_velocity_before := blocking_enemy.velocity
	_expect(
		bool(blocking_enemy.call("_try_contact_hurtbox", blocking_hurtbox)),
		"A non-pass-through enemy recognizes dash contact."
	)
	_expect(
		not chest.is_dash_active()
		and is_equal_approx(player.position.x, 7.0)
		and blocking_enemy.position == blocking_position_before
		and blocking_enemy.velocity == blocking_velocity_before,
		"Enemy contact restores the player's pre-move position without pushing the enemy."
	)
	player.call("_process_momentum", 0.359)
	_expect(
		bool(player.call("should_ignore_health_damage", DamageData.new()))
		and bool(player.call("should_ignore_enemy_contact")),
		"Dash remains immune through almost all 0.36 seconds."
	)
	player.call("_process_momentum", 0.002)
	_expect(
		not bool(player.call("should_ignore_health_damage", DamageData.new()))
		and not bool(player.call("should_ignore_enemy_contact")),
		"Dash immunity ends after the 0.36-second window."
	)
	_expect(
		not bool(player.call("is_dash_contact_phasing")),
		"Dash contact handling ends with the immunity window so lingering contact can deal damage."
	)
	_expect(
		bool(blocking_enemy.call("_try_contact_hurtbox", blocking_hurtbox))
		and lingering_contact_hits[0] == 1,
		"Contact is delivered if the player remains against the enemy when dash immunity ends."
	)
	_expect(
		blocking_enemy.position == blocking_position_before
		and blocking_enemy.velocity == blocking_velocity_before,
		"Lingering player contact never displaces the enemy."
	)
	blocking_hurtbox.free()
	blocking_enemy.free()

	chest.process_passive(0.649)
	_expect(
		chest.get_dash_cooldown_remaining() > 0.0,
		"Dash remains unavailable just before 0.65 seconds."
	)
	chest.process_passive(0.002)
	_expect(
		is_zero_approx(chest.get_dash_cooldown_remaining()),
		"Dash cooldown ends after 0.65 seconds."
	)
	player.set("current_chest", null)
	chest.free()
	player.free()


func _verify_dash_collision_runtime() -> void:
	var player := PLAYER_SCENE.instantiate()
	var enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	enemy.stats = THREADLING_STATS
	player.position = Vector2(300.0, 400.0)
	enemy.position = Vector2(400.0, 400.0)
	add_child(player)
	add_child(enemy)
	await get_tree().physics_frame

	player.set_physics_process(false)
	if enemy.state_machine:
		enemy.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.velocity = Vector2.ZERO
	await get_tree().physics_frame

	var safe_position: Vector2 = player.global_position
	var enemy_position_before: Vector2 = enemy.global_position
	player.set("_position_before_movement", safe_position)
	player.call("start_dash_iframe", 0.36, Vector2.RIGHT)
	player.global_position = enemy.global_position
	player.velocity = Vector2(1150.0, 0.0)
	await get_tree().physics_frame

	_expect(player.hurtbox.monitorable, "Dash immunity hides the player from solid enemy contact detection.")
	_expect(
		is_equal_approx(player.global_position.x, safe_position.x)
		and is_zero_approx(player.velocity.x),
		"A real enemy overlap does not stop dash movement at the last safe position."
	)
	_expect(
		enemy.global_position == enemy_position_before,
		"A real dash overlap transfers player movement into the enemy."
	)

	player.queue_free()
	enemy.queue_free()
	await get_tree().process_frame

func _verify_enemy_receiver_profiles() -> void:
	var cases: Array[Dictionary] = [
		{
			"label": "Threadling light",
			"stats": THREADLING_STATS,
			"knockback": 1.10,
			"hitstun": 1.20,
		},
		{
			"label": "Loomkin middle",
			"stats": LOOMKIN_STATS,
			"knockback": 0.90,
			"hitstun": 1.05,
		},
		{
			"label": "Tensioner heavy",
			"stats": TENSIONER_STATS,
			"knockback": 0.75,
			"hitstun": 0.90,
		},
	]

	for test_case in cases:
		var label := String(test_case["label"])
		var stats := test_case["stats"] as EnemyStats
		var expected_knockback := float(test_case["knockback"])
		var expected_hitstun := float(test_case["hitstun"])
		_expect(stats != null, "%s receiver stats load." % label)
		if stats == null:
			continue
		_expect(stats.use_polished_hurt_response, "%s opts into polished hurt response." % label)
		_expect(
			is_equal_approx(stats.incoming_hit_invulnerability, 0.06),
			"%s accepts distinct rapid combo strikes after 0.06 seconds." % label
		)
		_expect(
			is_equal_approx(stats.incoming_knockback_multiplier, expected_knockback),
			"%s uses its approved knockback multiplier." % label
		)
		_expect(
			is_equal_approx(stats.incoming_hitstun_multiplier, expected_hitstun),
			"%s uses its approved hitstun multiplier." % label
		)

		var enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
		_expect(enemy != null, "%s receiver instantiates." % label)
		if enemy == null:
			continue
		enemy.stats = stats
		var outgoing := enemy.call("_build_attack_damage") as DamageData
		_expect(
			outgoing != null
			and is_equal_approx(outgoing.screen_shake_strength, stats.screen_shake_strength)
			and not outgoing.use_receiver_screen_shake_fallback,
			"%s opts into move-owned outgoing screen shake." % label
		)
		var incoming := DamageData.new()
		incoming.amount = 11
		incoming.knockback = Vector2(100.0, -40.0)
		incoming.hitstun = 0.20
		var source := Node2D.new()
		incoming.source = source
		incoming.hit_position = Vector2(42.0, -18.0)
		var modified := enemy.modify_incoming_health_damage(incoming)
		_expect(modified != null, "%s returns modified incoming damage." % label)
		if modified:
			_expect(modified.amount == incoming.amount, "%s does not alter incoming damage." % label)
			_expect(
				modified.knockback.is_equal_approx(
					incoming.knockback * expected_knockback
				),
				"%s applies its knockback multiplier to the received hit." % label
			)
			_expect(
				is_equal_approx(
					modified.hitstun,
					incoming.hitstun * expected_hitstun
				),
				"%s applies its hitstun multiplier to the received hit." % label
			)
			_expect(
				modified.source == source
				and modified.hit_position == incoming.hit_position,
				"%s preserves source and hit-position metadata while scaling." % label
			)
		_expect(
			incoming.knockback.is_equal_approx(Vector2(100.0, -40.0))
			and is_equal_approx(incoming.hitstun, 0.20),
			"%s leaves the shared incoming DamageData unchanged." % label
		)
		source.free()
		enemy.free()

	var legacy_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	legacy_enemy.stats = EnemyStats.new()
	var legacy_outgoing := legacy_enemy.call("_build_attack_damage") as DamageData
	_expect(
		legacy_outgoing != null
		and legacy_outgoing.use_receiver_screen_shake_fallback
		and is_zero_approx(legacy_outgoing.screen_shake_strength),
		"Non-opt-in enemies preserve legacy receiver-owned feedback for boss isolation."
	)
	legacy_enemy.free()

func _verify_enemy_health_bar_contract() -> void:
	var owner := Node2D.new()
	var health := HealthComponent.new()
	var hurtbox := HurtboxComponent.new()
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	var health_bar := ENEMY_HEALTH_BAR_SCENE.instantiate() as EnemyHealthBar
	rectangle.size = Vector2(80.0, 120.0)
	collision_shape.position = Vector2(0.0, -60.0)
	collision_shape.shape = rectangle
	owner.add_child(health)
	owner.add_child(hurtbox)
	hurtbox.add_child(collision_shape)
	owner.add_child(health_bar)
	health.configure(100)
	health_bar.setup(health, hurtbox, true)

	_expect(not health_bar.visible, "Enemy health bar starts hidden at full health.")
	_expect(
		health_bar.position.y < -120.0,
		"Enemy health bar follows the top of its hurtbox."
	)
	health.current_health = 75
	health.damaged.emit(DamageData.new())
	_expect(
		health_bar.visible
		and is_equal_approx(float(health_bar.get("_health_ratio")), 0.75),
		"Enemy health bar appears with the recent damaged health ratio."
	)
	health_bar.call("_process", health_bar.visible_duration + 0.1)
	_expect(
		health_bar.visible and health_bar.modulate.a < 1.0,
		"Enemy health bar fades after its recent-damage hold."
	)
	health_bar.call("_process", health_bar.fade_duration)
	_expect(not health_bar.visible, "Enemy health bar hides after its fade.")

	health.current_health = 50
	health.damaged.emit(DamageData.new())
	health.died.emit(DamageData.new())
	_expect(not health_bar.visible, "Enemy health bar hides immediately on death.")

	health_bar.setup(health, hurtbox, false)
	health.current_health = 40
	health.damaged.emit(DamageData.new())
	_expect(
		not health_bar.visible,
		"Disabled health bars stay hidden for boss and non-resetting-enemy opt-outs."
	)
	owner.free()

	var normal_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	normal_enemy.stats = THREADLING_STATS
	normal_enemy.resets_at_save_points = true
	add_child(normal_enemy)
	_expect(
		bool(normal_enemy.enemy_health_bar.get("_enabled")),
		"Resetting normal enemies enable their recent-damage health bar."
	)
	normal_enemy.free()

	var boss_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	boss_enemy.stats = THREADLING_STATS
	boss_enemy.resets_at_save_points = true
	boss_enemy.add_to_group("bosses")
	add_child(boss_enemy)
	_expect(
		not bool(boss_enemy.enemy_health_bar.get("_enabled")),
		"Boss-group enemies opt out of the normal-enemy health bar."
	)
	boss_enemy.free()

	var persistent_enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	persistent_enemy.stats = THREADLING_STATS
	persistent_enemy.resets_at_save_points = false
	add_child(persistent_enemy)
	_expect(
		not bool(persistent_enemy.enemy_health_bar.get("_enabled")),
		"Non-resetting enemies opt out of the normal recent-damage health bar."
	)
	persistent_enemy.free()

func _verify_per_target_damage_hook() -> void:
	var owner := DamageModifierOwner.new()
	var target_owner := Node2D.new()
	var hitbox := HitboxComponent.new()
	var hurtbox := HurtboxComponent.new()
	add_child(owner)
	add_child(target_owner)
	owner.add_child(hitbox)
	target_owner.add_child(hurtbox)
	hitbox.hitbox_owner = owner
	hurtbox.hurtbox_owner = target_owner

	var base_damage := DamageData.new()
	base_damage.amount = 10
	hitbox.damage = base_damage
	var landed: Dictionary = {}
	hitbox.hit_landed.connect(
		func(_hurtbox: HurtboxComponent, damage: DamageData) -> void:
			landed["damage"] = damage
	)
	hitbox.enable()
	hitbox.call("_on_area_entered", hurtbox)

	_expect(owner.modifier_calls == 1, "Hitbox asks its owner to modify each outgoing hit.")
	var landed_damage := landed.get("damage") as DamageData
	_expect(landed_damage != null, "Modified outgoing damage still lands.")
	if landed_damage:
		_expect(landed_damage.amount == 17, "Per-target damage modification is preserved.")

	owner.queue_free()
	target_owner.queue_free()

func _verify_enemy_hitstun() -> void:
	var enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	_expect(enemy != null, "Enemy base scene instantiates for hitstun verification.")
	if enemy == null:
		return

	add_child(enemy)
	var damage := DamageData.new()
	damage.amount = 1
	damage.hitstun = 0.31
	damage.hit_pause = 0.0
	enemy.health_component.apply_damage(damage)

	_expect(
		enemy.state_machine.current_state_name == &"Hurt",
		"Accepted damage transitions an enemy to Hurt."
	)
	if enemy.state_machine.current_state_name == &"Hurt":
		var hurt_timer := float(enemy.state_machine.current_state.get("_timer"))
		_expect(
			is_equal_approx(hurt_timer, damage.hitstun),
			"Enemy Hurt duration comes from DamageData.hitstun."
		)
	enemy.queue_free()

func _verify_attack_overlap_retry() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for rapid-hit overlap verification.")
	if player == null:
		return
	add_child(player)
	await get_tree().process_frame
	player.set_physics_process(false)

	var target_owner := Node2D.new()
	var health := HealthComponent.new()
	var hurtbox := HurtboxComponent.new()
	var hurtbox_shape := CollisionShape2D.new()
	var hurtbox_rectangle := RectangleShape2D.new()
	health.max_health = 100
	health.invincible_after_hit = 0.06
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 4
	hurtbox_rectangle.size = Vector2(96.0, 96.0)
	hurtbox_shape.shape = hurtbox_rectangle
	target_owner.add_child(health)
	target_owner.add_child(hurtbox)
	hurtbox.add_child(hurtbox_shape)
	add_child(target_owner)
	hurtbox.health_component = health
	hurtbox.hurtbox_owner = target_owner
	target_owner.global_position = player.attack_hitbox.global_position
	await get_tree().physics_frame

	var strike_damage := DamageData.new()
	strike_damage.amount = 7
	strike_damage.hit_pause = 0.0
	strike_damage.use_receiver_screen_shake_fallback = false
	player.attack_hitbox.damage = strike_damage
	health.current_health = 100
	health.set("_invincible_timer", 0.06)
	player.attack_hitbox.enable()
	await get_tree().physics_frame
	_expect(
		player.attack_hitbox.get_overlapping_areas().has(hurtbox),
		"Rapid-hit verifier establishes a real persistent hitbox overlap."
	)

	player.call("_retry_active_attack_overlaps")
	_expect(
		health.current_health == 100,
		"An overlap retry remains rejected while target immunity is active."
	)
	health.call("_process", 0.061)
	player.call("_retry_active_attack_overlaps")
	_expect(
		health.current_health == 93,
		"A distinct strike activation lands once after the short immunity expires."
	)
	player.call("_retry_active_attack_overlaps")
	_expect(
		health.current_health == 93,
		"Accepted overlap retry cannot duplicate within the same strike activation."
	)

	player.attack_hitbox.disable()
	player.queue_free()
	target_owner.queue_free()
	await get_tree().process_frame

func _verify_coalesced_feedback() -> void:
	var camera := Camera2D.new()
	var base_offset := Vector2(3.0, -2.0)
	camera.offset = base_offset
	add_child(camera)
	camera.enabled = true
	camera.make_current()
	await get_tree().process_frame

	CombatFeedback.screen_shake(self, 2.0, 0.035)
	CombatFeedback.screen_shake(self, 7.0, 0.075)
	await get_tree().create_timer(0.11, true, false, true).timeout
	_expect(
		camera.offset.is_equal_approx(base_offset),
		"Overlapping screen-shake requests settle on the camera's original offset."
	)

	_expect(
		is_equal_approx(CombatFeedback.get_effective_hit_pause_duration(0.03), 0.05),
		"Light hitstop reaches the minimum visible duration."
	)
	_expect(
		is_equal_approx(CombatFeedback.get_effective_hit_pause_duration(0.065), 0.10725),
		"Heavy authored hitstop scales to approximately one tenth of a second."
	)
	_expect(
		is_equal_approx(CombatFeedback.get_effective_hit_pause_duration(0.20), 0.12),
		"Hitstop is capped so repeated heavy impacts cannot become disruptive."
	)
	_expect(
		is_zero_approx(CombatFeedback.get_effective_hit_pause_duration(0.0)),
		"Explicitly disabled hitstop remains disabled."
	)

	CombatFeedback.hit_pause(self, 0.03)
	var short_pause_end := CombatFeedback._pause_end_usec
	CombatFeedback.hit_pause(self, 0.07)
	var long_pause_end := CombatFeedback._pause_end_usec
	_expect(Engine.time_scale < 1.0, "Hit pause begins immediately.")
	_expect(
		long_pause_end > short_pause_end + 30000,
		"A longer overlapping hit-pause request extends the shared deadline."
	)
	await get_tree().create_timer(0.15, true, false, true).timeout
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Hit pause restores normal time once.")
	camera.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Combat feedback verification: " + message)

func _finish() -> void:
	if _failures.is_empty():
		print("Combat feedback verification passed.")
		get_tree().quit(0)
		return
	print("Combat feedback verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)

class DamageModifierOwner:
	extends Node2D

	var modifier_calls := 0

	func modify_outgoing_hit_damage(
		damage: DamageData,
		_target_hurtbox: HurtboxComponent
	) -> DamageData:
		modifier_calls += 1
		damage.amount += 7
		return damage
