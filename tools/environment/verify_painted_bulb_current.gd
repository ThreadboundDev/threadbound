extends SceneTree
var failures: Array[String] = []
var checks := 0
const OUT := "res://work/lakeside-playtest-2026-10-26"
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func image_at(view: SubViewport) -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for i in 25: await physics_frame
	var art = room.get_node("ArtComparison")
	art.set_process(false)
	var entry: Dictionary = art.bulbs[0]
	var original: Sprite2D = entry.painted
	var bulb: GreyboxBumper2D = entry.node
	var anchor := original.transform
	var collision: Transform2D = bulb.get_node("HitReceiver/CollisionShape2D").global_transform
	var view := SubViewport.new()
	view.size = Vector2i(512,560)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = original.texture
	sprite.material = original.material
	view.add_child(sprite)
	var first: Image
	var changed := 0
	var stem_changes := 0
	for time in [0.0,0.5,1.0,1.5]:
		art._clock = time
		art._update_bulbs(0)
		var image := await image_at(view)
		check(original.transform == anchor,"Idle current does not bounce the sac/attachment")
		check(bulb.get_node("HitReceiver/CollisionShape2D").global_transform == collision,"Idle current never moves collision")
		if time == 0.0:
			first = image
			image.save_png(OUT.path_join("bulb_idle_0.png"))
		else:
			for y in image.get_height():
				for x in image.get_width():
					if image.get_pixel(x,y) != first.get_pixel(x,y):
						if y < 320: stem_changes += 1
						else: changed += 1
			if time == 1.0: image.save_png(OUT.path_join("bulb_idle_1.png"))
	check(changed>1000,"Rendered inner water visibly moves across idle samples")
	check(stem_changes==0,"Rendered stem/petals remain stationary")
	check(bulb.activate_from_grapple(),"Existing grapple pop still works")
	for i in 15: await physics_frame
	art._update_bulbs(0)
	check(original.texture == art._texture("water_bulb",3),"Existing spent drawing retained")
	check(original.material.get_shader_parameter("idle_energy")==0.0,"Spent bulb has no living idle current")
	var result := {"checks":checks,"failures":failures,"changed_water_pixels":changed,"changed_stem_pixels":stem_changes}
	FileAccess.open(OUT.path_join("bulb_current.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("PAINTED_BULB_CURRENT ",JSON.stringify(result))
	view.queue_free()
	room.queue_free()
	await process_frame
	quit(1 if failures.size() else 0)
