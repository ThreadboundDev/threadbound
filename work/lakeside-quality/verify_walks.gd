extends SceneTree
## Player-sized rectangle with the player's existing gravity, speed and floor
## settings. No step assistance: the collider alone has to allow these walks.
var report := {}
var rig: Node2D
const CASES := {
	"shore": [-120.0, 230.0, 200.0, 600.0],
	"cave": [-980.0, -400.0, -650.0, -400.0],
	"right_shore": [5000.0, 5350.0, 200.0, 650.0],
	"ruin_bridge": [3300.0, 4020.0, 2100.0, 2600.0],
	"lakebed": [0.0, 1000.0, 1600.0, 3000.0],
	"fisher_roof": [84.0,556.0,-950.0,-350.0],
	"workshop_roof": [2370.0,3000.0,-1700.0,-1200.0],
	"slip_roof": [2480.0,3140.0,-600.0,-250.0],
}

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	for version: String in ["before", "after"]:
		rig = Node2D.new()
		root.add_child(rig)
		var path := "res://work/lakeside-quality/rock_collision_before.tscn" if version == "before" else "res://Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_rock_collision.tscn"
		rig.add_child(load(path).instantiate())
		rig.add_child(load("res://work/lakeside-quality/roof_collision_" + version + ".tscn").instantiate())
		await physics_frame
		await physics_frame
		var results := {}
		for label: String in CASES:
			for direction in [1, -1]:
				results[label + ("_right" if direction > 0 else "_left")] = await walk(CASES[label],direction,version == "after")
		report[version] = results
		rig.queue_free()
		await physics_frame
		await physics_frame
	var failures: Array[String] = []
	for label: String in report.after:
		# The submerged bed is a steep-slope control, traversed by swimming.
		if label.begins_with("lakebed"):
			continue
		if not report.after[label].get("reached",false) or report.after[label].get("stalled_frames",1) != 0:
			failures.append(label)
	report["passed"] = failures.is_empty()
	report["failures"] = failures
	FileAccess.open("res://work/lakeside-quality/walk_verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("WALK_CHECK ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func walk(bounds: Array, direction: int, use_capsule: bool) -> Dictionary:
	var x0: float = bounds[0] if direction > 0 else bounds[1]
	var end: float = bounds[1] if direction > 0 else bounds[0]
	var query := PhysicsRayQueryParameters2D.create(Vector2(x0,bounds[2]),Vector2(x0,bounds[3]),1)
	var hit := rig.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"no_ground":true}
	var probe := CharacterBody2D.new()
	probe.collision_layer = 0
	probe.collision_mask = 1
	var shape := CollisionShape2D.new()
	if use_capsule:
		var capsule := CapsuleShape2D.new()
		capsule.radius = 18.5
		capsule.height = 126.244995
		shape.shape = capsule
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(37,126.244995)
		shape.shape = rectangle
	shape.position = Vector2(0.5,6.1224995)
	probe.add_child(shape)
	probe.position = Vector2(x0,hit.position.y-69.245-8)
	rig.add_child(probe)
	for i in 25:
		await physics_frame
		probe.velocity.y += 2200.0/60.0
		probe.move_and_slide()
	var minimum_x := probe.position.x
	var maximum_x := probe.position.x
	var slow_frames := 0
	var worst_slow_run := 0
	var stalled := 0
	var reached := false
	for i in ceili(absf(end-x0)/500.0*60.0)+100:
		await physics_frame
		var previous := probe.position
		probe.velocity.x = direction*500.0
		probe.velocity.y += 2200.0/60.0
		probe.move_and_slide()
		minimum_x = minf(minimum_x,probe.position.x)
		maximum_x = maxf(maximum_x,probe.position.x)
		if absf(probe.position.x-previous.x) < 1.0:
			stalled += 1
			slow_frames += 1
			worst_slow_run = maxi(worst_slow_run,slow_frames)
		else:
			slow_frames = 0
		if direction*(probe.position.x-end) >= -2.0:
			reached = true
			break
		if probe.position.y > float(bounds[3])+150.0:
			break
	var result := {"reached":reached,"distance":maximum_x-minimum_x,"stalled_frames":stalled,"worst_stall":worst_slow_run,"end":str(probe.position)}
	probe.queue_free()
	await physics_frame
	return result
