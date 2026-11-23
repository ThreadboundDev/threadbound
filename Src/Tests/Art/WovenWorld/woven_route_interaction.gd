extends Area2D

@export var action_text := "Enter"
@export_file("*.tscn") var destination: String
@export var required_sluices := 0
@export var requires_water := false
@export var return_anchor: StringName

signal sluice_opened

const GATE_COLOR := Color(0.5, 0.7, 0.78)

var opened := false
var sluices_open := 0
var changing_scene := false

@onready var prompt: Label = $Prompt


func _ready() -> void:
	add_to_group("interaction_prompt_owners")
	refresh_interaction_prompt()
	_update_indicators()


func _process(_delta: float) -> void:
	prompt.visible = _nearby_player() != null


func _unhandled_input(event: InputEvent) -> void:
	if changing_scene or not event.is_action_pressed(&"interact") or event.is_echo():
		return
	var actor := _nearby_player()
	if not actor:
		return
	get_viewport().set_input_as_handled()
	if destination.is_empty():
		open_sluice()
		return
	if sluices_open < required_sluices:
		return
	changing_scene = true
	if return_anchor != &"":
		get_tree().set_meta(&"woven_shore_return", {
			"anchor": return_anchor,
			"sluices": get_tree().current_scene.get_sluice_state(),
		})
	var error := get_tree().change_scene_to_file(destination)
	if error != OK:
		changing_scene = false
		if return_anchor != &"":
			get_tree().remove_meta(&"woven_shore_return")
		push_error("Could not enter %s (error %d)" % [destination, error])


func _nearby_player() -> Node2D:
	for body in get_overlapping_bodies():
		if body.is_in_group(&"player") and not body.is_dead:
			if not requires_water or body.is_in_prototype_water():
				return body
	return null


func register_sluice() -> void:
	sluices_open += 1
	_update_indicators()
	refresh_interaction_prompt()


func open_sluice() -> void:
	if opened:
		return
	opened = true
	sluice_opened.emit()
	_update_indicators()
	refresh_interaction_prompt()


func _update_indicators() -> void:
	var latch := get_node_or_null("Latch") as CanvasItem
	if latch:
		latch.visible = sluices_open < required_sluices
	var light := get_node_or_null("Glow") as PointLight2D
	if light and (opened or required_sluices > 0 and sluices_open >= required_sluices):
		light.color = GATE_COLOR
		light.energy = 0.8


func refresh_interaction_prompt() -> void:
	if not is_node_ready():
		return
	var message := action_text
	if opened:
		message = "Sluice open"
	elif sluices_open < required_sluices:
		message = "Open both sluices (%d/%d)" % [sluices_open, required_sluices]
	InteractionPromptFormatter.apply_interact_prompt(prompt, message, 24)
