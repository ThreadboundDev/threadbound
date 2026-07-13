extends CharacterBody2D

signal action_points_changed(current: int, maximum: int)
signal momentum_changed(value: float)
signal momentum_state_changed(state: StringName, flow_active: bool)
signal save_point_seated(player: CharacterBody2D)

const GAME_OVER_OVERLAY_SCENE := preload("res://Src/UI/game_over_overlay.tscn")
const PAUSE_MENU_SCENE := preload("res://Src/UI/PauseMenu/pause_menu.tscn")
const GAME_MENU_SCENE := preload("res://Src/UI/GameMenu/game_menu.tscn")
const RADIAL_MENU_SCENE := preload("res://Src/UI/radial_menu.tscn")
const AimHelperScript := preload("res://Src/Global/aim_helper.gd")
const SIT_TEXTURE := preload("res://Assets/Threadborne/sit.png")
const MEDITATION_SHADER := preload("res://Src/Characters/Player/save_point_meditation.gdshader")
const SIT_ANIMATION := &"Sit"
const SIT_COLUMNS := 5
const SIT_ROWS := 10
const SIT_FRAME_COUNT := 48
const SIT_FPS := 12.0

# ===============================
# NODES
# ===============================
@onready var player_animation: AnimatedSprite2D = $"Player Animation"
@onready var equipment_mount: Node2D = $EquipmentMount
@onready var camera = get_node_or_null("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam")
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var flow_state_aura: Node = get_node_or_null("FlowStateAura")
@onready var ability_cooldown_timer: Timer = $AbilityCooldownTimer
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox as HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox as HitboxComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent as HitFlashComponent
@onready var weapon_animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_swing_root: Node2D = $EquipmentMount/AttackSwingRoot
@onready var attack_slash_sprite: Sprite2D = $EquipmentMount/AttackSwingRoot/AttackSlashVFX/SlashSprite
@onready var wall_cling_vfx: AnimatedSprite2D = $WallClingVFX as AnimatedSprite2D

# ===============================
# EQUIPMENT SCENES
# ===============================
@export var base_gloves_scene: PackedScene
@export var player_stats: PlayerStats

# Basic combat resource values for the HUD. Gameplay costs can build on these.
@export_range(1, 9999, 1) var max_health := 100
@export_range(0.0, 5.0, 0.05) var death_reset_delay := 0.45

@export_range(1, 6, 1) var max_action_points := 6:
	set(value):
		max_action_points = clampi(value, 1, 6)
		current_action_points = clampi(current_action_points, 0, max_action_points)
		_sync_hud()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0, 6, 1) var current_action_points := 6:
	set(value):
		current_action_points = clampi(value, 0, max_action_points)
		_sync_hud()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0.5, 30.0, 0.5) var action_point_recharge_time := 10.0

@export_range(0.0, 100.0, 1.0) var momentum := 0.0:
	set(value):
		momentum = clampf(value, 0.0, 100.0)
		_update_momentum_state()
		_sync_hud()
		momentum_changed.emit(momentum)

@export_range(0, 999999, 1) var thread_knot_count := 0:
	set(value):
		thread_knot_count = maxi(0, value)
		_sync_hud()

# ===============================
# MOVEMENT TUNABLES
# ===============================
@export var speed: float = 500.0
@export var air_control_mult: float = 0.9
@export var gravity: float = 2200.0
@export var fall_gravity_multiplier: float = 1.55
@export var jump_cut_gravity_multiplier: float = 2.25
@export var max_fall_speed: float = 1500.0
@export var coyote_time: float = 0.1

# Base grapple movement while rope is taut.
@export var base_grapple_steer_speed: float = 120.0
@export var base_grapple_steer_accel: float = 500.0

# Momentum tuning. Abilities should call report_momentum_action(category) when
# they successfully fire, connect, or otherwise complete a meaningful action.
@export_group("Momentum Gains")
@export var momentum_gain_movement := 0.24
@export var momentum_gain_jump := 1.7
@export var momentum_gain_dash := 7.5
@export var momentum_gain_grapple := 8.0
@export var momentum_gain_attack := 3.2
@export var momentum_gain_pogo := 6.5
@export var momentum_gain_utility := 2.4

@export_group("Special Attacks")
@export_range(1.0, 5.0, 0.05) var neutral_special_damage_multiplier := 1.65
@export_range(0.25, 3.0, 0.05) var neutral_special_windup_multiplier := 1.25
@export_range(0.25, 3.0, 0.05) var neutral_special_active_multiplier := 1.25
@export_range(0.25, 3.0, 0.05) var neutral_special_recovery_multiplier := 1.45
@export_range(0.25, 3.0, 0.05) var neutral_special_cooldown_multiplier := 1.55
@export var momentum_gain_equipment_swap := 1.5
@export var momentum_gain_use_after_swap := 7.0

@export_group("Momentum Rules")
@export var momentum_movement_report_interval := 0.16
@export var momentum_movement_min_speed := 90.0
@export var momentum_movement_reference_speed := 520.0
@export var momentum_movement_stale_duration := 5.0
@export var momentum_stale_duration := 7.0
@export_range(0.0, 1.0, 0.05) var momentum_stale_recovery_fraction := 0.25
@export var momentum_stale_penalty := 1.35
@export var momentum_weave_bonus_per_category := 0.16
@export var momentum_weave_recent_count := 4
@export var momentum_use_after_swap_window := 2.5
@export var momentum_low_threshold := 30.0
@export var momentum_high_threshold := 70.0
@export var flow_state_drain_delay := 1.35
@export var flow_state_drain_base := 3.0
@export var flow_state_drain_growth := 0.72
@export var flow_state_drain_max := 13.0
@export var momentum_damage_loss_per_damage := 8.0
@export var momentum_damage_loss_current_scale := 0.06
@export_range(1.0, 100.0, 1.0) var debug_momentum_fill_amount := 25.0
@export_range(1, 9999, 1) var debug_thread_knots_amount := 25

@export_group("Momentum Multipliers")
@export var momentum_action_point_recharge_low := 0.9
@export var momentum_action_point_recharge_mid := 1.0
@export var momentum_action_point_recharge_high := 1.24
@export var momentum_action_point_recharge_flow := 1.32
@export var momentum_move_speed_low := 0.92
@export var momentum_move_speed_mid := 1.0
@export var momentum_move_speed_high := 1.14
@export var momentum_move_speed_flow := 1.2
@export var momentum_jump_low := 0.94
@export var momentum_jump_mid := 1.0
@export var momentum_jump_high := 1.09
@export var momentum_jump_flow := 1.12
@export var momentum_air_control_low := 0.9
@export var momentum_air_control_mid := 1.0
@export var momentum_air_control_high := 1.16
@export var momentum_air_control_flow := 1.22
@export var momentum_grapple_speed_low := 0.94
@export var momentum_grapple_speed_mid := 1.0
@export var momentum_grapple_speed_high := 1.16
@export var momentum_grapple_speed_flow := 1.22
@export var momentum_grapple_pull_low := 0.92
@export var momentum_grapple_pull_mid := 1.0
@export var momentum_grapple_pull_high := 1.16
@export var momentum_grapple_pull_flow := 1.24
@export var momentum_attack_speed_low := 0.94
@export var momentum_attack_speed_mid := 1.0
@export var momentum_attack_speed_high := 1.16
@export var momentum_attack_speed_flow := 1.2
@export var momentum_dash_speed_low := 0.95
@export var momentum_dash_speed_mid := 1.0
@export var momentum_dash_speed_high := 1.14
@export var momentum_dash_speed_flow := 1.18
@export var momentum_dash_iframe_low := 0.9
@export var momentum_dash_iframe_mid := 1.0
@export var momentum_dash_iframe_high := 1.15
@export var momentum_dash_iframe_flow := 1.3
@export var momentum_coin_vacuum_low := 0.92
@export var momentum_coin_vacuum_mid := 1.0
@export var momentum_coin_vacuum_high := 1.2
@export var momentum_coin_vacuum_flow := 1.45
@export var momentum_decay_resistance_low := 0.0
@export var momentum_decay_resistance_mid := 0.05
@export var momentum_decay_resistance_high := 0.12
@export var momentum_decay_resistance_flow := 0.2

