extends SceneTree
const OUT := "res://work/lakeside-entry-focus-2026-10-26"
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("TOWER_ENTRY_FAIL "+message)
func _initialize() -> void:
	call_deferred("run")
func settle(count := 10) -> void:
	for i in count: await physics_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	check(root.get_texture().get_image().save_png(OUT.path_join(label+".png"))==OK,"Save "+label)
	captures.append(label)
func magenta_count(image: Image, bounds: Rect2i) -> int:
	var count := 0
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var pixel := image.get_pixel(x,y)
			if pixel.r>.5 and pixel.b>.5 and pixel.g<.3: count += 1
	return count
func run() -> void:
	var room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await settle(25)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false): ui.visible = false
	var player: CharacterBody2D = room.get_node("Player")
	player.set_physics_process(false)
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	var camera := Camera2D.new()
	camera.position = Vector2(1472,1830)
	camera.zoom = Vector2.ONE*1.4
	room.add_child(camera)
	camera.make_current()
	var tower: Node2D = room.get_node("Buildings/Tower")
	var model: Node3D = tower.render_model
	var rim := model.find_child("Entry_Foreground_Always",true,false) as MeshInstance3D
	check(is_instance_valid(rim) and rim.layers==2,"Front basin stone is in the foreground pass")
	var rear := model.find_child("05_Open_Bottom_Basin__slate",true,false) as MeshInstance3D
	check(rear.layers==1,"Rear basin stone remains behind the swimmer")
	check(tower.find_children("*","CollisionObject2D",true,false).size()==1,"Existing cutaway sensor is the only tower-owned collision object")
	var start := player.global_transform
	start.origin = Vector2(1472,2010)
	var motion_hit := KinematicCollision2D.new()
	var motion_blocked := player.test_move(start,Vector2(0,-380),motion_hit)
	var gate = room.get_node("Volumes/BreakableWall")
	check(motion_blocked and motion_hit.get_collider()==gate,"Existing authored breakable still blocks the uncleared entrance")
	var fish = room.get_node("TideDuelist")
	var required: int = gate.hits_to_break
	for strike in required:
		fish.begin_attack()
		fish.activate_attack_hitbox()
		fish.attack_hitbox.enable()
		var fractured: bool = gate.fracture_from_swordfish(fish)
		check(fractured == (strike==required-1),"Existing swordfish strike opens the authored gate at its required hit count")
		fish.end_attack()
	await settle(120)
	check(not player.test_move(start,Vector2(0,-380)),"Real player shape swims upward through the cleared entrance; no new rim collision")
	player.global_position = Vector2(1472,2050)
	player.velocity = Vector2.ZERO
	player.play_character_anim("Swim_Idle")
	player.reset_physics_interpolation()
	await settle()
	check(not model.is_cutaway and rim.visible,"Approach from below retains facade and front stone")
	await capture("tower_below_approach")
	player.global_position = Vector2(1472,1875)
	player.reset_physics_interpolation()
	await settle()
	check(model.is_cutaway and rim.is_visible_in_tree(),"Crossing behind the rim reveals interior while keeping the front stone")
	await capture("tower_behind_rim")
	var blocked := -1
	var exposed := -1
	if DisplayServer.get_name()!="headless":
		var display: Sprite2D = player.get_node("Live3DVisual")._display
		var saved := display.material
		var mask := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){COLOR=vec4(1.,0.,1.,texture(TEXTURE,UV).a);}"
		mask.shader = shader
		display.material = mask
		var canvas := root.get_canvas_transform()
		var a := canvas*Vector2(875,1818)
		var b := canvas*Vector2(2070,1920)
		var bounds := Rect2i(Vector2i(a),Vector2i(b-a))
		rim.visible = false
		await settle(3)
		exposed = magenta_count(root.get_texture().get_image(),bounds)
		rim.visible = true
		await settle(3)
		blocked = magenta_count(root.get_texture().get_image(),bounds)
		check(exposed>300 and blocked<exposed/5,"Rendered front stone occludes the actual player silhouette in its footprint")
		display.material = saved
	player.global_position = Vector2(1472,1690)
	player.reset_physics_interpolation()
	await settle()
	check(model.is_cutaway and rim.layers==2 and rear.layers==1,"Interior keeps independent front/rear basin depths")
	await capture("tower_swim_inside")
	var report := {"checks":checks,"failures":failures,"captures":captures,"exposed_player_pixels":exposed,"occluded_player_pixels_remaining":blocked,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("tower_rim_render.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("TOWER_ENTRY_FOREGROUND ",JSON.stringify(report))
	room.queue_free()
	await settle(2)
	quit(1 if failures.size() else 0)
