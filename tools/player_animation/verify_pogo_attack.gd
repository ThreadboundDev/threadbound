extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const POGO_PATH := "res://Assets/Threadborne/Player/Normalized_V2/attacks/pogo_attack_v2.png"


func _ready() -> void:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	var sprite := player.get_node("Player Animation") as AnimatedSprite2D
	assert(sprite.sprite_frames.has_animation(&"Pogo_Attack"))
	assert(sprite.sprite_frames.get_frame_count(&"Pogo_Attack") == 11)
	assert(is_equal_approx(sprite.sprite_frames.get_animation_speed(&"Pogo_Attack"), 24.0))
	for frame_index in 11:
		var texture := sprite.sprite_frames.get_frame_texture(&"Pogo_Attack", frame_index) as AtlasTexture
		assert(texture != null)
		assert(texture.region.size == Vector2(416, 416))
		assert(texture.atlas.resource_path == POGO_PATH)

	add_child(player)
	player.call("_begin_air_double_attack", Vector2.DOWN)
	assert(player.get("current_attack_body_anim") == "Pogo_Attack")
	assert(sprite.animation == &"Pogo_Attack")
	assert(player.get("air_attack_first_strike_frames") == Vector2i(5, 7))
	print("POGO_ATTACK_ART_VERIFY_OK")
	get_tree().quit()
