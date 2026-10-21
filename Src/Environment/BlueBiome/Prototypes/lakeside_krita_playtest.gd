@tool
extends Node2D
## Saved art and 2D gameplay, with independent 3D buildings and editable dressing.
@export_enum("Soft daylight", "Blue dusk") var lighting_preset := 0:
	set(value):
		lighting_preset = value
		if is_node_ready():
			_apply_lighting()
@export var all_cutaways := false:
	set(value):
		all_cutaways = value
		if is_node_ready():
			_apply_cutaways()

var overview := false
var _enemy_spawns: Array[Dictionary] = []
var _wall_spawns: Array[Dictionary] = []
var _status: Label
var _feedback: Label
var _player_spawn_position := Vector2.ZERO
const LANDMARKS := {
	"Shore": Vector2(128, 275),
	"Cave": Vector2(-1000, -610),
	"Tower": Vector2(1472, 1037.955),
	"Boat slip": Vector2(2816, 290),
	"Workshop": Vector2(3824, -1210.605),
	"Fisher house": Vector2(-32, 257.475),
	"Breakable rock": Vector2(-810, 1450),
	"Net mender": Vector2(51, 257.475),
	"Boatwright": Vector2(3978, -1210.605),
	"Eave Runner": Vector2(1440, -664.445),
	"Loom Heron": Vector2(3180, 314.755),
}
const HOUSE_LANDMARK_FLOORS := {
	"Workshop": ^"Geometry/BuildingCollision/WorkshopFloor/Outline",
	"Fisher house": ^"Geometry/BuildingCollision/FisherFloor/Outline",
	"Net mender": ^"Geometry/BuildingCollision/FisherFloor/Outline",
	"Boatwright": ^"Geometry/BuildingCollision/WorkshopFloor/Outline",
}
const LANDMARK_RESIDENTS := {
	"Net mender": ^"Residents/NetMender",
	"Boatwright": ^"Residents/Boatwright",
}

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	# Capture authored instances before _ready adds runtime health bars, lights,
	# AI state and signal connections. Respawns retain each scene override.
	_enemy_spawns.clear()
	_wall_spawns.clear()
	for child: Node in find_children("*", "", true, false):
		var records: Array[Dictionary]
		if child is EnemyBase:
			records = _enemy_spawns
		elif child.has_method("fracture_from_swordfish"):
			records = _wall_spawns
		else:
			continue
		var packed := PackedScene.new()
		if packed.pack(child) == OK:
			records.append({"path": get_path_to(child), "parent": get_path_to(child.get_parent()), "scene": packed, "name": child.name})

func _ready() -> void:
	_player_spawn_position = $Player.global_position
	_apply_lighting()
	_apply_cutaways()
	if not Engine.is_editor_hint():
		_build_controls()
		_bind_hud()
		$Player.call_deferred("_sync_hud")

func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F2:
			respawn_enemies.call_deferred()
		KEY_F1:
			restore_breakable_rocks.call_deferred()
		_:
			return
	get_viewport().set_input_as_handled()

func respawn_enemies() -> void:
	_replace_spawns(_enemy_spawns)
	_feedback.text = "%d enemies restored at their starting positions." % _enemy_spawns.size()

func restore_breakable_rocks() -> void:
	_replace_spawns(_wall_spawns)
	for effect: Node in find_children("BlueRockShatter*", "", true, false):
		effect.queue_free()
	_feedback.text = "Breakable rocks restored · test walls take 1, 2 or 4 swordfish dashes."

func _replace_spawns(records: Array[Dictionary]) -> void:
	for record: Dictionary in records:
		var old := get_node_or_null(record.path)
		if old:
			old.get_parent().remove_child(old)
			old.queue_free()
		var instance: Node = record.scene.instantiate()
		instance.name = record.name
		get_node(record.parent).add_child(instance)
		if instance is Node2D:
			instance.reset_physics_interpolation()

func _bind_hud() -> void:
	var hud := $HUD/CombatHUD
	_status = $HUD/VitalsReadout
	hud.health_changed.connect(func(_current: int, _maximum: int): _update_status())
	hud.action_points_changed.connect(func(_current: int, _maximum: int): _update_status())
	hud.momentum_changed.connect(func(_value: float): _update_status())
	_update_status()

