extends SceneTree
const OUT := "res://work/appearance-lab-2026-10-30"
var lab
var cases := []
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func capture(label: String) -> void:
	lab.apply()
	lab.visual._play_action(&"idle_4",&"",0.0,true,1.0,0.0)
	lab.visual._animation_player.seek(.2,true)
	lab.visual._animation_player.advance(0)
	lab.visual._animation_player.pause()
	lab.visual._process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png")
	cases.append({"label":label,"mode":lab.mode,"identity":lab.identity,"math":lab.math_mode,"mask":lab.mask_style,"motif":lab.motif,"armor":lab.armor,"weapon":lab.weapon,"softer_porcelain":lab.softer_porcelain})
func run() -> void:
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	lab = load("res://tools/art/appearance_lab.tscn").instantiate()
	lab.tree_entered.connect(func(): current_scene=lab,CONNECT_ONE_SHOT)
	root.add_child(lab)
	await frames(90)
	check(lab.player.is_on_floor(),"Preview uses the real grounded player")
	check(lab.visual._sword_mesh.visible and not lab.weapon_proxy.visible,"Original gear is the default")
	check(lab.camera.zoom.is_equal_approx(Vector2(.83,.83)),"Preview starts at saved gameplay zoom")
	check(lab.identity_color(Vector3.ONE,true).v < .16,"Authored full-absorption preview reaches the dark extreme")
	check(lab.identity_color(Vector3(0,1,1),true).g > lab.identity_color(Vector3(0,1,1),true).b,"Authored blue/yellow preview reads green")
	check(lab.identity_color(Vector3.ZERO,true).v > .8,"Zero-absorption palette target is pale")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/interface.png")
	lab.player.set_physics_process(false)
	lab.player.set_process(false)
	lab.visual.set_process(false)
	lab.controls.hide()
	for layer in root.find_children("*","CanvasLayer",true,false): layer.hide()
	var collider = lab.player.get_node("CollisionShape2D")
	var collision_before: Vector2 = collider.shape.get_rect().size
	lab.identity = 2
	for mode in 4:
		lab.mode = mode
		await capture("look_%d"%mode)
	lab.mode = 3
	for mask in 3:
		lab.mask_style = mask
		await capture("mask_%d"%mask)
	for identity in 9:
		lab.identity = identity
		await capture("palette_%d"%identity)
	lab.identity = 5
	for math in 2:
		lab.math_mode = math
		await capture("math_%d"%math)
	lab.armor = true
	lab.weapon = true
	await capture("gear_proxy")
	check(not lab.visual._sword_mesh.visible and lab.weapon_proxy.visible,"Long-weapon proxy can be compared without equipment mutation")
	lab.softer_porcelain = true
	await capture("softer_porcelain")
	check(collider.shape.get_rect().size == collision_before,"Appearance switches preserve the player collision shape")
	lab.player.set_physics_process(true)
	lab.player.set_process(true)
	lab.visual.set_process(true)
	var start: Vector2 = lab.player.position
	Input.action_press("move_right")
	await frames(30)
	check(lab.player.position.x > start.x+100 and lab.visual._current_action == &"run_1","Appearance preview supports actual running with the rigged study mesh")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/running.png")
	Input.action_release("move_right")
	await frames(20)
	lab.player.start_attack(false)
	await frames(12)
	check(lab.player.is_attacking,"Appearance preview supports the actual attack controller")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/attacking.png")
	FileAccess.open(OUT+"/validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"camera_zoom":.83,"display":DisplayServer.get_name()},"\t"))
	print("APPEARANCE_LAB ",JSON.stringify({"checks":checks,"failures":failures,"captures":cases.size()}))
	lab.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
