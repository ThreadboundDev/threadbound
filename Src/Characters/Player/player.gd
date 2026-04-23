extends CharacterBody2D

# ===============================
# NODES
# ===============================
@onready var player_animation: AnimatedSprite2D = $"Player Animation"
@onready var camera = get_node_or_null("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam")
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var ability_cooldown_timer: Timer = $AbilityCooldownTimer

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

# Wall Jump (baseline)
@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0

# Glow configuration (kept for future Red kit)
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

# Wall cling & wall jump
var is_wall_clinging: bool = false
var wall_cling_timer: float = 0.0
@export var wall_cling_stall_time: float = 0.32
@export var wall_slide_max_speed: float = 620.0
var has_wall_jumped: bool = false

# Charge ratios (kept for future Red kit)
var jump_charge_ratio: float = 0.0
var dash_charge_ratio: float = 0.0

# Equipment slots
var current_gloves: BaseEquipment = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

# ===============================
# READY
# ===============================
func _ready() -> void:
	if not current_gloves:
		current_gloves = BaseGloves.new(self)
	if not current_boots:
		current_boots = BaseBoots.new(self)
	if not current_chest:
		current_chest = BaseChest.new(self)

	add_to_group("player")
	print("✅ Player ready - Equipment system active (Base Gloves/Boots/Chest)")

	if ability_cooldown_timer:
		ability_cooldown_timer.timeout.connect(_on_ability_cooldown_timeout)

# ===============================
# PHYSICS PROCESS
# ===============================
func _physics_process(delta: float) -> void:
	# Gravity + Coyote
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		has_wall_jumped = false

	# Horizontal movement + last_direction
	var horizontal_input = Input.get_axis("move_left", "move_right")
	if horizontal_input != 0:
		last_direction = sign(horizontal_input)

	var control = 1.0 if is_on_floor() else air_control_mult
	velocity.x = speed * horizontal_input * control

	# Wall Cling
	handle_wall_cling(delta)

		# === JUMP LOGIC ===
	if Input.is_action_just_pressed("Jump"):
		if is_wall_clinging:
			# For now, just detach from wall cling (no wall jump yet)
			is_wall_clinging = false
			wall_cling_timer = 0.0
		else:
			if current_boots:
				current_boots.handle_primary(delta, BaseEquipment.ActionState.PRESSED)

	# Dash / Dodge (handled by Chest)
	if Input.is_action_just_pressed("Dash"):
		if current_chest:
			current_chest.handle_secondary(delta, BaseEquipment.ActionState.PRESSED)

	# Thread mechanic (Gloves)
	if current_gloves:
		current_gloves.thread_mechanic(delta)

	# Passive effects
	if current_gloves: current_gloves.process_passive(delta)
	if current_boots:  current_boots.process_passive(delta)
	if current_chest:  current_chest.process_passive(delta)

	move_and_slide()
	update_animations(horizontal_input)

# ===============================
# WALL CLING
# ===============================
func handle_wall_cling(delta: float) -> void:
	var on_wall = is_on_wall_only()
	var pushing_into_wall = false
	
	if on_wall:
		var wall_normal_x = get_wall_normal().x
		var input_dir = Input.get_axis("move_left", "move_right")
		pushing_into_wall = (input_dir != 0 and sign(input_dir) == -sign(wall_normal_x))

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
# INPUT & LOOK
# ===============================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# Radial menu polling
	var menu = get_tree().get_first_node_in_group("radial_menu")
	if menu:
		menu.update_hold_state(Input.is_action_pressed("open_menu"))

	# Interact
	if is_near_interactable and current_selector and Input.is_action_just_pressed("move_up"):
		print("Interacting with: ", current_selector.name)

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

# Animations
func update_animations(dir: float) -> void:
	if not player_animation or not player_animation.sprite_frames:
		return
		
	var is_dashing = false
	if current_chest and "is_dashing" in current_chest:
		is_dashing = current_chest.is_dashing
	
	if is_dashing and player_animation.sprite_frames.has_animation("Dash"):
		player_animation.play("Dash")
	elif dir != 0 and player_animation.sprite_frames.has_animation("Walk"):
		player_animation.play("Walk")
	elif not is_on_floor() and player_animation.sprite_frames.has_animation("Jump"):
		player_animation.play("Jump")
	elif player_animation.sprite_frames.has_animation("Idle"):
		player_animation.play("Idle")

	if velocity.x != 0:
		player_animation.flip_h = velocity.x < 0

# Interactables
func _on_interactable_entered(area: Area2D):
	is_near_interactable = true
	current_selector = area

func _on_interactable_exited(area: Area2D):
	is_near_interactable = false
	if current_selector == area:
		current_selector = null
