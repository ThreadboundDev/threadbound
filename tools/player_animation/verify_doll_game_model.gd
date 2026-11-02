extends SceneTree
## Exercise the fitted local character through the actual player visual pipeline.
const OUT := "res://ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	var visual = player.get_node("Live3DVisual")
	visual.model_scene = load("res://Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb")
	stage.add_child(player)
	await frames(3)
	player.set_physics_process(false)
	player.set_process(false)
	visual.set_process(false)
	check(visual._model_root.find_child("Threadborne_Doll",true,false) != null,"Doll replaces the clothed mesh")
	check(visual._model_root.find_child("Threadborne_Character",true,false) == null,"Old body is absent")
	check(visual._skeleton.get_bone_count()==62,"Game skeleton has 62 bones")
	check(visual._sword_mesh != null,"Original sword is present")
	check(visual._model_root.find_child("Threadborne_Shield_Combined_Test",true,false) != null,"Original shield is present")
	check(visual._lower_sampler_root.find_child("Threadborne_Doll",true,false) != null,"Lower body sampler uses fitted skeleton")
	var source: Node = load("res://Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb").instantiate()
	var source_player := visual._find_first_type(source,"AnimationPlayer") as AnimationPlayer
	var source_skeleton := visual._find_first_type(source,"Skeleton3D") as Skeleton3D
	for clip in source_player.get_animation_list():
		if clip == &"RESET": continue
		check(visual._animation_player.has_animation(clip),"Source clip retained: "+clip)
		if visual._animation_player.has_animation(clip):
			check(absf(source_player.get_animation(clip).length-visual._animation_player.get_animation(clip).length)<.04,"Duration retained: "+clip)
	for index in visual._skeleton.get_bone_count():
		var name = visual._skeleton.get_bone_name(index)
		var donor_index := source_skeleton.find_bone(name)
		check(donor_index >= 0,"Source bone retained: "+name)
		if donor_index >= 0:
			check(visual._skeleton.get_bone_rest(index).basis.is_equal_approx(source_skeleton.get_bone_rest(donor_index).basis),"Rest basis retained: "+name)
	var sample_count := 0
	for clip in visual._animation_player.get_animation_list():
		if clip == &"RESET": continue
		visual._animation_player.play(clip,0)
		for fraction in [0.0,.25,.5,.75,1.0]:
			visual._animation_player.seek(visual._animation_player.get_animation(clip).length*fraction,true)
			visual._animation_player.advance(0)
			var finite := true
			var largest := 0.0
			for index in visual._skeleton.get_bone_count():
				var pose: Transform3D = visual._skeleton.get_bone_global_pose(index)
				finite = finite and pose.is_finite()
				largest = maxf(largest,pose.origin.length())
			check(finite and largest<10,"Bounded pose: %s %.2f" % [clip,fraction])
			var joint_error := 0.0
			for bone_name in ["forearm.L","hand.L","forearm.R","hand.R","shin.L","foot.L","shin.R","foot.R"]:
				var index: int = visual._skeleton.find_bone(bone_name)
				var parent: int = visual._skeleton.get_bone_parent(index)
				var distance: float = visual._skeleton.get_bone_global_pose(index).origin.distance_to(visual._skeleton.get_bone_global_pose(parent).origin)
				joint_error = maxf(joint_error,absf(distance-visual._skeleton.get_bone_rest(index).origin.length()))
			check(joint_error<.002,"Limb joints preserve fitted lengths: %s %.2f" % [clip,fraction])
			sample_count += 1
	visual._animation_player.pause()
	var captures := ["idle_4","run_1","slash_2","block_idle_1","jump_1","swimming_1","air_attack_up","air_attack_down","casting_2"]
	for action in captures:
		visual._play_action(StringName(action),&"",0.0,true,1.0,0.0)
		var clip: StringName = visual._animation_player.current_animation
		visual._animation_player.seek(visual._animation_player.get_animation(clip).length*.35,true)
		visual._animation_player.advance(0)
		visual._animation_player.pause()
		visual._process(0.0)
		check(visual._get_blade_model_points().size()==2,"Bone-attached sword endpoints available: "+action)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			visual._viewport.get_texture().get_image().save_png(OUT+"/game_"+action+".png")
	if DisplayServer.get_name() != "headless":
		visual._play_action(&"idle_4",&"",0.0,true,1.0,0.0)
		visual._animation_player.seek(.2,true)
		visual._animation_player.advance(0)
		visual._animation_player.pause()
		visual._process(0.0)
		for side in ["R","L"]:
			var bone: int = visual._skeleton.find_bone("hand."+side)
			var hand: Vector3 = visual._skeleton.global_transform * visual._skeleton.get_bone_global_pose(bone).origin
			visual._camera.size = .45
			visual._camera.position = hand + Vector3(-3,.4,.7)
			visual._camera.look_at(hand,Vector3.UP)
			await process_frame
			await RenderingServer.frame_post_draw
			visual._viewport.get_texture().get_image().save_png(OUT+"/grip_"+side+".png")
	# Rebased authored tracks must retain each fitted local joint offset.
	var attack: Animation = visual._animation_player.get_animation("authored/air_attack_up")
	for track in attack.get_track_count():
		if attack.track_get_type(track) != Animation.TYPE_POSITION_3D: continue
		var bone: int = visual._skeleton.find_bone(attack.track_get_path(track).get_subname(0))
		if bone < 0 or visual._skeleton.get_bone_name(bone) in [&"root",&"pelvis"]: continue
		check((attack.track_get_key_value(track,0) as Vector3).distance_to(visual._skeleton.get_bone_rest(bone).origin)<.002,"Authored joint offset fitted: "+visual._skeleton.get_bone_name(bone))
	var report := {"checks":checks,"failures":failures,"sampled_poses":sample_count,"display":DisplayServer.get_name()}
	var file := FileAccess.open(OUT+"/godot_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("DOLL_GAME_CHECKS ",JSON.stringify(report))
	source.free()
	stage.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
