extends Control
class_name CombatHUD

signal action_points_changed(current: int, maximum: int)
signal health_changed(current: int, maximum: int)
signal momentum_changed(value: float)
signal momentum_stage_changed(stage: int)
signal momentum_state_changed(state: StringName, flow_active: bool)
signal rune_changed(index: int, color: Color, available: bool)
signal identity_visual_changed(identity_color: Color, pattern_visible: bool)

const ACTION_POINT_RED := &"red"
const ACTION_POINT_BLUE := &"blue"
const ACTION_POINT_YELLOW := &"yellow"
const ACTION_POINT_COLORLESS := &"colorless"
const VALID_ACTION_POINT_TYPES := [
	ACTION_POINT_RED,
	ACTION_POINT_BLUE,
	ACTION_POINT_YELLOW,
	ACTION_POINT_COLORLESS,
]

@onready var health_bar: CombatHealthBar = $HUDRoot/HealthBar as CombatHealthBar
@onready var momentum_bar: CombatMomentumBar = $HUDRoot/MomentumBar as CombatMomentumBar
@onready var identity_base: TextureRect = $HUDRoot/IdentityLayers/IdentityBase as TextureRect
@onready var pattern_overlay: TextureRect = $HUDRoot/IdentityLayers/PatternOverlay as TextureRect
@onready var action_point_orbs: Array[TextureRect] = [
	$HUDRoot/ActionPointOrbs/ActionPointOrb1 as TextureRect,
	$HUDRoot/ActionPointOrbs/ActionPointOrb2 as TextureRect,
	$HUDRoot/ActionPointOrbs/ActionPointOrb3 as TextureRect,
	$HUDRoot/ActionPointOrbs/ActionPointOrb4 as TextureRect,
	$HUDRoot/ActionPointOrbs/ActionPointOrb5 as TextureRect,
	$HUDRoot/ActionPointOrbs/ActionPointOrb6 as TextureRect,
]
@onready var thread_knot_label: Label = $ThreadKnotCounter/CountLabel as Label
@onready var thread_knot_counter: Control = $ThreadKnotCounter as Control
@onready var lore_pickup: Control = $LorePickup as Control
@onready var lore_pickup_kind: Label = $LorePickup/Kind as Label
@onready var lore_pickup_title: Label = $LorePickup/Title as Label
@onready var trial_timer: Control = $TrialTimer as Control
@onready var trial_timer_label: Label = $TrialTimer/Label as Label

@export_group("Identity and Pattern")
@export var default_identity_color := Color(0.72, 0.73, 0.72, 1.0)

@export_group("Action Points")
@export var action_point_red_texture: Texture2D
@export var action_point_blue_texture: Texture2D
@export var action_point_yellow_texture: Texture2D
@export var action_point_colorless_texture: Texture2D
@export var action_point_cooldown_shade := Color(0.04, 0.035, 0.035, 0.7)

@export_group("Thread Knots")
@export var thread_knot_visible_seconds := 3.5
@export var thread_knot_fade_seconds := 0.4

var _rune_colors: Array[Color] = []
var _rune_available: Array[bool] = []
var _action_point_types: Array[StringName] = []
var _action_point_cooldown_ratios: Array[float] = []
var _action_point_cooldown_overlay: Control
var _last_momentum_stage := 0
var _momentum_state: StringName = &"Low"
var _momentum_flow_active := false
var _thread_knot_counter_tween: Tween
var _thread_knot_reveal_armed := false
var _lore_pickup_tween: Tween
var _lore_pickup_resting_position := Vector2.ZERO

@export var max_health := 100:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		_sync_health()
		health_changed.emit(current_health, max_health)

@export var current_health := 100:
	set(value):
		current_health = clampi(value, 0, max_health)
		_sync_health()
		health_changed.emit(current_health, max_health)

@export_range(1, 6, 1) var max_action_points := 6:
	set(value):
		max_action_points = clampi(value, 1, 6)
		current_action_points = clampi(current_action_points, 0, max_action_points)
		_sync_hud_visuals()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0, 6, 1) var current_action_points := 6:
	set(value):
		current_action_points = clampi(value, 0, max_action_points)
		_sync_hud_visuals()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0.0, 100.0, 1.0) var momentum := 0.0:
	set(value):
		var previous_stage := get_momentum_stage()
		momentum = clampf(value, 0.0, 100.0)
		_sync_hud_visuals()
		momentum_changed.emit(momentum)
		var new_stage := get_momentum_stage()
		if new_stage != previous_stage:
			_last_momentum_stage = new_stage
			momentum_stage_changed.emit(new_stage)

