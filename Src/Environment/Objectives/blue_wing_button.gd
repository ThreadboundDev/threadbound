extends Area2D
class_name BlueWingButton

signal active_changed(button: BlueWingButton, active: bool, activator: Node)

@export var active_duration := 60.0
@export var prompt_text := "W"

@onready var button_sprite: AnimatedSprite2D = $ButtonSprite as AnimatedSprite2D
@onready var hurtbox: HurtboxComponent = $Hurtbox as HurtboxComponent
@onready var prompt_label: Label = $PromptLabel as Label

var is_active := false
var _active_timer := 0.0
var _player: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	if prompt_label:
		prompt_label.text = prompt_text
		prompt_label.visible = false
	_update_visual()

func _process(delta: float) -> void:
	if not is_active:
		return

	_active_timer = maxf(0.0, _active_timer - delta)
	if _active_timer <= 0.0:
		_set_active(false, null)

func interact(interacting_player: Node) -> void:
	if interacting_player != _player:
		return

	activate(interacting_player)

func activate_from_grapple(source: Node = null) -> void:
	activate(source)

func activate(activator: Node = null) -> void:
	_active_timer = active_duration
	if is_active:
		return

	_set_active(true, activator)

func _set_active(value: bool, activator: Node) -> void:
	if is_active == value:
		return

	is_active = value
	_update_visual()
	active_changed.emit(self, is_active, activator)

func _update_visual() -> void:
	if not button_sprite:
		return

	button_sprite.play(&"active" if is_active else &"inactive")

func _on_hurtbox_hit_received(damage: DamageData) -> void:
	activate(damage.source if damage else null)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	if prompt_label:
		prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)

func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	if prompt_label:
		prompt_label.visible = false
	if body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_player = null
