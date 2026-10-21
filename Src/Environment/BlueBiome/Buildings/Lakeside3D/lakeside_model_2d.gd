@tool
extends Node2D
## Place at the model's bottom-center in 2D; the shared art stage owns rendering.
@export var model_scene: PackedScene
@export var entry_rect := Rect2():
	set(value):
		entry_rect = value
		if is_node_ready():
			_update_entry()
@export var preview_inside := false:
	set(value):
		preview_inside = value
		_update_cutaway()

var render_model: Node3D
var stage: Node2D
var entry_area: Area2D
var occupants: Array[Node2D] = []

func _ready() -> void:
	add_to_group("lakeside_model_2d")
	_update_entry()
	call_deferred("_register")

func _register() -> void:
	for candidate in get_tree().get_nodes_in_group("lakeside_3d_stage"):
		if candidate.get_viewport() == get_viewport():
			stage = candidate
			stage.register_placement(self)
			return
	if not Engine.is_editor_hint():
		push_warning("Add lakeside_art_stage_2d.tscn to render " + str(name))

func _update_entry() -> void:
	if is_instance_valid(entry_area):
		remove_child(entry_area)
		entry_area.queue_free()
		entry_area = null
	if entry_rect.size.x <= 0.0 or entry_rect.size.y <= 0.0:
		return
	entry_area = Area2D.new()
	entry_area.name = "CutawayEntry"
	entry_area.collision_layer = 0
	# The player's body is on layer 1; layer 2 is its separate damage hurtbox.
	entry_area.collision_mask = 1
	entry_area.monitorable = false
	add_child(entry_area)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = entry_rect.size
	shape.shape = rectangle
	shape.position = entry_rect.get_center()
	entry_area.add_child(shape)
	if not Engine.is_editor_hint():
		entry_area.body_entered.connect(_entered)
		entry_area.body_exited.connect(_exited)

func _entered(body: Node2D) -> void:
	if body.is_in_group("player") and body not in occupants:
		occupants.append(body)
		_update_cutaway()

func _exited(body: Node2D) -> void:
	occupants.erase(body)
	_update_cutaway()

func _update_cutaway() -> void:
	if is_instance_valid(render_model) and render_model.has_method("set_cutaway"):
		render_model.set_cutaway(preview_inside or not occupants.is_empty())

func _process(_delta: float) -> void:
	if not is_instance_valid(render_model):
		return
	render_model.visible = is_visible_in_tree()
	render_model.position = Vector3(global_position.x / 128.0, -global_position.y / 128.0, 0.0)
	render_model.rotation.z = -global_rotation
	render_model.scale = Vector3(global_scale.x, global_scale.y, global_scale.x)

func _exit_tree() -> void:
	if is_instance_valid(render_model):
		render_model.queue_free()
