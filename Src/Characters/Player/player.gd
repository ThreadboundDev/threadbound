extends CharacterBody2D

# ===============================
# NODES
# ===============================
@onready var player_animation: AnimatedSprite2D = $"Player Animation"
@onready var equipment_mount: Node2D = $EquipmentMount
@onready var camera = get_node_or_null("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam")
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var ability_cooldown_timer: Timer = $AbilityCooldownTimer
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox as HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox as HitboxComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent as HitFlashComponent

# ===============================
# EQUIPMENT SCENES
# ===============================
@export var base_gloves_scene: PackedScene
@export var player_stats: PlayerStats

# ===============================
# MOVEMENT TUNABLES
# ===============================
@export var speed: float = 500.0
@export var air_control_mult: float = 0.75
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1000.0
@export var coyote_time: float = 0.12

# Base grapple movement while rope is taut.
@export var base_grapple_steer_speed: float = 120.0
@export var base_grapple_steer_accel: float = 500.0

# Equipment flip offsets
@export var equipment_right_offset := Vector2.ZERO
@export var equipment_left_offset := Vector2.ZERO

# Wall Jump / Wall Cling
@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0
@export var wall_cling_stall_time: float = 0.32
@export var wall_slide_max_speed: float = 620.0

# Glow configuration
@export var idle_glow_width: float = 1.2
@export var idle_glow_intensity: float = 0.35
@export var charge_glow_max_width: float = 4.0
@export var charge_glow_max_intensity: float = 1.2

# ===============================
# STATE
# ===============================
var coyote_timer: float = 0.0
var last_direction: int = 1
var is_near_interactable: bool = false
var current_selector = null

var is_wall_clinging: bool = false
var wall_cling_timer: float = 0.0
var has_wall_jumped: bool = false

var jump_charge_ratio: float = 0.0
var dash_charge_ratio: float = 0.0

var current_body_anim := ""
var current_equip_anim := ""

var is_attacking := false
var is_hurt := false
var is_dead := false
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var hurt_timer := 0.0
var attack_active_started := false
var attack_active_finished := false

# Equipment slots
var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

# ===============================
# READY
# ===============================
func _ready() -> void:
	if not player_stats:
		player_stats = PlayerStats.new()

	health_component.configure(player_stats.max_health)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

	hurtbox.health_component = health_component
	hurtbox.hurtbox_owner = self

	attack_hitbox.hitbox_owner = self
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.hit_landed.connect(_on_attack_hit_landed)

	if not current_boots:
		current_boots = BaseBoots.new(self)
	if not current_chest:
		current_chest = BaseChest.new(self)

	add_to_group("player")
	print("✅ Player ready - Scene-based equipment system active")

	if ability_cooldown_timer:
		ability_cooldown_timer.timeout.connect(_on_ability_cooldown_timeout)

	if base_gloves_scene:
		equip_gloves(base_gloves_scene)

	update_equipment_facing()

# ===============================
# EQUIP / UNEQUIP
# ===============================
func equip_gloves(glove_scene: PackedScene) -> void:
	unequip_gloves()

	current_gloves = glove_scene.instantiate()
	equipment_mount.add_child(current_gloves)

	current_gloves.player = self

	if current_gloves.has_method("on_equipped"):
		current_gloves.on_equipped()

	update_equipment_facing()

func unequip_gloves() -> void:
	if current_gloves:
		if current_gloves.has_method("on_unequipped"):
			current_gloves.on_unequipped()
		else:
			current_gloves.queue_free()

		current_gloves = null

