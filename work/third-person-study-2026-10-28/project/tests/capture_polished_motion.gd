extends SceneTree
var world
var actor
var folder := "res://captures/polish_motion"
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(folder+"/"+name+".png")
func run() -> void:
	world = load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(world)
	actor = world.actor
	for enemy in get_nodes_in_group("study_enemies"): enemy.ai_enabled=false
	DirAccess.make_dir_recursive_absolute(folder)
	await frames(45)
	actor.global_position = Vector3(0,0.2,17)
	actor.yaw = -0.35
	actor.pitch = -0.2
	actor.distance = 4.4
	actor.visual.rotation.y = PI
	await frames(20)
	actor.combat.attack()
	for i in range(4):
		await frames(6)
		await snapshot("player_"+str(i))
	await frames(25)
	var swordsman = get_nodes_in_group("study_enemies")[0]
	swordsman.global_position = Vector3(0,0.2,14.6)
	swordsman.ai_enabled=true
	actor.combat.invulnerable=99
	swordsman.begin_attack()
	for i in range(4):
		await frames(16)
		await snapshot("sentinel_"+str(i))
	swordsman.ai_enabled=false
	actor.momentum.amount=100
	actor.momentum.change(0)
	await frames(22)
	await snapshot("flow")
	actor.momentum.reset()
	actor.global_position=Vector3(21,0.2,7)
	actor.yaw=PI-0.22
	actor.pitch=-0.14
	actor.distance=5.7
	actor.visual.rotation.y=0
	actor.combat.invulnerable=99
	world.boss.visual.rotation.y=PI
	await frames(20)
	world.boss.ai_enabled=true
	world.boss.combo=2
	world.boss.begin_attack()
	for i in range(5):
		await frames(15)
		await snapshot("golem_"+str(i))
	world.boss.ai_enabled=false
	actor.global_position=Vector3(12.5,-1.5,-5)
	actor.yaw=0.3
	actor.pitch=-0.2
	actor.distance=4.5
	await frames(20)
	await snapshot("swimming")
	print("POLISH_MOTION_CAPTURED")
	world.shutdown()
