@tool
extends "res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_model_2d.gd"
## Uses the existing player interaction callbacks and shared lit art stage.
signal interacted(player: Node2D)
@export var villager_name := "Villager"
@export_range(0.2, 2.0, 0.01) var asset_scale := 0.78
@export_range(1.0, 30.0, 0.5) var greeting_seconds := 6.0
@export var model_depth := -0.4
@export var show_workstation := true
var _player: Node2D
var _prompt: Label
var _greeting_left := 0.0
var _registered := false

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group("lakeside_villagers")
	connect("body_entered", _entered_range)
	connect("body_exited", _exited_range)
	_prompt = Label.new()
	_prompt.name = "InteractionPrompt"
	_prompt.position = Vector2(-105, -226)
	_prompt.size = Vector2(210, 46)
	_prompt.z_index = 45
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_color_override("font_color", Color(0.96, 0.90, 0.77))
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.add_theme_font_size_override("font_size", 17)
	_prompt.visible = false
	add_child(_prompt)

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(render_model):
		render_model.scale *= asset_scale
		render_model.position.z = model_depth
		render_model.show_workstation = show_workstation
	if Engine.is_editor_hint() or not is_instance_valid(_player):
		return
	var accessible := _clear_to_player()
	_prompt.visible = accessible
	if accessible:
		if not _registered:
			_player.call("_on_interactable_entered", self)
			_registered = true
		var text := "Greet " + villager_name
		if _greeting_left > 0:
			text = "Back to work"
		InteractionPromptFormatter.apply_interact_prompt(_prompt, text, 26)
	elif _registered:
		_release_player()
	if _greeting_left > 0:
		_greeting_left = maxf(0, _greeting_left - delta)
		if is_instance_valid(render_model):
			render_model.face_player(_player.global_position.x - global_position.x)
		if _greeting_left == 0:
			_end_greeting()

func _entered_range(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("_on_interactable_entered"):
		_player = body

func _exited_range(body: Node2D) -> void:
	if body == _player:
		_release_player()
		_player = null
		_end_greeting()
		_prompt.visible = false

func _clear_to_player() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -64), _player.global_position + Vector2(0, -14), 1)
	if _player is CollisionObject2D:
		query.exclude = [_player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func interact(player: Node2D) -> void:
	if player != _player or not _clear_to_player() or not is_instance_valid(render_model):
		return
	if _greeting_left > 0:
		_end_greeting()
		return
	_greeting_left = greeting_seconds
	render_model.begin_interaction(player.global_position.x - global_position.x)
	interacted.emit(player)

func _end_greeting() -> void:
	_greeting_left = 0
	if is_instance_valid(render_model):
		render_model.end_interaction()

func _release_player() -> void:
	if is_instance_valid(_player) and _player.get("current_selector") == self:
		_player.call("_on_interactable_exited", self)
	_registered = false

func _exit_tree() -> void:
	_release_player()
	super._exit_tree()
