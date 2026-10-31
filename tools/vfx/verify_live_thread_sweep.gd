extends SceneTree
const OUT := "res://work/gameplay-review-followup-2026-10-30"
var checks := 0
var failures: Array[String] = []
var hits := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6000,60)
	collider.shape = shape
	floor_body.position.y = 100
	floor_body.add_child(collider)
	stage.add_child(floor_body)
	var players := []
	for i in 2:
		var player = load("res://Src/Characters/Player/player.tscn").instantiate()
		player.position.x = -340 if i == 0 else 340
		player.get_node("Live3DVisual").filled_sweep_enabled = i == 1
		stage.add_child(player)
		players.append(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0,-40)
	camera.zoom = Vector2(0.83,0.83)
	stage.add_child(camera)
	camera.make_current()
	await frames(70)
	Input.action_press("aim_right")
	for p in players: p.start_attack(false)
	var queues := [-1,-1]
	var emitted := false
	var matched := true
	var saved := {}
	var max_samples := 0
	for frame in 180:
		await process_frame
		var a = players[0]
		var b = players[1]
		matched = matched and a.ground_combo_step == b.ground_combo_step and a.ground_combo_active_strike == b.ground_combo_active_strike
		matched = matched and a.attack_collision_polygon.polygon == b.attack_collision_polygon.polygon
		matched = matched and absf(a.live_3d_visual.get_current_action_position()-b.live_3d_visual.get_current_action_position()) < 0.0001
		max_samples = maxi(max_samples,b.live_3d_visual._thread_sweep.samples.size())
		emitted = emitted or max_samples > 1
		for i in 2:
			var p = players[i]
			if p.is_attacking and p.ground_combo_step < 2 and p.attack_timer > 0.2 and queues[i] != p.ground_combo_step:
				queues[i] = p.ground_combo_step
				p.start_attack(false)
		if b.live_3d_visual._thread_sweep.samples.size() >= 4 and not saved.has(b.ground_combo_step):
			saved[b.ground_combo_step] = true
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"/live-sweep-%d.png"%b.ground_combo_step)
	check(matched,"Filled effect preserves matched combo timing, active windows and damage polygons")
	check(emitted and max_samples <= 32,"Actual live visual emits a bounded filled trail")
	check(saved.size() == 3,"All three real combo swings emit the filled treatment")
	check(players[1].live_3d_visual._thread_sweep.contact_age > 0.13,"Whiffs never create illustrative hit bursts")
	check(players[1].live_3d_visual._thread_sweep.samples.is_empty(),"Trail expires after the attack")
	var target = load("res://Src/Components/hurtbox_component.gd").new()
	target.collision_layer = 2
	var target_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60,140)
	target_shape.shape = rect
	target.add_child(target_shape)
	target.position = players[1].position+Vector2(100,-20)
	stage.add_child(target)
	players[1].attack_hitbox.hit_landed.connect(func(_box,_damage): hits += 1)
	await frames(5)
	players[1].start_attack(false)
	var actual_burst := false
	for frame in 60:
		await process_frame
		actual_burst = actual_burst or players[1].live_3d_visual._thread_sweep.contact_age < 0.13
	check(hits > 0 and actual_burst,"Physics overlap confirms a hit and triggers the contact burst")
	Input.action_release("aim_right")
	var report := {"checks":checks,"failures":failures,"max_samples":max_samples,"confirmed_hits":hits,"display":DisplayServer.get_name()}
	FileAccess.open(OUT+"/live-sweep-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LIVE_THREAD_SWEEP ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