# ===============================
# PHYSICS PROCESS
# ===============================
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
		move_and_slide()
		return

	update_combat_timers(delta)

	# Gravity + coyote time
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		has_wall_jumped = false

	# Horizontal movement
	var horizontal_input := Input.get_axis("move_left", "move_right")
	if horizontal_input != 0:
		last_direction = sign(horizontal_input)

	var grapple_restricting := false
	if current_gloves and current_gloves.has_method("is_base_grapple_restricting"):
		grapple_restricting = current_gloves.is_base_grapple_restricting()

	if grapple_restricting:
		# Only applies when airborne + grapple attached + rope is taut.
		# This prevents the base grapple from becoming a momentum-building swing.
		var target_x := horizontal_input * base_grapple_steer_speed
		velocity.x = move_toward(velocity.x, target_x, base_grapple_steer_accel * delta)
	else:
		var control = 1.0 if is_on_floor() else air_control_mult
		velocity.x = speed * horizontal_input * control

	# Jump
	if Input.is_action_just_pressed("Jump"):
		if is_wall_clinging:
			is_wall_clinging = false
			wall_cling_timer = 0.0
		elif current_boots:
			current_boots.handle_primary(delta, BaseEquipment.ActionState.PRESSED)

	# Dash / Dodge
	if Input.is_action_just_pressed("Dash"):
		if current_chest:
			current_chest.handle_secondary(delta, BaseEquipment.ActionState.PRESSED)

	if Input.is_action_just_pressed("Attack"):
		start_attack()

	# Gloves active mechanic
	if current_gloves and current_gloves.has_method("thread_mechanic"):
		current_gloves.thread_mechanic(delta)

	# Passive effects
	if current_gloves and current_gloves.has_method("process_passive"):
		current_gloves.process_passive(delta)
	if current_boots:
		current_boots.process_passive(delta)
	if current_chest:
		current_chest.process_passive(delta)

	# Apply base grapple rope limit before movement.
	if current_gloves and current_gloves.has_method("apply_grapple_velocity"):
		current_gloves.apply_grapple_velocity(delta)

	move_and_slide()

	handle_wall_cling(delta)
	update_animations(horizontal_input)

# ===============================
# PROCESS
# ===============================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	var menu = get_tree().get_first_node_in_group("radial_menu")
	if menu:
		menu.update_hold_state(Input.is_action_pressed("open_menu"))

	if is_near_interactable and current_selector and Input.is_action_just_pressed("move_up"):
		print("Interacting with: ", current_selector.name)

# ===============================
# WALL CLING
# ===============================
func handle_wall_cling(delta: float) -> void:
	var on_wall = is_on_wall_only()
	var pushing_into_wall = false
	
	if on_wall:
		var wall_normal_x = get_wall_normal().x
		var input_dir = Input.get_axis("move_left", "move_right")
		pushing_into_wall = input_dir != 0 and sign(input_dir) == -sign(wall_normal_x)

	if on_wall and pushing_into_wall and not is_on_floor():
		if not is_wall_clinging:
			is_wall_clinging = true
			wall_cling_timer = wall_cling_stall_time
			velocity.y = 0.0

		if wall_cling_timer > 0.0:
			wall_cling_timer -= delta
			velocity.y = lerp(velocity.y, -60.0, 0.25)
		else:
			velocity.y += 380.0 * delta
			velocity.y = min(velocity.y, wall_slide_max_speed)
	else:
		is_wall_clinging = false
		wall_cling_timer = 0.0

# ===============================
# ANIMATION
# ===============================
func play_character_anim(body_anim: String, equip_anim: String) -> void:
	var body_changed := current_body_anim != body_anim

	if body_changed:
		current_body_anim = body_anim
		player_animation.play(body_anim)

	if current_gloves:
		if body_changed or current_equip_anim != equip_anim:
			current_equip_anim = equip_anim

			if current_gloves.has_method("play_equipment_anim"):
				current_gloves.play_equipment_anim(equip_anim)

func update_animations(dir: float) -> void:
	if not player_animation or not player_animation.sprite_frames:
		return
	
	var is_dashing = false
	if current_chest and "is_dashing" in current_chest:
		is_dashing = current_chest.is_dashing
	
	if is_dashing and player_animation.sprite_frames.has_animation("Dash"):
		play_character_anim("Dash", "equip_idle")

	elif is_wall_clinging and player_animation.sprite_frames.has_animation("Wall_Cling"):
		play_character_anim("Wall_Cling", "equip_wall_cling")

	elif not is_on_floor():
		if velocity.y < -120.0 and player_animation.sprite_frames.has_animation("Jump_Ascent"):
			play_character_anim("Jump_Ascent", "equip_jump_ascent")
		elif abs(velocity.y) <= 120.0 and player_animation.sprite_frames.has_animation("Jump_Apex"):
			play_character_anim("Jump_Apex", "equip_jump_apex")
		elif velocity.y > 120.0 and player_animation.sprite_frames.has_animation("Jump_Descent"):
			play_character_anim("Jump_Descent", "equip_jump_descent")
		else:
			play_character_anim("Jump_Apex", "equip_jump_apex")

	elif dir != 0 and player_animation.sprite_frames.has_animation("Run"):
		play_character_anim("Run", "equip_run")

	elif player_animation.sprite_frames.has_animation("Idle"):
		play_character_anim("Idle", "equip_idle")

	if velocity.x != 0:
		player_animation.flip_h = velocity.x < 0
		update_equipment_facing()