# Equipment flip offsets
@export var equipment_right_offset := Vector2.ZERO
@export var equipment_left_offset := Vector2.ZERO

# Wall Jump / Wall Cling
@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0
@export var wall_cling_stall_time: float = 0.32
@export var wall_slide_max_speed: float = 620.0

# Debug testing helpers
@export var god_mode_fly_speed: float = 620.0
@export var god_mode_fly_acceleration: float = 2600.0

@export_group("Save Point Interaction")
@export var save_point_auto_run_speed := 420.0
@export var save_point_arrive_distance := 10.0
@export var save_point_sit_visual_scale := Vector2(1.4, 1.4)
@export var save_point_stand_up_speed_scale: float = 2.0

@export_group("Audio")
@export var footstep_interval := 0.28
@export var footstep_min_speed := 80.0
@export var coin_pickup_audio_cooldown := 0.045

# Glow configuration
@export var idle_glow_width: float = 1.2
@export var idle_glow_intensity: float = 0.35
@export var charge_glow_max_width: float = 4.0
@export var charge_glow_max_intensity: float = 1.2

# ===============================
# STATE
# ===============================
const ATTACK_DIRECTION_DEADZONE := 0.15
const MOMENTUM_CATEGORY_MOVEMENT := &"Movement"
const MOMENTUM_CATEGORY_JUMP := &"Jump"
const MOMENTUM_CATEGORY_DASH := &"Dash"
const MOMENTUM_CATEGORY_GRAPPLE := &"Grapple"
const MOMENTUM_CATEGORY_ATTACK := &"Attack"
const MOMENTUM_CATEGORY_POGO := &"Pogo"
const MOMENTUM_CATEGORY_UTILITY := &"Utility"
const MOMENTUM_CATEGORY_EQUIPMENT_SWAP := &"EquipmentSwap"
const MOMENTUM_CATEGORY_USE_AFTER_SWAP := &"UseAfterSwap"
const MOMENTUM_STATE_LOW := &"Low"
const MOMENTUM_STATE_MID := &"Mid"
const MOMENTUM_STATE_HIGH := &"High"
const MOMENTUM_STATE_FLOW := &"Flow"

var coyote_timer: float = 0.0
var last_direction: int = 1
var is_near_interactable: bool = false
var current_selector = null

var is_wall_clinging: bool = false
var wall_cling_timer: float = 0.0
var has_wall_jumped: bool = false
var air_jump_available: bool = true

var jump_charge_ratio: float = 0.0
var dash_charge_ratio: float = 0.0
var _action_point_recharge_timers: Array[float] = []
var _momentum_staleness: Dictionary = {}
var _momentum_recent_categories: Array[StringName] = []
var _movement_momentum_timer := 0.0
var _movement_momentum_distance := 0.0
var _movement_momentum_last_position := Vector2.ZERO
var _flow_state_active := false
var _flow_state_duration := 0.0
var _flow_state_audio_suspended := false
var _momentum_state: StringName = MOMENTUM_STATE_LOW
var _pending_use_after_swap := false
var _use_after_swap_timer := 0.0
var _momentum_system_ready := false
var _dash_iframe_timer := 0.0
var _debug_momentum_was_pressed := false
var _debug_force_doors_was_pressed := false
var _debug_thread_knots_was_pressed := false
var _footstep_timer := 0.0
var _coin_pickup_audio_timer := 0.0

var current_body_anim := ""
var current_equip_anim := ""
var current_weapon_pose_anim := ""
var current_attack_body_anim := "Attack"

var is_attacking := false
var is_hurt := false
var is_dead := false
var god_mode_enabled := false
var death_reset_started := false
var attack_direction := Vector2.RIGHT
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var hurt_timer := 0.0
var attack_active_started := false
var attack_active_finished := false
var current_attack_is_special := false

# Equipment slots
var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null

var save_point_interaction_active := false
var _save_point_target_position := Vector2.ZERO
var _save_point_sitting_down := false
var _save_point_seated := false
var _save_point_standing_up := false
var _save_point_controller: Node = null
var _save_point_original_material: Material
var _save_point_original_scale := Vector2.ONE
var _save_point_original_animation_speed_scale: float = 1.0
var _save_point_equipment_was_visible := true
var _save_point_breath_tween: Tween

# ===============================
# READY
# ===============================
func _ready() -> void:
	if not player_stats:
		player_stats = PlayerStats.new()

	max_health = player_stats.max_health
	health_component.configure(player_stats.max_health)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)

	hurtbox.health_component = health_component
	hurtbox.hurtbox_owner = self

	attack_hitbox.hitbox_owner = self
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.hit_landed.connect(_on_attack_hit_landed)

	if not current_boots:
		current_boots = BaseBoots.new(self)
	if not current_chest:
		current_chest = BaseChest.new(self)

	_ensure_action_point_timers()
	add_to_group("player")
	_apply_demo_checkpoint_spawn()
	print("✅ Player ready - Scene-based equipment system active")

	if ability_cooldown_timer:
		ability_cooldown_timer.timeout.connect(_on_ability_cooldown_timeout)

	if base_gloves_scene:
		equip_gloves(base_gloves_scene)

	AudioManager.enter_gameplay_music()
	_movement_momentum_last_position = global_position
	_momentum_system_ready = true
	_set_flow_state_visuals(_flow_state_active)
	_ensure_sit_animation()
	update_equipment_facing()
	_update_wall_cling_vfx()
	call_deferred("_sync_hud")

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

	if _momentum_system_ready:
		report_momentum_action(MOMENTUM_CATEGORY_EQUIPMENT_SWAP)

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
	_update_god_mode_toggle()
	_update_debug_momentum_fill()
	_update_debug_thread_knots()
	_process_audio_timers(delta)
	_process_momentum(delta)
	_process_action_point_recharge(delta)

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, speed * get_momentum_move_speed_multiplier() * delta)
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		move_and_slide()
		return

	update_combat_timers(delta)

	if save_point_interaction_active:
		_process_save_point_interaction(delta)
		return

	var was_on_floor := is_on_floor()

	# Gravity + coyote time
	if god_mode_enabled:
		coyote_timer = coyote_time
		has_wall_jumped = false
		air_jump_available = true
	elif not is_on_floor():
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		has_wall_jumped = false
		air_jump_available = true

	# Horizontal movement
	var horizontal_input := Input.get_axis("move_left", "move_right")
	if horizontal_input != 0:
		last_direction = sign(horizontal_input)

	var grapple_restricting := false
	if current_gloves and current_gloves.has_method("is_base_grapple_restricting"):
		grapple_restricting = current_gloves.is_base_grapple_restricting()

	if not grapple_restricting and not is_hurt:
		var control := 1.0 if is_on_floor() else air_control_mult * get_momentum_air_control_multiplier()
		velocity.x = speed * get_momentum_move_speed_multiplier() * horizontal_input * control
	elif is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, speed * get_momentum_move_speed_multiplier() * delta)

	if god_mode_enabled:
		_apply_god_mode_flight(delta)

	# Jump
	if Input.is_action_just_pressed("Jump"):
		if is_wall_clinging:
			is_wall_clinging = false
			wall_cling_timer = 0.0
		elif current_gloves and current_gloves.has_method("jump_off_grapple") and current_gloves.jump_off_grapple():
			pass
		elif current_boots:
			current_boots.handle_primary(delta, BaseEquipment.ActionState.PRESSED)

	# Dash / Dodge
	if Input.is_action_just_pressed("Dash"):
		if current_chest:
			current_chest.handle_secondary(delta, BaseEquipment.ActionState.PRESSED)

	if Input.is_action_just_pressed("SpecialAttack"):
		start_attack(true)
	elif Input.is_action_just_pressed("Attack"):
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
	if current_gloves and current_gloves.has_method("apply_grapple_velocity") and not god_mode_enabled:
		current_gloves.apply_grapple_velocity(delta)

	move_and_slide()
	_process_movement_audio(delta, was_on_floor)
	_process_movement_momentum(delta)

	handle_wall_cling(delta)
	update_animations(horizontal_input)

