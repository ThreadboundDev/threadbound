extends CanvasLayer

# Slot buttons (add all 9)
@onready var monarch_gloves: TextureButton = $MenuFadeContainer/MonarchGloves
@onready var monarch_boots: TextureButton  = $MenuFadeContainer/MonarchBoots
@onready var monarch_chest: TextureButton  = $MenuFadeContainer/MonarchChest

@onready var hermit_gloves: TextureButton = $MenuFadeContainer/HermitGloves
@onready var hermit_boots: TextureButton  = $MenuFadeContainer/HermitBoots
@onready var hermit_chest: TextureButton  = $MenuFadeContainer/HermitChest

@onready var sage_gloves: TextureButton = $MenuFadeContainer/SageGloves
@onready var sage_boots: TextureButton  = $MenuFadeContainer/SageBoots
@onready var sage_chest: TextureButton  = $MenuFadeContainer/SageChest

@onready var menu_fade_container: Control = $MenuFadeContainer
@onready var background: TextureRect = $MenuFadeContainer/Background
@onready var blur_layer: CanvasLayer = get_tree().get_first_node_in_group("blur_layer")
@onready var blur_rect: ColorRect = get_tree().get_first_node_in_group("blur_rect")

@export var player_path: NodePath = "../Player"
@onready var player: CharacterBody2D = get_node_or_null(player_path)

@export var max_slow_bank: float = 2.0
@export var recharge_rate: float = 0.2
@export var slow_scale: float = 0.25
@export var open_fade_time: float = 0.35
@export var close_fade_time: float = 0.18
@export var blur_max_amount: float = 2.8

var slow_bank: float = 2.0
var last_real_time: float = 0.0
var is_slowing: bool = false
var is_held: bool = false
var time_tween: Tween
var blur_tween: Tween
var menu_tween: Tween

signal equip_swapped(slot_index: int)

func _ready() -> void:
	menu_fade_container.visible = false
	menu_fade_container.modulate.a = 0.0
	
	if blur_layer:
		blur_layer.visible = false
	if blur_rect:
		blur_rect.visible = false
		blur_rect.material.set_shader_parameter("blur_amount", 0.0)
	
	visible = true  # CanvasLayer must be visible
	add_to_group("radial_menu")
	slow_bank = max_slow_bank
	last_real_time = Time.get_ticks_msec() / 1000.0
	
	# Connect all hover / pressed signals
	_connect_slot(monarch_gloves, EquipManager.ThreadColor.RED)
	_connect_slot(monarch_boots,  EquipManager.ThreadColor.RED)
	_connect_slot(monarch_chest,  EquipManager.ThreadColor.RED)

	_connect_slot(hermit_gloves, EquipManager.ThreadColor.BLUE)
	_connect_slot(hermit_boots,  EquipManager.ThreadColor.BLUE)
	_connect_slot(hermit_chest,  EquipManager.ThreadColor.BLUE)

	_connect_slot(sage_gloves, EquipManager.ThreadColor.YELLOW)
	_connect_slot(sage_boots,  EquipManager.ThreadColor.YELLOW)
	_connect_slot(sage_chest,  EquipManager.ThreadColor.YELLOW)

# Helper to connect one button
func _connect_slot(button: TextureButton, color: EquipManager.ThreadColor) -> void:
	button.mouse_entered.connect(_on_slot_hover.bind(button, color))
	button.mouse_exited.connect(_on_slot_unhover.bind(button))
	button.pressed.connect(_on_slot_pressed.bind(button))

func _get_real_delta() -> float:
	var now = Time.get_ticks_msec() / 1000.0
	var delta = now - last_real_time
	last_real_time = now
	return delta

func _process(_delta: float) -> void:
	var real_delta = _get_real_delta()
	
	if not is_held:
		slow_bank = min(slow_bank + recharge_rate * real_delta, max_slow_bank)
	
	if is_slowing and is_held:
		slow_bank -= real_delta
		if slow_bank <= 0.0:
			slow_bank = 0.0
			is_slowing = false
			is_held = false
			_close_menu()

	if player and is_held:
		var player_screen_pos = player.get_global_transform_with_canvas().origin
		var viewport_size = get_viewport().get_visible_rect().size
		background.position = player_screen_pos - (viewport_size / 2)
		background.position.y -= 80

