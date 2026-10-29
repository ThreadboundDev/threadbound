extends SceneTree
var world
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func save(name: String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/combat/"+name+".png")
func run() -> void:
	world=load("res://scenes/chamber_demo.tscn").instantiate();root.add_child(world)
	world.enter_practice("reedhook",true)
	await frames(30)
	var actor=world.actor
	var enemy=world.practice_subject
	enemy.ai_enabled=false
	actor.set_physics_process(false);actor.set_process(false)
	var camera: Camera3D=actor.camera
	camera.reparent(world,true);camera.top_level=true;camera.fov=44
	DirAccess.make_dir_recursive_absolute("res://captures/combat")
	world.hud_layer.visible=false
	for clip in ["combat_strafe_left","combat_strafe_right","heavy_hit","air_attack_forward","slash_2"]:
		actor.play_clip(clip,true);actor.animation.pause()
		actor.animation.seek(.3,true);actor.animation.advance(0)
		camera.global_position=actor.global_position+Vector3(2,1.1,3.2)
		camera.look_at(actor.global_position+Vector3.UP*.95)
		await save(clip)
	actor.visible=false
	camera.global_position=enemy.global_position+Vector3(2,1.3,3)
	camera.look_at(enemy.global_position+Vector3.UP*1.1)
	await save("armored_swordsman")
	world.shutdown()
