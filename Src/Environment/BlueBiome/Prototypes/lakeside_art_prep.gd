@tool
extends Node2D
## Disposable art/lighting test. Final terrain, water and routes await the map.
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

func _ready() -> void:
	_apply_lighting()
	_apply_cutaways()
	if not Engine.is_editor_hint():
		_build_controls()

func _apply_lighting() -> void:
	$LakesideArtStage.lighting_preset = lighting_preset
	$ActorAmbient.color = Color(0.44, 0.57, 0.76) if lighting_preset == 1 else Color(0.85, 0.91, 0.98)
	$ActorDaylight.energy = 0.08 if lighting_preset == 1 else 0.20

func _apply_cutaways() -> void:
	for child in $Buildings.get_children():
		if child.has_method("_update_cutaway"):
			child.preview_inside = all_cutaways

func focus_building(index: int) -> void:
	var xs := [-1400.0, 0.0, 1152.0, 2560.0]
	$Player.position = Vector2(xs[clampi(index, 0, 3)], -69.245)
	$Player.velocity = Vector2.ZERO
	set_overview(false)
	$Player/Camera2D.reset_smoothing()

func set_overview(enabled: bool) -> void:
	overview = enabled
	$Player/Camera2D.enabled = not enabled
	$OverviewCamera.enabled = enabled
	if enabled:
		$OverviewCamera.make_current()
	else:
		$Player/Camera2D.make_current()

func _button(row: HBoxContainer, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	row.add_child(button)

func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ArtReviewControls"
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "LAKESIDE ART TEST  ·  128 px/unit  ·  temporary floor, awaiting Krita layout"
	column.add_child(title)
	var row := HBoxContainer.new()
	column.add_child(row)
	_button(row, "Daylight", func(): lighting_preset = 0)
	_button(row, "Dusk", func(): lighting_preset = 1)
	_button(row, "All cutaways", func(): all_cutaways = true)
	_button(row, "Entry cutaways", func(): all_cutaways = false)
	_button(row, "Overview", func(): set_overview(not overview))
	for i in 4:
		_button(row, ["Boat slip", "Workshop", "Fisher house", "Tower"][i], focus_building.bind(i))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and $Player.position.y > 650:
		focus_building(1)
