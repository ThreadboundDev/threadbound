extends CanvasLayer

# Slot Controls
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

# Polygon hit data — read from CollisionPolygon2D nodes once on _ready.
# Hit testing runs in _input / _process, never through the physics engine.
# This ensures immediate response regardless of Engine.time_scale.
var slot_data: Array = []  # [{slot: Control, idx: int, poly: PackedVector2Array}]
var hovered_slot: Control = null
var pulse_tweens: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	# Indices match EquipManager: Sage=0-2, Hermit=3-5, Monarch=6-8
	_connect_slot(sage_gloves_slot,    0)
	_connect_slot(sage_boots_slot,     1)
	_connect_slot(sage_chest_slot,     2)
	_connect_slot(hermit_gloves_slot,  3)
	_connect_slot(hermit_boots_slot,   4)
	_connect_slot(hermit_chest_slot,   5)
	_connect_slot(monarch_gloves_slot, 6)
	_connect_slot(monarch_boots_slot,  7)
	_connect_slot(monarch_chest_slot,  8)

func _connect_slot(slot: Control, slot_idx: int) -> void:
	if slot == null:
		push_warning("RadialMenu: slot is null for index %d" % slot_idx)
		return

	var icon = slot.get_node_or_null("Icon") as TextureRect
	var area = slot.get_node_or_null("HitArea") as Area2D

	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = icon.size / 2.0

	if area:
		var collision = area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if collision and collision.polygon.size() >= 3:
			slot_data.append({"slot": slot, "idx": slot_idx, "poly": collision.polygon})
		else:
			push_warning("RadialMenu: missing/empty CollisionPolygon2D on %s" % slot.name)
	else:
		push_warning("RadialMenu: no HitArea on %s" % slot.name)

# === INPUT — runs every frame, unaffected by Engine.time_scale ===

func _input(event: InputEvent) -> void:
	if not menu_fade_container.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = _get_local_mouse()
		for entry in slot_data:
			if Geometry2D.is_point_in_polygon(local_mouse, entry.poly):
				get_viewport().set_input_as_handled()
				select_equip(entry.idx)
				return

func _process(_delta: float) -> void:
	var real_delta = _get_real_delta()

	if not is_held:
		slow_bank = min(slow_bank + recharge_rate * real_delta, max_slow_bank)

	if is_held and menu_fade_container.visible:
		_update_hover()

# Maps the mouse position into Background's local space,
# where the CollisionPolygon2D vertices are defined.
# get_local_mouse_position() handles anchors and canvas transforms correctly —
# background.global_position is unreliable for FULL_RECT anchored Controls.
func _get_local_mouse() -> Vector2:
	return background.get_local_mouse_position()

func _update_hover() -> void:
	var local_mouse = _get_local_mouse()
	var new_hover: Control = null

	for entry in slot_data:
		if Geometry2D.is_point_in_polygon(local_mouse, entry.poly):
			new_hover = entry.slot
			break

	if new_hover == hovered_slot:
		return

	if hovered_slot:
		_on_slot_unhover(hovered_slot)
	if new_hover:
		_on_slot_hover(new_hover)
	hovered_slot = new_hover

# === HOVER ===

func _on_slot_hover(slot: Control) -> void:
	var icon = slot.get_node_or_null("Icon") as TextureRect
	if not icon:
		return

	var tween = _create_ui_tween()
	tween.set_parallel()
	tween.tween_property(icon, "modulate", Color(1.2, 1.2, 1.2), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if pulse_tweens.has(slot) and pulse_tweens[slot]:
		pulse_tweens[slot].kill()

	var pulse = _create_ui_tween()
	pulse.set_loops()
	pulse.tween_property(icon, "modulate:a", 0.85, 0.4).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(icon, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)
	pulse_tweens[slot] = pulse

func _on_slot_unhover(slot: Control) -> void:
	var icon = slot.get_node_or_null("Icon") as TextureRect
	if not icon:
		return

	if pulse_tweens.has(slot) and pulse_tweens[slot]:
		pulse_tweens[slot].kill()
		pulse_tweens.erase(slot)

	var tween = _create_ui_tween()
	tween.set_parallel()
	tween.tween_property(icon, "modulate", Color.WHITE, 0.10).set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.10).set_ease(Tween.EASE_IN)
	icon.modulate.a = 1.0