# ===============================
# PROCESS
# ===============================
func _process(_delta: float) -> void:
	if save_point_interaction_active:
		return

	var debug_force_doors_pressed := Input.is_key_pressed(KEY_F7)
	if debug_force_doors_pressed and not _debug_force_doors_was_pressed:
		_debug_force_open_demo_doors()
	_debug_force_doors_was_pressed = debug_force_doors_pressed

	if Input.is_action_just_pressed("ui_cancel") and not death_reset_started:
		_open_pause_menu()

	var requested_game_menu_tab := _get_requested_game_menu_tab()
	if requested_game_menu_tab != &"" and not death_reset_started:
		_open_game_menu(requested_game_menu_tab)

	var menu = _get_or_create_radial_menu()
	if menu:
		menu.update_hold_state(Input.is_action_pressed("open_menu"))

	if is_near_interactable and current_selector and Input.is_action_just_pressed("interact"):
		print("Interacting with: ", current_selector.name)
		if current_selector.has_method("interact"):
			current_selector.interact(self)

func _open_pause_menu() -> void:
	if get_tree().paused:
		return
	if get_tree().get_first_node_in_group("pause_menu"):
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(pause_menu)

func _get_or_create_radial_menu() -> Node:
	var menu := get_tree().get_first_node_in_group("radial_menu")
	if menu:
		return menu
	if not get_tree().current_scene:
		return null

	menu = RADIAL_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.set("player_path", menu.get_path_to(self))
	return menu

func _get_requested_game_menu_tab() -> StringName:
	if Input.is_action_just_pressed("open_inventory"):
		return &"Inventory"
	if Input.is_action_just_pressed("open_map"):
		return &"Map"
	if Input.is_action_just_pressed("open_lore"):
		return &"Lore"
	if Input.is_action_just_pressed("open_controls"):
		return &"Controls"
	return &""

func _open_game_menu(initial_tab: StringName) -> void:
	if get_tree().paused:
		return
	if get_tree().get_first_node_in_group("game_menu"):
		return

	var game_menu := GAME_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(game_menu)
	if game_menu.has_method("open"):
		game_menu.open(initial_tab, _get_game_menu_input_family(initial_tab))

func _get_game_menu_input_family(initial_tab: StringName) -> StringName:
	if _is_game_menu_keyboard_tab_pressed(initial_tab):
		return &"keyboard_mouse"
	if _is_game_menu_controller_tab_pressed(initial_tab):
		return _get_connected_controller_family()
	return &"keyboard_mouse"

func _is_game_menu_keyboard_tab_pressed(initial_tab: StringName) -> bool:
	match initial_tab:
		&"Inventory":
			return Input.is_physical_key_pressed(KEY_I)
		&"Map":
			return Input.is_physical_key_pressed(KEY_M)
		&"Lore":
			return Input.is_physical_key_pressed(KEY_L)
		&"Controls":
			return Input.is_physical_key_pressed(KEY_C)
	return false

func _is_game_menu_controller_tab_pressed(initial_tab: StringName) -> bool:
	var button_index := -1
	match initial_tab:
		&"Inventory":
			button_index = 11
		&"Map":
			button_index = 13
		&"Lore":
			button_index = 12
		&"Controls":
			button_index = 14

	if button_index < 0:
		return false

	for device_id in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device_id, button_index):
			return true
	return false

func _get_connected_controller_family(device_id := -1) -> StringName:
	var resolved_device_id := device_id
	if resolved_device_id < 0:
		var connected := Input.get_connected_joypads()
		if connected.is_empty():
			return &"xbox"
		resolved_device_id = int(connected[0])

	var joy_name := Input.get_joy_name(resolved_device_id).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("ps5") or joy_name.contains("dualsense") or joy_name.contains("dualshock"):
		return &"ps5"
	if joy_name.contains("nintendo") or joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("pro controller"):
		return &"nintendo"
	if joy_name.contains("steam"):
		return &"steam"
	return &"xbox"

func _update_god_mode_toggle() -> void:
	if Input.is_action_just_pressed("debug_god_mode"):
		god_mode_enabled = not god_mode_enabled
		if god_mode_enabled and health_component:
			health_component.heal(health_component.max_health)
		_sync_hud()
		print("God mode: ", "ON" if god_mode_enabled else "OFF")

func _update_debug_momentum_fill() -> void:
	var pressed := Input.is_key_pressed(KEY_F8)
	if pressed and not _debug_momentum_was_pressed:
		_change_momentum(debug_momentum_fill_amount)
		print("Debug momentum: ", momentum)
	_debug_momentum_was_pressed = pressed

func _update_debug_thread_knots() -> void:
	var pressed := Input.is_key_pressed(KEY_F9)
	if pressed and not _debug_thread_knots_was_pressed:
		collect_thread_knots(debug_thread_knots_amount)
		print("Debug thread knots: +", debug_thread_knots_amount, " total ", thread_knot_count)
	_debug_thread_knots_was_pressed = pressed

func _debug_force_open_demo_doors() -> void:
	for door in get_tree().get_nodes_in_group("demo_doors"):
		if door.has_method("debug_force_open"):
			door.debug_force_open()
	print("Debug doors: forced open")

func _apply_god_mode_flight(delta: float) -> void:
	var vertical_input := 0.0
	if Input.is_action_pressed("Jump") or Input.is_action_pressed("move_up"):
		vertical_input -= 1.0
	if Input.is_action_pressed("move_down"):
		vertical_input += 1.0

	var target_y := vertical_input * god_mode_fly_speed
	velocity.y = move_toward(velocity.y, target_y, god_mode_fly_acceleration * delta)

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

func _get_current_gravity() -> float:
	if velocity.y < 0.0:
		if not Input.is_action_pressed("Jump"):
			return gravity * jump_cut_gravity_multiplier
		return gravity

	return gravity * fall_gravity_multiplier

# ===============================
# ANIMATION
# ===============================
func play_character_anim(body_anim: String, equip_anim: String) -> void:
	var body_changed := current_body_anim != body_anim

	if body_changed:
		current_body_anim = body_anim
		player_animation.play(body_anim)
		if not is_attacking:
			_play_weapon_pose_anim(body_anim)

	if current_gloves:
		if body_changed or current_equip_anim != equip_anim:
			current_equip_anim = equip_anim

			if current_gloves.has_method("play_equipment_anim"):
				current_gloves.play_equipment_anim(equip_anim)

