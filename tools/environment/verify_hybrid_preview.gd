extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_hybrid_preview.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	assert(room.get_node("StillVillageArt").find_children("*", "CollisionObject2D", true, false).is_empty(), "Art cannot add collisions")
	assert(room.get_node("Geometry/RecoveryFloor").size == Vector2(5120,128))
	assert(room.get_node("StillVillageArt/DashChoiceArt").sprite_frames.resource_path.contains("PetalV2"))
	var stroke := SwordSweepVFX.new()
	root.add_child(stroke)
	var colors: Array[Color] = []
	for facing in [-1,1]:
		var pose := Transform2D(PI if facing < 0 else 0.0, Vector2(400,300))
		var blade := PackedVector2Array([Vector2(400-facing*40,290),Vector2(400-facing*100,290)])
		stroke.set_sweep(.3,195,90,pose,colors,false,blade,1)
		assert((stroke._sprite.global_position.x-400)*facing > 0, "Second stroke stays forward during recovery")
		assert(stroke._sprite.scale.y < stroke._sprite.scale.x*.6, "Second cut is horizontal")
		stroke.set_sweep(.9,195,90,pose,colors,false,blade,1)
		assert(not stroke.visible, "Quick second cut ends before recovery")
		stroke.set_sweep(.3,195,90,pose,colors,false,blade,0)
		var first_size := stroke._sprite.scale.x
		stroke.set_sweep(.3,195,90,pose,colors,false,blade,2)
		assert(stroke._sprite.scale.x > first_size*1.5, "Third hit reads larger than first")
	print("HYBRID PREVIEW AND COMBO VFX: PASS")
	quit()
