extends SceneTree
const OUT := "res://work/gameplay-review-followup-2026-10-30"
var room
var camera: Camera2D
var report := {}
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func shot(label: String, center: Vector2) -> void:
	camera.position = center
	camera.force_update_scroll()
	await frames(5)
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png(OUT+"/"+report.label+"_"+label+".png")
func run() -> void:
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	report.label = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	room.get_node("LakesideArtStage").render_scale = 2.0 if "--full-quality" in OS.get_cmdline_user_args() else 1.0
	room.tree_entered.connect(func(): current_scene=room,CONNECT_ONE_SHOT)
	root.add_child(room)
	var player = room.get_node("Player")
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
	report.geometry = {}
	for node: CollisionPolygon2D in room.find_children("*","CollisionPolygon2D",true,false):
		if String(room.get_path_to(node)).begins_with("Geometry/") or String(room.get_path_to(node)).begins_with("Volumes/"):
			var points := []
			for p in node.polygon:
				var world := node.to_global(p)
				points.append([world.x,world.y])
			report.geometry[String(room.get_path_to(node))] = points
	if "--survey-only" in OS.get_cmdline_user_args():
		for deck in room.get_node("Geometry/BridgeLandings").get_children():
			var covered := []
			for x in range(0,int(deck.span_width),8):
				var query := PhysicsPointQueryParameters2D.new()
				query.position = deck.to_global(Vector2(x+4,10))
				query.collision_mask = 1
				for overlap in room.get_world_2d().direct_space_state.intersect_point(query):
					if overlap.collider == room.get_node("Geometry/RockCollision"):
						covered.append(x)
			print("ROCK_COVER ",deck.name," ",covered)
		FileAccess.open(OUT+"/geometry-baseline.json",FileAccess.WRITE).store_string(JSON.stringify(report.geometry,"\t"))
		room.queue_free()
		await process_frame
		quit()
		return
	if "--house-only" not in OS.get_cmdline_user_args():
		for pair in [["surface",Vector2(1000,500)],["depth",Vector2(2200,1600)],["pocket",Vector2(3300,2400)],["sky",Vector2(2500,-1200)]]:
			player.position = pair[1]+Vector2(-100,40)
			player.reset_physics_interpolation()
			await shot(pair[0],pair[1])
		for deck in room.get_node("Geometry/BridgeLandings").get_children():
			player.position = deck.position+Vector2(minf(100,deck.span_width*.5),-70.245)
			player.velocity = Vector2.ZERO
			player.reset_physics_interpolation()
			player.set_physics_process(true)
			await frames(35)
			player.set_physics_process(false)
			await shot(String(deck.name),deck.global_position+Vector2(deck.span_width*.5,20))
	# House keeps the actual player camera so the focus shader follows its real
	# framing. Capture in a 1280x720 window to catch logical/framebuffer mismatch.
	camera.enabled = false
	var pc = player.get_node("Camera2D")
	pc.enabled = true
	pc.make_current()
	var house = room.get_node("Buildings/Workshop")
	house._enter_house(player)
	player.set_physics_process(true)
	await frames(100)
	if DisplayServer.get_name() != "headless": root.get_texture().get_image().save_png(OUT+"/"+report.label+"_workshop.png")
	report.house_bounds = str(house.global_transform*house.entry_rect)
	FileAccess.open(OUT+"/blue-"+report.label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BLUE_FEEDBACK_CAPTURE ",report.label)
	room.queue_free()
	await process_frame
	quit()
