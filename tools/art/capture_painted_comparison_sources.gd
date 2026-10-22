extends SceneTree
const OUT := "res://work/painted-2d-comparison-2026-10-22"
const ROOM := "res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn"
var manifest := {}
var room: Node2D
var camera: Camera2D

func _initialize() -> void:
	call_deferred("capture_sources")

func settle(count := 12) -> void:
	for index in count:
		await process_frame
	await RenderingServer.frame_post_draw

func model_bounds(model: Node3D) -> Rect2:
	var result := Rect2()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree():
			continue
		var box := mesh.get_aabb()
		for corner in 8:
			var v := mesh.to_global(box.get_endpoint(corner))
			var point := Vector2(v.x,-v.y)*128.0
			if first:
				result = Rect2(point,Vector2.ZERO)
				first = false
			else:
				result = result.expand(point)
	return result

func capture_sources() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	room = load(ROOM).instantiate()
	root.add_child(room)
	current_scene = room
	await settle()
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false):
		ui.visible = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	room.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	var stage = room.get_node("LakesideArtStage")
	stage.set_process(false)
	stage.far_view.size = Vector2i(1536,1536)
	stage.near_view.size = Vector2i(1536,1536)
	var placements: Array = stage.placements.duplicate()
	for placement in placements:
		placement.set_process(false)
		placement.render_model.visible = false
	for placement in placements:
		var model: Node3D = placement.render_model
		model.visible = true
		var key := String(placement.name).to_snake_case()
		var bounds := model_bounds(model)
		var local_bounds := Rect2(bounds.position-placement.global_position,bounds.size)
		manifest[key] = {"path":String(room.get_path_to(placement)),"bounds":[local_bounds.position.x,local_bounds.position.y,local_bounds.size.x,local_bounds.size.y],"position":[placement.position.x,placement.position.y]}
		var span := maxf(bounds.size.x,bounds.size.y)*1.12
		for view_camera in [stage.far_camera,stage.near_camera]:
			view_camera.size = span/128.0
			view_camera.position = Vector3(bounds.get_center().x/128.0,-bounds.get_center().y/128.0,40)
		for inside in [false,true] if model.has_method("set_cutaway") else [false]:
			if model.has_method("set_cutaway"):
				model.set_cutaway(inside)
			await settle()
			# Both model layers are rendered in one transparent viewport for reference.
			stage.far_camera.cull_mask = 3
			await settle()
			stage.far_view.get_texture().get_image().save_png(OUT.path_join(key+("_inside" if inside else "_source")+".png"))
			stage.far_camera.cull_mask = 1
		if model.has_method("set_cutaway"):
			model.set_cutaway(false)
		model.visible = false
	for enemy in get_nodes_in_group("enemies"):
		var candidates := enemy.find_children("*","Sprite2D",true,false)
		for sprite: Sprite2D in candidates:
			if sprite.texture is ViewportTexture:
				sprite.get_parent().set_process(false)
				for view: SubViewport in sprite.get_parent().find_children("*","SubViewport",true,false):
					view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				await settle()
				var image := sprite.texture.get_image()
				var used := image.get_used_rect()
				assert(used.has_area(), "Empty source render: "+str(enemy.name))
				var a: Vector2 = sprite.transform * (sprite.get_rect().position+Vector2(used.position))
				var b: Vector2 = sprite.transform * (sprite.get_rect().position+Vector2(used.end))
				var world_rect := Rect2(a,b-a).abs()
				var key := String(enemy.name).to_snake_case()
				image.save_png(OUT.path_join(key+"_source.png"))
				manifest[key] = {"path":String(room.get_path_to(enemy)),"sprite_path":String(enemy.get_path_to(sprite)),"bounds_space":"visual_model_local","bounds":[world_rect.position.x,world_rect.position.y,world_rect.size.x,world_rect.size.y],"used_pixels":[used.position.x,used.position.y,used.size.x,used.size.y]}
				break
	FileAccess.open(OUT.path_join("source_manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t")+"\n")
	print("PAINTED_SOURCES ",JSON.stringify(manifest))
	quit()
