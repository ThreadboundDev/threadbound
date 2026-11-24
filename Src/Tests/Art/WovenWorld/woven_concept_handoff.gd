extends Area2D

signal activated

const ARRIVAL := &"woven_concept_arrival"

@export var action_text := "Enter"
@export_file("*.tscn") var destination: String
@export var arrival: StringName
@export var underwater := false
var available := true

@onready var prompt: Label = $Prompt


func _ready() -> void:
	add_to_group(&"interaction_prompt_owners")
	refresh_interaction_prompt()


func refresh_interaction_prompt() -> void:
	InteractionPromptFormatter.apply_interact_prompt(prompt, action_text, 22)


func _process(_delta: float) -> void:
	prompt.visible = _can_interact()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact") or event.is_echo() or not _can_interact():
		return
	get_viewport().set_input_as_handled()
	if destination.is_empty():
		activated.emit()
		return
	var tree := get_tree()
	tree.set_meta(ARRIVAL, arrival)
	var error := tree.change_scene_to_file(destination)
	if error != OK:
		tree.remove_meta(ARRIVAL)
		push_error("Woven Shore handoff failed (%d): %s" % [error, destination])


func _can_interact() -> bool:
	if not available:
		return false
	for actor in get_overlapping_bodies():
		if actor.is_in_group(&"player") and not actor.is_dead:
			return not underwater or actor.is_in_prototype_water()
	return false
