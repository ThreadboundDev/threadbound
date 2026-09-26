extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")


func _ready() -> void:
	assert(InputMap.has_action("Block"))
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	var visual := player.get_node("Live3DVisual") as PlayerLive3DVisual
	visual.enabled = false
	add_child(player)
	await get_tree().process_frame

	player.player_stats = PlayerStats.new()
	player.player_stats.resistance = 0
	player.global_position = Vector2.ZERO
	player.last_direction = 1
	player.is_blocking = true

	var frontal := DamageData.new()
	frontal.amount = 100
	frontal.hit_position = Vector2(100, 0)
	var frontal_result: DamageData = player.modify_incoming_health_damage(frontal)
	assert(frontal_result.amount == 25)
	assert(player._last_incoming_hit_blocked)

	var rear := DamageData.new()
	rear.amount = 100
	rear.hit_position = Vector2(-100, 0)
	var rear_result: DamageData = player.modify_incoming_health_damage(rear)
	assert(rear_result.amount == 100)
	assert(not player._last_incoming_hit_blocked)

	var body_collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var standing_height := (body_collision.shape as RectangleShape2D).size.y
	player._apply_crouch_collision(true)
	var crouched_height := (body_collision.shape as RectangleShape2D).size.y
	assert(is_equal_approx(crouched_height, standing_height * player.crouch_height_ratio))
	player._apply_crouch_collision(false)
	assert(is_equal_approx((body_collision.shape as RectangleShape2D).size.y, standing_height))

	print("PLAYER_DEFENSE_TEST_PASS frontal=25 rear=100 crouch_ratio=", player.crouch_height_ratio)
	get_tree().quit()
