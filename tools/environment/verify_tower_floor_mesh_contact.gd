extends SceneTree
## Compare physical floors directly with the installed model's deck vertices.
var checks := 0
var failures: Array[String] = []
const OUT := "res://work/lakeside-playtest-2026-10-26"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for i in 25: await physics_frame
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var tower: Node2D = room.get_node("Buildings/Tower")
	var mesh: MeshInstance3D = tower.render_model.find_child("03_Interior_Platforms__walnut",true,false)
	var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var player: CharacterBody2D = room.get_node("Player")
	player.set_physics_process(false)
	var nominal := [6.35,8.24,8.98,11.48,14.30,17.0,19.65,23.0,26.65]
	var measured: Array[Dictionary] = []
	for index in 9:
		var peak := -INF
		for vertex: Vector3 in vertices:
			if vertex.y > nominal[index]-0.5 and vertex.y < nominal[index]+0.01:
				peak = maxf(peak,vertex.y)
		var visible_y := -mesh.to_global(Vector3(0,peak,0)).y*128.0
		var body: StaticBody2D = room.get_node("Geometry/BuildingCollision/TowerPlatform"+str(index))
		var outline: CollisionPolygon2D = body.get_node("Outline")
		var physical_y := outline.to_global(outline.polygon[0]).y
		# Godot's imported vertex compression differs from raw GLB by <0.04 px.
		check(absf(visible_y-physical_y)<0.1,"Platform %d collider matches installed deck vertices" % index)
		player.position = Vector2(body.position.x,physical_y-player._get_player_collision_bottom_offset()-20)
		player.reset_physics_interpolation()
		await physics_frame
		var hit := player.move_and_collide(Vector2(0,40))
		check(hit != null and hit.get_collider()==body,"Actual player sweep lands on aligned platform %d" % index)
		measured.append({"platform":index,"mesh_top_y":visible_y,"collision_top_y":physical_y})
	if DisplayServer.get_name() != "headless":
		room.get_node("Player/Camera2D").enabled = false
		room.get_node("OverviewCamera").enabled = false
		var camera := Camera2D.new()
		camera.position = Vector2(1472,-720)
		camera.zoom = Vector2.ONE*1.3
		room.add_child(camera)
		camera.make_current()
		for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false): ui.visible = false
		player.position = Vector2(1472,room.get_node("Geometry/BuildingCollision/TowerPlatform6").position.y-6-player._get_player_collision_bottom_offset()-20)
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		player.set_physics_process(true)
		for i in 40: await physics_frame
		await RenderingServer.frame_post_draw
		check(player.is_on_floor(),"Live player settles on the aligned visible deck")
		check(root.get_texture().get_image().save_png(OUT.path_join("tower_floor_contact.png"))==OK,"Save actual in-room contact")
	var result := {"checks":checks,"failures":failures,"floors":measured,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("tower_floor_contact.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("TOWER_FLOOR_MESH_CONTACT ",JSON.stringify(result))
	room.queue_free()
	await process_frame
	quit(1 if failures.size() else 0)
