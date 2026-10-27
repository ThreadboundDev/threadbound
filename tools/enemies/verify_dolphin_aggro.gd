extends SceneTree
## Exercise real detection signals and attack states at the widened distances.
const OUT := "res://work/dolphin-aggro-2026-10-27"
var failures: Array[String] = []
var checks := 0
var baseline := false

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("DOLPHIN_AGGRO_FAIL "+message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var water = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	water.points = PackedVector2Array([Vector2(-3000,-1500),Vector2(3000,-1500),Vector2(3000,1500),Vector2(-3000,1500)])
	world.add_child(water)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.position = Vector2(1250,0)
	player.collision_layer = 1
	player.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20
	player.add_child(shape)
	world.add_child(player)
	var fish = load("res://Src/Enemies/TideDuelist/tide_duelist.tscn").instantiate()
	world.add_child(fish)
	await frames(5)
	check(is_equal_approx(fish.get_node("DetectionArea/CollisionShape2D").shape.radius,1000.0),"Detection radius is 1000 pixels")
	check(is_equal_approx(fish.attack_range,850.0),"Stationary fish can commit from 850 pixels")
	for direction: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		player.position = direction*1250
		fish.reset_for_save_point()
		await frames(4)
		check(not is_instance_valid(fish.target),"Outside awareness radius: "+str(direction))
		fish._attack_cooldown_timer = 5.0
		player.position = direction*950
		await frames(5)
		check(fish.target==player,"Acquire a clear wet target 950 pixels away: "+str(direction))
		check(fish.attack_phase==&"" and fish.position.length()<.1,"Awareness band remains a stationary tell")
		player.position = direction*1250
		await frames(4)
		check(not is_instance_valid(fish.target),"Leaving the enlarged detector releases the target")
		fish.reset_for_save_point()
		player.position = direction*800
		await frames(5)
		check(fish.attack_phase==&"windup","Commit from 800 pixels after acquisition: "+str(direction))
		check(not fish.attack_hitbox.active,"Long-range windup remains harmless")
		player.position = direction*1250
		fish.reset_for_save_point()
	var wall := StaticBody2D.new()
	wall.position = Vector2(400,0)
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(16,2000)
	wall.add_child(wall_shape)
	world.add_child(wall)
	player.position = Vector2(800,0)
	await frames(5)
	check(not is_instance_valid(fish.target) and not fish.is_player_in_attack_range(),"Longer aggro cannot acquire through a solid wall")
	wall.queue_free()
	await frames(3)
	player.position = Vector2(1250,0)
	fish.reset_for_save_point()
	var pocket = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	pocket.air_pocket = true
	pocket.points = PackedVector2Array([Vector2(390,-300),Vector2(396,-300),Vector2(396,300),Vector2(390,300)])
	world.add_child(pocket)
	player.position = Vector2(800,0)
	await frames(5)
	check(not is_instance_valid(fish.target),"Longer aggro cannot acquire across a six-pixel dry seam")
	check(is_equal_approx(fish.dash_speed,1050.0) and fish.stats.attack_damage==18 and is_equal_approx(fish.stats.attack_windup,.733333),"Damage, speed and windup are unchanged")
	for scene_path: String in ["res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn","res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn"]:
		var authored = load(scene_path).instantiate()
		for node: Node in authored.find_children("*","CharacterBody2D",true,false):
			if node.get_script()==fish.get_script():
				check(is_equal_approx(node.attack_range,850.0),"Authored dolphin keeps the wider trigger: "+scene_path+":"+String(node.name))
		authored.free()
	var result := {"checks":checks,"failures":failures,"detection_radius":fish.get_node("DetectionArea/CollisionShape2D").shape.radius,"attack_range":fish.attack_range}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("DOLPHIN_AGGRO ",JSON.stringify(result))
	world.queue_free()
	await frames(2)
	quit(1 if failures.size() else 0)
