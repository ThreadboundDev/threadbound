@tool
extends Area2D
## Adapter for the existing player's interaction action and prompt formatter.
var _player: CharacterBody2D
var _registered := false
var _prompt: Label

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_prompt = Label.new()
	_prompt.name = "DoorPrompt"
	_prompt.position = Vector2(-110, -190)
	_prompt.size = Vector2(220, 42)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.z_index = 45
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_color_override("font_color", Color(0.96, 0.90, 0.77))
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.add_theme_font_size_override("font_size", 17)
	_prompt.visible = false
	add_child(_prompt)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var house := get_parent()
	if not house.use_door_entry:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(_player):
		return
	var available: bool = house.can_use_door(_player)
	_prompt.visible = available
	if available:
		if _player.current_selector != self:
			_player.call("_on_interactable_entered", self)
		_registered = true
		InteractionPromptFormatter.apply_interact_prompt(_prompt, "Exit" if house.is_player_inside(_player) else "Enter", 26)
	else:
		_release()

func interact(player: Node2D) -> void:
	if player == _player and get_parent().can_use_door(_player):
		get_parent().request_door(_player)

func _release() -> void:
	if is_instance_valid(_player) and _player.get("current_selector") == self:
		_player.call("_on_interactable_exited", self)
	_registered = false

func _exit_tree() -> void:
	_release()
