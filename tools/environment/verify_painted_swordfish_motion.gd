extends SceneTree
const OUT := "res://work/painted-registration-2026-10-22"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("PAINTED_SWORDFISH_FAIL "+message)

func frames(count: int) -> void:
	for i in count:
		await process_frame

func verify() -> void:
	var room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(20)
	var art = room.get_node("ArtComparison")
	art.set_process(false)
	room.get_node("Player").set_physics_process(false)
	room.get_node("Player").visible = false
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false):
		ui.visible = false
	var entry: Dictionary
	for candidate: Dictionary in art.actors:
		if candidate.key == "tide_duelist":
			entry = candidate
	var fish: CharacterBody2D = entry.enemy
	entry.model.set_process(false)
	entry.model.play_clip(&"still")
	entry.model.animator.pause()
	var camera := Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = fish.global_position+Vector2(0,-15)
	camera.zoom = Vector2.ONE*3
	room.add_child(camera)
	camera.make_current()
	var key := "tide_duelist_swim_v2"
	var sheet: Dictionary = art.manifest[key]
	check(sheet.frames.size()==12,"Twelve consecutive swim frames loaded")
	var original_collision: Transform2D = fish.get_node("CollisionShape2D").global_transform
	var first_anchor := Vector2.ZERO
	var maximum_drift := 0.0
	var images: Array[String] = []
	for i in 12:
		art._clock = (float(i)+.1)/16.0
		art._process(0)
		check(entry.painted.texture == art._texture(key,i),"Hover selects swim frame "+str(i))
		var anchor: Array = sheet.bill_anchors[i]
		var world: Vector2 = entry.painted.to_global(Vector2(anchor[0],anchor[1]))
		if i == 0:
			first_anchor = world
		maximum_drift = maxf(maximum_drift,world.distance_to(first_anchor))
		check(world.distance_to(first_anchor)<.001,"Rigid bill stays fixed in frame "+str(i))
		check(fish.get_node("CollisionShape2D").global_transform == original_collision,"Animation does not move collision "+str(i))
		await frames(3)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var filename := "swordfish_swim_%02d.png"%i
			check(root.get_texture().get_image().save_png(OUT.path_join(filename))==OK,"GPU capture "+filename)
			images.append(filename)
	fish.begin_attack()
	art._process(0)
	check(entry.painted.texture == art._texture("tide_duelist",2),"Real windup retains curled attack tell")
	fish.activate_attack_hitbox()
	art._process(0)
	check(entry.painted.texture == art._texture("tide_duelist",3),"Real release retains strike pose")
	entry.model._on_clip_finished(&"dash")
	for i in 12:
		art._clock = (float(i)+.1)/20.0
		art._process(0)
		check(entry.painted.texture == art._texture(key,i),"Dash glide selects swim frame "+str(i))
	fish.deactivate_attack_hitbox()
	art._process(0)
	check(entry.painted.texture == art._texture("tide_duelist",4),"Real recovery retains recovery pose")
	fish.begin_polished_hurt_response()
	art._process(0)
	check(entry.painted.texture == art._texture("tide_duelist",5),"Real hurt retains hurt pose")
	art.set_all(false)
	check(entry.original.visible and not entry.painted.visible,"F7 restores original model")
	art.set_all(true)
	check(entry.painted.visible and not entry.original.visible,"F7 restores painted fish")
	var report := {"passed":failures.is_empty(),"checks":checks,"max_bill_anchor_drift_px":maximum_drift,"swim_frames":12,"gpu_captures":images,"failures":failures}
	FileAccess.open(OUT.path_join("swordfish_motion.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("PAINTED_SWORDFISH_CHECK ",JSON.stringify(report))
	room.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
