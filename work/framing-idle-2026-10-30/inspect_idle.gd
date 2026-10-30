extends SceneTree
const OUT := "res://tmp/framing-idle"
func _initialize() -> void: call_deferred("run")
func settle(n := 4) -> void:
	for i in n: await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	player.set_physics_process(false)
	await settle(12)
	player.set_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	for animator in player.find_children("*","AnimationPlayer",true,false): animator.pause()
	var data := {"clips":{},"bones":{}}
	for key in [&"idle_1",&"idle_2",&"idle_3",&"idle_4"]:
		visual._play_action(key,&"",0.0,true,1.0,0.0)
		var animation: Animation = visual._animation_player.get_animation(visual._clips[key])
		var frames := []
		for time in [0.2,animation.length*0.5]:
			visual._animation_player.seek(time,true)
			visual._animation_player.advance(0.0)
			visual._animation_player.pause()
			visual._process(0.0)
			await settle()
			var image: Image = visual._viewport.get_texture().get_image()
			var rect := image.get_used_rect()
			image.save_png(OUT+"/%s_%d.png"%[key,frames.size()])
			frames.append({"time":time,"used":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
		data.clips[String(key)]={"length":animation.length,"frames":frames}
	var skeleton: Skeleton3D = visual._skeleton
	for name in ["pelvis","spine_01","spine_02","spine_03","neck_01","head","thigh.L","shin.L","foot.L","thigh.R","shin.R","foot.R"]:
		var bone := skeleton.find_bone(name)
		if bone < 0: continue
		var pose := skeleton.get_bone_pose(bone)
		var rest := skeleton.get_bone_rest(bone)
		data.bones[name]={"pose_euler":str(pose.basis.get_euler()),"rest_euler":str(rest.basis.get_euler()),"pose_origin":str(pose.origin),"rest_origin":str(rest.origin)}
	data.bone_names=[]
	for i in skeleton.get_bone_count(): data.bone_names.append(skeleton.get_bone_name(i))
	FileAccess.open(OUT+"/inspection.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	print("IDLE_INSPECTION ",JSON.stringify(data))
	stage.queue_free()
	await process_frame
	quit()
