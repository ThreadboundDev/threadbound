extends Control
class_name CombatHUD

signal action_points_changed(current: int, maximum: int)
signal health_changed(current: int, maximum: int)
signal momentum_changed(value: float)
signal momentum_stage_changed(stage: int)
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

var _rune_colors: Array[Color] = []
var _rune_available: Array[bool] = []
var _last_momentum_stage := 0

@export var max_health := 5:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		_sync_health()
		health_changed.emit(current_health, max_health)

@export var current_health := 5:
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

func _sync_action_point_orbs() -> void:
	for i in action_point_orbs.size():
		var orb := action_point_orbs[i]
		if not orb:
			continue

		orb.visible = i < max_action_points
		var available := i < current_action_points and i < _rune_available.size() and _rune_available[i]
		orb.modulate = Color.WHITE if available else Color(0.55, 0.57, 0.62, 0.42)

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
