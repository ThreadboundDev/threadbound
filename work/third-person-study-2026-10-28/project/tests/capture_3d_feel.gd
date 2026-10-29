extends SceneTree
var world
var actor
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func save(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://captures/feel/"+name+".png")
func run() -> void:
	world = load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(world)
	actor = world.actor
	for e in get_nodes_in_group("study_enemies"):e.ai_enabled=false
	await frames(35)
	actor.set_physics_process(false)
	actor.set_process(false)
	actor.global_position=Vector3(0,0,17)
	actor.visual.rotation.y=0
	actor.camera.reparent(world,true)
	actor.camera.top_level=true
	DirAccess.make_dir_recursive_absolute("res://captures/feel")
	actor.play_clip("run_1",true)
	actor.animation.pause()
	for view in ["front","side"]:
		actor.camera.global_position=actor.global_position+Vector3(0,1.05,3.7) if view=="front" else actor.global_position+Vector3(3.7,1.05,0)
		actor.camera.look_at(actor.global_position+Vector3.UP*.95)
		actor.camera.fov=42
		for i in range(6):
			actor.animation.seek(i/6.0*actor.animation.current_animation_length,true)
			actor.animation.advance(0)
			await process_frame
			await save("run_"+view+"_"+str(i))
	var enemy = get_nodes_in_group("study_enemies")[0]
	enemy.global_position=Vector3(0,0,14)
	enemy.visual.rotation.y=0
	enemy.play("idle")
	actor.visible=false
	actor.camera.global_position=enemy.global_position+Vector3(2,1.2,2.6)
	actor.camera.look_at(enemy.global_position+Vector3.UP*1.1)
	await frames(12)
	await save("sword_grip")
	world.shutdown()
