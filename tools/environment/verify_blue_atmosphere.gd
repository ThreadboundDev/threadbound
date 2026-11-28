extends SceneTree
## Clock/weather/shelter regression plus optional rendered Blue art review.
const ATMOSPHERE := preload("res://Src/Environment/BlueBiome/Atmosphere/blue_atmosphere.tscn")
const OUT := "res://work/blue-atmosphere-trial"
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("ATMOSPHERE_FAIL: " + message)

func solid(parent: Node, at: Vector2, size: Vector2, one_way: bool = false) -> CollisionShape2D:
	var body := StaticBody2D.new()
	parent.add_child(body)
	var collision := CollisionShape2D.new()
	collision.position = at
	collision.shape = RectangleShape2D.new()
	collision.shape.size = size
	collision.one_way_collision = one_way
	body.add_child(collision)
	return collision

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var room := Node2D.new()
	root.add_child(room)
	var geometry := Node2D.new()
	geometry.name = "Geometry"
	room.add_child(geometry)
	var roof := solid(geometry, Vector2(0, -300), Vector2(600, 60))
	var bridge := solid(geometry, Vector2(650, -300), Vector2(300, 60), true)
	var disabled := solid(geometry, Vector2(1200, -300), Vector2(200, 60))
	disabled.disabled = true
	var atmosphere := ATMOSPHERE.instantiate()
	atmosphere.ambience_enabled = false
	atmosphere.waterline_y = 500.0
	room.add_child(atmosphere)
	atmosphere.set_process(false)
	atmosphere.set_preview(12.0, 0)
	check(atmosphere.day_minutes == 40.0, "Normal day lasts forty minutes")
	atmosphere.advance(2400.0)
	check(is_equal_approx(atmosphere.hour, 12.0), "A full day wraps without drift")
	atmosphere.advance(100.0)
	check(is_equal_approx(atmosphere.hour, 13.0), "One game hour is one hundred seconds")
	atmosphere.time_scale = 0.0
	atmosphere.advance(180.0)
	check(is_equal_approx(atmosphere.hour, 13.0), "Paused preview clock stays fixed")
	atmosphere.time_scale = 1.0
	atmosphere.set_preview(12.0, 0)
	check(atmosphere.is_exposed(Vector2(0, -400), true), "Rain reaches air above a full roof")
	check(not atmosphere.is_exposed(Vector2(0, -100), true), "Full collision shelters the space below")
	var sun: Vector2 = atmosphere.get_node("Sun").global_position
	check(atmosphere._shaft_material.get_shader_parameter("source_position") == sun, "Rendered shafts use the visible sun as their origin")
	check(not atmosphere.is_exposed(sun.lerp(roof.global_position, 1.16)), "Full collision blocks the ray continuing away from the sun")
	check(atmosphere.is_exposed(Vector2(650, -100), true), "Rain passes through one-way platforms")
	check(atmosphere.is_exposed(sun.lerp(bridge.global_position, 1.16)), "Radial shafts pass through one-way platforms")
	check(atmosphere.is_exposed(Vector2(1200, -100), true), "Disabled collision does not become a roof")
	check(not atmosphere.is_exposed(Vector2(650, 550), true), "Rain stops at the lake instead of falling underwater")
	check(atmosphere.get_node("SolidLightOccluders").get_child_count() == 1, "Only enabled full solids cast scene-light shadows")
	check(atmosphere.get_node("SkyLight").range_item_cull_mask == 3, "Sky light includes the player composite lighting layer")
	check(roof.one_way_collision == false and bridge.one_way_collision, "Atmosphere leaves authored collision flags intact")
	atmosphere.set_preview(7.0, 0)
	var morning_sun: Vector2 = atmosphere.get_node("Sun").global_position
	check(morning_sun.x < sun.x and atmosphere._shaft_origin == morning_sun, "The ray fan and shelter follow the morning sun")
	# A roof far above the visible camera still shelters the same world point.
	roof.get_parent().position.x = 1000.0
	atmosphere.rebuild_shelter()
	atmosphere.set_preview(12.0, 0)
	check(atmosphere.is_exposed(Vector2(0, -100), true), "Moving a full roof releases the old shelter")
	check(not atmosphere.is_exposed(Vector2(1000, -100), true), "Shelter respects transformed collision")
	verify_sky_path(atmosphere, geometry)
	atmosphere._rng.seed = 7149
	atmosphere.automatic_weather = true
	var previous: int = atmosphere.weather_index
	for index in 80:
		atmosphere.advance(atmosphere.weather_remaining + 0.01)
		check(atmosphere.NEXT_WEATHER[previous].has(atmosphere.weather_index), "Weather transition follows its allowed sequence")
		check(atmosphere.weather_remaining >= 359.0 and atmosphere.weather_remaining <= 900.0, "Weather duration stays within six to fifteen minutes")
		previous = atmosphere.weather_index
	atmosphere.set_preview(12.0, 0)
	atmosphere.weather_index = 3
	atmosphere.advance(1.0)
	check(atmosphere.rain_amount > 0.0 and atmosphere.rain_amount < 0.1, "Rain builds gradually instead of switching instantly")
	verify_review_cycles(atmosphere)
	room.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await inspect_light_pixels()
	if OS.get_cmdline_user_args().has("--scene"):
		await inspect_blue()
	var report := {"checks": checks, "failures": failures, "captures": captures, "renderer": RenderingServer.get_current_rendering_method()}
	var file := FileAccess.open(OUT + "/" + ("headless" if DisplayServer.get_name() == "headless" else "rendered") + "_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BLUE_ATMOSPHERE_RESULT " + JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func verify_sky_path(atmosphere: Node, geometry: Node) -> void:
	var original_canvas := root.canvas_transform
	var sky_disc := atmosphere.get_node("Sun") as Sprite2D
	var shaft_material := atmosphere.get_node("Shafts").material as ShaderMaterial
	var noon := sky_disc.global_position
	root.canvas_transform = original_canvas.translated(Vector2(-300, 0))
	atmosphere.set_preview(12.0, 0)
	var pan := sky_disc.global_position - noon
	check(pan.x > 0.0 and pan.x < 200.0 and is_zero_approx(pan.y), "A 300 px horizontal pan moves the sky source less than 200 px")
	atmosphere.set_preview(10.0, 0)
	check(absf(noon.x + pan.x - sky_disc.global_position.x) > pan.x, "The clock moves the sun farther than the camera pan")
	root.canvas_transform = original_canvas
	atmosphere.set_preview(5.0, 0)
	var sunrise_y := sky_disc.global_position.y
	atmosphere.set_preview(12.0, 0)
	check(sunrise_y - sky_disc.global_position.y > 1400.0, "Noon reaches the higher sky arc")
	var blocker := solid(geometry, noon + Vector2(0, 110), Vector2(128, 40))
	atmosphere.rebuild_shelter()
	atmosphere.set_preview(12.0, 0)
	var near_visibility: float = shaft_material.get_shader_parameter("source_visibility")
	check(near_visibility > 0.0 and near_visibility < 1.0, "Nearby rock softens the fan while the source is still out in the open")
	blocker.position = noon + Vector2(0, 26)
	atmosphere.rebuild_shelter()
	atmosphere.set_preview(12.0, 0)
	var edge_visibility: float = shaft_material.get_shader_parameter("source_visibility")
	check(edge_visibility > 0.0 and edge_visibility < near_visibility * 0.1, "The fan is almost gone before the disc center reaches the edge")
	blocker.position = noon
	atmosphere.rebuild_shelter()
	atmosphere.set_preview(12.0, 0)
	check(shaft_material.get_shader_parameter("source_visibility") == 0.0, "A source inside a solid is fully sheltered")
	blocker.get_parent().free()
	atmosphere.rebuild_shelter()
	atmosphere.set_preview(12.0, 0)
	check(shaft_material.get_shader_parameter("source_visibility") == 1.0, "An open sky restores the full ray fan")

func verify_review_cycles(atmosphere: Node) -> void:
	var panel := atmosphere.get_node("Review/AtmosphereReview")
	var next_weather := panel.find_child("NextWeather", true, false) as Button
	var next_time := panel.find_child("NextTime", true, false) as Button
	var apply_weather := panel.find_child("ApplyWeather", true, false) as Button
	check(next_weather != null and next_time != null and apply_weather != null, "Review panel offers both cycle buttons and immediate weather")
	if next_weather == null or next_time == null or apply_weather == null:
		return
	atmosphere.set_preview(10.0, 3)
	atmosphere.automatic_weather = true
	for state in [4, 5, 0, 1, 2, 3]:
		next_weather.pressed.emit()
		check(atmosphere.weather_index == state and not atmosphere.automatic_weather,
			"Weather button previews the next state and wraps")
		check(atmosphere.hour == 10.0 and atmosphere.rain_amount == atmosphere.RAIN_AMOUNT[state]
			and atmosphere.cloud_cover == atmosphere.CLOUD_COVER[state], "Weather button applies immediately at the same hour")
	atmosphere.time_scale = 0.0
	atmosphere._weather_picker.item_selected.emit(0)
	check(atmosphere.automatic_weather, "Weather dropdown can resume automatic changes after cycling")
	for time in [12.0, 18.0, 0.0, 6.0, 12.0]:
		next_time.pressed.emit()
		check(atmosphere.hour == time and atmosphere.weather_index == 3 and atmosphere.automatic_weather
			and atmosphere.time_scale == 0.0, "Time button advances through presets and preserves weather and clock speed")
	atmosphere._weather_picker.item_selected.emit(1)
	apply_weather.pressed.emit()
	check(atmosphere.weather_index == 0 and atmosphere.rain_amount == 0.0 and atmosphere.hour == 12.0,
		"Apply Weather Now updates the dropdown selection even with the clock paused")

func inspect_light_pixels() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(512, 512)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var room := Node2D.new()
	view.add_child(room)
	var geometry := Node2D.new()
	geometry.name = "Geometry"
	room.add_child(geometry)
	solid(geometry, Vector2(128, 80), Vector2(150, 32))
	solid(geometry, Vector2(380, 80), Vector2(150, 32), true)
	for x in [128, 380]:
		var patch := Polygon2D.new()
		patch.light_mask = 2
		patch.polygon = PackedVector2Array([Vector2(x - 30, 170), Vector2(x + 30, 170), Vector2(x + 30, 230), Vector2(x - 30, 230)])
		room.add_child(patch)
	var atmosphere := ATMOSPHERE.instantiate()
	atmosphere.review_controls = false
	atmosphere.ambience_enabled = false
	room.add_child(atmosphere)
	atmosphere.set_process(false)
	atmosphere.set_preview(12.0, 0)
	for index in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var day := view.get_texture().get_image()
	var sheltered := day.get_pixel(128, 200).get_luminance()
	var exposed := day.get_pixel(380, 200).get_luminance()
	check(exposed > sheltered + 0.06, "Rendered light reaches player layer through a one-way roof while full roof casts shadow")
	atmosphere.set_preview(12.0, 4)
	for index in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var storm := view.get_texture().get_image()
	check(storm.get_pixel(380, 200).get_luminance() < exposed - 0.12, "Noon storm dims the rendered exposed surface")
	check(storm.get_pixel(128, 200).get_luminance() < sheltered - 0.09, "Noon storm also dims indirect light under cover")
	atmosphere.set_preview(0.0, 0)
	for index in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var night := view.get_texture().get_image()
	check(night.get_pixel(380, 200).get_luminance() < exposed - 0.1, "Rendered player-layer patch changes from daylight to moonlight")
	check(night.get_pixel(128, 200).get_luminance() > 0.08, "Indirect night light preserves sheltered shape readability")
	view.queue_free()
	await process_frame

func capture(name_text: String) -> Image:
	for index in 4:
		await physics_frame
	for index in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := OUT + "/" + name_text + ".png"
	image.save_png(path)
	captures.append(path)
	return image

func inspect_blue() -> void:
	var scene: PackedScene = load("res://Src/Environment/BlueBiome/blue_blockout.tscn")
	var blue := scene.instantiate()
	root.add_child(blue)
	current_scene = blue
	for index in 10:
		await process_frame
	var atmosphere := blue.get_node("Atmosphere")
	atmosphere.time_scale = 0.0
	check(blue.get_node("Player/Live3DVisual").receive_level_lighting, "Blue player opts into world lighting")
	check(atmosphere._lake_materials.size() >= 2, "Both lake presentation passes follow the clock")
	var player := blue.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var camera := blue.get_node("Player/Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	var shaft_material := atmosphere.get_node("Shafts").material as ShaderMaterial
	var route_min_visibility := 1.0
	for x in range(970, 1367, 36):
		player.position = Vector2(x, -1591.3)
		player.reset_physics_interpolation()
		camera.force_update_scroll()
		atmosphere.set_preview(11.67, 0)
		route_min_visibility = minf(route_min_visibility, shaft_material.get_shader_parameter("source_visibility"))
	check(route_min_visibility > 0.9, "The ray fan stays clear for the reported bridge route at 11:40: " + str(route_min_visibility))
	if DisplayServer.get_name() != "headless":
		await capture("blue_ray_report_bridge")
	player.position = Vector2(2200, -1560)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	camera.reset_smoothing()
	atmosphere.set_preview(12.0, 0)
	var backdrop := blue.get_node("Backgrounds/FarSkyCliffs") as CanvasItem
	var clear_backdrop := backdrop.modulate.get_luminance()
	if DisplayServer.get_name() != "headless":
		await capture("blue_day")
	atmosphere.set_preview(18.3, 0)
	if DisplayServer.get_name() != "headless":
		await capture("blue_dusk")
	atmosphere.set_preview(0.0, 0)
	if DisplayServer.get_name() != "headless":
		await capture("blue_night")
	atmosphere.set_preview(12.0, 4)
	check(backdrop.modulate.get_luminance() < clear_backdrop - 0.20, "Storm grading reaches the unshaded painted backdrop")
	if DisplayServer.get_name() != "headless":
		await capture("blue_storm")
	player.position = Vector2(-969, -1520)
	player.reset_physics_interpolation()
	camera.reset_smoothing()
	atmosphere.set_preview(0.0, 0)
	if DisplayServer.get_name() != "headless":
		await capture("blue_sheltered_night")
	player.position = Vector2(1800, -900)
	player.reset_physics_interpolation()
	camera.zoom = Vector2(0.35, 0.35)
	camera.reset_smoothing()
	atmosphere.set_preview(12.0, 0)
	if DisplayServer.get_name() != "headless":
		await capture("blue_overview_day")
	atmosphere.set_preview(0.0, 0)
	if DisplayServer.get_name() != "headless":
		await capture("blue_overview_night")
	atmosphere.set_preview(12.0, 4)
	if DisplayServer.get_name() != "headless":
		await capture("blue_overview_storm")
	blue.queue_free()
	await process_frame
