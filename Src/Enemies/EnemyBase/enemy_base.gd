class_name EnemyBase
extends CharacterBody2D

signal target_acquired(target: Node2D)
signal target_lost()
signal attack_started()
signal attack_finished()

const ENEMY_DAMAGE_FRAY_TEXTURE := preload("res://Assets/VFX/enemy_damage_fray_VFX.png")
const ENEMY_DEATH_UNRAVEL_TEXTURE := preload("res://Assets/VFX/enemy_death_unravel_VFX.png")
const WHITE_KEY_VFX_SHADER := preload("res://Src/VFX/white_key_vfx.gdshader")

@export var stats: EnemyStats
@export var patrol_distance: float = 160.0
@export var start_facing: int = -1
@export var facing_dead_zone: float = 12.0

@onready var visuals: Node2D = $Visuals
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox as HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox as HitboxComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var hit_flash: HitFlashComponent = $HitFlashComponent as HitFlashComponent
@onready var state_machine: EnemyStateMachine = $StateMachine as EnemyStateMachine

var target: Node2D = null
var facing: int = -1
var is_dead := false
var home_position := Vector2.ZERO
var _target_speed := 0.0
var _attack_cooldown_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	home_position = global_position
	facing = sign(start_facing) if start_facing != 0 else -1

	if not stats:
		stats = EnemyStats.new()

	health_component.configure(stats.max_health)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

	hurtbox.health_component = health_component
	hurtbox.hurtbox_owner = self
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)

	attack_hitbox.hitbox_owner = self
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.hit_landed.connect(_on_attack_hit_landed)

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_area.body_exited.connect(_on_attack_body_exited)

	update_facing(facing)
	state_machine.initialize(self)

