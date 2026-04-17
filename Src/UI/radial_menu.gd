extends CanvasLayer

# Slot Controls - your exact names
@onready var monarch_gloves_slot: Control = $MenuFadeContainer/Background/MonarchGlovesButton
@onready var monarch_boots_slot: Control = $MenuFadeContainer/Background/MonarchBootsButton
@onready var monarch_chest_slot: Control = $MenuFadeContainer/Background/MonarchChestButton
@onready var hermit_gloves_slot: Control = $MenuFadeContainer/Background/HermitGlovesButton
@onready var hermit_boots_slot: Control = $MenuFadeContainer/Background/HermitBootsButton
@onready var hermit_chest_slot: Control = $MenuFadeContainer/Background/HermitChestButton
@onready var sage_gloves_slot: Control = $MenuFadeContainer/Background/SageGlovesButton
@onready var sage_boots_slot: Control = $MenuFadeContainer/Background/SageBootsButton
@onready var sage_chest_slot: Control = $MenuFadeContainer/Background/SageChestButton

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
	
	visible = true
	add_to_group("radial_menu")
	slow_bank = max_slow_bank
	last_real_time = Time.get_ticks_msec() / 1000.0
	
	print("=== Slot Load Debug ===")
	print("MonarchGlovesButton: ", monarch_gloves_slot != null)
	print("MonarchBootsButton: ", monarch_boots_slot != null)
	print("MonarchChestButton: ", monarch_chest_slot != null)
	print("HermitGlovesButton: ", hermit_gloves_slot != null)
	print("HermitBootsButton: ", hermit_boots_slot != null)
	print("HermitChestButton: ", hermit_chest_slot != null)
	print("SageGlovesButton: ", sage_gloves_slot != null)
	print("SageBootsButton: ", sage_boots_slot != null)
	print("SageChestButton: ", sage_chest_slot != null)
	print("=======================")
	
	_connect_slot(monarch_gloves_slot, EquipManager.ThreadColor.RED, 0)
	_connect_slot(monarch_boots_slot, EquipManager.ThreadColor.RED, 3)
	_connect_slot(monarch_chest_slot, EquipManager.ThreadColor.RED, 6)
	_connect_slot(hermit_gloves_slot, EquipManager.ThreadColor.BLUE, 1)
	_connect_slot(hermit_boots_slot, EquipManager.ThreadColor.BLUE, 4)
	_connect_slot(hermit_chest_slot, EquipManager.ThreadColor.BLUE, 7)
	_connect_slot(sage_gloves_slot, EquipManager.ThreadColor.YELLOW, 2)
	_connect_slot(sage_boots_slot, EquipManager.ThreadColor.YELLOW, 5)
	_connect_slot(sage_chest_slot, EquipManager.ThreadColor.YELLOW, 8)

func _connect_slot(slot: Control, color: EquipManager.ThreadColor, slot_idx: int) -> void:
	if slot == null:
		print("Warning: slot is null")
		return
	
	var icon = slot.get_node_or_null("Icon") as TextureRect
	var area = slot.get_node_or_null("HitArea") as Area2D
	
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = icon.size / 2.0   # grow in place
	
	print("Connected slot: ", slot.name, " (index ", slot_idx, ")")
	
	if area:
		area.mouse_entered.connect(_on_slot_hover.bind(slot, color))
		area.mouse_exited.connect(_on_slot_unhover.bind(slot))
		area.input_event.connect(_on_slot_input_event.bind(slot, slot_idx))
		
	if area:
		area.input_pickable = true
		area.monitoring = true
	area.process_mode = Node.PROCESS_MODE_ALWAYS
	
func _on_slot_hover(slot: Control, color: EquipManager.ThreadColor) -> void:
	print("Hover triggered on: ", slot.name)
	var icon = slot.get_node_or_null("Icon") as TextureRect
	if not icon: return
	
	var glow_color = EquipManager.THREAD_COLORS[color].lightened(0.6)
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_parallel()
	tween.tween_property(icon, "modulate", glow_color, 0.12)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.12)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	var pulse = create_tween()
	pulse.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	pulse.set_loops()
	pulse.tween_property(icon, "modulate:a", 0.85, 0.4)\
		.set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(icon, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_slot_unhover(slot: Control) -> void:
	print("Unhover on: ", slot.name)
	var icon = slot.get_node_or_null("Icon") as TextureRect
	if not icon: return
	
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_parallel()
	tween.tween_property(icon, "modulate", Color.WHITE, 0.10)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.10)\
		.set_ease(Tween.EASE_IN)
	icon.modulate.a = 1.0

func _on_slot_input_event(viewport: Node, event: InputEvent, shape_idx: int, slot: Control, slot_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click detected on: ", slot.name)
		#get_viewport().set_input_as_handled()
		select_equip(slot_idx)

func select_equip(slot_idx: int) -> void:
	var slot_type = slot_idx / 3
	var color_idx = slot_idx % 3
	EquipManager.current_equip[slot_type] = color_idx
	EquipManager.equip_changed.emit(slot_type, slot_idx)
	var equip_name = EquipManager.equip_data[slot_idx]["name"]
	print("Equipped: ", equip_name, " (slot ", slot_type, ", color ", color_idx, ")")
	slow_bank = max_slow_bank
	_close_menu()

# === Your existing time slow / fade / blur code ===
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