@export var momentum_stage_thresholds := PackedFloat32Array([25.0, 50.0, 75.0, 100.0]):
	set(value):
		momentum_stage_thresholds = value
		_emit_stage_if_changed()

@export var thread_knot_count := 0:
	set(value):
		thread_knot_count = maxi(0, value)
		_sync_thread_knot_counter()

func _ready() -> void:
	add_to_group("combat_hud")
	if thread_knot_counter:
		thread_knot_counter.pivot_offset = thread_knot_counter.size * 0.5
		thread_knot_counter.visible = false
		thread_knot_counter.modulate.a = 0.0
	if lore_pickup:
		lore_pickup.visible = false
		_lore_pickup_resting_position = lore_pickup.position
	if trial_timer:
		trial_timer.visible = false
	if not DemoProgress.lore_unlocked.is_connected(_on_lore_unlocked):
		DemoProgress.lore_unlocked.connect(_on_lore_unlocked)
	if identity_base:
		_sync_identity_pattern_palette()
	_create_action_point_cooldown_overlay()
	_configure_default_action_points()
	_sync_hud_visuals()
	_sync_health()
	_sync_thread_knot_counter()
	call_deferred("_arm_thread_knot_reveal")
	call_deferred("_show_starting_lore_hint")

func set_health(current: int, maximum: int = max_health) -> void:
	max_health = maximum
	current_health = current

func set_action_points(current: int, maximum: int = max_action_points) -> void:
	max_action_points = maximum
	current_action_points = current
	for i in _rune_available.size():
		_rune_available[i] = i < current_action_points
	_sync_hud_visuals()

func set_action_point_cooldowns(cooldown_ratios: Array[float]) -> void:
	_action_point_cooldown_ratios = cooldown_ratios.duplicate()
	_sync_hud_visuals()
	if _action_point_cooldown_overlay:
		_action_point_cooldown_overlay.queue_redraw()

