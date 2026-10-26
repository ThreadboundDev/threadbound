extends SceneTree
## Check rendered boot pixels, not merely a capsule resting on its own collider.
var failures: Array[String] = []
var checks := 0
var samples: Array[Dictionary] = []
const OUT := "res://work/lakeside-playtest-2026-10-26"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rendered boot contact requires a GPU renderer")
		quit(1)
		return
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(2000, 10)
	floor_shape.shape = box
	floor_shape.position.y = 405
	floor_body.add_child(floor_shape)
	scene.add_child(floor_body)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	scene.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	player.position.y = 400.0 - player._get_player_collision_bottom_offset()
	player.velocity.y = 10.0
	player.move_and_slide()
	check(player.is_on_floor(), "Real player is grounded on the fixture")
	var visual = player.get_node("Live3DVisual")
	visual.set_process(false)
	var animator: AnimationPlayer = visual._animation_player
	for action: StringName in [&"idle_4", &"walk_1", &"crouch_idle_1"]:
		visual._current_action = action
		animator.play(visual._clips[action], 0)
		animator.pause()
		for phase in [0.0, 0.25, 0.5, 0.75]:
			animator.seek(animator.current_animation_length * phase, true)
			visual._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = visual._viewport.get_texture().get_image()
			var sole_y := 0
			for bone_name: String in ["foot.L", "toe.L", "foot.R", "toe.R"]:
				var bone: int = visual._skeleton.find_bone(bone_name)
				var at: Vector3 = visual._skeleton.to_global(visual._skeleton.get_bone_global_pose(bone).origin)
				var screen: Vector2 = visual._camera.unproject_position(at)
				for x in range(maxi(0, int(screen.x)-15), mini(image.get_width(), int(screen.x)+16)):
					for y in range(550, image.get_height()):
						if image.get_pixel(x,y).a > 0.5:
							sole_y = maxi(sole_y,y)
			var error: float = (sole_y-image.get_height()*0.5+visual._display.offset.y)*visual._display.scale.y
			check(sole_y > 550 and absf(error) < 2.0, "%s phase %.2f: rendered sole is within 2 world pixels of floor (%f)" % [action, phase, error])
			samples.append({"action":action,"phase":phase,"rendered_sole_error_world_pixels":error})
			if phase == 0.0:
				image.save_png(OUT.path_join("grounded_"+action+".png"))
	var water := Node2D.new()
	scene.add_child(water)
	player._prototype_water_surfaces[water] = -1000.0
	visual._process(0)
	check(visual._display.offset == Vector2(0,-255), "Existing swimming crop/rotation registration is preserved")
	var report := {"checks":checks,"failures":failures,"samples":samples,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("boot_contact.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("RENDERED_BOOT_CONTACT ",JSON.stringify(report))
	scene.queue_free()
	await process_frame
	quit(1 if failures.size() else 0)
