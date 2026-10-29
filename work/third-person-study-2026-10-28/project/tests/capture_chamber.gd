extends SceneTree
var world
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	world=load("res://scenes/chamber_demo.tscn").instantiate();root.add_child(world)
	world.hud_layer.close_dialogue()
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	await frames(45)
	world.actor.set_physics_process(false)
	var camera: Camera3D=world.actor.camera
	camera.reparent(world,true);camera.top_level=true;camera.fov=60
	DirAccess.make_dir_recursive_absolute("res://captures/chamber")
	var views=[
		["overview",Vector3(-17,12,27),Vector3(1,1,0)],
		["workshop",Vector3(-7,4,8),Vector3(0,1,-5)],
		["tower",Vector3(0,5,-9),Vector3(12,4,-19)],
		["yellow",Vector3(-15,4,27),Vector3(0,1,13)],
		["guardian",Vector3(16,4,20),Vector3(23,1.8,12)]]
	for view in views:
		camera.global_position=view[1];camera.look_at(view[2])
		await frames(4);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/chamber/"+view[0]+".png")
	world.shutdown()
