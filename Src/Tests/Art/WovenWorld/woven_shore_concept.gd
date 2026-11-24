extends Node2D

const CONTACT_SHADOW := preload("res://Src/Tests/Art/WovenWorld/woven_contact_shadow.gd")
const OUTLINE := preload("res://Src/Tests/Art/WovenWorld/woven_outline_comparison.gd")
const HANDOFF := preload("res://Src/Tests/Art/WovenWorld/woven_concept_handoff.gd")
const IRRIGATION_OPEN := &"woven_concept_irrigation_open"
const INTAKE_OPEN := &"woven_concept_intake_open"

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
var outline: RefCounted


func _ready() -> void:
	outline = OUTLINE.new()
	outline.initialize(player.live_3d_visual)
	var shadow := CONTACT_SHADOW.new()
	shadow.target = player
	for surface in $Terrain.get_children():
		if not surface.has_meta(&"standing_span"):
			continue
		var span: Vector3 = surface.get_meta(&"standing_span")
		shadow.receivers.append({"id": surface.name, "left": span.x, "right": span.y, "y": span.z})
	add_child(shadow)
	$Interactions/IrrigationLatch.activated.connect(_open_irrigation)
	$Interactions/IntakeLatch.activated.connect(_open_intake)
	if get_tree().has_meta(IRRIGATION_OPEN):
		_open_irrigation()
	if get_tree().has_meta(INTAKE_OPEN):
		_open_intake()
	var arrival: StringName = get_tree().get_meta(HANDOFF.ARRIVAL, &"Chamber")
	get_tree().remove_meta(HANDOFF.ARRIVAL)
	var marker := $Arrivals.get_node_or_null(NodePath(arrival)) as Marker2D
	if marker:
		player.position = marker.position
		player.reset_physics_interpolation()
	_follow_player()
	camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		_follow_player()


func _follow_player() -> void:
	# Keep the arrival shot low. The upper shelf enters view on the return climb.
	var entry_framing := player.position.x < 825.0 and player.position.y > 860.0
	camera.position = player.position + Vector2(0, 66 if entry_framing else -54)


func _open_irrigation() -> void:
	get_tree().set_meta(IRRIGATION_OPEN, true)
	$Art/IrrigationLatch.hide()
	$Terrain/IrrigationBarrier/Shape.set_deferred(&"disabled", true)
	$Interactions/IrrigationLatch.available = false


func _open_intake() -> void:
	get_tree().set_meta(INTAKE_OPEN, true)
	$Art/AqueductGrate.hide()
	$Terrain/IntakeBarrier/Shape.set_deferred(&"disabled", true)
	$Interactions/IntakeLatch.available = false