func _physics_process(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += stats.gravity * delta
		velocity.y = min(velocity.y, stats.max_fall_speed)

func move_enemy(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _target_speed, stats.acceleration * delta)
	move_and_slide()

func update_attack_motion(delta: float) -> void:
	apply_gravity(delta)
	move_enemy(delta)

func set_horizontal_target_speed(speed: float) -> void:
	_target_speed = speed

func on_patrol_started() -> void:
	if facing == 0:
		facing = -1
	update_facing(facing)

func patrol(_delta: float) -> void:
	var distance_from_home := global_position.x - home_position.x
	var is_moving_past_right_edge := distance_from_home >= patrol_distance and facing > 0
	var is_moving_past_left_edge := distance_from_home <= -patrol_distance and facing < 0
	if is_moving_past_right_edge or is_moving_past_left_edge:
		facing *= -1
		update_facing(facing)

	set_horizontal_target_speed(float(facing) * stats.move_speed)

func chase_target(_delta: float) -> void:
	if not target:
		set_horizontal_target_speed(0.0)
		return

	var target_delta_x := target.global_position.x - global_position.x
	var direction: int = facing
	if abs(target_delta_x) > facing_dead_zone:
		direction = int(sign(target_delta_x))
	else:
		set_horizontal_target_speed(0.0)
		return

	if direction == 0:
		direction = facing

	update_facing(direction)
	set_horizontal_target_speed(float(direction) * stats.chase_speed)

func can_attack() -> bool:
	return _attack_cooldown_timer <= 0.0 and not is_dead

func is_player_in_attack_range() -> bool:
	return target != null and attack_area.get_overlapping_bodies().has(target)

func begin_attack() -> void:
	attack_started.emit()
	set_horizontal_target_speed(0.0)
	_attack_cooldown_timer = stats.attack_cooldown

func activate_attack_hitbox() -> void:
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.enable()

func deactivate_attack_hitbox() -> void:
	if attack_hitbox.active:
		attack_hitbox.disable()

func end_attack() -> void:
	deactivate_attack_hitbox()
	attack_finished.emit()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	end_attack()
	set_physics_process(false)
	hurtbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	_play_death_collapse()
	await get_tree().create_timer(stats.death_cleanup_delay).timeout
	queue_free()

func update_facing(direction: int) -> void:
	if direction == 0:
		return

	facing = sign(direction)
	if visuals:
		visuals.scale.x = abs(visuals.scale.x) * float(facing)

	attack_hitbox.position.x = abs(attack_hitbox.position.x) * float(facing)
	attack_area.position.x = abs(attack_area.position.x) * float(facing)

func _build_attack_damage() -> DamageData:
	var data := DamageData.new()
	data.amount = stats.attack_damage
	data.hitstun = stats.hurt_time
	data.hit_pause = stats.hit_pause
	data.knockback = Vector2(float(facing) * stats.knockback_strength, -70.0)
	return data

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		target_acquired.emit(target)

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		target_lost.emit()

func _on_attack_body_entered(_body: Node2D) -> void:
	pass

func _on_attack_body_exited(_body: Node2D) -> void:
	pass

func _on_hurtbox_hit_received(_damage: DamageData) -> void:
	pass

func _on_damaged(damage: DamageData) -> void:
	if hit_flash:
		hit_flash.flash()

	if health_component.current_health > 0:
		_spawn_enemy_damage_vfx(damage)

	CombatFeedback.screen_shake(self, stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

	var knockback := damage.knockback
	if knockback == Vector2.ZERO and damage.source is Node2D:
		var source_node := damage.source as Node2D
		knockback = Vector2(sign(global_position.x - source_node.global_position.x) * stats.knockback_strength, -70.0)

	velocity = knockback

	if state_machine.current_state_name != &"Dead":
		state_machine.transition_to(&"Hurt")

func _on_died(_damage: DamageData) -> void:
	_spawn_enemy_death_vfx(_damage)
	if state_machine.current_state_name != &"Dead":
		state_machine.transition_to(&"Dead")

func _on_attack_hit_landed(_hurtbox: HurtboxComponent, damage: DamageData) -> void:
	CombatFeedback.screen_shake(self, stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

func _spawn_enemy_damage_vfx(damage: DamageData) -> void:
	var direction := _get_hit_direction(damage)
	var sprite := _make_one_shot_vfx_sprite(ENEMY_DAMAGE_FRAY_TEXTURE, 0.085)
	sprite.global_position = _get_vfx_origin(damage) + direction * 16.0
	sprite.rotation = direction.angle()
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.88)

	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.18, 0.18), 0.06).from(Vector2(0.045, 0.045))
	tween.tween_property(sprite, "modulate:a", 0.0, 0.16).set_delay(0.04)
	tween.tween_property(sprite, "position", sprite.position + direction * 22.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _spawn_enemy_death_vfx(damage: DamageData) -> void:
	var direction := _get_hit_direction(damage)
	var sprite := _make_one_shot_vfx_sprite(ENEMY_DEATH_UNRAVEL_TEXTURE, 0.12)
	sprite.global_position = global_position + Vector2(0.0, -24.0)
	sprite.rotation = direction.angle() * 0.2
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.34, 0.34), 0.2).from(Vector2(0.08, 0.08))
	tween.tween_property(sprite, "modulate:a", 0.95, 0.08)
	tween.tween_property(sprite, "position", sprite.position + direction * 18.0, 0.24)
	tween.set_parallel(false)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.26)
	tween.tween_callback(sprite.queue_free)

func _make_one_shot_vfx_sprite(texture: Texture2D, start_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.scale = Vector2(start_scale, start_scale)
	sprite.z_index = 80
	sprite.material = _make_white_key_material()

	var parent := get_parent()
	if parent:
		parent.add_child(sprite)
	else:
		add_child(sprite)
	return sprite

func _make_white_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WHITE_KEY_VFX_SHADER
	material.set_shader_parameter("key_threshold", 0.93)
	material.set_shader_parameter("key_softness", 0.08)
	return material

func _get_vfx_origin(damage: DamageData) -> Vector2:
	if damage.hit_position != Vector2.ZERO:
		return damage.hit_position
	return global_position + Vector2(0.0, -24.0)

func _get_hit_direction(damage: DamageData) -> Vector2:
	if damage.knockback.length() > 0.01:
		return damage.knockback.normalized()
	if damage.source is Node2D:
		var source_node := damage.source as Node2D
		var from_source := global_position - source_node.global_position
		if from_source.length() > 0.01:
			return from_source.normalized()
	return Vector2(float(facing), -0.15).normalized()

func _play_death_collapse() -> void:
	if not visuals:
		return

	var tween := visuals.create_tween()
	tween.set_parallel(true)
	tween.tween_property(visuals, "scale", Vector2(0.12 * float(facing), 0.02), 0.18)
	tween.tween_property(visuals, "modulate:a", 0.0, 0.18)
