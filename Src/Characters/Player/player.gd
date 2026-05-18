extends CharacterBody2D

# ===============================
# NODES
# ===============================
@onready var player_animation: AnimatedSprite2D = $"Player Animation"
@onready var equipment_mount: Node2D = $EquipmentMount
@onready var camera = get_node_or_null("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam")
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var ability_cooldown_timer: Timer = $AbilityCooldownTimer

# ===============================
# EQUIPMENT SCENES
# ===============================
@export var base_gloves_scene: PackedScene

# ===============================
# TUNABLES
# ===============================
@export var speed: float = 500.0
@export var air_control_mult: float = 0.75
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1000.0
@export var coyote_time: float = 0.12
@export var look_offset: float = 60.0
@export var look_speed: float = 10.0
@export var hold_duration: float = 1.0

@export var equipment_right_offset := Vector2.ZERO
@export var equipment_left_offset := Vector2.ZERO

@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0
@export var wall_cling_stall_time: float = 0.32
@export var wall_slide_max_speed: float = 620.0

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
var current_look_offset_y: float = 0.0
var hold_timer: float = 0.0

var is_wall_clinging: bool = false
var wall_cling_timer: float = 0.0
var has_wall_jumped: bool = false

var jump_charge_ratio: float = 0.0
var dash_charge_ratio: float = 0.0

var current_body_anim := ""
var current_equip_anim := ""

var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

# ===============================
# READY
# ===============================
func _ready() -> void:
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
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		has_wall_jumped = false

	var horizontal_input = Input.get_axis("move_left", "move_right")
	if horizontal_input != 0:
		last_direction = sign(horizontal_input)

	var control = 1.0 if is_on_floor() else air_control_mult
	velocity.x = speed * horizontal_input * control

	if Input.is_action_just_pressed("Jump"):
		if is_wall_clinging:
			is_wall_clinging = false
			wall_cling_timer = 0.0
		elif current_boots:
			current_boots.handle_primary(delta, BaseEquipment.ActionState.PRESSED)

	if Input.is_action_just_pressed("Dash"):
		if current_chest:
			current_chest.handle_secondary(delta, BaseEquipment.ActionState.PRESSED)

	if current_gloves and current_gloves.has_method("thread_mechanic"):
		current_gloves.thread_mechanic(delta)

	if current_gloves and current_gloves.has_method("process_passive"):
		current_gloves.process_passive(delta)
	if current_boots:
		current_boots.process_passive(delta)
	if current_chest:
		current_chest.process_passive(delta)

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
# ANIMATION HELPERS
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
