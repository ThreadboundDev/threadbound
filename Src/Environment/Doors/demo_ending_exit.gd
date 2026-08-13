class_name DemoEndingExit
extends Area2D

signal revealed
signal ending_requested

const ENDING_SCENE := preload("res://Src/UI/DemoEnding/demo_ending.tscn")

@export var prompt_action_text := "Choose Demo Ending"
@export_range(0.1, 3.0, 0.05) var reveal_duration := 0.75

@onready var blossom: Sprite2D = $Blossom as Sprite2D
@onready var glow: PointLight2D = $Glow as PointLight2D
@onready var interaction_shape: CollisionShape2D = $InteractionShape as CollisionShape2D
@onready var prompt_label: Label = $PromptLabel as Label
@onready var choice_layer: CanvasLayer = $ChoiceLayer as CanvasLayer
@onready var continue_button: Button = $ChoiceLayer/Root/Panel/Margin/Choices/ContinueButton as Button
@onready var keep_exploring_button: Button = $ChoiceLayer/Root/Panel/Margin/Choices/KeepExploringButton as Button

var _player: Node
var _revealed := false
var _choice_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	continue_button.pressed.connect(_continue_to_ending)
	keep_exploring_button.pressed.connect(_keep_exploring)
	choice_layer.visible = false
	visible = false
	monitoring = false
	interaction_shape.disabled = true
	prompt_label.visible = false
	prompt_label.text = InteractionPromptFormatter.format_interact_prompt(prompt_action_text)
	var input_manager := get_node_or_null("/root/InputBindingManager")
	if input_manager and input_manager.has_signal("bindings_changed"):
		input_manager.bindings_changed.connect(_refresh_prompt)

func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	visible = true
	monitoring = true
	interaction_shape.set_deferred("disabled", false)
	modulate.a = 0.0
	blossom.scale = Vector2(0.24, 0.24)
	glow.energy = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, reveal_duration)
	tween.tween_property(blossom, "scale", Vector2(0.36, 0.36), reveal_duration)
	tween.tween_property(glow, "energy", 1.6, reveal_duration)
	tween.finished.connect(_begin_idle_pulse)
	revealed.emit()

func interact(interacting_player: Node) -> void:
	if not _revealed or _choice_open or interacting_player != _player:
		return
	_choice_open = true
	choice_layer.visible = true
	prompt_label.visible = false
	get_tree().paused = true
	continue_button.grab_focus()

func _continue_to_ending() -> void:
	if get_tree().get_first_node_in_group("demo_ending_screen"):
		return
	AudioManager.play_ui(&"menu_select")
	choice_layer.visible = false
	_choice_open = false
	ending_requested.emit()
	var ending := ENDING_SCENE.instantiate()
	get_tree().root.add_child(ending)

func _keep_exploring() -> void:
	AudioManager.play_ui(&"ui_click")
	choice_layer.visible = false
	_choice_open = false
	get_tree().paused = false
	if is_instance_valid(_player):
		prompt_label.visible = true

func _begin_idle_pulse() -> void:
	if not is_inside_tree():
		return
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE)
	pulse.set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(glow, "energy", 1.15, 1.1)
	pulse.tween_property(glow, "energy", 1.65, 1.1)

func _refresh_prompt() -> void:
	prompt_label.text = InteractionPromptFormatter.format_interact_prompt(prompt_action_text)

func _on_body_entered(body: Node2D) -> void:
	if not _revealed or not body.is_in_group("player"):
		return
	_player = body
	_refresh_prompt()
	prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body.call("_on_interactable_entered", self)

func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	prompt_label.visible = false
	if body.has_method("_on_interactable_exited"):
		body.call("_on_interactable_exited", self)
	_player = null