func update_hold_state(held: bool) -> void:
	if held and not is_held:
		is_held = true
		_fade_in_menu()
		
		if slow_bank > 0.1:
			is_slowing = true
			Engine.time_scale = slow_scale
			_fade_in_blur()
		else:
			is_slowing = false
			Engine.time_scale = 1.0

	elif not held and is_held:
		is_held = false
		_close_menu()

func _close_menu() -> void:
	is_slowing = false
	_fade_out_menu()
	_fade_out_blur()
	
	if time_tween:
		time_tween.kill()
	time_tween = create_tween()
	time_tween.tween_property(Engine, "time_scale", 1.0, close_fade_time * 0.8)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)

func _fade_in_menu() -> void:
	menu_fade_container.visible = true
	menu_fade_container.modulate.a = 0.0
	
	if menu_tween:
		menu_tween.kill()
	menu_tween = create_tween()
	menu_tween.tween_property(menu_fade_container, "modulate:a", 1.0, open_fade_time)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)

func _fade_out_menu() -> void:
	if menu_tween:
		menu_tween.kill()
	menu_tween = create_tween()
	menu_tween.tween_property(menu_fade_container, "modulate:a", 0.0, close_fade_time)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	menu_tween.tween_callback(func():
		menu_fade_container.visible = false
	)

func _fade_in_blur() -> void:
	if blur_layer:
		blur_layer.visible = true
	if blur_rect:
		blur_rect.visible = true
		blur_rect.material.set_shader_parameter("blur_amount", 0.0)
		
		if blur_tween:
			blur_tween.kill()
		blur_tween = create_tween()
		blur_tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", blur_max_amount, open_fade_time)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE)

func _fade_out_blur() -> void:
	if blur_tween:
		blur_tween.kill()
	if blur_rect:
		blur_tween = create_tween()
		blur_tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, close_fade_time)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_SINE)
		blur_tween.tween_callback(func():
			if blur_layer:
				blur_layer.visible = false
			if blur_rect:
				blur_rect.visible = false
		)

func select_equip(slot_idx: int) -> void:
	var slot_type = slot_idx / 3          # 0=gloves, 1=boots, 2=chest
	var color_idx = slot_idx % 3          # 0=red, 1=blue, 2=yellow
	
	EquipManager.current_equip[slot_type] = color_idx
	
	EquipManager.equip_changed.emit(slot_type, slot_idx)
	
	# Debug print
	var equip_name = EquipManager.equip_data[slot_idx]["name"]
	print("Equipped: ", equip_name, " (slot ", slot_type, ", color ", color_idx, ")")
	
	# Refill slow bank on swap (as before)
	slow_bank = max_slow_bank
	
	# Optional: close menu after selection
	_close_menu()
	


# Called when mouse enters any slot
func _on_slot_hover(button: TextureButton, color: EquipManager.ThreadColor) -> void:
	# Glow color = thread color with extra brightness
	var glow_color = EquipManager.THREAD_COLORS[color].lightened(0.4)
	
	var tween = create_tween().set_parallel()
	tween.tween_property(button, "modulate", glow_color, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Subtle pulse loop while hovered
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(button, "modulate:a", 0.85, 0.6)\
		.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(button, "modulate:a", 1.0, 0.6)\
		.set_ease(Tween.EASE_IN_OUT)

# Called when mouse leaves
func _on_slot_unhover(button: TextureButton) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(button, "modulate", Color.WHITE, 0.18)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(button, "scale", Vector2.ONE, 0.18)\
		.set_ease(Tween.EASE_IN)
	
	# Kill any pulse tween
	button.modulate.a = 1.0

# Called when clicked
func _on_slot_pressed(button: TextureButton) -> void:
	# Find which slot this button is (you'll need a way to map button → slot index)
	# For now we'll hard-code an example; later use a dictionary or group
	var slot_idx = -1
	
	match button.name:
		"MonarchGloves":   slot_idx = 0
		"MonarchBoots":    slot_idx = 3
		"MonarchChest":    slot_idx = 6
		"HermitGloves":    slot_idx = 1
		"HermitBoots":     slot_idx = 4
		"HermitChest":     slot_idx = 7
		"SageGloves":      slot_idx = 2
		"SageBoots":       slot_idx = 5
		"SageChest":       slot_idx = 8
	
	if slot_idx >= 0:
		select_equip(slot_idx)
	else:
		print("Warning: unknown button pressed: ", button.name)

func _input(event: InputEvent) -> void:
	if menu_fade_container.visible and event.is_action_pressed("ui_cancel"):
		update_hold_state(false)
