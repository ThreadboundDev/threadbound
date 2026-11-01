extends SceneTree
const OUT := "res://work/oct31-feedback"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
	await RenderingServer.frame_post_draw
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func save(label: String) -> void:
	root.get_texture().get_image().save_png(OUT+"/"+label+".png")
func run() -> void:
	var room=load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	room.get_node("LakesideArtStage").render_scale=1.0
	room.tree_entered.connect(func():current_scene=room,CONNECT_ONE_SHOT)
	root.add_child(room)
	var player=room.get_node("Player")
	player.set_physics_process(false)
	for e in get_nodes_in_group("enemies"): e.set_physics_process(false)
	await frames(15)
	for ui in root.find_children("*","CanvasLayer",true,false): ui.hide()
	var pc=player.get_node("Camera2D")
	var tower=room.get_node("Buildings/Tower")
	player.position=Vector2(1472,1400)
	player.reset_physics_interpolation()
	await frames(70)
	check(tower.is_cutaway_open(),"Actual tower entry opens its facade")
	check(tower.automatic_focus.occupied and tower.automatic_focus.follow_vertical,"Tower automatically owns interior focus")
	check(pc.zoom.x>.95,"Tower interior camera moves closer")
	check(tower.automatic_focus.effect.material.get_shader_parameter("outside_brightness")<.1,"Outside world is strongly de-emphasized")
	var far=room.get_node("Geometry/TerrainArtwork/underwater_background")
	check(far.z_index<room.get_node("LakesideArtStage").far_sprite.z_index,"Distant rocks draw behind building interiors")
	await save("tower_below")
	player.position=Vector2(1472,0)
	player.reset_physics_interpolation()
	await frames(70)
	var lake=room.get_node("Volumes/Lake")
	check(lake.underwater_view<.01,"Upper tower uses outside-head presentation")
	var rooms: PackedFloat32Array=lake._immersion_fill.material.get_shader_parameter("air_rooms")
	check(rooms.has(1.0),"Occupied tower always contributes a dry-room mask")
	await save("tower_above")
	player.position=Vector2(900,1450)
	player.reset_physics_interpolation()
	await frames(70)
	check(not tower.automatic_focus.occupied and tower.automatic_focus.saved.is_empty(),"Leaving tower restores camera ownership")
	pc.enabled=false
	var camera:=Camera2D.new()
	room.add_child(camera)
	camera.zoom=Vector2.ONE*.83
	camera.position=Vector2(50,-100)
	camera.make_current();camera.force_update_scroll()
	player.position=Vector2(-50,330)
	await frames(15)
	await save("fisher_roof")
	var comparison=room.get_node("PaintedComparison") if room.has_node("PaintedComparison") else null
	var geometry:={}
	for shape:CollisionPolygon2D in room.find_children("*","CollisionPolygon2D",true,false):
		var path:=String(room.get_path_to(shape))
		if not path.begins_with("Geometry/") and not path.begins_with("Volumes/"):continue
		var pts:=[]
		for p in shape.polygon:
			var world:=shape.to_global(p);pts.append([world.x,world.y])
		geometry[path]=pts
	FileAccess.open(OUT+"/room-capture.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"geometry":geometry},"\t"))
	print("OCT31_ROOM ",JSON.stringify({"checks":checks,"failures":failures}))
	room.queue_free();await process_frame
	quit(0 if failures.is_empty() else 1)
