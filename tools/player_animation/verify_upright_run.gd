extends SceneTree
const OUT := "res://work/gameplay-review-followup-2026-10-30"
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
func signature(animation: Animation, lower_only := false) -> int:
	var values := [animation.length]
	for track in animation.get_track_count():
		var path := animation.track_get_path(track)
		if lower_only and path.get_subname_count() == 1 and path.get_subname(0) in [&"spine",&"chest",&"neck",&"head"]:
			continue
		values.append(path)
		for key in animation.track_get_key_count(track):
			values.append(animation.track_get_key_time(track,key))
			values.append(animation.track_get_key_value(track,key))
	return hash(values)
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var players := []
	for strength in [0.0,1.0]:
		var player = load("res://Src/Characters/Player/player.tscn").instantiate()
		player.get_node("Live3DVisual").upright_run_strength = strength
		stage.add_child(player)
		player.set_physics_process(false)
		player.set_process(false)
		players.append(player)
	await frames(3)
	var baseline = players[0].live_3d_visual
	var candidate = players[1].live_3d_visual
	for action: StringName in [&"run_1",&"run_2"]:
		var original: Animation = baseline._animation_player.get_animation(baseline._clips[action])
		var revised: Animation = candidate._animation_player.get_animation(candidate._clips[action])
		check(signature(original,true) == signature(revised,true),"Stride, arms, translations and timing preserved: "+String(action))
		check(signature(original) != signature(revised),"Torso correction installed: "+String(action))
		check(signature(original) == signature(candidate._animation_player.get_animation(action)),"Imported run stays unchanged: "+String(action))
		check(candidate._lower_sampler_player.has_animation(candidate._clips[action]),"Grapple sampler has corrected run: "+String(action))
	for action: StringName in [&"idle_4",&"jump_1",&"slash_2",&"casting_2",&"swimming_1"]:
		check(signature(baseline._animation_player.get_animation(baseline._clips[action])) == signature(candidate._animation_player.get_animation(candidate._clips[action])),"Unrelated selected action preserved: "+String(action))
	for i in players.size():
		var visual = players[i].live_3d_visual
		visual.set_process(false)
		for frame in [0,5,10,15]:
			visual._play_action(&"run_1",&"",0.0,true,1.0,0.0)
			visual._animation_player.seek(frame/30.0,true)
			visual._animation_player.advance(0.0)
			visual._animation_player.pause()
			visual._process(0.0)
			if DisplayServer.get_name() != "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute(OUT)
				visual._viewport.get_texture().get_image().save_png(OUT+"/run_%d_%02d.png"%[i,frame])
	# Enter the real running grapple path; no synthetic animation-map substitute.
	players[1].velocity = Vector2(250,0)
	candidate.set_process(true)
	candidate.play_gameplay_animation(&"Run")
	candidate.play_grapple_throw()
	await frames(4)
	check(candidate._upper_body_overlay_active,"Running grapple overlay starts")
	# Airborne fixture selects jump legs; the installed run sampler was checked above.
	await frames(35)
	check(not candidate._upper_body_overlay_active,"Running grapple overlay finishes")
	var report := {"checks":checks,"failures":failures,"display":DisplayServer.get_name()}
	DirAccess.make_dir_recursive_absolute(OUT)
	FileAccess.open(OUT+"/run-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("UPRIGHT_RUN ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
