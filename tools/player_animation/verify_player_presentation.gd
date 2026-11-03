extends Node
## Real-player regression for the sprite-free presentation boundary.
const PLAYER := preload("res://Src/Characters/Player/player.tscn")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("PLAYER_PRESENTATION_FAIL: " + message)

func _ready() -> void:
	var player = PLAYER.instantiate()
	add_child(player)
	player.set_physics_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	var clock: PlayerAnimationClock = player.animation_clock
	check(clock.get_animation_names().size() == 24, "All 24 action timelines remain available.")
	for path in ["Player Animation", "GlowSprite", "WallClingVFX", "PatternClothingOverlay", "EquipmentMount/BackSheathedWeaverShuttle", "AnimationPlayer"]:
		check(not player.has_node(path), "Retired node remains: " + path)
	check(player.get_character_visual() is Sprite2D, "Visible avatar is the live composite.")
	check(clock.get_class() == "Node", "Timing does not render or carry sprite transforms.")
	check(is_equal_approx(player.get_node("CollisionShape2D").shape.height,126.244995), "Standing collider is preserved.")
	check(player.get_node("Hurtbox/CollisionShape2D").shape.size == Vector2(38,124), "Hurtbox is preserved.")
	player.is_crouching = true
	player._apply_crouch_collision(true)
	player.update_animations(0.0)
	check(player.current_body_anim == "Crouch_Idle", "Crouch selects the current 3D action.")
	check(player.get_node("CollisionShape2D").shape.height < 100.0, "Crouch retains the shorter physical collider.")
	player.is_crouching = false
	player._apply_crouch_collision(false)
	player.is_blocking = true
	player.update_animations(0.0)
	check(player.current_body_anim == "Block_Idle", "Standing guard selects the current 3D action.")
	check(is_equal_approx(player.get_node("CollisionShape2D").shape.height,126.244995), "Standing restores the collider.")
	player.is_blocking = false
	var anchor_player: AnimationPlayer = player.get_node("AttackPoseAnimationPlayer")
	check(anchor_player.get_animation_list() == PackedStringArray(["RESET","quick_attack"]), "Only active anchor clips remain.")
	for name in anchor_player.get_animation_list():
		var clip := anchor_player.get_animation(name)
		for index in clip.get_track_count():
			check(String(clip.track_get_path(index)).begins_with("EquipmentMount/AttackSwingRoot/AttackHitboxAnchor:"), "Pose tracks target the active hitbox anchor.")
	for side in [-1,1]:
		player.set_presentation_facing(side)
		player.update_equipment_facing()
		check(player.is_facing_left() == (side<0), "Controller stores presentation facing.")
		check(player.equipment_mount.scale.x == side, "Equipment follows presentation facing.")
		player.current_gloves.grapple_direction = Vector2(side,0)
		player.current_gloves._play_grapple_fire_animation()
		check(player.last_direction == side and player.get_presentation_facing() == side, "Grapple toss preserves movement and presentation facing.")
		player.current_attack_is_special = true
		player._apply_attack_visual_tuning()
		var expected: Vector2 = Vector2(4,-2) + Vector2(player.neutral_special_visual_offset.x*side,player.neutral_special_visual_offset.y) + Vector2(134*side,109)*Vector2(0.7,0.7)*player.neutral_special_visual_scale_multiplier
		check(player._get_neutral_special_ground_contact_position().is_equal_approx(player.to_global(expected)), "Special impact point is preserved for each facing.")
	player.current_attack_is_special = false
	var pattern := EquipmentPattern.new()
	pattern.action_point_recharge_multiplier = 1.25
	pattern.momentum_generation_multiplier = 1.5
	player.apply_equipment_pattern(pattern)
	check(is_equal_approx(player.get_pattern_action_point_recharge_multiplier(),1.25), "Pattern AP effect remains active.")
	check(is_equal_approx(player.get_pattern_momentum_generation_multiplier(),1.5), "Pattern momentum effect remains active.")
	check(not player.has_node("PatternClothingOverlay"), "Patterns do not recreate the hidden sprite layer.")
	player.apply_equipment_pattern(null)
	var damage := DamageData.new()
	damage.amount = 1
	damage.hit_pause = 0.0
	player._on_damaged(damage)
	check(player.hit_flash.target == player.get_character_visual(), "Damage flash targets the visible avatar.")
	player.is_hurt = false
	player.hurt_timer = 0.0
	clock.speed_scale = 1.25
	check(player.begin_save_point_interaction(self,player.global_position), "Save point interaction starts.")
	player._process_save_point_interaction(1.0/60.0)
	# Exercise real asynchronous completion and reverse playback with both clocks.
	for tick in 420:
		if player._save_point_seated: break
		await get_tree().process_frame
	check(player._save_point_seated and clock.animation == &"Sit", "Sitting completes and reaches the seated state: seated=%s clock=%s:%s playing=%s action=%s sequence=%s" % [player._save_point_seated,clock.animation,clock.frame,clock.is_playing(),player.live_3d_visual.get("_current_action"),player.live_3d_visual.get("_action_sequence_name")])
	player.end_save_point_interaction()
	check(clock.get_playing_speed()<0.0, "Standing reverses the preserved sit timeline.")
	for tick in 420:
		if not player.save_point_interaction_active: break
		await get_tree().process_frame
	check(not player.save_point_interaction_active, "Standing completes and restores control.")
	check(is_equal_approx(clock.speed_scale,1.25), "Save point restores playback speed.")
	check(player.equipment_mount.visible, "Save point restores active equipment visibility.")
	player.queue_free()
	await get_tree().process_frame
	print("PLAYER_PRESENTATION_CHECKS ", JSON.stringify({"checks":checks,"failed":failures.size(),"details":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
