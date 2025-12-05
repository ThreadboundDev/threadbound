extends Node2D

@onready var prompt_label: Label = $PromptLabel
@onready var energy_burst: GPUParticles2D = $EnergyBurst
@onready var interaction_area: Area2D = $InteractionArea

var player_in_range: bool = false

func _ready() -> void:
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true
		prompt_label.text = "↑ to weave ↑"
		energy_burst.restart()
		energy_burst.emitting = true

func _on_player_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
		energy_burst.emitting = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("move_up"):
		print("LOOM SHRINE OPENED — EQUIPMENT MENU READY")
		# open_equipment_menu()  # ← next step
