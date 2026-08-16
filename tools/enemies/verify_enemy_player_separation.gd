extends Node

const EnemyScene := preload("res://Src/Enemies/EnemyBase/enemy_base.tscn")

class TestPlayer:
	extends CharacterBody2D
	var targeting_suspended := false

	func _init() -> void:
		add_to_group("player")

	func is_enemy_targeting_suspended() -> bool:
		return targeting_suspended

func _ready() -> void:
	var enemy := EnemyScene.instantiate() as EnemyBase
	var player := TestPlayer.new()
	add_child(player)
	add_child(enemy)

	enemy._on_detection_body_entered(player)
	assert(enemy.target == player, "Available player should be acquired")
	assert(
		enemy.get_collision_exceptions().has(player),
		"Enemy physics must ignore the player body"
	)

	player.targeting_suspended = true
	enemy._refresh_target_availability()
	assert(enemy.target == null, "Save-point interaction should release enemy aggro")

	player.targeting_suspended = false
	assert(enemy._try_acquire_target(player), "Player should be targetable after leaving the save point")
	assert(enemy.target == player, "Enemy should reacquire an available player")

	var grade_source := FileAccess.get_file_as_string("res://Src/Environment/World/room_hue_grade.gd")
	assert(
		grade_source.contains("Vector2(-1000.0, -5000.0), Vector2(2000.0, 8300.0)"),
		"Neutral center shaft should extend through the upper main chamber"
	)

	print("Enemy/player separation and central lighting verification passed.")
	get_tree().quit(0)