func update_animations(dir: float) -> void:
	if not player_animation or not player_animation.sprite_frames:
		return

	if save_point_interaction_active:
		return

	if is_attacking and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		player_animation.rotation = 0.0
		play_character_anim(current_attack_body_anim, "equip_idle")
		return
	
	var is_dashing = false
	if current_chest and "is_dashing" in current_chest:
		is_dashing = current_chest.is_dashing
	if current_gloves and current_gloves.has_method("forces_dash_animation") and current_gloves.forces_dash_animation():
		is_dashing = true
	var forced_dash_direction := Vector2.ZERO
	if current_gloves and current_gloves.has_method("get_forced_dash_direction"):
		forced_dash_direction = current_gloves.get_forced_dash_direction()
	
	if is_dashing and player_animation.sprite_frames.has_animation("Dash"):
		play_character_anim("Dash", "equip_idle")
		player_animation.rotation = 0.0
		if forced_dash_direction.length() > 0.001:
			player_animation.flip_h = forced_dash_direction.x < 0.0
			update_equipment_facing()

	elif is_wall_clinging and player_animation.sprite_frames.has_animation("Wall_Cling"):
		player_animation.rotation = 0.0
		play_character_anim("Wall_Cling", "equip_wall_cling")

	elif not is_on_floor():
		player_animation.rotation = 0.0
		if velocity.y < -120.0 and player_animation.sprite_frames.has_animation("Jump_Ascent"):
			play_character_anim("Jump_Ascent", "equip_jump_ascent")
		elif velocity.y > 120.0 and player_animation.sprite_frames.has_animation("Jump_Descent"):
			play_character_anim("Jump_Descent", "equip_jump_descent")
		elif velocity.y <= 0.0 and player_animation.sprite_frames.has_animation("Jump_Ascent"):
			play_character_anim("Jump_Ascent", "equip_jump_ascent")
		else:
			play_character_anim("Jump_Descent", "equip_jump_descent")

	elif dir != 0 and player_animation.sprite_frames.has_animation("Run"):
		player_animation.rotation = 0.0
		play_character_anim("Run", "equip_run")

	elif player_animation.sprite_frames.has_animation("Idle"):
		player_animation.rotation = 0.0
		play_character_anim("Idle", "equip_idle")

	if velocity.x != 0 and forced_dash_direction.length() <= 0.001:
		player_animation.flip_h = velocity.x < 0
		update_equipment_facing()

	_update_wall_cling_vfx()

func update_equipment_facing() -> void:
	if not equipment_mount:
		return

	if player_animation.flip_h:
		equipment_mount.scale.x = -1
		equipment_mount.position = equipment_left_offset
	else:
		equipment_mount.scale.x = 1
		equipment_mount.position = equipment_right_offset

	_apply_attack_direction()

func _update_wall_cling_vfx() -> void:
	if not wall_cling_vfx:
		return

	var should_show := is_wall_clinging and not is_on_floor()
	wall_cling_vfx.visible = should_show
	if not should_show:
		wall_cling_vfx.stop()
		return

	var wall_direction: float = -signf(get_wall_normal().x)
	if wall_direction == 0.0:
		wall_direction = -1 if player_animation.flip_h else 1

	wall_cling_vfx.position = Vector2(32.0 * wall_direction, -54.0)
	wall_cling_vfx.flip_h = wall_direction > 0
	if not wall_cling_vfx.is_playing():
		wall_cling_vfx.play("cling")

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
	_sync_attack_hitbox_to_slash()
	var attack_speed_multiplier := maxf(0.1, get_momentum_attack_speed_multiplier())
	var windup := player_stats.attack_windup / attack_speed_multiplier
	var active_time := player_stats.attack_active_time / attack_speed_multiplier
	var recovery := player_stats.attack_recovery / attack_speed_multiplier
	if current_attack_is_special:
		windup *= neutral_special_windup_multiplier
		active_time *= neutral_special_active_multiplier
		recovery *= neutral_special_recovery_multiplier

	if not attack_active_started and attack_timer >= windup:
		attack_active_started = true
		_sync_attack_hitbox_to_slash()
		attack_hitbox.damage = _build_attack_damage()
		attack_hitbox.enable()

	if attack_active_started and not attack_active_finished and attack_timer >= windup + active_time:
		attack_active_finished = true
		attack_hitbox.disable()

	if attack_timer >= windup + active_time + recovery:
		is_attacking = false
		current_attack_is_special = false
		attack_hitbox.disable()
		_reset_weapon_visuals()

func start_attack(is_special := false) -> void:
	if not can_start_attack():
		return

	AudioManager.play_sfx(&"player_attack")
	is_attacking = true
	current_attack_is_special = is_special
	attack_timer = 0.0
	var cooldown := player_stats.attack_cooldown
	if current_attack_is_special:
		cooldown *= neutral_special_cooldown_multiplier
	attack_cooldown_timer = cooldown / maxf(0.1, get_momentum_attack_speed_multiplier())
	attack_active_started = false
	attack_active_finished = false
	attack_direction = _get_attack_input_direction()
	current_attack_body_anim = _get_special_body_animation() if current_attack_is_special else _get_attack_body_animation()
	update_equipment_facing()
	_play_weapon_attack_anim()

	if player_animation and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		play_character_anim(current_attack_body_anim, "equip_idle")
		if current_gloves and current_gloves.has_method("play_attack_follow_pose"):
			current_gloves.play_attack_follow_pose(attack_direction, _get_equipment_attack_follow_anim())

func can_start_attack() -> bool:
	# Attacks are intentionally allowed while grounded, airborne, or attached to a grapple.
	return not is_dead and not is_hurt and not is_attacking and attack_cooldown_timer <= 0.0

func _play_weapon_attack_anim() -> void:
	if not weapon_animation_player:
		return

	if not weapon_animation_player.has_animation("quick_attack"):
		return

	weapon_animation_player.stop()
	weapon_animation_player.play("quick_attack")

func _play_weapon_pose_anim(body_anim: String) -> void:
	if not weapon_animation_player:
		return

	var pose_anim := "weapon_%s" % body_anim.to_lower()
	if not weapon_animation_player.has_animation(pose_anim):
		pose_anim = "weapon_idle"
	if not weapon_animation_player.has_animation(pose_anim):
		return
	if current_weapon_pose_anim == pose_anim and weapon_animation_player.current_animation == pose_anim:
		return

	current_weapon_pose_anim = pose_anim
	weapon_animation_player.play(pose_anim)

func _reset_weapon_visuals() -> void:
	if attack_swing_root:
		attack_swing_root.rotation = 0.0

	if not weapon_animation_player:
		return

	if weapon_animation_player.has_animation("weapon_%s" % current_body_anim.to_lower()):
		_play_weapon_pose_anim(current_body_anim)
		return

	if not weapon_animation_player.has_animation("RESET"):
		return

	weapon_animation_player.play("RESET")
	weapon_animation_player.seek(0.0, true)

func _get_attack_input_direction() -> Vector2:
	var direction := AimHelperScript.get_aim_direction(
		self,
		global_position,
		Vector2(float(last_direction), 0.0),
		ATTACK_DIRECTION_DEADZONE
	)

	if abs(direction.x) > ATTACK_DIRECTION_DEADZONE:
		last_direction = int(sign(direction.x))
		if player_animation:
			player_animation.flip_h = direction.x < 0.0

	return direction

