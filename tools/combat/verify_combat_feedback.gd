extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const ENEMY_BASE_SCENE := preload("res://Src/Enemies/EnemyBase/enemy_base.tscn")

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run_verification")

func _run_verification() -> void:
	_verify_neutral_special_contract()
	_verify_per_target_damage_hook()
	_verify_enemy_hitstun()
	await _verify_coalesced_feedback()
	_finish()

func _verify_neutral_special_contract() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect(player != null, "Player scene instantiates for neutral-special verification.")
	if player == null:
		return

	player.set("current_attack_is_special", true)
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
		_expect(
			is_equal_approx(damage.hitstun, float(player.get("neutral_special_hitstun"))),
			"Neutral special applies its dedicated hitstun."
		)
		_expect(
			is_equal_approx(damage.hit_pause, float(player.get("neutral_special_hit_pause"))),
			"Neutral special applies one dedicated hit-pause request."
		)

	var target_owner := Node2D.new()
	var target_hurtbox := HurtboxComponent.new()
	target_owner.position = Vector2(100.0, 0.0)
	target_hurtbox.hurtbox_owner = target_owner
	var radial_damage := player.call(
		"modify_outgoing_hit_damage",
		damage,
		target_hurtbox
	) as DamageData
	_expect(radial_damage != null, "Neutral special returns per-target damage.")
	if radial_damage:
		_expect(
			radial_damage.knockback.x > 0.0 and radial_damage.knockback.y < 0.0,
			"Neutral-special knockback moves each target outward with upward lift."
		)
	target_hurtbox.free()
	target_owner.free()
	player.free()

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

	CombatFeedback.hit_pause(self, 0.03)
	CombatFeedback.hit_pause(self, 0.07)
	_expect(Engine.time_scale < 1.0, "Hit pause begins immediately.")
	await get_tree().create_timer(0.045, true, false, true).timeout
	_expect(
		Engine.time_scale < 1.0,
		"A longer overlapping hit-pause request is not ended by the shorter request."
	)
	await get_tree().create_timer(0.05, true, false, true).timeout
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
