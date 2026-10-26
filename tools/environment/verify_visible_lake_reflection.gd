extends SceneTree
## Exercise reflected pixels, including an earlier screen reader and movement.
var failures: Array[String] = []
var checks := 0
const OUT := "res://work/lakeside-playtest-2026-10-26"
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func rectangle(at: Rect2, color: Color, depth: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([at.position,Vector2(at.end.x,at.position.y),at.end,Vector2(at.position.x,at.end.y)])
	polygon.color = color
	polygon.z_index = depth
	return polygon
func frame_image(view: SubViewport) -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Reflection pixels require GPU rendering")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(512,512)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(rectangle(Rect2(0,0,512,512),Color(.02,.08,.12),-30))
	var earlier := rectangle(Rect2(0,0,1,1),Color.WHITE,-20)
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D screen: hint_screen_texture; void fragment(){COLOR=texture(screen,SCREEN_UV);}"
	material.shader = shader
	earlier.material = material
	view.add_child(earlier)
	var marker := rectangle(Rect2(128,120,80,50),Color(1,.02,.7),-10)
	view.add_child(marker)
	var lake = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	lake.lake_presentation = true
	lake.points = PackedVector2Array([Vector2(0,200),Vector2(512,200),Vector2(512,512),Vector2(0,512)])
	view.add_child(lake)
	lake.set_process(false)
	var results := []
	for wet in [false,true]:
		lake._submersion_blend = 1.0 if wet else 0.0
		lake._update_water_preview(0)
		lake._fill.material.set_shader_parameter("submersion_blend",1.0 if wet else 0.0)
		lake._fill.material.set_shader_parameter("water_opacity",.16 if wet else .34)
		marker.position.x = 0
		var image := await frame_image(view)
		var reflected := image.get_pixel(168,250)
		var clear := image.get_pixel(340,250)
		check(reflected.r-clear.r > .12,"Visible magenta reflection with %s observer" % ("underwater" if wet else "dry"))
		check(reflected.b-clear.b > .05,"Reflected source color survives water tint")
		image.save_png(OUT.path_join("reflection_"+("wet" if wet else "dry")+".png"))
		marker.position.x = 180
		image = await frame_image(view)
		check(image.get_pixel(348,250).r-image.get_pixel(168,250).r > .12,"Reflection follows moved scenery despite earlier cached screen reader")
		results.append({"submerged":wet,"reflected_red":reflected.r,"clear_red":clear.r})
	var result := {"checks":checks,"failures":failures,"samples":results,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("visible_reflection.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("VISIBLE_LAKE_REFLECTION ",JSON.stringify(result))
	view.queue_free()
	await process_frame
	quit(1 if failures.size() else 0)
