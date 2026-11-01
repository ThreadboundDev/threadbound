extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func floor_body(y: float, one_way: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(600,20)
	shape.position.y = y
	shape.one_way_collision = one_way
	body.add_child(shape)
	root.add_child(body)
	return body
func settle(player: CharacterBody2D, at: Vector2) -> void:
	player.position = at
	for i in 12:
		await physics_frame
		player.velocity = Vector2(0,100)
		player.move_and_slide()
func run() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	scene.add_child(player)
	player.set_physics_process(false)
	var rock := floor_body(100,false)
	await settle(player,Vector2(0,10))
	var mask: int = player.collision_mask
	var start: Vector2 = player.position
	for i in 20: check(not player._begin_one_way_drop(),"Solid rock rejects drop %d"%i)
	check(player.position.distance_to(start)<.01 and player.collision_mask==mask,"Repeated drops do not nudge through solid rock or change terrain mask")
	rock.queue_free()
	await physics_frame
	var platform := floor_body(100,true)
	var lower := floor_body(140,false)
	await settle(player,Vector2(0,10))
	check(player.is_on_floor(),"Player stands on actual one-way platform")
	check(player._begin_one_way_drop(),"Actual one-way floor accepts drop")
	check(player.collision_mask==mask,"Drop preserves every collision mask bit")
	for i in 30:
		await physics_frame
		player._process_one_way_drop_input(1.0/60.0)
		player.velocity=Vector2(0,240)
		player.move_and_slide()
	check(player.is_on_floor() and player.position.y<80,"Solid rock below catches dropped player")
	check(not player._has_solid_overlap(player.position),"Drop never leaves body embedded in lower rock")
	check(player._one_way_drop_exceptions.is_empty(),"Platform exception expires")
	player._recent_clear_positions.clear()
	player._collision_guard_position=Vector2.INF
	player.position=Vector2(0,-50)
	player._update_collision_recovery()
	var safe: Vector2=player.position
	player.position=Vector2(0,140)
	check(player._has_solid_overlap(player.position),"Fixture reproduces deep solid overlap")
	player._update_collision_recovery()
	check(player.position==safe and player.velocity==Vector2.ZERO,"Overlap returns to recent verified clear position")
	player.add_collision_exception_with(lower)
	player.position=Vector2(0,140)
	check(not player._has_solid_overlap(player.position),"Intentional house-style collision exceptions remain excluded from recovery query")
	player.remove_collision_exception_with(lower)
	check(player._has_solid_overlap(player.position),"Removing the exception restores ordinary overlap detection")
	print("SAFE_PLATFORM_DROP ",JSON.stringify({"checks":checks,"failures":failures}))
	DirAccess.make_dir_recursive_absolute("res://work/oct31-feedback")
	FileAccess.open("res://work/oct31-feedback/collision-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	scene.queue_free(); platform.queue_free(); lower.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
