extends SceneTree
## Compare real grounded instances, shared-source isolation and grapple legs.
const OUT := "res://work/framing-idle-2026-10-30"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func keys(animation: Animation) -> int:
	var values := []
	for track in animation.get_track_count():
		values.append(animation.track_get_path(track))
		for key in animation.track_get_key_count(track):
			values.append(animation.track_get_key_time(track,key))
			values.append(animation.track_get_key_value(track,key))
	return hash(values)
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var floor_body := StaticBody2D.new()
	floor_body.position.y = 200
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000,40)
	collider.shape = shape
	floor_body.add_child(collider)
	stage.add_child(floor_body)
	var instances := []
	for strength in [0.0,1.0]:
		var player = load("res://Src/Characters/Player/player.tscn").instantiate()
		player.get_node("Live3DVisual").upright_idle_strength = strength
		player.position.x = -200 if strength == 0 else 200
		stage.add_child(player)
		instances.append(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0,40)
	camera.zoom = Vector2(0.83,0.83)
	stage.add_child(camera)
	camera.make_current()
	await frames(90)
	var normal = instances[0].live_3d_visual
	var upright = instances[1].live_3d_visual
	check(instances[0].is_on_floor() and instances[1].is_on_floor(),"Both variants settle on the actual floor")
	check(String(normal._clips[&"idle_4"]) == "idle_4", "Strength zero retains the original idle")
	check(upright._animation_player.has_animation(upright._clips[&"idle_4"]),"Upright main idle exists")
	check(upright._lower_sampler_player.has_animation(upright._clips[&"idle_4"]),"Grapple leg sampler has the same upright idle")
	check(keys(normal._animation_player.get_animation("idle_4")) == keys(upright._animation_player.get_animation("idle_4")),"Imported idle source keys remain intact")
	for action in [&"run_1",&"jump_1",&"slash_2",&"casting_2"]:
		check(keys(normal._animation_player.get_animation(normal._clips[action])) == keys(upright._animation_player.get_animation(upright._clips[action])),"Non-idle source unchanged: "+String(action))
	var measurements := []
	for i in instances.size():
		var player = instances[i]
		var visual = player.live_3d_visual
		player.set_physics_process(false)
		player.set_process(false)
		visual.set_process(false)
		visual._play_action(&"idle_4",&"",0.0,true,1.0,0.0)
		visual._animation_player.seek(0.2,true)
		visual._animation_player.advance(0.0)
		visual._animation_player.pause()
		visual._process(0.0)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = visual._viewport.get_texture().get_image()
			var used := image.get_used_rect()
			DirAccess.make_dir_recursive_absolute(OUT)
			image.save_png(OUT+("/baseline.png" if i==0 else "/upright.png"))
			var foot: Vector2 = visual._display.to_global(visual._display.get_rect().position+Vector2(used.end))
			check(absf(foot.y-180.0)<4.0,"Rendered boots meet the real floor: variant "+str(i))
			measurements.append({"variant":i,"body_height_world":used.size.y*0.5,"screen_percent":used.size.y*0.5*0.83/1080.0*100.0,"foot_world_y":foot.y})
		visual.set_process(true)
	upright.play_grapple_throw()
	await frames(5)
	check(upright._upper_body_overlay_active,"Actual grapple throw starts with upright leg sampler")
	check(upright._lower_sampler_player.current_animation == upright._clips[&"idle_4"],"Standing grapple samples the installed upright clip")
	await frames(35)
	check(not upright._upper_body_overlay_active,"Grapple overlay finishes normally")
	check(upright._current_action == &"idle_4","Grapple returns to the selected idle")
	for path in ["res://Src/Environment/World/Chamber Of The First Weave.tscn","res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn"]:
		var state := (load(path) as PackedScene).get_state()
		var found := false
		for node in state.get_node_count():
			if state.get_node_name(node) != &"Camera2D": continue
			for property in state.get_node_property_count(node):
				if state.get_node_property_name(node,property) == &"zoom":
					found = state.get_node_property_value(node,property).is_equal_approx(Vector2(0.83,0.83))
		check(found,"Authored gameplay camera is 0.83: "+path)
	var report := {"checks":checks,"failures":failures,"measurements":measurements,"display":DisplayServer.get_name()}
	DirAccess.make_dir_recursive_absolute(OUT)
	FileAccess.open(OUT+"/"+("headless.json" if DisplayServer.get_name()=="headless" else "render.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("UPRIGHT_IDLE ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