func _get_attack_body_animation() -> String:
	if not player_animation or not player_animation.sprite_frames:
		return "Attack"

	if is_on_floor() and not _is_grapple_restricting():
		return "Attack"

	var attack_anim := "Attack_Forward"
	if attack_direction.y < -0.6 and abs(attack_direction.y) >= abs(attack_direction.x):
		attack_anim = "Attack_Up"
	elif attack_direction.y > 0.6 and abs(attack_direction.y) >= abs(attack_direction.x):
		attack_anim = "Attack_Down"
	elif abs(attack_direction.y) > 0.25 and abs(attack_direction.x) > 0.25:
		attack_anim = "Attack_Diagonal"

	if player_animation.sprite_frames.has_animation(attack_anim):
		return attack_anim
	return "Attack"

func _get_special_body_animation() -> String:
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Neutral_Special_Attack"):
		return "Neutral_Special_Attack"
	return "Attack"

func _get_equipment_attack_follow_anim() -> String:
	if current_attack_is_special:
		return "Attack"
	return current_attack_body_anim

func _is_grapple_restricting() -> bool:
	if current_gloves and current_gloves.has_method("is_base_grapple_restricting"):
		return current_gloves.is_base_grapple_restricting()
	return false

func _apply_attack_direction() -> void:
	var direction := attack_direction
	if direction.length() <= ATTACK_DIRECTION_DEADZONE:
		direction = Vector2(float(last_direction), 0.0)
	direction = direction.normalized()

	if attack_swing_root and equipment_mount:
		var local_direction := equipment_mount.global_transform.basis_xform_inv(direction).normalized()
		attack_swing_root.rotation = local_direction.angle()
		_sync_attack_hitbox_to_slash()

func _sync_attack_hitbox_to_slash() -> void:
	if not attack_hitbox or not attack_slash_sprite:
		return

	attack_hitbox.global_transform = attack_slash_sprite.global_transform

func _build_attack_damage() -> DamageData:
	var data := DamageData.new()
	data.amount = player_stats.attack_damage
	if current_attack_is_special:
		data.amount = roundi(float(player_stats.attack_damage) * neutral_special_damage_multiplier * player_stats.skill_damage_multiplier)
	data.hitstun = player_stats.hurt_time
	data.hit_pause = player_stats.hit_pause
	var knockback_direction := attack_direction
	if knockback_direction.length() <= ATTACK_DIRECTION_DEADZONE:
		knockback_direction = Vector2(float(last_direction), 0.0)
	data.knockback = knockback_direction.normalized() * player_stats.knockback_strength
	if current_attack_is_special:
		data.knockback *= 1.2
		data.hit_pause *= 1.2
	return data

func set_action_points(current: int, maximum: int = max_action_points) -> void:
	max_action_points = maximum
	current_action_points = current
	_ensure_action_point_timers()

func spend_action_points(amount: int) -> bool:
	if amount <= 0:
		return true
	_ensure_action_point_timers()
	if current_action_points < amount:
		return false

	var spent := 0
	for i in range(max_action_points - 1, -1, -1):
		if _action_point_recharge_timers[i] <= 0.0:
			_action_point_recharge_timers[i] = action_point_recharge_time
			spent += 1
			if spent >= amount:
				break

	current_action_points = _count_available_action_points()
	return true

func restore_action_points(amount: int) -> void:
	if amount <= 0:
		return

	_ensure_action_point_timers()
	var restored := 0
	for i in max_action_points:
		if _action_point_recharge_timers[i] > 0.0:
			_action_point_recharge_timers[i] = 0.0
			restored += 1
			if restored >= amount:
				break

	current_action_points = _count_available_action_points()

func refill_action_points() -> void:
	_ensure_action_point_timers()
	for i in _action_point_recharge_timers.size():
		_action_point_recharge_timers[i] = 0.0
	current_action_points = max_action_points
	AudioManager.play_ui(&"loot_special_item")

func set_momentum(value: float) -> void:
	momentum = value
	if momentum >= 100.0 and not _flow_state_active:
		_enter_flow_state()
	elif momentum < 100.0 and _flow_state_active:
		_exit_flow_state()

func collect_thread_knots(amount: int) -> void:
	thread_knot_count += maxi(0, amount)
	if _coin_pickup_audio_timer <= 0.0:
		AudioManager.play_ui(&"coin_pickup")
		_coin_pickup_audio_timer = coin_pickup_audio_cooldown

func can_weave_stat_upgrade(cost: int) -> bool:
	return thread_knot_count >= maxi(0, cost)

func weave_stat_upgrade(stat_id: StringName, cost: int = 0) -> bool:
	var upgrade_cost := maxi(0, cost)
	if not player_stats or not can_weave_stat_upgrade(upgrade_cost):
		return false

	var previous_max_health := player_stats.max_health
	if not player_stats.apply_stat_upgrade(stat_id):
		return false

	if upgrade_cost > 0:
		thread_knot_count -= upgrade_cost

	_apply_player_stats_after_upgrade(previous_max_health)
	AudioManager.play_ui(&"loot_special_item")
	return true

func get_weave_stat_display(stat_id: StringName) -> String:
	if not player_stats:
		return ""
	return player_stats.get_stat_display_value(stat_id)

func get_weave_stat_preview(stat_id: StringName) -> String:
	if not player_stats:
		return ""
	return player_stats.get_next_stat_display_value(stat_id)

func get_weave_stat_points(stat_id: StringName) -> int:
	if not player_stats:
		return 0
	return player_stats.get_upgrade_points(stat_id)

func _apply_player_stats_after_upgrade(previous_max_health: int) -> void:
	max_health = player_stats.max_health
	if health_component:
		var health_delta := maxi(0, player_stats.max_health - previous_max_health)
		health_component.max_health = player_stats.max_health
		health_component.current_health = clampi(health_component.current_health + health_delta, 0, health_component.max_health)
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)
	_sync_hud()

func _sync_hud() -> void:
	if not is_inside_tree():
		return

	var hud := get_tree().get_first_node_in_group("combat_hud")
	if not hud:
		return

	if hud.has_method("set_health") and health_component:
		hud.set_health(health_component.current_health, health_component.max_health)
	if hud.has_method("set_action_points"):
		hud.set_action_points(current_action_points, max_action_points)
	if hud.has_method("set_action_point_cooldowns"):
		hud.set_action_point_cooldowns(_get_action_point_cooldown_ratios())
	if hud.has_method("set_momentum"):
		hud.set_momentum(momentum)
	if hud.has_method("set_momentum_state"):
		hud.set_momentum_state(_momentum_state, _flow_state_active)
	if hud.has_method("set_thread_knots"):
		hud.set_thread_knots(thread_knot_count)

func _process_action_point_recharge(delta: float) -> void:
	_ensure_action_point_timers()
	var recharge_delta := delta * get_momentum_action_point_recharge_multiplier() * player_stats.action_point_recharge_multiplier
	var changed := false
	for i in _action_point_recharge_timers.size():
		if _action_point_recharge_timers[i] <= 0.0:
			continue

		_action_point_recharge_timers[i] = maxf(0.0, _action_point_recharge_timers[i] - recharge_delta)
		changed = true

	if changed:
		current_action_points = _count_available_action_points()
		_sync_hud()