func select_equip(slot_idx: int) -> void:
	if EquipManager:
		EquipManager.equip_item(slot_idx)
	slow_bank = max_slow_bank
	_close_menu()

# === TIME SYSTEM ===

func _get_real_delta() -> float:
	var now = Time.get_ticks_msec() / 1000.0
	var delta = now - last_real_time
	last_real_time = now
	return delta

func _restore_time() -> void:
	if time_tween:
		time_tween.kill()
	time_tween = _create_ui_tween()
	time_tween.tween_property(Engine, "time_scale", 1.0, close_fade_time * 0.8) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

# === INPUT FROM PLAYER ===

func update_hold_state(held: bool) -> void:
	if held and not is_held:
		is_held = true
		slow_bank = max_slow_bank  # always start with a full bank

		# Kill any restore tween before setting time scale — an ongoing
		# tween targeting 1.0 would override the slow_scale we're about to set.
		if time_tween:
			time_tween.kill()

		if player:
			var player_screen_pos = player.get_global_transform_with_canvas().origin
			var viewport_size = get_viewport().get_visible_rect().size
			background.position = player_screen_pos - (viewport_size / 2)
			background.position.y -= 80

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

# === CLOSE & VISUALS ===

func _close_menu() -> void:
	is_slowing = false
	# Reset hover state immediately so icons don't stay highlighted
	hovered_slot = null
	_reset_slot_visuals()
	_fade_out_menu()
	_fade_out_blur()
	# Only restore time when Tab was released (is_held = false).
	# If equipment was selected while Tab is still held, keep time slowed
	# until the player releases Tab.
	if not is_held:
		_restore_time()

func _reset_slot_visuals() -> void:
	for slot in pulse_tweens:
		if pulse_tweens[slot]:
			pulse_tweens[slot].kill()
	pulse_tweens.clear()

	for entry in slot_data:
		var icon = entry.slot.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.modulate = Color.WHITE
			icon.scale = Vector2.ONE

# Creates a tween that runs at real-time speed regardless of Engine.time_scale.
func _create_ui_tween() -> Tween:
	var t = create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	if Engine.time_scale > 0.0:
		t.set_speed_scale(1.0 / Engine.time_scale)
	return t

func _fade_in_menu() -> void:
	menu_fade_container.visible = true
	menu_fade_container.modulate.a = 0.0
	if menu_tween:
		menu_tween.kill()
	menu_tween = _create_ui_tween()
	menu_tween.tween_property(menu_fade_container, "modulate:a", 1.0, open_fade_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _fade_out_menu() -> void:
	if menu_tween:
		menu_tween.kill()
	menu_tween = _create_ui_tween()
	menu_tween.tween_property(menu_fade_container, "modulate:a", 0.0, close_fade_time) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	menu_tween.tween_callback(func(): menu_fade_container.visible = false)

func _fade_in_blur() -> void:
	if blur_layer:
		blur_layer.visible = true
	if blur_rect:
		blur_rect.visible = true
		blur_rect.material.set_shader_parameter("blur_amount", 0.0)
		if blur_tween:
			blur_tween.kill()
		blur_tween = _create_ui_tween()
		blur_tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", blur_max_amount, open_fade_time) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _fade_out_blur() -> void:
	if blur_tween:
		blur_tween.kill()
	if blur_rect:
		blur_tween = _create_ui_tween()
		blur_tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, close_fade_time) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		blur_tween.tween_callback(func():
			if blur_layer: blur_layer.visible = false
			if blur_rect: blur_rect.visible = false
		)
	else:
		if blur_layer:
			blur_layer.visible = false