func _update_status() -> void:
	var hud := $HUD/CombatHUD
	_status.text = "HP %d / %d    AP %d / %d    Momentum %d%%" % [hud.current_health, hud.max_health, hud.current_action_points, hud.max_action_points, roundi(hud.momentum)]

func _apply_lighting() -> void:
	$LakesideArtStage.lighting_preset = lighting_preset
	var ambient := get_node_or_null("LakePresentation/LakeAmbient") as CanvasModulate
	if ambient:
		ambient.color = Color(0.44, 0.57, 0.76) if lighting_preset == 1 else Color(0.82, 0.89, 0.97)
	var sun := get_node_or_null("LakePresentation/LakeDaylight") as DirectionalLight2D
	if sun:
		sun.energy = 0.08 if lighting_preset == 1 else 0.20

func _apply_cutaways() -> void:
	for child in $Buildings.get_children():
		child.preview_inside = all_cutaways

func set_overview(value: bool) -> void:
	overview = value
	$Player/Camera2D.enabled = not value
	$OverviewCamera.enabled = value
	if value:
		$OverviewCamera.make_current()
	else:
		$Player/Camera2D.make_current()

func focus_landmark(label: String) -> void:
	for house in get_tree().get_nodes_in_group("lakeside_door_houses"):
		if house.is_player_inside($Player):
			house.leave_house(false)
	$Player.global_position = get_landmark_position(label)
	$Player.velocity = Vector2.ZERO
	$Player.reset_physics_interpolation()
	set_overview(false)
	$Player/Camera2D.reset_smoothing()

func get_landmark_position(label: String) -> Vector2:
	var house := get_landmark_house(label)
	if is_instance_valid(house) and house.use_door_entry:
		return house.outside_destination($Player)
	return get_interior_landmark_position(label)

func get_landmark_house(label: String) -> Node2D:
	if label in ["Fisher house", "Net mender"]:
		return $Buildings/FisherHouse
	if label in ["Workshop", "Boatwright"]:
		return $Buildings/Workshop
	return null

func get_interior_landmark_position(label: String) -> Vector2:
	if label == "Shore":
		return _player_spawn_position
	if not HOUSE_LANDMARK_FLOORS.has(label):
		return LANDMARKS[label]
	# Follow the saved collision and residents when the room is rearranged.
	var floor_shape := get_node(HOUSE_LANDMARK_FLOORS[label]) as CollisionPolygon2D
	var bounds := Rect2(floor_shape.to_global(floor_shape.polygon[0]), Vector2.ZERO)
	for point: Vector2 in floor_shape.polygon:
		bounds = bounds.expand(floor_shape.to_global(point))
	var target_x := bounds.get_center().x
	if LANDMARK_RESIDENTS.has(label):
		target_x = get_node(LANDMARK_RESIDENTS[label]).global_position.x - 60.0
		target_x = clampf(target_x, bounds.position.x + 24.0, bounds.end.x - 24.0)
	var body := $Player/CollisionShape2D as CollisionShape2D
	var foot_offset: float = body.to_global(Vector2(0.0, body.shape.get_rect().end.y)).y - $Player.global_position.y
	# Start slightly above the one-way floor so contact is acquired normally.
	return Vector2(target_x, bounds.position.y - foot_offset - 6.0)

func _button(row: HBoxContainer, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	row.add_child(button)

func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PlaytestControls"
	layer.layer = 30
	add_child(layer)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 12
	panel.offset_right = -12
	panel.offset_top = -122
	panel.offset_bottom = -12
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	_button(row, "Overview / play", func(): set_overview(not overview))
	_button(row, "Day / dusk", func(): lighting_preset = 1 - lighting_preset)
	_button(row, "Cutaways", func(): all_cutaways = not all_cutaways)
	_button(row, "Collision", func(): get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint)
	for label: String in LANDMARKS:
		_button(row, label, focus_landmark.bind(label))
	var debug_row := HBoxContainer.new()
	column.add_child(debug_row)
	_button(debug_row, "Respawn enemies [F2]", respawn_enemies)
	_button(debug_row, "Restore rocks [F1]", restore_breakable_rocks)
	_feedback = Label.new()
	_feedback.text = "Enemies return at full health; the player and map stay in place."
	debug_row.add_child(_feedback)
	var hint := Label.new()
	hint.text = "Krita map · 1 px = 1 game unit · normal movement / swimming controls"
	column.add_child(hint)