func _ensure_action_point_timers() -> void:
	while _action_point_recharge_timers.size() < max_action_points:
		_action_point_recharge_timers.append(0.0)
	while _action_point_recharge_timers.size() > max_action_points:
		_action_point_recharge_timers.pop_back()

func _count_available_action_points() -> int:
	_ensure_action_point_timers()
	var available := 0
	for timer in _action_point_recharge_timers:
		if timer <= 0.0:
			available += 1
	return clampi(available, 0, max_action_points)

func _get_action_point_cooldown_ratios() -> Array[float]:
	_ensure_action_point_timers()
	var ratios: Array[float] = []
	var recharge_time := maxf(action_point_recharge_time, 0.001)
	for timer in _action_point_recharge_timers:
		ratios.append(clampf(timer / recharge_time, 0.0, 1.0))
	return ratios

func report_momentum_action(category: StringName, strength: float = 1.0) -> void:
	if strength <= 0.0:
		return

	_apply_momentum_category(category, strength)

	if _pending_use_after_swap and category != MOMENTUM_CATEGORY_EQUIPMENT_SWAP and category != MOMENTUM_CATEGORY_USE_AFTER_SWAP and category != MOMENTUM_CATEGORY_MOVEMENT:
		_pending_use_after_swap = false
		_use_after_swap_timer = 0.0
		_apply_momentum_category(MOMENTUM_CATEGORY_USE_AFTER_SWAP, 1.0)

func start_dash_iframe(duration: float) -> void:
	_dash_iframe_timer = maxf(_dash_iframe_timer, duration * get_momentum_dash_iframe_multiplier())

func get_momentum_action_point_recharge_multiplier() -> float:
	return _get_momentum_multiplier(momentum_action_point_recharge_low, momentum_action_point_recharge_mid, momentum_action_point_recharge_high, momentum_action_point_recharge_flow)

func get_momentum_move_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_move_speed_low, momentum_move_speed_mid, momentum_move_speed_high, momentum_move_speed_flow)

func get_momentum_jump_multiplier() -> float:
	return _get_momentum_multiplier(momentum_jump_low, momentum_jump_mid, momentum_jump_high, momentum_jump_flow)

func get_momentum_air_control_multiplier() -> float:
	return _get_momentum_multiplier(momentum_air_control_low, momentum_air_control_mid, momentum_air_control_high, momentum_air_control_flow)

func get_momentum_grapple_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_grapple_speed_low, momentum_grapple_speed_mid, momentum_grapple_speed_high, momentum_grapple_speed_flow)

func get_momentum_grapple_pull_multiplier() -> float:
	return _get_momentum_multiplier(momentum_grapple_pull_low, momentum_grapple_pull_mid, momentum_grapple_pull_high, momentum_grapple_pull_flow)

func get_momentum_attack_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_attack_speed_low, momentum_attack_speed_mid, momentum_attack_speed_high, momentum_attack_speed_flow)

func get_momentum_dash_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_dash_speed_low, momentum_dash_speed_mid, momentum_dash_speed_high, momentum_dash_speed_flow)

func get_momentum_dash_iframe_multiplier() -> float:
	return _get_momentum_multiplier(momentum_dash_iframe_low, momentum_dash_iframe_mid, momentum_dash_iframe_high, momentum_dash_iframe_flow)

func get_coin_vacuum_multiplier() -> float:
	return _get_momentum_multiplier(momentum_coin_vacuum_low, momentum_coin_vacuum_mid, momentum_coin_vacuum_high, momentum_coin_vacuum_flow)

func _process_momentum(delta: float) -> void:
	if _dash_iframe_timer > 0.0:
		_dash_iframe_timer = maxf(0.0, _dash_iframe_timer - delta)

	if _pending_use_after_swap:
		_use_after_swap_timer -= delta
		if _use_after_swap_timer <= 0.0:
			_pending_use_after_swap = false

	if not _flow_state_active:
		return

	_flow_state_duration += delta
	if _flow_state_duration < flow_state_drain_delay:
		return

	var active_flow_time := _flow_state_duration - flow_state_drain_delay
	var drain := minf(flow_state_drain_base + active_flow_time * flow_state_drain_growth, flow_state_drain_max)
	_change_momentum(-drain * delta)
	if momentum <= 0.0:
		_exit_flow_state()

func _process_audio_timers(delta: float) -> void:
	if _footstep_timer > 0.0:
		_footstep_timer = maxf(0.0, _footstep_timer - delta)
	if _coin_pickup_audio_timer > 0.0:
		_coin_pickup_audio_timer = maxf(0.0, _coin_pickup_audio_timer - delta)

func _process_movement_audio(_delta: float, was_on_floor: bool) -> void:
	var on_floor := is_on_floor()
	if on_floor and not was_on_floor and not god_mode_enabled:
		AudioManager.play_sfx(&"player_land")

	if on_floor and not is_dead and not is_hurt and absf(velocity.x) >= footstep_min_speed and _footstep_timer <= 0.0:
		AudioManager.play_sfx(&"player_footstep")
		_footstep_timer = footstep_interval

func _process_movement_momentum(delta: float) -> void:
	var moved_distance := global_position.distance_to(_movement_momentum_last_position)
	_movement_momentum_last_position = global_position

	if is_dead or is_hurt:
		_movement_momentum_distance = 0.0
		return

	_movement_momentum_distance += moved_distance
	_movement_momentum_timer -= delta
	if _movement_momentum_timer > 0.0:
		return

	var sample_time := maxf(momentum_movement_report_interval, 0.001)
	var sample_speed := _movement_momentum_distance / sample_time
	_movement_momentum_timer = momentum_movement_report_interval
	_movement_momentum_distance = 0.0

	if sample_speed < momentum_movement_min_speed:
		return

	var strength := clampf(sample_speed / maxf(momentum_movement_reference_speed, 1.0), 0.15, 1.6)
	report_momentum_action(MOMENTUM_CATEGORY_MOVEMENT, strength)

func _apply_momentum_category(category: StringName, strength: float) -> void:
	var base_gain := _get_momentum_base_gain(category)
	if base_gain == 0.0:
		return

	if category == MOMENTUM_CATEGORY_MOVEMENT:
		var movement_stale_timer := float(_momentum_staleness.get(category, 0.0))
		var movement_duration := maxf(momentum_movement_stale_duration, 0.001)
		var movement_stale_multiplier := maxf(0.0, 1.0 - movement_stale_timer / movement_duration)
		var movement_gain := base_gain * strength * movement_stale_multiplier * _get_momentum_gain_curve_multiplier() * player_stats.momentum_generation_multiplier
		_change_momentum(movement_gain)
		_reduce_other_momentum_staleness(category)
		_momentum_staleness[category] = minf(movement_duration, movement_stale_timer + momentum_movement_report_interval)
		_update_recent_momentum_categories(category)
		return

	var stale_duration := maxf(momentum_stale_duration, 0.001)
	var stale_timer := float(_momentum_staleness.get(category, 0.0))
	var stale_ratio := clampf(stale_timer / stale_duration, 0.0, 1.0)
	var stale_multiplier := maxf(0.0, 1.0 - stale_ratio)
	var gain := base_gain * strength * stale_multiplier * _get_momentum_gain_curve_multiplier() * _get_weaving_multiplier(category) * player_stats.momentum_generation_multiplier

	if stale_ratio >= 1.0:
		gain -= momentum_stale_penalty

	_change_momentum(gain)
	_reduce_other_momentum_staleness(category)
	_momentum_staleness[category] = stale_duration
	_update_recent_momentum_categories(category)

	if category == MOMENTUM_CATEGORY_EQUIPMENT_SWAP:
		_pending_use_after_swap = true
		_use_after_swap_timer = momentum_use_after_swap_window

