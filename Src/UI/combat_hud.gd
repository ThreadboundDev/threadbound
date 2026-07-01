extends Control
class_name CombatHUD

signal action_points_changed(current: int, maximum: int)
signal health_changed(current: int, maximum: int)
signal momentum_changed(value: float)
signal momentum_stage_changed(stage: int)
signal momentum_state_changed(state: StringName, flow_active: bool)
signal rune_changed(index: int, color: Color, available: bool)

@onready var health_bar: CombatHealthBar = $HUDRoot/HealthBar as CombatHealthBar
@onready var momentum_bar: Control = $HUDRoot/MomentumBar as Control
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

@export var action_point_cooldown_shade := Color(0.08, 0.08, 0.09, 0.58)
@export var momentum_low_color := Color(0.72, 0.78, 0.9, 0.88)
@export var momentum_mid_color := Color.WHITE
@export var momentum_high_color := Color(1.12, 1.06, 0.88, 1.0)
@export var momentum_flow_color := Color(1.22, 1.18, 1.0, 1.0)

var _rune_colors: Array[Color] = []
var _rune_available: Array[bool] = []
var _action_point_cooldown_ratios: Array[float] = []
var _action_point_cooldown_overlay: Control
var _last_momentum_stage := 0
var _momentum_state: StringName = &"Low"
var _momentum_flow_active := false
var _thread_knot_counter_tween: Tween

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
		var previous_count := thread_knot_count
		thread_knot_count = maxi(0, value)
		_sync_thread_knot_counter()
		if thread_knot_count > previous_count:
			_pulse_thread_knot_counter()

func _ready() -> void:
	add_to_group("combat_hud")
	if thread_knot_counter:
		thread_knot_counter.pivot_offset = thread_knot_counter.size * 0.5
	_create_action_point_cooldown_overlay()
	_configure_default_runes()
	_sync_hud_visuals()
	_sync_health()
	_sync_thread_knot_counter()

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
	thread_knot_count = count

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

	_configure_default_runes()
	_rune_colors[index] = color
	_rune_available[index] = available
	_sync_hud_visuals()
	rune_changed.emit(index, color, available)

func _sync_hud_visuals() -> void:
	if not is_node_ready():
		return

	if momentum_bar and momentum_bar.has_method("set_momentum"):
		momentum_bar.call("set_momentum", momentum / 100.0)
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
		thread_knot_label.text = str(thread_knot_count)

func _sync_momentum_state_visuals() -> void:
	if not is_node_ready() or not momentum_bar:
		return

	match _momentum_state:
		&"Flow":
			momentum_bar.modulate = momentum_flow_color
		&"High":
			momentum_bar.modulate = momentum_high_color
		&"Low":
			momentum_bar.modulate = momentum_low_color
		_:
			momentum_bar.modulate = momentum_mid_color

func _pulse_thread_knot_counter() -> void:
	if not is_node_ready() or not thread_knot_counter:
		return

	if _thread_knot_counter_tween:
		_thread_knot_counter_tween.kill()

	thread_knot_counter.scale = Vector2.ONE
	_thread_knot_counter_tween = create_tween()
	_thread_knot_counter_tween.tween_property(thread_knot_counter, "scale", Vector2(1.06, 1.06), 0.06)
	_thread_knot_counter_tween.tween_property(thread_knot_counter, "scale", Vector2.ONE, 0.12)

func _sync_action_point_orbs() -> void:
	for i in action_point_orbs.size():
		var orb := action_point_orbs[i]
		if not orb:
			continue

		orb.visible = i < max_action_points
		var cooldown_driven := _action_point_cooldown_ratios.size() > 0
		var available := false
		if cooldown_driven:
			available = _get_action_point_cooldown_ratio(i) <= 0.0
		else:
			available = i < current_action_points
			available = available and i < _rune_available.size() and _rune_available[i]
		orb.modulate = Color.WHITE if available else Color(0.55, 0.57, 0.62, 0.42)

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

func _configure_default_runes() -> void:
	if _rune_colors.size() == 6 and _rune_available.size() == 6:
		return

	_rune_colors.clear()
	_rune_available.clear()
	for i in 6:
		_rune_colors.append(Color.WHITE)
		_rune_available.append(i < current_action_points)

func _emit_stage_if_changed() -> void:
	var new_stage := get_momentum_stage()
	if new_stage == _last_momentum_stage:
		return

	_last_momentum_stage = new_stage
	momentum_stage_changed.emit(new_stage)
