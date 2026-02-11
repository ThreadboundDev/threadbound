extends CanvasLayer

@onready var background: TextureRect = $Background          # Your radial PNG (centered on player)
@onready var dim_overlay: TextureRect = $DimOverlay        # Full-screen grey dim (anchored full rect)

# ──────────────────────────────────────
# Player Reference for Centering
# ──────────────────────────────────────
@export var player_path: NodePath = "../Player"            # Set in inspector or change path
@onready var player: CharacterBody2D = get_node_or_null(player_path)

# ──────────────────────────────────────
# Time Slow Banking (anti-exploit)
# ──────────────────────────────────────
@export var max_slow_bank: float = 2.0                     # Max seconds of slow time banked
@export var recharge_rate: float = 0.2                     # Full recharge in ~10s when closed
@export var slow_scale: float = 0.25                       # Quarter speed during slow
@export var lerp_back_speed: float = 0.8                   # Snappy return to normal

var slow_bank: float = 2.0
var last_real_time: float = 0.0
var is_slowing: bool = false
var is_held: bool = false
var time_scale_tween: Tween

# ──────────────────────────────────────
# Signals
# ──────────────────────────────────────
signal equip_swapped(slot_index: int)                      # For refill on equip select

func _ready() -> void:
	visible = false
	if dim_overlay:
		dim_overlay.visible = false
	add_to_group("radial_menu")
	slow_bank = max_slow_bank
	last_real_time = Time.get_ticks_msec() / 1000.0

# Real delta (ignores time_scale)
func _get_real_delta() -> float:
	var now = Time.get_ticks_msec() / 1000.0
	var delta = now - last_real_time
	last_real_time = now
	return delta

func _process(delta: float) -> void:
	var real_delta = _get_real_delta()
	
	# Recharge only when menu closed
	if not is_held:
		slow_bank = min(slow_bank + (recharge_rate * real_delta), max_slow_bank)
	
	# Deplete bank while slowing
	if is_slowing and is_held:
		slow_bank -= real_delta
		if slow_bank <= 0.0:
			slow_bank = 0.0
			is_slowing = false
			is_held = false
			visible = false
			if dim_overlay:
				dim_overlay.visible = false
			# Smooth return instead of snap
			if time_scale_tween:
				time_scale_tween.kill()
			time_scale_tween = create_tween()
			time_scale_tween.tween_property(Engine, "time_scale", 1.0, 0.3)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_SINE)
	
	# Center radial background on player (only while open)
	if player and is_held:
		var player_screen_pos = player.get_global_transform_with_canvas().origin
		var viewport_size = get_viewport().get_visible_rect().size
		background.position = player_screen_pos - (viewport_size / 2)
		# Optional vertical bias (menu above player head)
		background.position.y -= 80  # Tune: 50–120 pixels

# Called every frame from player.gd _process
func update_hold_state(held: bool) -> void:
	if held and not is_held:
		# Tab pressed → open
		is_held = true
		visible = true
		if dim_overlay:
			dim_overlay.visible = true
		
		# Slow only if bank remains
		if slow_bank > 0.1:
			is_slowing = true
			Engine.time_scale = slow_scale
			if time_scale_tween:
				time_scale_tween.kill()
		# else: menu shows in real-time (brief view)
	
	elif not held and is_held:
		# Tab released → close
		is_held = false
		_close_menu()

func _close_menu() -> void:
	visible = false
	if dim_overlay:
		dim_overlay.visible = false
	is_slowing = false
	
	# Smooth time return
	if time_scale_tween:
		time_scale_tween.kill()
	time_scale_tween = create_tween()
	time_scale_tween.tween_property(Engine, "time_scale", 1.0, lerp_back_speed)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)

# Stub for when player selects an equip (call from future slice logic)
func select_equip(slot_index: int) -> void:
	# Refill bank on equip change
	slow_bank = max_slow_bank
	equip_swapped.emit(slot_index)
	print("Equip selected: ", slot_index)
	# Optional: close_menu() after select

# Optional: Esc to force close
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		update_hold_state(false)
