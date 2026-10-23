extends SceneTree
const ROOM := "res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn"
const OUT := "res://work/painted-2d-comparison-2026-10-22"
var room
var art
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []
var camera: Camera2D

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("PAINTED_COMPARISON_FAIL "+message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func capture(label: String, center: Vector2, zoom: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	camera.global_position = center
	camera.zoom = Vector2.ONE*zoom
	camera.force_update_scroll()
	for index in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT.path_join(label+".png")) == OK,"Saved "+label)
	captures.append(label)

func interact() -> void:
	await process_frame
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
	await frames(30)

func physics_snapshot() -> Dictionary:
	var values := {}
	for node: CollisionShape2D in room.find_children("*","CollisionShape2D",true,false):
		values[String(room.get_path_to(node))] = [node.shape.get_instance_id(),node.transform,node.disabled]
	for node: CollisionPolygon2D in room.find_children("*","CollisionPolygon2D",true,false):
		values[String(room.get_path_to(node))] = [node.polygon,node.transform,node.disabled]
	return values

func verify() -> void:
	room = load(ROOM).instantiate()
	root.add_child(room)
	current_scene = room
	await frames(30)
	art = room.get_node("ArtComparison")
	if "--draft" not in OS.get_cmdline_user_args():
		check(art.manifest.size() == 14,"All thirteen base sheets and swordfish swim extension installed")
	for key: String in art.manifest:
		for frame in art.manifest[key].frames.size():
			check(art._texture(key,frame).atlas != null,key+": imported frame "+str(frame))
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var player: CharacterBody2D = room.get_node("Player")
	var before := physics_snapshot()
	var player_scene: String = player.scene_file_path
	var beak = room.get_node("LoomHeron/Visuals/Model")
	var original_beak: Variant = beak.bone_world_position(&"beak_tip")
	art.set_all(false)
	check(physics_snapshot() == before,"Switching to current models changes no collision")
	art.set_all(true)
	check(physics_snapshot() == before,"Switching to painted art changes no collision")
	check(original_beak is Vector2 and original_beak.is_equal_approx(beak.bone_world_position(&"beak_tip")),"Existing projectile bone anchor is unchanged by art switch")
	check(player.scene_file_path == player_scene and not player.get_node_or_null("Painted_player"),"Player art/scene retained")
	for entry: Dictionary in art.placements:
		var model: Node3D = entry.node.render_model
		if entry.key == "lantern":
			for mesh: GeometryInstance3D in model.find_children("*","GeometryInstance3D",true,false):
				check(not mesh.visible,"Painted lantern suppresses original mesh while retaining light")
		else:
			check(not model.visible,"Painted placement hides original model: "+entry.key)
		if entry.key not in ["net_mender","boatwright"]:
			var sprite: Sprite2D = entry.near if entry.near.visible else entry.far
			check((sprite.texture.get_size()*sprite.scale.abs()).is_equal_approx(entry.bounds.size),"Exact original envelope: "+entry.key)
	check(art.actors.size() == 5,"All five current model enemies have painted bindings")
	check(art.bulbs.size() == 4,"All four placed bulbs have painted bindings")
	for entry: Dictionary in art.actors:
		check(entry.painted.visible and not entry.original.visible,entry.key+": painted display active")
		check(entry.enemy.get_node("Visuals").is_ancestor_of(entry.painted),entry.key+": existing facing and hit flash retained")
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	camera = Camera2D.new()
	room.add_child(camera)
	camera.make_current()
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false):
		ui.visible = false
	for label: String in ["Fisher house","Workshop"]:
		room.focus_landmark(label)
		room.get_node("Player/Camera2D").enabled = false
		camera.make_current()
		await frames(30)
		var house = room.get_landmark_house(label)
		var key := "fisher" if label == "Fisher house" else "workshop"
		var center: Vector2 = house.global_position+Vector2(0,-330 if key == "fisher" else -245)
		for painted in [false,true]:
			art.set_all(painted)
			await capture(key+("_painted" if painted else "_models"),center,.95)
		await interact()
		check(house.is_player_inside(player),label+": actual Interact enters")
		check(player.is_on_floor(),label+": stands on existing interior floor")
		check(absf(player.global_position.y+house.foot_offset(player)-house.floor_bounds().position.y)<.1,label+": feet contact retained")
		for painted in [false,true]:
			art.set_all(painted)
			await capture(key+("_inside_painted" if painted else "_inside_models"),center,.95)
		art.buildings_enabled = true
		art.actors_enabled = false
		art._process(0)
		check(art.resident_image.visible,"Mixed mode keeps model residents in front of painted walls")
		await capture(key+"_inside_mixed",center,.95)
		house.leave_house()
	# Inspect wet exterior and dry interior with the same water setup/camera.
	player.set_physics_process(false)
	player.visible = false
	player.global_position = Vector2(2200,1200)
	player.reset_physics_interpolation()
	await frames(20)
	for painted in [false,true]:
		art.set_all(painted)
		await capture("tower_wet_"+("painted" if painted else "models"),Vector2(1472,1150),.48)
	player.global_position = Vector2(1472,1037.955)
	player.reset_physics_interpolation()
	await frames(20)
	for painted in [false,true]:
		art.set_all(painted)
		await capture("tower_inside_"+("painted" if painted else "models"),Vector2(1472,1150),.48)
	art.set_all(true)
	room.lighting_preset = 1
	await capture("tower_dusk_painted",Vector2(1472,1150),.48)
	room.lighting_preset = 0
	for painted in [false,true]:
		art.set_all(painted)
		await capture("boat_slip_"+("painted" if painted else "models"),Vector2(2816,-40),.78)
		await capture("overview_"+("painted" if painted else "models"),Vector2(2048,384),.17)
	for entry: Dictionary in art.actors:
		var center: Vector2 = entry.enemy.global_position+Vector2(0,-65)
		for painted in [false,true]:
			art.set_all(painted)
			await capture(entry.key+("_painted" if painted else "_models"),center,2.5)
	var bulb = art.bulbs[0].node
	for painted in [false,true]:
		art.set_all(painted)
		await capture("bulb_"+("painted" if painted else "models"),bulb.global_position+Vector2(-25,-60),2.5)
	check(bulb.activate_from_grapple(),"Painted bulb accepts existing grapple activation")
	await frames(15)
	check(bulb.is_broken() and bulb._bulb_visual.animation == &"spent","Painted bulb retains actual spent state")
	check(art.bulbs[0].painted.texture == art._texture("water_bulb",3),"Spent painted frame follows existing lifecycle")
	await capture("bulb_spent_painted",bulb.global_position+Vector2(-25,-60),2.5)
	await frames(190)
	check(not bulb.is_broken(),"Existing timed regeneration restores painted bulb")
	check(art.bulbs[0].painted.texture in [art._texture("water_bulb",0),art._texture("water_bulb",1)],"Ready painted frame returns after regeneration")
	# Existing F2 path must bind newly respawned enemies to the selected artwork.
	room.respawn_enemies()
	await frames(20)
	art._scan_actors()
	art.set_all(true)
	check(art.actors.size() == 5,"F2 restores five painted enemy bindings")
	for entry: Dictionary in art.actors:
		check(is_instance_valid(entry.enemy) and entry.painted.visible,"Respawn retains painted art: "+entry.key)
	art.set_all(true)
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"sheets":art.manifest.size(),"placements":art.placements.size(),"enemies":art.actors.size(),"bulbs":art.bulbs.size(),"captures":captures}
	FileAccess.open(OUT.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("PAINTED_COMPARISON_CHECK ",JSON.stringify(result))
	room.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
