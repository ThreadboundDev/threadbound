extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(world)
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	for i in range(40): await physics_frame
	var boss = world.boss
	print("BOSS ",boss.global_position," MODEL ",boss.model.position," SCALE ",boss.model.scale," SKEL ",boss.skeleton.global_transform)
	for name in ["root","pelvis","head","foot_l","foot_r","lowerarm_l"]:
		var id:int=boss.skeleton.find_bone(name)
		if id>=0: print(name," REST ",boss.skeleton.get_bone_global_rest(id)," POSE ",boss.skeleton.get_bone_global_pose(id)," GLOBAL ",boss.skeleton.to_global(boss.skeleton.get_bone_global_pose(id).origin))
	for m in boss.model.find_children("*","MeshInstance3D",true,false): print("MESH ",m.name," ",m.get_aabb()," world ",m.global_transform)
	world.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	quit()