func update_equipment_facing() -> void:
	if not equipment_mount:
		return

	if player_animation.flip_h:
		equipment_mount.scale.x = -1
		equipment_mount.position = equipment_left_offset
	else:
		equipment_mount.scale.x = 1
		equipment_mount.position = equipment_right_offset

	update_attack_facing()

# ===============================
# COMBAT
# ===============================
func update_combat_timers(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			is_hurt = false

	if not is_attacking:
		return

	attack_timer += delta
	var windup := player_stats.attack_windup
	var active_time := player_stats.attack_active_time
	var recovery := player_stats.attack_recovery

	if not attack_active_started and attack_timer >= windup:
		attack_active_started = true
		attack_hitbox.damage = _build_attack_damage()
		attack_hitbox.enable()

	if attack_active_started and not attack_active_finished and attack_timer >= windup + active_time:
		attack_active_finished = true
		attack_hitbox.disable()

	if attack_timer >= windup + active_time + recovery:
		is_attacking = false
		attack_hitbox.disable()

func start_attack() -> void:
	if is_dead or is_hurt or is_attacking or attack_cooldown_timer > 0.0:
		return

	is_attacking = true
	attack_timer = 0.0
	attack_cooldown_timer = player_stats.attack_cooldown
	attack_active_started = false
	attack_active_finished = false
	update_attack_facing()

	if player_animation and player_animation.sprite_frames.has_animation("Attack"):
		play_character_anim("Attack", "equip_idle")

func update_attack_facing() -> void:
	if not attack_hitbox:
		return

	var direction := last_direction
	if player_animation and player_animation.flip_h:
		direction = -1
	elif player_animation:
		direction = 1

	attack_hitbox.position.x = abs(attack_hitbox.position.x) * float(direction)

func _build_attack_damage() -> DamageData:
	var data := DamageData.new()
	data.amount = player_stats.attack_damage
	data.hitstun = player_stats.hurt_time
	data.hit_pause = player_stats.hit_pause
	data.knockback = Vector2(float(last_direction) * player_stats.knockback_strength, -90.0)
	return data

func _on_attack_hit_landed(_hurtbox: HurtboxComponent, damage: DamageData) -> void:
	CombatFeedback.screen_shake(self, player_stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

func _on_damaged(damage: DamageData) -> void:
	is_hurt = true
	hurt_timer = player_stats.hurt_time
	is_attacking = false
	attack_hitbox.disable()

	if hit_flash:
		hit_flash.flash(Color(1.0, 0.35, 0.35, 1.0), 0.08)

	var knockback := damage.knockback
	if knockback == Vector2.ZERO and damage.source is Node2D:
		var source_node := damage.source as Node2D
		knockback = Vector2(sign(global_position.x - source_node.global_position.x) * player_stats.knockback_strength, -90.0)

	velocity = knockback
	CombatFeedback.screen_shake(self, player_stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

func _on_died(_damage: DamageData) -> void:
	is_dead = true
	is_attacking = false
	attack_hitbox.disable()

# ===============================
# CHARGE / COOLDOWN HELPERS
# ===============================
func set_jump_charge_level(level: float) -> void:
	jump_charge_ratio = clamp(level, 0.0, 1.0)

func set_dash_charge_level(level: float) -> void:
	dash_charge_ratio = clamp(level, 0.0, 1.0)

func start_ability_cooldown(duration: float) -> void:
	if ability_cooldown_timer:
		ability_cooldown_timer.wait_time = duration
		ability_cooldown_timer.start()

func _on_ability_cooldown_timeout() -> void:
	if current_boots and current_boots.has_method("on_ability_cooldown_complete"):
		current_boots.on_ability_cooldown_complete()
	if current_gloves and current_gloves.has_method("on_ability_cooldown_complete"):
		current_gloves.on_ability_cooldown_complete()

# ===============================
# INTERACTABLES
# ===============================
func _on_interactable_entered(area: Area2D) -> void:
	is_near_interactable = true
	current_selector = area

func _on_interactable_exited(area: Area2D) -> void:
	is_near_interactable = false
	if current_selector == area:
		current_selector = null
