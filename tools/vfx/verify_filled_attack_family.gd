extends SceneTree
const OUT := "res://work/overnight-playtest-2026-10-30"
var checks := 0
var failures: Array[String] = []
var player
var visual
var cases := []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"/vfx_"+label+".png")
func reset() -> void:
	player._cancel_attack_for_dash()
	player.attack_cooldown_timer = 0
	player.refill_action_points()
	visual._thread_sweep.clear_trail()
func run() -> void:
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2(-5000,-5000),Vector2(5000,-5000),Vector2(5000,5000),Vector2(-5000,5000)])
	background.color = Color("203b49")
	background.z_index = -100
	stage.add_child(background)
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(5000,40)
	collision.shape = shape
	floor_body.position.y = 200
	floor_body.add_child(collision)
	stage.add_child(floor_body)
	player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	visual = player.live_3d_visual
	var camera := Camera2D.new()
	camera.position = Vector2(0,20)
	camera.zoom = Vector2(.83,.83)
	stage.add_child(camera)
	camera.make_current()
	await frames(65)
	player.set_physics_process(false)
	player.set_process(false)
	visual.set_process(false)
	for side in [-1,1]:
		for direction in [Vector2.UP,Vector2.DOWN]:
			reset()
			player.last_direction = side
			player._begin_air_double_attack(direction)
			visual._animation_player.play(visual._clips[visual._current_action],0.0)
			visual._animation_player.pause()
			var emitted := false
			var unchanged := true
			var saved := false
			var aligned := false
			for tick in 22:
				visual._animation_player.seek(minf(tick/60.0,visual.get_action_duration(visual._current_action)),true)
				player.update_combat_timers(1.0/60.0)
				var polygon: PackedVector2Array = player.attack_collision_polygon.polygon.duplicate()
				var active: bool = player.attack_hitbox.active
				visual._process(1.0/60.0)
				unchanged = unchanged and polygon == player.attack_collision_polygon.polygon and active == player.attack_hitbox.active
				emitted = emitted or not visual._thread_sweep.thrust.is_empty()
				if not saved and not visual._thread_sweep.thrust.is_empty() and tick >= 4:
					saved = true
					var blade: PackedVector2Array = visual._get_blade_world_points()
					aligned = (blade[1]-blade[0]).normalized().dot(direction) > .80
					await capture(("up" if direction.y<0 else "down")+"_"+str(side))
			check(emitted,"Vertical filled blade treatment emits: "+str(direction)+" facing "+str(side))
			check(unchanged,"Vertical VFX do not modify damage state: "+str(direction)+" facing "+str(side))
			check(aligned,"Filled vertical treatment follows the actual up/down blade direction")
			cases.append({"vertical":str(direction),"facing":side,"emitted":emitted,"damage_unchanged":unchanged})
	var water := Node2D.new()
	stage.add_child(water)
	for wet in [false,true]:
		for spin in [false,true]:
			reset()
			player._prototype_water_surfaces.clear()
			if wet: player._prototype_water_surfaces[water] = -1000.0
			if spin: Input.action_press("move_right")
			player.start_attack(true)
			Input.action_release("move_right")
			check(player.is_attacking and player.current_attack_is_special,"Actual special starts: wet="+str(wet)+" spin="+str(spin))
			visual._animation_player.play(visual._clips[visual._current_action],0.0)
			visual._animation_player.pause()
			var emitted := false
			var rate: float = visual._animation_player.speed_scale
			for tick in 85:
				visual._animation_player.seek(minf(tick/60.0*rate,visual.get_action_duration(visual._current_action)),true)
				player.update_combat_timers(1.0/60.0)
				visual._process(1.0/60.0)
				if spin and visual._sword_sweep.phase > .40 and visual._sword_sweep.phase < .55 and not emitted:
					emitted = true
					await capture("spin_"+("water" if wet else "land"))
				var effect = player._neutral_special_vfx_instance
				if not spin and is_instance_valid(effect):
					effect.set_process(false)
					effect._process(1.0/60.0)
					if effect._impact_started and effect._impact_elapsed > .065 and not emitted:
						emitted = true
						await capture("neutral_"+("water" if wet else "land"))
				if not player.is_attacking: break
			check(emitted,"Filled special treatment reaches its live effect: wet="+str(wet)+" spin="+str(spin))
			check(not player.attack_hitbox.active,"Special hitbox shuts down normally")
	reset()
	player._prototype_water_surfaces.clear()
	visual._play_action(&"idle_4",&"",.2,true,1.0,0.0)
	visual._animation_player.pause()
	visual._process(0)
	var burst = load("res://Src/VFX/grapple_strike_vfx.tscn").instantiate()
	stage.add_child(burst)
	burst.position = player.position+Vector2(100,-50)
	burst.play(Vector2.RIGHT)
	var trail = load("res://Src/VFX/grapple_strike_trail_vfx.tscn").instantiate()
	stage.add_child(trail)
	trail.play(player,Vector2.RIGHT)
	await capture("grapple")
	trail.stop()
	await frames(25)
	check(not is_instance_valid(burst) and not is_instance_valid(trail),"Grapple burst and ribbon expire after release")
	var report := {"checks":checks,"failures":failures,"cases":cases,"display":DisplayServer.get_name()}
	FileAccess.open(OUT+"/vfx-family-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FILLED_ATTACK_FAMILY ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
