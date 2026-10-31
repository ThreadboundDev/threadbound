extends SceneTree
const OUT := "res://work/overnight-playtest-2026-10-30"
var room
var player
var lake
var camera: Camera2D
var report := {}
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func shot(label: String, center: Vector2, observer: Vector2) -> void:
	camera.position = center
	camera.force_update_scroll()
	player.position = observer
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(35)
	root.get_texture().get_image().save_png(OUT+"/water_"+label+".png")
	report[label] = {"underwater_view":lake.underwater_view,"camera":str(center),"player":str(observer),"eye":str(player.live_3d_visual.get_water_eye_global_position())}
func run() -> void:
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	room.get_node("LakesideArtStage").render_scale = 2.0 if "--full-quality" in OS.get_cmdline_user_args() else 1.0
	room.tree_entered.connect(func(): current_scene=room,CONNECT_ONE_SHOT)
	root.add_child(room)
	player = room.get_node("Player")
	lake = room.get_node("Volumes/Lake")
	player.set_physics_process(false)
	for e in get_nodes_in_group("enemies"): e.set_physics_process(false)
	await frames(15)
	for layer in root.find_children("*","CanvasLayer",true,false): layer.hide()
	for old in room.find_children("*","Camera2D",true,false): old.enabled=false
	camera = Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.zoom = Vector2(0.83,0.83)
	room.add_child(camera)
	camera.make_current()
	if "--quality-smoke" in OS.get_cmdline_user_args():
		await shot("quality_above",Vector2(1000,400),Vector2(650,350))
		await shot("quality_below",Vector2(1000,400),Vector2(650,600))
		var passed: bool = room.get_node("LakesideArtStage").render_scale == 2.0 and report.quality_above.underwater_view < .01 and report.quality_below.underwater_view > .99
		report["passed"] = passed
		report["render_scale"] = room.get_node("LakesideArtStage").render_scale
		FileAccess.open(OUT+"/water-full-quality-smoke.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("WATER_FULL_QUALITY ",JSON.stringify(report))
		room.queue_free()
		await process_frame
		quit(0 if passed else 1)
		return
	if "--diagnose-cave" in OS.get_cmdline_user_args():
		await shot("cave_source",Vector2(2200,1600),Vector2(2100,1640))
		room.get_node("Geometry/TerrainArtwork/rear_cave").hide()
		await shot("cave_source_hidden",Vector2(2200,1600),Vector2(2100,1640))
		room.queue_free()
		await process_frame
		quit()
		return
	if "--motion" in OS.get_cmdline_user_args():
		camera.position = Vector2(1000,400)
		camera.force_update_scroll()
		player.position = Vector2(650,330)
		await frames(35)
		for i in 80:
			var phase := float(i)/79.0
			player.position.y = 330.0+300.0*pow(sin(phase*PI),2.0)
			player.reset_physics_interpolation()
			await frames(3)
			var frame := root.get_texture().get_image()
			frame.resize(960,540,Image.INTERPOLATE_LANCZOS)
			frame.save_png(OUT+"/water_motion_%03d.png"%i)
		room.queue_free()
		await process_frame
		quit()
		return
	for mode in [false,true]:
		lake.painted_surface = mode
		var label := "painted" if mode else "previous"
		await shot(label+"_above",Vector2(1000,400),Vector2(650,350))
		await shot(label+"_half",Vector2(1000,400),Vector2(650,460))
		await shot(label+"_below",Vector2(1000,400),Vector2(650,600))
		await shot(label+"_depth",Vector2(2200,1600),Vector2(2100,1640))
		await shot(label+"_pocket",Vector2(4000,2150),Vector2(4000,2150))
	await shot("sky",Vector2(2500,-1500),Vector2(2400,-1460))
	report.geometry = {}
	for node: CollisionPolygon2D in room.find_children("*","CollisionPolygon2D",true,false):
		if String(room.get_path_to(node)).begins_with("Geometry/") or String(room.get_path_to(node)).begins_with("Volumes/"):
			var points := []
			for p in node.polygon:
				var world := node.to_global(p)
				points.append([world.x,world.y])
			report.geometry[String(room.get_path_to(node))] = points
	FileAccess.open(OUT+"/water-capture.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("WATER_CAPTURE_COMPLETE")
	room.queue_free()
	await process_frame
	quit()