func _get_momentum_base_gain(category: StringName) -> float:
	match category:
		MOMENTUM_CATEGORY_MOVEMENT:
			return momentum_gain_movement
		MOMENTUM_CATEGORY_JUMP:
			return momentum_gain_jump
		MOMENTUM_CATEGORY_DASH:
			return momentum_gain_dash
		MOMENTUM_CATEGORY_GRAPPLE:
			return momentum_gain_grapple
		MOMENTUM_CATEGORY_ATTACK:
			return momentum_gain_attack
		MOMENTUM_CATEGORY_POGO:
			return momentum_gain_pogo
		MOMENTUM_CATEGORY_UTILITY:
			return momentum_gain_utility
		MOMENTUM_CATEGORY_EQUIPMENT_SWAP:
			return momentum_gain_equipment_swap
		MOMENTUM_CATEGORY_USE_AFTER_SWAP:
			return momentum_gain_use_after_swap
	return 0.0

func _get_momentum_gain_curve_multiplier() -> float:
	if momentum < momentum_low_threshold:
		return 1.05
	if momentum < momentum_high_threshold:
		return 1.0
	if momentum < 100.0:
		var high_span := maxf(1.0, 100.0 - momentum_high_threshold)
		return lerpf(0.58, 0.22, (momentum - momentum_high_threshold) / high_span)
	return 0.15

func _get_weaving_multiplier(category: StringName) -> float:
	if _momentum_recent_categories.is_empty() or _momentum_recent_categories.back() == category:
		return 1.0

	var distinct := {}
	for recent_category in _momentum_recent_categories:
		if recent_category != category:
			distinct[recent_category] = true

	return 1.0 + minf(0.6, float(distinct.size()) * momentum_weave_bonus_per_category)

func _reduce_other_momentum_staleness(category: StringName) -> void:
	for key in _momentum_staleness.keys():
		if key == category:
			continue
		var timer := float(_momentum_staleness[key])
		var duration := momentum_movement_stale_duration if key == MOMENTUM_CATEGORY_MOVEMENT else momentum_stale_duration
		var reduction := maxf(duration, 0.001) * momentum_stale_recovery_fraction
		_momentum_staleness[key] = maxf(0.0, timer - reduction)

func _update_recent_momentum_categories(category: StringName) -> void:
	_momentum_recent_categories.append(category)
	while _momentum_recent_categories.size() > momentum_weave_recent_count:
		_momentum_recent_categories.pop_front()

func _change_momentum(amount: float) -> void:
	if amount == 0.0:
		return

	momentum = clampf(momentum + amount, 0.0, 100.0)
	if momentum >= 100.0 and not _flow_state_active:
		_enter_flow_state()

func _enter_flow_state() -> void:
	if _flow_state_active:
		return

	_flow_state_active = true
	_flow_state_duration = 0.0
	AudioManager.play_sfx(&"enter_momentum")
	_sync_flow_state_audio()
	_set_flow_state_visuals(true)
	_update_momentum_state()

func _exit_flow_state() -> void:
	if not _flow_state_active:
		return

	_flow_state_active = false
	_flow_state_duration = 0.0
	_sync_flow_state_audio()
	_set_flow_state_visuals(false)
	_update_momentum_state()

func set_flow_state_audio_suspended(is_suspended: bool) -> void:
	_flow_state_audio_suspended = is_suspended
	_sync_flow_state_audio()

func _sync_flow_state_audio() -> void:
	if _flow_state_active and not _flow_state_audio_suspended:
		AudioManager.play_loop(&"momentum_aura")
	else:
		AudioManager.stop_loop(&"momentum_aura")

func _set_flow_state_visuals(is_active: bool) -> void:
	if flow_state_aura and flow_state_aura.has_method("set_flow_active"):
		flow_state_aura.set_flow_active(is_active)

func _lose_momentum_from_damage(damage: DamageData) -> void:
	var severity := maxf(1.0, float(damage.amount))
	var resistance := _get_momentum_multiplier(momentum_decay_resistance_low, momentum_decay_resistance_mid, momentum_decay_resistance_high, momentum_decay_resistance_flow)
	var loss := (momentum_damage_loss_per_damage * severity) + (momentum * momentum_damage_loss_current_scale * severity)
	_change_momentum(-loss * (1.0 - clampf(resistance, 0.0, 0.9)))

func _get_momentum_multiplier(low_value: float, mid_value: float, high_value: float, flow_value: float) -> float:
	if _flow_state_active:
		return flow_value

	if momentum <= momentum_low_threshold:
		return lerpf(low_value, mid_value, clampf(momentum / maxf(momentum_low_threshold, 1.0), 0.0, 1.0))
	if momentum < momentum_high_threshold:
		return mid_value

	var high_span := maxf(1.0, 100.0 - momentum_high_threshold)
	return lerpf(mid_value, high_value, clampf((momentum - momentum_high_threshold) / high_span, 0.0, 1.0))

func _update_momentum_state() -> void:
	var next_state := MOMENTUM_STATE_MID
	if _flow_state_active:
		next_state = MOMENTUM_STATE_FLOW
	elif momentum < momentum_low_threshold:
		next_state = MOMENTUM_STATE_LOW
	elif momentum >= momentum_high_threshold:
		next_state = MOMENTUM_STATE_HIGH

	if next_state == _momentum_state:
		return

	_momentum_state = next_state
	momentum_state_changed.emit(_momentum_state, _flow_state_active)

func _on_attack_hit_landed(_hurtbox: HurtboxComponent, damage: DamageData) -> void:
	CombatFeedback.screen_shake(self, player_stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)
	if attack_direction.y > 0.55 and not is_on_floor():
		report_momentum_action(MOMENTUM_CATEGORY_POGO)
	else:
		report_momentum_action(MOMENTUM_CATEGORY_ATTACK, 1.25)

func _on_health_changed(_current: int, _maximum: int) -> void:
	_sync_hud()

func should_ignore_health_damage(_damage: DamageData) -> bool:
	return god_mode_enabled or _dash_iframe_timer > 0.0

func modify_incoming_health_damage(damage: DamageData) -> DamageData:
	if not player_stats or player_stats.resistance <= 0:
		return damage

	var modified := damage.duplicate(true) as DamageData
	var mitigation := player_stats.get_resistance_mitigation()
	modified.amount = maxi(1, roundi(float(damage.amount) * (1.0 - mitigation)))
	return modified

func receive_ignored_health_hit(damage: DamageData) -> void:
	if _dash_iframe_timer > 0.0 and not god_mode_enabled:
		_sync_hud()
		return

	_on_damaged(damage)
	_sync_hud()

