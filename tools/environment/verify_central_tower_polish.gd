extends SceneTree
const OUT := "res://work/central-tower-polish-2026-10-24"
var room: Node2D
var camera: Camera2D
var failures: Array[String] = []
var captures: Array[String] = []
var baseline := false
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("TOWER_POLISH_FAIL "+message)

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("verify")

func settle(count := 10) -> void:
	for i in count:
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func capture(label: String, center: Vector2, zoom: float) -> void:
	camera.position = center
	camera.zoom = Vector2.ONE*zoom
	camera.force_update_scroll()
	await settle()
	if DisplayServer.get_name() != "headless":
		var filename := ("before_" if baseline else "after_")+label+".png"
		root.get_texture().get_image().save_png(OUT.path_join(filename))
		captures.append(filename)

func model_center(model: Node3D, pattern: String) -> Vector2:
	var matches := model.find_children(pattern,"MeshInstance3D",true,false)
	if matches.is_empty():
		failures.append("Missing model mesh: "+pattern)
		return Vector2.ZERO
	var mesh := matches[0] as MeshInstance3D
	var at := mesh.to_global(mesh.get_aabb().get_center())
	return Vector2(at.x,-at.y)*128

func angle_captures(art: Node, tower: Node2D) -> void:
	art.set_process(false)
	var stage: Node2D = room.get_node("LakesideArtStage")
	stage.set_process(false)
	for entry: Dictionary in art.placements:
		entry.far.visible = false
		entry.near.visible = false
	for placement in stage.placements:
		placement.set_process(false)
		placement.render_model.visible = false
	var original: Node3D = load("res://Assets/BlueBiome/Art/Lakeside3D/Models/central_tower.glb").instantiate()
	stage.world_stage.add_child(original)
	original.transform = tower.render_model.transform
	var target_2d := model_center(tower.render_model,"*Tier03_Front_Mitered*")
	var target := Vector3(target_2d.x/128,-target_2d.y/128,0)
	stage.far_view.size = Vector2i(1500,1000)
	stage.far_camera.cull_mask = 3
	stage.far_camera.size = 9
	stage.far_camera.position = target+Vector3(5,3,12)
	stage.far_camera.look_at(target)
	for version in ["before","after"]:
		original.visible = version == "before"
		tower.render_model.visible = version == "after"
		tower.render_model.set_cutaway(false)
		for cutaway in [false,true]:
			tower.render_model.set_cutaway(cutaway)
			for part: Node3D in original.find_children("*Facade_Removable*","Node3D",true,false):
				part.visible = not cutaway
			await settle()
			var filename: String = version+"_roof_angle_"+("cutaway" if cutaway else "exterior")+".png"
			stage.far_view.get_texture().get_image().save_png(OUT.path_join(filename))
			captures.append(filename)
	check(original.find_children("*Roof_Tier03*","MeshInstance3D",true,false).size()>0,"Angle comparison loads retained v3 roof")
	original.queue_free()

func verify() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await settle(25)
	var art = room.get_node("ArtComparison")
	if not baseline:
		check(not art.tower_painted_enabled,"Default tower is 3D")
		check(room.get_node("Buildings/Tower").render_model.visible,"Tower model renders alongside painted buildings")
		for state in [false,true]:
			art.set_all(state)
			check(not art.tower_painted_enabled and room.get_node("Buildings/Tower").render_model.visible,"F7 category switch retains 3D tower")
		art.set_tower_painted(true)
		check(not room.get_node("Buildings/Tower").render_model.visible,"Separate tower comparison can select painted art")
		art.set_tower_painted(false)
		check(room.get_node("Buildings/Tower").render_model.visible,"Separate tower comparison restores 3D")
	art.set_all(false)
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false):
		ui.visible = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var player: Node2D = room.get_node("Player")
	player.set_physics_process(false)
	player.visible = false
	player.position = Vector2(4900,-2100)
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	camera = Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	room.add_child(camera)
	camera.make_current()
	var tower: Node2D = room.get_node("Buildings/Tower")
	var model: Node3D = tower.render_model
	if model.find_children("*Tier03_Front_Mitered*","MeshInstance3D",true,false).is_empty():
		push_error("TOWER_POLISH_FAIL missing imported roof meshes")
		quit(1)
		return
	check(model.scene_file_path.ends_with("central_tower_3d.tscn"),"Live tower uses the existing wrapper")
	check(model.facade_parts.size()>0,"Existing removable facade assembly retained")
	# Real player sweeps onto every existing platform. Artwork must not require
	# moving collision or changing the entry route to make contact look right.
	var player_shape: CollisionShape2D = player.get_node("CollisionShape2D")
	var foot: float = player_shape.to_global(Vector2(0,player_shape.shape.get_rect().end.y)).y-player.global_position.y
	for index in 9:
		var body: StaticBody2D = room.get_node("Geometry/BuildingCollision/TowerPlatform"+str(index))
		var outline: CollisionPolygon2D = body.get_node("Outline")
		var surface := outline.to_global(outline.polygon[0])
		player.global_position = Vector2(body.global_position.x,surface.y-foot-20)
		player.reset_physics_interpolation()
		await physics_frame
		var hit: KinematicCollision2D = player.move_and_collide(Vector2(0,40))
		check(hit != null and hit.get_collider()==body,"Actual player lands on platform "+str(index))
		check(absf(player.global_position.y+foot-surface.y)<.2,"Platform "+str(index)+" preserves player foot contact")
	player.global_position = Vector2(1472,1600)
	player.reset_physics_interpolation()
	await physics_frame
	check(not player.test_move(player.global_transform,Vector2(120,0)),"Base entry retains unobstructed center crossing")
	player.global_position = Vector2(4900,-2100)
	player.reset_physics_interpolation()
	tower.preview_inside = false
	await capture("roof_exterior",model_center(model,"*Tier03_Front_Mitered*"),1.25)
	await capture("crown",Vector2(1472,-2020),1.1)
	await capture("tower_exterior",Vector2(1472,-130),.22)
	tower.preview_inside = true
	check(model.is_cutaway,"Tower cutaway opens")
	for part: Node3D in model.facade_parts:
		check(not part.visible,"Facade/inner roof return hides: "+String(part.name))
	await capture("roof_cutaway",model_center(model,"*Tier03_Left_Side_With_Corners*"),1.25)
	await capture("platform_depth",Vector2(1472,-670),.85)
	await capture("base_entrance",Vector2(1472,1400),.6)
	room.lighting_preset = 1
	await capture("base_dusk",Vector2(1472,1400),.6)
	room.lighting_preset = 0
	if not baseline:
		art.set_all(true)
		await capture("hybrid_default",Vector2(1472,1000),.3)
		check(model.visible and not art.tower_painted_enabled,"Hybrid view retains 3D tower")
		if DisplayServer.get_name() != "headless":
			await angle_captures(art,tower)
	var report := {"baseline":baseline,"checks":checks,"passed":failures.is_empty(),"captures":captures,"failures":failures}
	FileAccess.open(OUT.path_join("before.json" if baseline else "after.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("TOWER_POLISH_CHECK ",JSON.stringify(report))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
