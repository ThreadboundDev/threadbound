extends Node2D

@export var follows_player := true
@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player

var outline: RefCounted


func _ready() -> void:
	outline = preload("res://Src/Tests/Art/WovenWorld/woven_outline_comparison.gd").new()
	outline.initialize(player.get("live_3d_visual"))


func _physics_process(_delta: float) -> void:
	if follows_player:
		camera.position.x = player.position.x
	if player.position.y > 1520:
		player.position = $Spawn.position
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
