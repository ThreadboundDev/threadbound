extends SceneTree
## Real jump inputs and the demo's authored lights; optional Forward+ captures.
const OUT := "res://work/demo-jump-lighting-2026-10-30"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	if DisplayServer.get_name() != "headless" and "--render-fixtures" not in OS.get_cmdline_user_args():
		push_error("Run the full audit headless, or use -- --render-fixtures for GPU verification")
		quit(1)
		return
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await physics_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func jump() -> void:
	Input.action_press("Jump")
	await frames(2)
	Input.action_release("Jump")
	await frames(1)

func verify_jumps() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 40)
	collider.shape = shape
	floor_body.position.y = 200
	floor_body.add_child(collider)
	stage.add_child(floor_body)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	await frames(80)
	var visual = player.live_3d_visual
	var animator: AnimationPlayer = visual._animation_player
	check(player.is_on_floor(), "Fixture settles on real floor")
	await jump()
	check(player.velocity.y < 0 and player.air_jump_available, "First jump preserves the air jump")
	await frames(5)
	var first_rate := animator.speed_scale
	animator.seek(0.28, true)
	var ap: int = player.current_action_points
	await jump()
	check(not player.air_jump_available, "Second input consumes the existing air jump")
	check(player.current_action_points == ap - 1, "Second jump retains the existing AP cost")
	check(visual._current_action == &"jump_1", "Second jump reuses the normal jump clip")
	check(animator.current_animation_position < 0.15, "Early double jump restarts the clip even during ascent")
	check(is_equal_approx(animator.speed_scale, first_rate * 1.2), "Second jump plays 20 percent faster")
	await frames(100)
	check(player.is_on_floor(), "Player lands after double jump")
	await jump()
	check(is_equal_approx(animator.speed_scale, first_rate), "Next grounded jump restores the normal rate")
	for i in 100:
		if player.velocity.y > 150: break
		await frames(1)
	animator.seek(0.28, true)
	await jump()
	check(player.velocity.y < 0 and not player.air_jump_available, "Late double jump still boosts the falling player")
	check(animator.current_animation_position < 0.15, "Late double jump restarts the clip")
	check(is_equal_approx(animator.speed_scale, first_rate * 1.2), "Late double jump uses the same faster rate")
	await frames(100)
	await jump()
	player.refill_action_points()
	player.spend_action_points(player.max_action_points)
	animator.seek(0.28, true)
	await jump()
	check(player.air_jump_available, "Rejected air jump does not consume availability")
	check(animator.current_animation_position > 0.28, "Rejected air jump does not restart its animation")
	stage.queue_free()
	await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if "--render-fixtures" in OS.get_cmdline_user_args():
		await verify_fixture_render()
		quit(0 if failures.is_empty() else 1)
		return
	await verify_jumps()
	var demo = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(12)
	var live_display: Sprite2D = demo.get_node("Player/Live3DComposite")
	var world_lights: Array[Light2D] = []
	for node in demo.find_children("*", "Light2D", true, false):
		if demo.get_node("Player").is_ancestor_of(node): continue
		# Enemy auras/soul glows are combat effects, not level lighting. Some
		# enemies are spawned after ready; their own masks are out of scope.
		if node.name in [&"EnemySoulLight", &"BackgroundAura"]:
			check(node.range_item_cull_mask == 1, "Enemy effect retains its mask: " + str(demo.get_path_to(node)))
			continue
		world_lights.append(node)
		check((node.range_item_cull_mask & live_display.light_mask) != 0,
			"Demo light reaches the character: " + str(demo.get_path_to(node)))
	check(world_lights.size() >= 13, "Main demo and all wing fixtures are covered")
	var soul := demo.get_node("Player/PlayerSoulLight") as Light2D
	check((soul.range_item_cull_mask & live_display.light_mask) == 0, "Soul light remains excluded from its own character")
	var report := {"checks":checks, "failures":failures, "world_lights":world_lights.size(), "display":DisplayServer.get_name()}
	FileAccess.open(OUT + "/results.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("DEMO_JUMP_LIGHTING ", JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func verify_fixture_render() -> void:
	# Keep the full demo mask audit headless: a second complete GPU copy can
	# exhaust VRAM while Chase's editor is open. Render actual fixtures here.
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var ambient := CanvasModulate.new()
	ambient.name = "Ambient"
	ambient.color = Color(0.25, 0.25, 0.25)
	stage.add_child(ambient)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	player.set_physics_process(false)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -60)
	camera.zoom = Vector2(2, 2)
	stage.add_child(camera)
	camera.make_current()
	var fixture: Node2D = load("res://Src/Environment/WingLighting/red_wing_light.tscn").instantiate()
	stage.add_child(fixture)
	fixture.set_process(false)
	for sprite in fixture.find_children("*", "Sprite2D", true, false): sprite.visible = false
	var lights := fixture.find_children("*", "Light2D", true, false)
	for light in lights: light.position = Vector2(0, -60)
	var grade = load("res://Src/Environment/World/room_hue_grade.gd").new()
	grade.player_path = ^"../Player"
	grade.ambient_modulate_path = ^"../Ambient"
	grade.remove_placeholder_nodes = false
	stage.add_child(grade)
	grade.set_process(false)
	ambient.color = Color(0.25, 0.25, 0.25)
	await frames(20)
	player.live_3d_visual._animation_player.pause()
	await RenderingServer.frame_post_draw
	var lit := root.get_texture().get_image()
	check(lit.save_png(OUT + "/fixture_lit.png") == OK, "Lit character capture saves")
	for light in lights: light.enabled = false
	await frames(5)
	await RenderingServer.frame_post_draw
	var dark := root.get_texture().get_image()
	check(dark.save_png(OUT + "/fixture_lights_off.png") == OK, "Unlit character capture saves")
	var changed := 0
	for y in lit.get_height():
		for x in lit.get_width():
			var a := lit.get_pixel(x, y)
			var b := dark.get_pixel(x, y)
			if a.r > b.r + 0.05: changed += 1
	check(changed > 100, "Real red-wing fixture visibly illuminates the live character")
	var report := {"checks":checks, "failures":failures, "red_lit_pixels":changed, "display":DisplayServer.get_name()}
	FileAccess.open(OUT + "/render_results.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("DEMO_LIGHT_RENDER ", JSON.stringify(report))
	stage.queue_free()
	await process_frame
