extends SceneTree
## Real player/visual and all glove variants; no rope or delayed pose after entry.
const OUT := "res://work/grapple-water-entry-2026-10-27"
var failures: Array[String] = []
var checks := 0
var baseline := false
var samples: Array[Dictionary] = []

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await process_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("WATER_GRAPPLE_FAIL "+message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var water = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	water.points = PackedVector2Array([Vector2(-2000,400),Vector2(2000,400),Vector2(2000,1800),Vector2(-2000,1800)])
	scene.add_child(water)
	water.set_process(false)
	water.monitoring = false
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	scene.add_child(player)
	player.set_physics_process(false)
	player.debug_blue_water_power_unlocked = true
	await frames(10)
	var visual = player.get_node("Live3DVisual")
	for label: String in ["base","blue","red","yellow"]:
		for phase: String in ["firing","attached","retracting"]:
			player.position = Vector2(0,100)
			player._prototype_water_surfaces.clear()
			player.equip_gloves(load("res://Src/Equipment/"+label+"_gloves.tscn"))
			var gloves = player.current_gloves
			gloves.grapple_direction = Vector2(1,-.4).normalized()
			if label=="red": gloves._start_red_grapple_fire()
			else: gloves._start_grapple_fire()
			check(visual._upper_body_overlay_active,label+" "+phase+": real throw owns the upper body before entry")
			if phase=="attached":
				gloves.grapple_state = gloves.GrappleState.ATTACHED
				gloves.grapple_attached = true
				gloves.grapple_attach_position = Vector2(500,100)
				if label=="red": gloves.red_grapple_state = gloves.RedGrappleState.TOWING
				if label=="yellow": gloves._snap_pending = true
			elif phase=="retracting":
				gloves.grapple_state = gloves.GrappleState.RETRACTING
				if label=="red": gloves.red_grapple_state = gloves.RedGrappleState.RETRACTING
			if label=="blue":
				gloves.stored_swing_momentum = 300.0
				gloves._release_jump_buffer_timer = .12
			player.position.y = 700
			player.velocity = Vector2(240,380)
			player.enter_prototype_water(water,400.0)
			gloves.thread_mechanic(1.0/60.0)
			check(gloves.grapple_state==gloves.GrappleState.STOWED,label+" "+phase+": rope cancels immediately")
			check(not gloves.active_grapple_root.visible and gloves.active_rope_line.points.is_empty(),label+" "+phase+": no active rope/needle remains")
			check(not visual._upper_body_overlay_active,label+" "+phase+": casting arm lock clears")
			check(is_zero_approx(gloves.action_anim_lock_timer),label+" "+phase+": equipment action lock clears")
			if label=="blue": check(gloves._release_jump_buffer_timer==0 and gloves.stored_swing_momentum==0,"Blue water entry clears delayed release momentum")
			if label=="red": check(gloves.red_grapple_state==gloves.RedGrappleState.STOWED,"Red water entry clears towing/charge state")
			if label=="yellow": check(not gloves._snap_pending,"Yellow water entry clears pending snap")
			var entry_velocity: Vector2 = player.velocity
			check(entry_velocity.is_equal_approx(Vector2(240,380)),label+" "+phase+": cancellation preserves earned movement velocity")
			Input.action_press("Grapple")
			await frames(1)
			gloves.thread_mechanic(1.0/60.0)
			Input.action_release("Grapple")
			for i in 35:
				gloves.thread_mechanic(1.0/60.0)
				visual.play_gameplay_animation(&"Swim")
				await physics_frame
				await process_frame
			check(gloves.grapple_state==gloves.GrappleState.STOWED,label+" "+phase+": underwater input cannot restart rope")
			check(not visual._upper_body_overlay_active and visual._current_action!=&"casting_2",label+" "+phase+": swimmer remains free of the cast after its old duration")
			samples.append({"gloves":label,"phase":phase,"grapple_state":gloves.grapple_state,"overlay":visual._upper_body_overlay_active,"action":visual._current_action})
			# A fresh dry throw must still work after leaving the water.
			player.position.y = 100
			player._prototype_water_surfaces.clear()
			gloves.thread_mechanic(0.0)
			if label=="red": gloves._start_red_grapple_fire()
			else: gloves._start_grapple_fire()
			check(gloves.grapple_state==gloves.GrappleState.FIRING and visual._upper_body_overlay_active,label+" "+phase+": dry throw still starts after exit")
			visual._finish_upper_body_overlay()
	# Red charge is still stowed in the shared rope enum, so cover it separately.
	player.position.y = 100
	player.equip_gloves(load("res://Src/Equipment/red_gloves.tscn"))
	var red = player.current_gloves
	red._begin_charge()
	red._process_charge(.4)
	player.position.y = 700
	player.enter_prototype_water(water,400.0)
	red.thread_mechanic(1.0/60.0)
	check(red.red_grapple_state==red.RedGrappleState.STOWED and red.charge_percentage==0,"Water entry cancels a charging red grapple before release")
	# Dry pockets remain ordinary dry traversal even inside the lake polygon.
	var pocket = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	pocket.air_pocket = true
	pocket.points = PackedVector2Array([Vector2(-150,550),Vector2(150,550),Vector2(150,850),Vector2(-150,850)])
	scene.add_child(pocket)
	pocket.set_process(false)
	pocket.monitoring = false
	for label: String in ["base","blue","red","yellow"]:
		player.equip_gloves(load("res://Src/Equipment/"+label+"_gloves.tscn"))
		var gloves = player.current_gloves
		if label=="red": gloves._start_red_grapple_fire()
		else: gloves._start_grapple_fire()
		gloves.thread_mechanic(0.0)
		check(not player.is_in_prototype_water() and gloves.grapple_state==gloves.GrappleState.FIRING,label+": dry pocket does not cancel a valid grapple")
		visual._finish_upper_body_overlay()
	var result := {"checks":checks,"failures":failures,"samples":samples,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("WATER_GRAPPLE ",JSON.stringify({"checks":checks,"failures":failures}))
	scene.queue_free()
	await frames(2)
	quit(1 if failures.size() else 0)
