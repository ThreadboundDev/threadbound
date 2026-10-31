extends SceneTree
const OUT := "res://work/blue-depth-bridges-2026-10-30"
var room
var camera: Camera2D
var report := {}
func _initialize() -> void: call_deferred("run")
func settle(n := 10) -> void:
	for i in n: await physics_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func point(node: Node2D, local: Vector2) -> Array:
	var p := node.get_global_transform_with_canvas()*local
	return [p.x,p.y]
func run() -> void:
	# Captures must not react to Chase typing while this short fixture runs.
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	var baseline := "--baseline" in OS.get_cmdline_user_args()
	var label := "before" if baseline else "after"
	room=load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	room.tree_entered.connect(func(): current_scene=room,CONNECT_ONE_SHOT)
	root.add_child(room)
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	var player=room.get_node("Player")
	player.set_physics_process(false)
	await settle(15)
	for layer in root.find_children("*","CanvasLayer",true,false): layer.hide()
	for old in room.find_children("*","Camera2D",true,false): old.enabled=false
	camera=Camera2D.new()
	camera.zoom=Vector2(0.83,0.83)
	room.add_child(camera)
	camera.make_current()
	var rock=room.get_node("Geometry/TerrainArtwork/underwater_background")
	var wood=room.get_node("Geometry/TerrainArtwork/rear_supports")
	report={"label":label,"anchors":{},"collision":{},"pan":[],"zoom":0.83}
	var solid: StaticBody2D=room.get_node("Geometry/RockCollision")
	var excluded: Array[RID]=[]
	for body in room.find_children("*","CollisionObject2D",true,false):
		if body != solid and not String(body.name).begins_with("TowerWall"): excluded.append(body.get_rid())
	for deck: Node2D in room.get_node("Geometry/BridgeLandings").get_children():
		var collision: CollisionPolygon2D=room.get_node("Geometry/BuildingCollision/BridgeLanding"+String(deck.name).trim_prefix("Deck")+"/Outline")
		var points=[]
		for p in collision.polygon:
			var world=collision.to_global(p)
			points.append([world.x,world.y])
		report.collision[String(deck.name)]=points
		if int(String(deck.name).trim_prefix("Deck")) in [5,7,8,9]: continue
		var best := {}
		var best_distance := INF
		for fraction in [0.25,0.5,0.75]:
			var origin: Vector2=deck.global_position+Vector2(deck.span_width*float(fraction),25)
			for degrees in range(15,166,10):
				var query := PhysicsRayQueryParameters2D.create(origin,origin+Vector2.from_angle(deg_to_rad(degrees))*1000.0,1)
				query.exclude=excluded
				var hit=room.get_world_2d().direct_space_state.intersect_ray(query)
				if hit.is_empty() or hit.position.y<deck.global_position.y+100: continue
				var distance: float=origin.distance_to(hit.position)
				if distance<best_distance:
					var anchor_world: Vector2=hit.position
					var supported:=false
					for depth in [12.0,8.0,4.0,2.0]:
						var probe=PhysicsPointQueryParameters2D.new()
						probe.position=hit.position-hit.normal*float(depth)
						probe.collision_mask=1
						for overlap in room.get_world_2d().direct_space_state.intersect_point(probe):
							if overlap.collider==hit.collider:
								anchor_world=probe.position
								supported=true
						if supported: break
					if not supported: continue
					best_distance=distance
					var anchor: Vector2=anchor_world-deck.global_position
					best={"anchor":[anchor.x,anchor.y],"distance":distance,"collider":String(room.get_path_to(hit.collider))}
		report.anchors[String(deck.name)]=best
	if "--survey-only" in OS.get_cmdline_user_args():
		FileAccess.open(OUT+"/anchors.json",FileAccess.WRITE).store_string(JSON.stringify(report.anchors,"\t"))
		print("ANCHOR_SURVEY ",JSON.stringify(report.anchors))
		room.queue_free()
		await process_frame
		quit()
		return
	for shot in [["floating",Vector2(3580,400),Vector2(3400,313.755)],
		["high",Vector2(4900,-1580),Vector2(4900,-1734.245)]]:
		camera.position=shot[1]
		camera.force_update_scroll()
		player.position=shot[2]
		player.velocity=Vector2.ZERO
		player.reset_physics_interpolation()
		player.set_physics_process(true)
		await settle(40)
		player.set_physics_process(false)
		await settle(5)
		root.get_texture().get_image().save_png(OUT+"/"+label+"_"+shot[0]+".png")
	player.position=Vector2(1800,1500)
	for position in [Vector2(1800,1600),Vector2(2200,1600),Vector2(2200,1800)]:
		camera.position=position
		camera.force_update_scroll()
		await settle()
		report.pan.append({"camera":[position.x,position.y],"rock":point(rock,Vector2(2000,1600)),"wood":point(wood,Vector2(2000,1600)),"rock_world_origin":[rock.global_position.x,rock.global_position.y]})
		root.get_texture().get_image().save_png(OUT+"/"+label+"_underwater_"+str(report.pan.size())+".png")
	FileAccess.open(OUT+"/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BLUE_DEPTH_CAPTURE ",label," anchors=",JSON.stringify(report.anchors)," pan=",JSON.stringify(report.pan))
	room.queue_free()
	await process_frame
	quit()
