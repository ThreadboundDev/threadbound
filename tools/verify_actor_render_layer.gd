extends SceneTree


func _initialize() -> void:
	var player_scene := load("res://Src/Characters/Player/player.tscn") as PackedScene
	var enemy_scene := load("res://Src/Enemies/Threadling/threadling.tscn") as PackedScene
	if not player_scene or not enemy_scene:
		push_error("Actor render-layer verification could not load actor scenes.")
		quit(1)
		return

	var player := player_scene.instantiate() as CharacterBody2D
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	player.z_index = 10 # Matches the world placement override.
	if enemy.z_index != player.z_index:
		push_error("Enemy z-index %d does not match player z-index %d." % [enemy.z_index, player.z_index])
		player.free()
		enemy.free()
		quit(1)
		return

	print("Actor render-layer verification passed.")
	player.free()
	enemy.free()
	quit()