func spend_action_points(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_action_points < amount:
		return false

	current_action_points -= amount
	return true

func restore_action_points(amount: int) -> void:
	current_action_points += max(0, amount)

func refill_action_points() -> void:
	current_action_points = max_action_points

func set_momentum(value: float) -> void:
	momentum = value

func set_momentum_state(state: StringName, flow_active: bool) -> void:
	if _momentum_state == state and _momentum_flow_active == flow_active:
		return

	_momentum_state = state
	_momentum_flow_active = flow_active
	_sync_momentum_state_visuals()
	momentum_state_changed.emit(_momentum_state, _momentum_flow_active)

func set_thread_knots(count: int) -> void:
	var previous_count := thread_knot_count
	thread_knot_count = count
	if _thread_knot_reveal_armed and thread_knot_count > previous_count:
		_reveal_thread_knot_counter()

func show_lore_pickup(title: String, kind := "LORE ADDED") -> void:
	if not lore_pickup:
		return
	if _lore_pickup_tween:
		_lore_pickup_tween.kill()
	lore_pickup_kind.text = kind.to_upper()
	lore_pickup_title.text = title.to_upper()
	lore_pickup.visible = true
	lore_pickup.modulate.a = 0.0
	lore_pickup.position = _lore_pickup_resting_position + Vector2(32.0, 0.0)
	_lore_pickup_tween = create_tween()
	_lore_pickup_tween.set_parallel(true)
	_lore_pickup_tween.tween_property(lore_pickup, "modulate:a", 1.0, 0.16)
	_lore_pickup_tween.tween_property(lore_pickup, "position", _lore_pickup_resting_position, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_lore_pickup_tween.set_parallel(false)
	_lore_pickup_tween.tween_interval(3.5)
	_lore_pickup_tween.tween_property(lore_pickup, "modulate:a", 0.0, 0.3)
	_lore_pickup_tween.tween_callback(func() -> void: lore_pickup.visible = false)

func show_thread_reward(title: String) -> void:
	show_lore_pickup(title, "A NEW THREAD ANSWERS")

func set_trial_timer(seconds_remaining: float, active: bool) -> void:
	if not trial_timer:
		return
	trial_timer.visible = active
	if active:
		var total_seconds := maxi(0, ceili(seconds_remaining))
		trial_timer_label.text = "TRIAL OF BALANCE   %02d:%02d" % [total_seconds / 60, total_seconds % 60]

func _on_lore_unlocked(lore_id: StringName) -> void:
	var lore_input := InteractionPromptFormatter.get_action_display(&"open_lore", "L")
	show_lore_pickup(LoreCatalog.get_title(lore_id), "LORE ADDED  •  %s TO VIEW" % lore_input)

func _show_starting_lore_hint() -> void:
	if (
		not DemoProgress.has_lore(&"threadbound")
		or DemoProgress.is_lore_read(&"threadbound")
		or DemoProgress.has_completed_world_event(&"tutorial.starting_lore_notified")
	):
		return
	DemoProgress.complete_world_event(&"tutorial.starting_lore_notified")
	_on_lore_unlocked(&"threadbound")

func set_identity_color(color: Color) -> void:
	default_identity_color = color
	_sync_identity_pattern_palette()
	identity_visual_changed.emit(color, pattern_overlay.visible if pattern_overlay else false)

func set_pattern_texture(texture: Texture2D, show_pattern := true) -> void:
	if not pattern_overlay:
		return
	pattern_overlay.texture = texture
	pattern_overlay.visible = show_pattern and texture != null
	_sync_identity_pattern_palette()
	identity_visual_changed.emit(default_identity_color, pattern_overlay.visible)

func set_pattern_visible(show_pattern: bool) -> void:
	if not pattern_overlay:
		return
	pattern_overlay.visible = show_pattern and pattern_overlay.texture != null
	_sync_identity_pattern_palette()
	identity_visual_changed.emit(default_identity_color, pattern_overlay.visible)

func _sync_identity_pattern_palette() -> void:
	if identity_base:
		identity_base.modulate = default_identity_color

func set_action_point_type(index: int, point_type: StringName, available := true) -> void:
	if index < 0 or index >= 6:
		push_warning("CombatHUD.set_action_point_type index must be between 0 and 5.")
		return
	if point_type not in VALID_ACTION_POINT_TYPES:
		push_warning("CombatHUD.set_action_point_type received unknown type: %s" % point_type)
		point_type = ACTION_POINT_COLORLESS

	_configure_default_action_points()
	_action_point_types[index] = point_type
	_rune_available[index] = available
	_sync_hud_visuals()

func get_action_point_type(index: int) -> StringName:
	_configure_default_action_points()
	if index < 0 or index >= _action_point_types.size():
		return ACTION_POINT_COLORLESS
	return _action_point_types[index]

func get_momentum_stage() -> int:
	var clamped_momentum := clampf(momentum, 0.0, 100.0)
	for i in momentum_stage_thresholds.size():
		if clamped_momentum < momentum_stage_thresholds[i]:
			return i

	return momentum_stage_thresholds.size()

func set_rune(index: int, color: Color, available: bool) -> void:
	if index < 0 or index >= 6:
		push_warning("CombatHUD.set_rune index must be between 0 and 5.")
		return

	_configure_default_action_points()
	_rune_colors[index] = color
	_rune_available[index] = available
	_action_point_types[index] = _action_point_type_from_color(color)
	_sync_hud_visuals()
	rune_changed.emit(index, color, available)

func _sync_hud_visuals() -> void:
	if not is_node_ready():
		return

	if momentum_bar:
		momentum_bar.set_momentum(momentum / 100.0)
	_sync_momentum_state_visuals()
	_sync_action_point_orbs()

func _sync_health() -> void:
	if not is_node_ready():
		return

	if health_bar:
		health_bar.set_health(current_health, max_health)

func _sync_thread_knot_counter() -> void:
	if not is_node_ready():
		return

	if thread_knot_label:
		thread_knot_label.text = "× " + _format_thread_knot_count(thread_knot_count)

func _sync_momentum_state_visuals() -> void:
	if not is_node_ready() or not momentum_bar:
		return

	momentum_bar.set_momentum_state(_momentum_state, _momentum_flow_active)

func _reveal_thread_knot_counter() -> void:
	if not is_node_ready() or not thread_knot_counter:
		return

	if _thread_knot_counter_tween:
		_thread_knot_counter_tween.kill()

	thread_knot_counter.visible = true
	thread_knot_counter.modulate.a = 1.0
	thread_knot_counter.scale = Vector2.ONE
	_thread_knot_counter_tween = create_tween()
	_thread_knot_counter_tween.tween_property(thread_knot_counter, "scale", Vector2(1.045, 1.045), 0.06)
	_thread_knot_counter_tween.tween_property(thread_knot_counter, "scale", Vector2.ONE, 0.12)
	_thread_knot_counter_tween.tween_interval(thread_knot_visible_seconds)
	_thread_knot_counter_tween.tween_property(thread_knot_counter, "modulate:a", 0.0, thread_knot_fade_seconds)
	_thread_knot_counter_tween.tween_callback(func() -> void:
		if thread_knot_counter:
			thread_knot_counter.visible = false
	)

func _sync_action_point_orbs() -> void:
	_configure_default_action_points()
	for i in action_point_orbs.size():
		var orb := action_point_orbs[i]
		if not orb:
			continue

		orb.visible = i < max_action_points
		orb.texture = _get_action_point_texture(_action_point_types[i])
		var cooldown_driven := _action_point_cooldown_ratios.size() > 0
		var available := false
		if cooldown_driven:
			available = _get_action_point_cooldown_ratio(i) <= 0.0
		else:
			available = i < current_action_points
			available = available and _rune_available[i]
		orb.modulate = Color.WHITE if available else Color(0.45, 0.46, 0.47, 0.38)

func _create_action_point_cooldown_overlay() -> void:
	if action_point_orbs.is_empty() or not action_point_orbs[0]:
		return

	var orb_parent := action_point_orbs[0].get_parent() as Control
	if not orb_parent:
		return

	_action_point_cooldown_overlay = Control.new()
	_action_point_cooldown_overlay.name = "ActionPointCooldownOverlay"
	_action_point_cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_point_cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_action_point_cooldown_overlay.draw.connect(_draw_action_point_cooldown_overlay)
	orb_parent.add_child(_action_point_cooldown_overlay)

func _draw_action_point_cooldown_overlay() -> void:
	if not _action_point_cooldown_overlay:
		return

	for i in action_point_orbs.size():
		var orb := action_point_orbs[i]
		var ratio := _get_action_point_cooldown_ratio(i)
		if not orb or not orb.visible or ratio <= 0.0:
			continue

		var rect := Rect2(orb.position, orb.size)
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.48
		var points := PackedVector2Array()
		points.append(center)
		var segment_count := maxi(4, ceili(40.0 * ratio))
		for step in range(segment_count + 1):
			var angle := -PI * 0.5 + TAU * ratio * (float(step) / float(segment_count))
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)

		_action_point_cooldown_overlay.draw_colored_polygon(points, action_point_cooldown_shade)

func _get_action_point_cooldown_ratio(index: int) -> float:
	if index < 0 or index >= _action_point_cooldown_ratios.size():
		return 0.0
	return clampf(_action_point_cooldown_ratios[index], 0.0, 1.0)

func _configure_default_action_points() -> void:
	if (
		_rune_colors.size() == 6
		and _rune_available.size() == 6
		and _action_point_types.size() == 6
	):
		return

	_rune_colors.clear()
	_rune_available.clear()
	_action_point_types = [
		ACTION_POINT_COLORLESS,
		ACTION_POINT_COLORLESS,
		ACTION_POINT_COLORLESS,
		ACTION_POINT_COLORLESS,
		ACTION_POINT_COLORLESS,
		ACTION_POINT_COLORLESS,
	]
	for i in 6:
		_rune_colors.append(Color.WHITE)
		_rune_available.append(i < current_action_points)

func _get_action_point_texture(point_type: StringName) -> Texture2D:
	match point_type:
		ACTION_POINT_RED:
			return action_point_red_texture
		ACTION_POINT_BLUE:
			return action_point_blue_texture
		ACTION_POINT_YELLOW:
			return action_point_yellow_texture
		_:
			return action_point_colorless_texture

func _action_point_type_from_color(color: Color) -> StringName:
	if color.s < 0.18:
		return ACTION_POINT_COLORLESS
	if color.r > color.b * 1.15 and color.g > color.b * 1.15:
		return ACTION_POINT_YELLOW
	if color.b > color.r and color.b > color.g:
		return ACTION_POINT_BLUE
	return ACTION_POINT_RED

func _format_thread_knot_count(count: int) -> String:
	var digits := str(maxi(0, count))
	var formatted := ""
	while digits.length() > 3:
		formatted = "," + digits.substr(digits.length() - 3) + formatted
		digits = digits.substr(0, digits.length() - 3)
	return digits + formatted

func _arm_thread_knot_reveal() -> void:
	_thread_knot_reveal_armed = true

func _emit_stage_if_changed() -> void:
	var new_stage := get_momentum_stage()
	if new_stage == _last_momentum_stage:
		return

	_last_momentum_stage = new_stage
	momentum_stage_changed.emit(new_stage)
