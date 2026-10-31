extends SceneTree
const OUT := "res://work/blue-depth-bridges-2026-10-30"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var background := Polygon2D.new()
	background.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1920,0),Vector2(1920,1080),Vector2(0,1080)])
	background.color=Color("283d48")
	stage.add_child(background)
	var water := Polygon2D.new()
	water.polygon=PackedVector2Array([Vector2(0,620),Vector2(960,620),Vector2(960,1080),Vector2(0,1080)])
	water.color=Color("386b7c")
	stage.add_child(water)
	var rock := Polygon2D.new()
	rock.polygon=PackedVector2Array([Vector2(930,230),Vector2(1100,250),Vector2(1110,480),Vector2(1070,730),Vector2(1030,1050),Vector2(930,1080)])
	rock.color=Color("6f7c7b")
	stage.add_child(rock)
	for floating in [true,false]:
		var asset=load("res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/"+("pontoon_bridge_2d.tscn" if floating else "braced_landing_2d.tscn")).instantiate()
		asset.position=Vector2(160,593) if floating else Vector2(1060,350)
		asset.span_width=600
		if not floating: asset.support_anchor=Vector2(-30,330)
		stage.add_child(asset)
		asset.z_index=1
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/asset-review.png")
	stage.queue_free()
	await process_frame
	quit()
