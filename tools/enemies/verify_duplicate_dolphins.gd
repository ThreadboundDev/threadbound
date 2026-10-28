extends SceneTree
const SOURCE := "res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn"
const OUT := "res://work/duplicate-dolphins-2026-10-27"
var failures: Array[String] = []
var checks := 0
var samples := {}
var baseline := false

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("DUPLICATE_DOLPHIN_FAIL "+message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func freeze(actor: Node) -> void:
	actor.set_physics_process(false)
	actor.state_machine.set_physics_process(false)

func fish_in_tree() -> Array[Node]:
	var result: Array[Node] = []
	for actor in get_nodes_in_group("swordfish"): result.append(actor)
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var water = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	water.points = PackedVector2Array([Vector2.ZERO,Vector2(4000,0),Vector2(4000,3000),Vector2(0,3000)])
	world.add_child(water)
	# Extract the authored actors without changing their saved relationship.
	var source = load(SOURCE).instantiate()
	var first = source.get_node("TideDuelist")
	var second = source.get_node_or_null("TideDuelist2")
	if second==null: second = first.get_node("TideDuelist")
	var nested: bool = second.get_parent()==first
	var authored_position: Vector2 = first.position+second.position if nested else second.position
	check(authored_position.is_equal_approx(Vector2(349,2008)),"Added dolphin retains its authored world position")
	first.position = Vector2(500,800)
	second.position = Vector2(200,600) if nested else Vector2(700,1400)
	first.owner = null
	second.owner = null
	source.remove_child(first)
	world.add_child(first)
	if not nested:
		source.remove_child(second)
		world.add_child(second)
	source.free()
	freeze(first)
	freeze(second)
	check(second.get_parent()==world,"Dolphins are independent sibling actors")
	var wall := StaticBody2D.new()
	wall.position = Vector2(1100,1400)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(16,300)
	wall.add_child(shape)
	world.add_child(wall)
	await frames(3)
	var before: Vector2 = second.global_position
	check(first._move_in_water(Vector2(600,0)),"Original dolphin advances through its clear lane")
	var inherited_distance: float = second.global_position.distance_to(before)
	check(inherited_distance<.01,"Original dash cannot carry the other dolphin (%.1f px inherited)" % inherited_distance)
	check(second.global_position.x<1043,"Idle duplicate does not pass through its own wall")
	second.global_position = Vector2(700,1400)
	check(not second._move_in_water(Vector2(800,0),true),"Duplicate's own dash stops at solid terrain")
	check(second.global_position.x<1043,"Duplicate remains on the near side of its wall")
	var at_wall: Vector2 = second.global_position
	first.die()
	await frames(42)
	check(second.is_visible_in_tree() and not second.is_dead,"Original death/hiding does not hide or kill the other dolphin")
	first.reset_for_save_point()
	freeze(first)
	check(second.global_position.distance_to(at_wall)<.01,"Resetting the original cannot move the other dolphin")
	second.reset_for_save_point()
	freeze(second)
	check(second.global_position.is_equal_approx(second.home_position),"Duplicate resets to its own home")
	check(first.global_position.is_equal_approx(first.home_position),"Duplicate reset preserves original home")
	check(not is_equal_approx(first.fish_visual._phase_offset,second.fish_visual._phase_offset),"Existing living-motion phases remain independent")
	var targets: Array[CharacterBody2D] = []
	for point: Vector2 in [Vector2(500,100),Vector2(700,2150)]:
		var target := CharacterBody2D.new()
		target.add_to_group("player")
		target.position = point
		var target_shape := CollisionShape2D.new()
		target_shape.shape = CircleShape2D.new()
		target_shape.shape.radius = 20
		target.add_child(target_shape)
		world.add_child(target)
		targets.append(target)
	await frames(5)
	check(first.target==targets[0],"Original independently detects its nearby target")
	check(second.target==targets[1],"Duplicate independently detects a different nearby target")
	first.begin_attack()
	second.begin_attack()
	check(first.dash_direction.dot(second.dash_direction)<-.99,"Independent targets produce independent committed dash directions")
	first.end_attack()
	check(second.attack_phase==&"windup","Ending original attack does not end duplicate attack")
	samples = {"authored_position":str(authored_position),"inherited_motion_pixels":inherited_distance,"duplicate_wall_stop":str(at_wall)}
	world.queue_free()
	await frames(3)
	# Exercise the actual F2 snapshot/reset path, including the comparison art.
	var room = load(SOURCE).instantiate()
	root.add_child(room)
	current_scene = room
	room.get_node("LakesideArtStage").render_scale = .5
	room.get_node("Player").set_physics_process(false)
	for actor in get_nodes_in_group("enemies"): actor.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(25)
	for cycle in 2:
		var event := InputEventKey.new()
		event.keycode = KEY_F2
		event.pressed = true
		room._unhandled_key_input(event)
		await frames(25)
		for actor in get_nodes_in_group("enemies"): actor.process_mode = Node.PROCESS_MODE_DISABLED
		var fish := fish_in_tree()
		check(fish.size()==2,"F2 restores exactly two dolphins, cycle %d" % cycle)
		for actor in fish:
			check(actor.get_parent()==room,"F2 keeps dolphin as a room sibling")
			var home := Vector2(624,823) if actor.name==&"TideDuelist" else Vector2(349,2008)
			check(actor.global_position.distance_to(home)<.01,"F2 preserves each authored dolphin position")
		var art = room.get_node("ArtComparison")
		art._scan_actors()
		art._process(0.0)
		var models := 0
		for entry: Dictionary in art.actors:
			if is_instance_valid(entry.enemy) and entry.key=="tide_duelist" and entry.original.visible and not entry.painted.visible: models += 1
		check(models==2,"F2 retains the selected 3D art on both dolphins")
	var result := {"checks":checks,"failures":failures,"samples":samples}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("DUPLICATE_DOLPHINS ",JSON.stringify(result))
	room.queue_free()
	await frames(2)
	quit(1 if failures.size() else 0)
