extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var p = room.get_node("Player")
	p.set_physics_process(false)
	p.set_process(false)
	var lake = room.get_node("Volumes/Lake")
	var pocket = room.get_node("Volumes/AirPocket")
	# Stable authoring fixture: the designer's live room layout changes frequently.
	lake.position = Vector2.ZERO
	lake.points = PackedVector2Array([Vector2(256,448), Vector2(2200,448), Vector2(2200,1500), Vector2(0,1500), Vector2(0,640), Vector2(256,640)])
	pocket.position = Vector2.ZERO
	pocket.points = PackedVector2Array([Vector2(1500,900), Vector2(1800,900), Vector2(1800,1200), Vector2(1500,1200)])
	assert(lake.contains_global_point(Vector2(800,800)))
	assert(not lake.contains_global_point(Vector2(200,500)), "Concave notch stays dry")
	p.position = Vector2(800,800)
	p.velocity = Vector2.ZERO
	p.enter_prototype_water(lake,448)
	assert(p.velocity == Vector2.ZERO, "Entry must not force minimum drift")
	for i in 60:
		p._process_prototype_swim_movement(1.0/60,1.0)
	assert(absf(p.velocity.x-480) < 1, "Cruise is controllable")
	for i in 20:
		p._process_prototype_swim_movement(1.0/60,0.0)
	assert(p.velocity.length() < 1, "Release input brakes to rest")
	p.velocity = Vector2(480,0)
	for i in 20:
		p._process_prototype_swim_movement(1.0/60,-1.0)
	assert(p.velocity.x < 0, "Reversal responds without a broad turning circle")
	p.position = Vector2(1568,1024)
	assert(not p.is_in_prototype_water(), "Air pocket overrides enclosing water")
	p.position = Vector2(800,800)
	assert(p.is_in_prototype_water(), "Leaving pocket resumes swimming")
	p.velocity = Vector2(0,-100)
	p.exit_prototype_water(lake)
	assert(p.velocity == Vector2(0,-100), "Slow exits do not force a launch")
	p.enter_prototype_water(lake,448)
	p.velocity = Vector2(0,-1100)
	p.exit_prototype_water(lake)
	assert(p.velocity.y < -1100, "Fast upward exits preserve earned momentum")
	var adjacent = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	root.add_child(adjacent)
	adjacent.position = p.position
	p.enter_prototype_water(lake,448)
	p.velocity = Vector2(0,-1100)
	p.exit_prototype_water(lake)
	assert(p.velocity.y == -1100, "Crossing overlapping water pieces must not add a breach boost")
	adjacent.free()
	var packed := PackedScene.new()
	assert(packed.pack(lake) == OK)
	var restored = packed.instantiate()
	assert(restored.points == lake.points, "Drawn shape survives packing and reopening")
	restored.free()
	var rect = load("res://Src/Environment/Greybox/greybox_water.tscn")
	var a = rect.instantiate()
	var b = rect.instantiate()
	root.add_child(a)
	root.add_child(b)
	a.size = Vector2(100,200)
	b.size = Vector2(700,800)
	assert(a.get_node("CollisionShape2D").shape.size == Vector2(100,200))
	pocket.position += Vector2(100,0)
	assert(pocket.contains_global_point(Vector2(1668,1024)))
	print("LAKE AUTHORING: PASS")
	quit()
