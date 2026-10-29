extends SceneTree
var world
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func save(name: String) -> void:
	await frames(5);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/loom_trial/"+name+".png")
func run() -> void:
	world=load("res://scenes/loom_crossing_trial.tscn").instantiate();root.add_child(world)
	world.hud_layer.close_dialogue()
	for e in get_nodes_in_group("study_enemies"):e.ai_enabled=false
	await frames(45)
	var actor=world.actor
	actor.set_physics_process(false);actor.set_process(false)
	var camera: Camera3D=actor.camera;camera.reparent(world,true);camera.top_level=true
	DirAccess.make_dir_recursive_absolute("res://captures/loom_trial")
	camera.global_position=Vector3(-18,17,24);camera.look_at(Vector3(3,0,-4));camera.fov=62
	await save("overview")
	camera.global_position=Vector3(-1,4.2,21);camera.look_at(Vector3(-4,1,10));camera.fov=60
	await save("village_start")
	camera.global_position=Vector3(1,4,-1);camera.look_at(Vector3(8,1,-9));camera.fov=58
	await save("spool_crossing")
	camera.global_position=Vector3(5,2.5,12);camera.look_at(Vector3(11,-.4,7));camera.fov=60
	await save("river")
	world.hud_layer.visible=false
	actor.global_position=Vector3(0,.1,-1);actor.visual.rotation.y=0
	camera.global_position=actor.global_position+Vector3(-2,1.2,3.2);camera.look_at(actor.global_position+Vector3.UP)
	for slot in [1,2]:
		actor.combat.reset();actor.kit.set_slot(slot)
		actor.play_clip("staff_cast" if slot==1 else "pole_sweep",true);actor.animation.pause();actor.animation.seek(.35,true);actor.animation.advance(0)
		print("HELD_DEBUG ",slot," actual ",actor.kit.slot," attachment ",actor.kit.attachment.global_position," held ",actor.kit.held.global_position," visible ",actor.kit.held.is_visible_in_tree()," bounds ",world.model_bounds(actor.kit.held))
		await save("staff" if slot==1 else "spear")
	world.shutdown()
