extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")


func _ready() -> void:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	var clock := player.get_node("AnimationClock") as PlayerAnimationClock
	assert(clock.has_animation(&"Pogo_Attack"))
	assert(clock.get_frame_count(&"Pogo_Attack") == 11)
	assert(is_equal_approx(clock.get_animation_speed(&"Pogo_Attack"), 24.0))
	assert(not clock.get_animation_loop(&"Pogo_Attack"))
	for frame_index in 11:
		assert(is_equal_approx(clock.get_frame_duration(&"Pogo_Attack",frame_index),1.0))

	add_child(player)
	player.call("_begin_air_double_attack", Vector2.DOWN)
	assert(player.get("current_attack_body_anim") == "Pogo_Attack")
	assert(clock.animation == &"Pogo_Attack")
	assert(player.get("air_attack_first_strike_frames") == Vector2i(5, 7))
	print("POGO_ATTACK_TIMING_VERIFY_OK")
	get_tree().quit()