func _on_damaged(damage: DamageData) -> void:
	is_hurt = true
	hurt_timer = player_stats.hurt_time
	is_attacking = false
	current_attack_is_special = false
	attack_hitbox.disable()
	_reset_weapon_visuals()
	AudioManager.play_sfx(&"player_damage")

	if hit_flash:
		hit_flash.flash(Color(1.0, 0.35, 0.35, 1.0), 0.08)

	var knockback := damage.knockback
	if knockback == Vector2.ZERO and damage.source is Node2D:
		var source_node := damage.source as Node2D
		knockback = Vector2(sign(global_position.x - source_node.global_position.x) * player_stats.knockback_strength, -90.0)

	velocity = knockback
	_lose_momentum_from_damage(damage)
	CombatFeedback.screen_shake(self, player_stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

func _on_died(_damage: DamageData) -> void:
	if death_reset_started:
		return

	_exit_flow_state()
	AudioManager.stop_loop(&"grapple_hanging")
	is_dead = true
	death_reset_started = true
	is_attacking = false
	current_attack_is_special = false
	attack_hitbox.disable()
	_reset_weapon_visuals()
	call_deferred("_show_game_over_after_death")

func _show_game_over_after_death() -> void:
	if death_reset_delay > 0.0:
		await get_tree().create_timer(death_reset_delay, true, false, true).timeout

	if not is_inside_tree():
		return

	var overlay := GAME_OVER_OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(overlay)

	if overlay.has_signal("completed"):
		await overlay.completed

	_reload_scene_after_death()

func _reload_scene_after_death() -> void:
	if not is_inside_tree():
		return

	var error := get_tree().reload_current_scene()
	if error != OK:
		push_warning("Player: Failed to reload current scene after death.")

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
# SAVE POINT INTERACTION
# ===============================
func begin_save_point_interaction(save_point: Node, sit_target_position: Vector2) -> bool:
	if save_point_interaction_active or is_dead:
		return false

	save_point_interaction_active = true
	_save_point_controller = save_point
	_save_point_target_position = sit_target_position
	_save_point_sitting_down = false
	_save_point_seated = false
	_save_point_standing_up = false
	is_near_interactable = false
	current_selector = null
	is_attacking = false
	is_hurt = false
	current_attack_is_special = false
	is_wall_clinging = false
	wall_cling_timer = 0.0
	attack_timer = 0.0
	attack_cooldown_timer = 0.0
	velocity = Vector2.ZERO
	if player_animation:
		_save_point_original_scale = player_animation.scale
		_save_point_original_animation_speed_scale = player_animation.speed_scale
	if equipment_mount:
		_save_point_equipment_was_visible = equipment_mount.visible
	if attack_hitbox:
		attack_hitbox.disable()
	_reset_weapon_visuals()
	return true

func end_save_point_interaction() -> void:
	if not save_point_interaction_active:
		return
	if _save_point_standing_up:
		return

	_save_point_standing_up = true
	_stop_save_point_breathing(false)
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		player_animation.animation = SIT_ANIMATION
		player_animation.frame = maxi(player_animation.sprite_frames.get_frame_count(SIT_ANIMATION) - 1, 0)
		player_animation.speed_scale = _save_point_original_animation_speed_scale * save_point_stand_up_speed_scale
		player_animation.play_backwards(SIT_ANIMATION)
		await player_animation.animation_finished
	_complete_save_point_interaction()

func recover_at_save_point() -> void:
	if health_component:
		health_component.heal(health_component.max_health)
	refill_action_points()
	_sync_hud()

func _apply_demo_checkpoint_spawn() -> void:
	if not DemoProgress.has_checkpoint():
		return

	var current_scene := get_tree().current_scene
	if not current_scene or current_scene.scene_file_path != DemoProgress.get_checkpoint_scene_path():
		return

	global_position = DemoProgress.get_checkpoint_position()
	_movement_momentum_last_position = global_position

func _complete_save_point_interaction() -> void:
	save_point_interaction_active = false
	_save_point_controller = null
	_save_point_sitting_down = false
	_save_point_seated = false
	_save_point_standing_up = false
	velocity = Vector2.ZERO
	_restore_save_point_visual_state()
	if current_gloves and current_gloves.has_method("exit_save_point_pose"):
		current_gloves.exit_save_point_pose()
	_restore_save_point_equipment()
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Idle"):
		play_character_anim("Idle", "equip_idle")

func _process_save_point_interaction(delta: float) -> void:
	if _save_point_sitting_down or _save_point_seated or _save_point_standing_up:
		return

	var target_delta := _save_point_target_position - global_position
	if abs(target_delta.x) > save_point_arrive_distance:
		var direction := int(sign(target_delta.x))
		last_direction = direction
		if player_animation:
			player_animation.flip_h = direction < 0
		update_equipment_facing()
		velocity.x = float(direction) * save_point_auto_run_speed
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		move_and_slide()
		if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Run"):
			play_character_anim("Run", "equip_run")
		return

	global_position = _save_point_target_position
	velocity = Vector2.ZERO
	_save_point_sitting_down = true
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		player_animation.scale = _save_point_original_scale * save_point_sit_visual_scale
		_hide_save_point_equipment()
		play_character_anim(String(SIT_ANIMATION), "equip_idle")
		if current_gloves and current_gloves.has_method("enter_save_point_pose"):
			current_gloves.enter_save_point_pose()
		call_deferred("_complete_save_point_sit_down")
	else:
		_complete_save_point_sit_down()

func _complete_save_point_sit_down() -> void:
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		await player_animation.animation_finished
		player_animation.frame = maxi(player_animation.sprite_frames.get_frame_count(SIT_ANIMATION) - 1, 0)
	_save_point_sitting_down = false
	_save_point_seated = true
	_start_save_point_breathing()
	save_point_seated.emit(self)

func _start_save_point_breathing() -> void:
	if not player_animation:
		return

	_save_point_original_material = player_animation.material
	var seated_scale := player_animation.scale
	var meditation_material := ShaderMaterial.new()
	meditation_material.shader = MEDITATION_SHADER
	player_animation.material = meditation_material

	if _save_point_breath_tween:
		_save_point_breath_tween.kill()
	_save_point_breath_tween = create_tween()
	_save_point_breath_tween.set_loops()
	_save_point_breath_tween.tween_property(player_animation, "scale", seated_scale * Vector2(1.015, 0.992), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_save_point_breath_tween.tween_property(player_animation, "scale", seated_scale, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_save_point_breathing(restore_scale := true) -> void:
	if _save_point_breath_tween:
		_save_point_breath_tween.kill()
		_save_point_breath_tween = null
	if player_animation:
		player_animation.material = _save_point_original_material
		if restore_scale:
			player_animation.scale = _save_point_original_scale
			player_animation.speed_scale = _save_point_original_animation_speed_scale

func _restore_save_point_visual_state() -> void:
	if player_animation:
		player_animation.material = _save_point_original_material
		player_animation.scale = _save_point_original_scale
		player_animation.speed_scale = _save_point_original_animation_speed_scale

func _hide_save_point_equipment() -> void:
	if equipment_mount:
		equipment_mount.visible = false

func _restore_save_point_equipment() -> void:
	if equipment_mount:
		equipment_mount.visible = _save_point_equipment_was_visible

func _ensure_sit_animation() -> void:
	if not player_animation or not player_animation.sprite_frames:
		return
	if player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		return

	player_animation.sprite_frames.add_animation(SIT_ANIMATION)
	player_animation.sprite_frames.set_animation_loop(SIT_ANIMATION, false)
	player_animation.sprite_frames.set_animation_speed(SIT_ANIMATION, SIT_FPS)
	var frame_width := SIT_TEXTURE.get_width() / SIT_COLUMNS
	var frame_height := SIT_TEXTURE.get_height() / SIT_ROWS
	for frame_index in SIT_FRAME_COUNT:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = SIT_TEXTURE
		atlas_texture.region = Rect2(
			(frame_index % SIT_COLUMNS) * frame_width,
			(frame_index / SIT_COLUMNS) * frame_height,
			frame_width,
			frame_height
		)
		player_animation.sprite_frames.add_frame(SIT_ANIMATION, atlas_texture)

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
