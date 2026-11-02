extends SceneTree
const OUT := "res://ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll"
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok
func run() -> void:
	var scene: Node = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	scene.get_node("TutorialController").tutorial_enabled = false
	scene.get_node("PlaytestWelcome").free()
	root.add_child(scene)
	current_scene = scene
	await frames(120)
	var player = scene.get_node("Player")
	print("DOLL_START ",player.position," floor=",player.is_on_floor()," paused=",paused)
	if not check(player.live_3d_visual._model_root.find_child("Threadborne_Doll",true,false) != null,"Local default selects doll"): return
	if not check(player.is_on_floor(),"Doll settles on actual Chamber floor"): return
	await capture("chamber_idle")
	var start_x: float = player.position.x
	Input.action_press("move_right")
	await frames(30)
	await capture("chamber_run")
	Input.action_release("move_right")
	if not check(player.position.x>start_x+20,"Move input advances player"): return
	await frames(30)
	Input.action_press("Attack")
	await frames(4)
	Input.action_release("Attack")
	if not check(player.is_attacking,"Attack input starts gameplay attack"): return
	await capture("chamber_attack")
	await frames(60)
	Input.action_press("Jump")
	await frames(10)
	Input.action_release("Jump")
	if not check(not player.is_on_floor(),"Jump input leaves floor"): return
	await capture("chamber_jump")
	await frames(90)
	if not check(player.is_on_floor(),"Jump returns to floor"): return
	var report := {"checks":6,"position":str(player.position),"on_floor":player.is_on_floor(),"model":"Threadborne_Doll","display":DisplayServer.get_name()}
	FileAccess.open(OUT+"/gameplay_report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DOLL_CHAMBER_CHECK ",JSON.stringify(report))
	scene.queue_free()
	await process_frame
	await process_frame
	quit()
