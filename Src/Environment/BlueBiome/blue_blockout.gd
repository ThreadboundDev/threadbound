extends Node2D
## Blue playtest room.

const EAST_HOUSE_BOUNDS := Rect2(388, 104, 704, 337)

@onready var player: CharacterBody2D = $Player
@onready var spawn: Marker2D = $Spawn
@onready var follow_camera: Camera2D = $Player/Camera2D
@onready var east_house: Sprite2D = $Geometry/EastTerraceHouse
@onready var east_house_interior: Node2D = $Geometry/EastTerraceHouse/Interior


func _ready() -> void:
	$HUD.visible = true
	return_to_spawn()


func _physics_process(_delta: float) -> void:
	if player.global_position.y > spawn.global_position.y + 3200.0:
		return_to_spawn()
	east_house_interior.visible = EAST_HOUSE_BOUNDS.has_point(east_house.to_local(player.global_position))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		return_to_spawn()
		get_viewport().set_input_as_handled()


func return_to_spawn() -> void:
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	follow_camera.reset_smoothing()
