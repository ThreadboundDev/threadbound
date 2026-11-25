@tool
class_name BlueBuildingCutaway
extends Node2D

@export_group("Cutaway Presentation")
@export_range(0.0, 1.0, 0.01) var exterior_inside_alpha := 0.12
@export_range(0.0, 1.0, 0.01) var interior_outside_alpha := 0.18
@export_range(0.05, 1.0, 0.01) var transition_seconds := 0.24
@export var preview_inside := false:
	set(value):
		preview_inside = value
		if Engine.is_editor_hint():
			_apply_visual_state(value, true)

@onready var interior: CanvasItem = $Interior
@onready var exterior: CanvasItem = $Exterior
@onready var interior_warmth: CanvasItem = $InteriorWarmth

var _occupants: Array[Node2D] = []
var _transition_tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_visual_state", preview_inside, true)
		return
	$EntryZone.body_entered.connect(_on_body_entered)
	$EntryZone.body_exited.connect(_on_body_exited)
	_apply_visual_state(false, true)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or body in _occupants:
		return
	_occupants.append(body)
	_apply_visual_state(true)


func _on_body_exited(body: Node2D) -> void:
	_occupants.erase(body)
	if _occupants.is_empty():
		_apply_visual_state(false)


func _apply_visual_state(inside: bool, immediate := false) -> void:
	if not is_node_ready():
		return
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	var exterior_alpha := exterior_inside_alpha if inside else 1.0
	var interior_alpha := 1.0 if inside else interior_outside_alpha
	var warmth_alpha := 0.42 if inside else 0.0
	if immediate:
		_set_item_alpha(exterior_alpha, exterior)
		_set_item_alpha(interior_alpha, interior)
		_set_item_alpha(warmth_alpha, interior_warmth)
		return
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_method(_set_item_alpha.bind(exterior), exterior.modulate.a, exterior_alpha, transition_seconds)
	_transition_tween.tween_method(_set_item_alpha.bind(interior), interior.modulate.a, interior_alpha, transition_seconds)
	_transition_tween.tween_method(_set_item_alpha.bind(interior_warmth), interior_warmth.modulate.a, warmth_alpha, transition_seconds)


func _set_item_alpha(alpha: float, item: CanvasItem) -> void:
	var color := item.modulate
	color.a = alpha
	item.modulate = color
