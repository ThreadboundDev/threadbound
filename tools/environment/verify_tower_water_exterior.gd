extends SceneTree
const OUT := "res://work/tower-water-exterior-2026-10-27"
var failures: Array[String] = []
var checks := 0
var baseline := false
var samples := {}

class CutawayOwner extends Node2D:
	var open := false
	func is_cutaway_open() -> bool: return open

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	root.content_scale_size = Vector2i(960,540)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("TOWER_WATER_FAIL "+message)

func frames(count := 5) -> void:
	for i in count: await physics_frame

func rectangle(bounds: Rect2, color: Color, depth: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	node.color = color
	node.z_index = depth
	return node

func image_at(view: Viewport) -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func save(image: Image, label: String) -> void:
	check(image.save_png(OUT.path_join(("before_" if baseline else "after_")+label+".png"))==OK,"Save "+label)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Tower exterior pixel checks require a GPU")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	var view := SubViewport.new()
	view.size = Vector2i(512,512)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(rectangle(Rect2(0,0,512,512),Color(.02,.08,.12),-30))
	view.add_child(rectangle(Rect2(50,180,80,240),Color.WHITE,-10))
	view.add_child(rectangle(Rect2(210,100,50,100),Color.WHITE,-10))
	var facade := rectangle(Rect2(300,180,80,240),Color.WHITE,10)
	var facade_material := ShaderMaterial.new()
	facade_material.shader = load("res://Src/Environment/BlueBiome/Water/submerged_facade.gdshader")
	facade.material = facade_material
	view.add_child(facade)
	var owner := CutawayOwner.new()
	owner.name = "TowerOwner"
	view.add_child(owner)
	var lake = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	lake.lake_presentation = true
	lake.points = PackedVector2Array([Vector2(0,-400),Vector2(512,-400),Vector2(512,512),Vector2(0,512)])
	view.add_child(lake)
	var pocket = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	pocket.air_pocket = true
	pocket.lake_presentation = true
	pocket.pocket_caustic_intensity = 0.0
	pocket.points = PackedVector2Array([Vector2(20,100),Vector2(180,100),Vector2(180,450),Vector2(20,450)])
	view.add_child(pocket)
	var linked: bool = pocket.has_method("is_presentation_active")
	check(linked,"Air pocket supports an independently linked presentation owner")
	if linked: pocket.presentation_owner_path = NodePath("../TowerOwner")
	var other = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	other.air_pocket = true
	other.lake_presentation = true
	other.pocket_caustic_intensity = 0.0
	other.points = PackedVector2Array([Vector2(200,90),Vector2(270,90),Vector2(270,210),Vector2(200,210)])
	view.add_child(other)
	var boundary: PackedVector2Array = lake.points.duplicate()
	boundary.resize(256)
	facade_material.set_shader_parameter("lake_points",boundary)
	facade_material.set_shader_parameter("lake_count",4)
	facade_material.set_shader_parameter("surface_y",-400.0)
	facade_material.set_shader_parameter("water_opacity",lake.water_color.a)
	facade_material.set_shader_parameter("immersion_opacity",lake.immersion_opacity)
	await frames()
	lake._update_water_preview(0.0)
	pocket._update_water_preview(0.0)
	var closed := await image_at(view)
	var wet := closed.get_pixel(90,300)
	var front := closed.get_pixel(340,300)
	check(int(lake._fill.material.get_shader_parameter("pocket_count"))==1,"Closed tower excludes only its own visual dry mask")
	check(not pocket._fill.visible,"Closed tower has no dry-pocket caustic overlay")
	check(wet.b-wet.r>.08 and wet.r<.87,"Water continues across the closed tower pocket")
	check(absf(front.r-wet.r)<.025 and absf(front.g-wet.g)<.025 and absf(front.b-wet.b)<.025,"Foreground facade shares the surrounding underwater grade")
	check(closed.get_pixel(235,150).r>.99,"Unlinked dry pocket remains clear while tower is closed")
	save(closed,"fixture_closed")
	owner.open = true
	lake._update_water_preview(0.0)
	pocket._update_water_preview(0.0)
	var opened := await image_at(view)
	check(int(lake._fill.material.get_shader_parameter("pocket_count"))==2,"Open tower restores its visual dry mask")
	check(pocket._fill.visible,"Open interior can show its pocket presentation")
	var dry := opened.get_pixel(90,300)
	check(dry.r>.99 and dry.g>.99 and dry.b>.99,"Open tower interior is dry and clear")
	check(opened.get_pixel(235,150).r>.99,"Other dry pocket remains unchanged while tower is open")
	check(pocket.contains_global_point(Vector2(90,300)),"Physical air-pocket geometry remains present in both reveal states")
	samples = {"closed_rear":str(wet),"closed_facade":str(front),"open_interior":str(dry)}
	save(opened,"fixture_open")
	view.queue_free()
	await frames(3)
	await inspect_room()
	var result := {"checks":checks,"failures":failures,"samples":samples,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("TOWER_WATER_EXTERIOR ",JSON.stringify(result))
	quit(1 if failures.size() else 0)

func inspect_room() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	room.get_node("LakesideArtStage").render_scale = 1.0
	var art = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.gd").new()
	room.add_child(art)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var player: CharacterBody2D = room.get_node("Player")
	player.set_physics_process(false)
	player.get_node("Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	var camera := Camera2D.new()
	room.add_child(camera)
	camera.make_current()
	await frames(25)
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false): ui.visible = false
	var lake = room.get_node("Volumes/Lake")
	var pocket = room.get_node("Volumes/AirPocket")
	var tower = room.get_node("Buildings/Tower")
	var rim: MeshInstance3D = tower.render_model.find_child("Entry_Foreground_Always",true,false)
	check(pocket.has_method("is_presentation_active") and not pocket.get("presentation_owner_path").is_empty(),"Authored tower pocket links its presentation to the tower")
	var signature: Array = []
	for shape: CollisionPolygon2D in room.get_node("Geometry/BuildingCollision").find_children("*","CollisionPolygon2D",true,false):
		signature.append([str(shape.get_path()),shape.polygon,shape.global_transform])
	samples["building_collision_signature"] = hash(var_to_str(signature))
	samples["physical_pocket_points"] = str(pocket.points)
	if not baseline and FileAccess.file_exists(OUT.path_join("before.json")):
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("before.json")))
		check(int(previous.samples.building_collision_signature)==samples.building_collision_signature,"Building collision geometry matches the captured baseline")
		check(previous.samples.physical_pocket_points==samples.physical_pocket_points,"Physical tower pocket polygon matches the captured baseline")
	player.position = Vector2(900,1450)
	player.play_character_anim("Swim_Idle")
	camera.position = Vector2(1160,1350)
	camera.zoom = Vector2.ONE*.9
	await frames()
	lake._update_water_preview(0.0)
	pocket._update_water_preview(0.0)
	check(not tower.render_model.is_cutaway,"Exterior inspection keeps the facade closed")
	check(int(lake._fill.material.get_shader_parameter("pocket_count"))==2,"Closed exterior leaves only the two unrelated visual air pockets")
	check(player.is_in_prototype_water(),"Exterior swimmer remains physically wet")
	save(await image_at(root),"left_exterior")
	player.position = Vector2(1472,2050)
	player.reset_physics_interpolation()
	camera.position = Vector2(1472,1830)
	camera.zoom = Vector2.ONE*1.15
	await frames()
	check(not tower.render_model.is_cutaway and rim.is_visible_in_tree(),"Approach below retains the front facade and stone")
	save(await image_at(root),"below_approach")
	player.position = Vector2(1472,1875)
	player.reset_physics_interpolation()
	await frames()
	check(tower.render_model.is_cutaway and rim.layers==2,"Behind the rim reveals interior without removing foreground stone")
	var display: Sprite2D = player.get_node("Live3DVisual")._display
	var original := display.material
	var mask := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){COLOR=vec4(1.,0.,1.,texture(TEXTURE,UV).a);}"
	mask.shader = shader
	display.material = mask
	# DisplaySettings may resize the physical window after startup. Include its
	# stretch when mapping world-space rim bounds into captured texture pixels.
	var canvas := root.get_stretch_transform()*root.get_canvas_transform()
	var a := canvas*Vector2(875,1818)
	var b := canvas*Vector2(2070,1920)
	var bounds := Rect2i(Vector2i(a),Vector2i(b-a))
	rim.visible = false
	var exposed := magenta_count(await image_at(root),bounds)
	rim.visible = true
	var hidden := magenta_count(await image_at(root),bounds)
	check(exposed>50 and hidden<exposed/5,"Wet front stone still occludes the swimmer at the entrance")
	samples["rim_exposed_pixels"] = exposed
	samples["rim_remaining_pixels"] = hidden
	display.material = original
	player.position = Vector2(1472,1400)
	player.reset_physics_interpolation()
	camera.position = Vector2(1472,1400)
	camera.zoom = Vector2.ONE*.8
	await frames()
	lake._update_water_preview(0.0)
	pocket._update_water_preview(0.0)
	check(tower.render_model.is_cutaway and not player.is_in_prototype_water(),"Actual interior reveals and retains physical dry traversal")
	check(int(lake._fill.material.get_shader_parameter("pocket_count"))==3,"Open interior restores all three visual dry pockets")
	check(rim.is_visible_in_tree(),"Interior retains its wet foreground stone rim")
	check(is_equal_approx(lake.get_surface_global_y(),411),"Shared waterline remains y=411")
	save(await image_at(root),"dry_interior")
	var floor_shape: CollisionPolygon2D = room.get_node("Geometry/BuildingCollision/TowerPlatform0/Outline")
	var floor_y := INF
	for point: Vector2 in floor_shape.polygon: floor_y = minf(floor_y,floor_shape.to_global(point).y)
	player.position = Vector2(1472,floor_y-player._get_player_collision_bottom_offset()-.1)
	player.velocity = Vector2(0,10)
	player.move_and_slide()
	player.velocity = Vector2.ZERO
	player.play_character_anim("Idle")
	player.reset_physics_interpolation()
	camera.position = Vector2(1472,floor_y-160)
	await frames()
	check(player.is_on_floor() and not player.is_in_prototype_water(),"Real player stands dry on the existing submerged tower platform")
	save(await image_at(root),"dry_platform")
	player.position = Vector2(900,1450)
	player.reset_physics_interpolation()
	await frames()
	lake._update_water_preview(0.0)
	check(not tower.render_model.is_cutaway and int(lake._fill.material.get_shader_parameter("pocket_count"))==2,"Leaving the tower closes its cutaway and restores continuous exterior water")
	check(player.is_in_prototype_water(),"Leaving the dry tower restores ordinary swimming classification")
	room.queue_free()
	await frames(2)

func magenta_count(image: Image, bounds: Rect2i) -> int:
	var count := 0
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var pixel := image.get_pixel(x,y)
			if pixel.r>.5 and pixel.b>.5 and pixel.g<.3: count += 1
	return count
