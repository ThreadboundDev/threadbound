extends CanvasLayer

# Slot Controls
@onready var monarch_gloves_slot: Control = $MenuFadeContainer/Background/MonarchGlovesButton
@onready var hermit_gloves_slot: Control = $MenuFadeContainer/Background/HermitGlovesButton
@onready var sage_gloves_slot: Control = $MenuFadeContainer/Background/SageGlovesButton

@onready var menu_fade_container: Control = $MenuFadeContainer
@onready var background: Control = $MenuFadeContainer/Background
@onready var empty_message: Label = $MenuFadeContainer/Background/EmptyMessage
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
var slot_data: Array = []  # [{slot: Control, idx: int}]
var hovered_slot: Control = null
var controller_hover_active := false
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

	_refresh_unlocked_slots()
	if DemoProgress and not DemoProgress.threads_changed.is_connected(_refresh_unlocked_slots):
		DemoProgress.threads_changed.connect(_refresh_unlocked_slots)
	if EquipManager and not EquipManager.equip_changed.is_connected(_on_equip_changed):
		EquipManager.equip_changed.connect(_on_equip_changed)

func _refresh_unlocked_slots() -> void:
	slot_data.clear()
	_configure_slot(hermit_gloves_slot, EquipManager.BLUE_GLOVES_SLOT)
	_configure_slot(monarch_gloves_slot, EquipManager.RED_GLOVES_SLOT)
	_configure_slot(sage_gloves_slot, EquipManager.YELLOW_GLOVES_SLOT)
	empty_message.visible = slot_data.is_empty()
	_refresh_selected_slot()

func _configure_slot(slot: Control, slot_idx: int) -> void:
	var unlocked := EquipManager.is_slot_unlocked(slot_idx)
	slot.visible = unlocked
	if unlocked:
		_connect_slot(slot, slot_idx)

func _connect_slot(slot: Control, slot_idx: int) -> void:
	if slot == null:
		push_warning("RadialMenu: slot is null for index %d" % slot_idx)
		return

	var icon = slot.get_node_or_null("Icon") as TextureRect
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = icon.size / 2.0
	slot_data.append({"slot": slot, "idx": slot_idx})

# === INPUT — runs every frame, unaffected by Engine.time_scale ===

func _input(event: InputEvent) -> void:
	if not menu_fade_container.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var entry := _get_slot_entry_at(event.position)
		if not entry.is_empty():
			get_viewport().set_input_as_handled()
			select_equip(int(entry["idx"]))
			return
	if event is InputEventJoypadButton and event.is_action_pressed("ui_accept") and hovered_slot:
		var hovered_entry := _get_entry_for_slot(hovered_slot)
		if not hovered_entry.is_empty():
			get_viewport().set_input_as_handled()
			select_equip(int(hovered_entry["idx"]))

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
func _update_hover() -> void:
	var new_hover: Control = null
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var entry: Dictionary = {}
	if aim.length() >= 0.35:
		controller_hover_active = true
		entry = _get_slot_entry_in_direction(aim.normalized())
	elif controller_hover_active:
		return
	else:
		entry = _get_slot_entry_at(get_viewport().get_mouse_position())
	if not entry.is_empty():
		new_hover = entry["slot"] as Control

	if new_hover == hovered_slot:
		return

	if hovered_slot:
		_on_slot_unhover(hovered_slot)
	if new_hover:
		AudioManager.play_ui(&"ui_click")
		_on_slot_hover(new_hover)
	hovered_slot = new_hover

func _get_slot_entry_at(mouse_position: Vector2) -> Dictionary:
	for entry in slot_data:
		var slot := entry["slot"] as Control
		if slot.visible and slot.get_global_rect().has_point(mouse_position):
			return entry
	return {}

func _get_slot_entry_in_direction(direction: Vector2) -> Dictionary:
	var center := background.get_global_rect().get_center()
	var best_entry: Dictionary = {}
	var best_dot := -2.0
	for entry in slot_data:
		var slot := entry["slot"] as Control
		if not slot.visible:
			continue
		var slot_direction := (slot.get_global_rect().get_center() - center).normalized()
		var alignment := slot_direction.dot(direction)
		if alignment > best_dot:
			best_dot = alignment
			best_entry = entry
	return best_entry

func _get_entry_for_slot(target: Control) -> Dictionary:
	for entry in slot_data:
		if entry["slot"] == target:
			return entry
	return {}

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
	if not EquipManager.is_slot_unlocked(slot_idx):
		return
	AudioManager.play_ui(&"menu_select")
	if EquipManager:
		EquipManager.equip_item(slot_idx)
	slow_bank = max_slow_bank
	_close_menu()

func _on_equip_changed(_slot_type: int, _slot_idx: int) -> void:
	_refresh_selected_slot()

func _refresh_selected_slot() -> void:
	for entry in slot_data:
		var slot := entry["slot"] as Control
		var panel := slot.get_node_or_null("Panel") as Panel
		if panel:
			panel.modulate = Color(1.22, 1.14, 0.72, 1.0) if int(entry["idx"]) == EquipManager.current_equip[0] else Color.WHITE

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
		controller_hover_active = false
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
		if controller_hover_active and hovered_slot:
			var hovered_entry := _get_entry_for_slot(hovered_slot)
			if not hovered_entry.is_empty():
				select_equip(int(hovered_entry["idx"]))
				return
		_close_menu()

# === CLOSE & VISUALS ===

func _close_menu() -> void:
	is_slowing = false
	# Reset hover state immediately so icons don't stay highlighted
	hovered_slot = null
	controller_hover_active = false
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
