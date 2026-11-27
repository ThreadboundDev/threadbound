extends Node2D
## Scene-local Blue art trial. No global clock, gameplay, or save-data changes.

const CLOUD_SHADER := preload("res://Src/Environment/BlueBiome/Atmosphere/sky_clouds.gdshader")
const RAIN_SHADER := preload("res://Src/Environment/BlueBiome/Atmosphere/rain.gdshader")
const SHAFT_SHADER := preload("res://Src/Environment/BlueBiome/Atmosphere/light_shafts.gdshader")
const MASK_SIZE := 2048
const MASK_LEFT := -9000.0
const MASK_WIDTH := 23000.0
const MASK_DEPTH := 8000.0
const RAIN_SLOPE := 0.10
const WEATHER := ["Clear", "Gathering", "Overcast", "Rain", "Storm", "Clearing"]
const NEXT_WEATHER := [[1], [0, 2, 2], [1, 3, 3], [2, 4, 5, 5], [3], [0, 0, 1]]
const CLOUD_COVER := [0.05, 0.38, 0.78, 0.88, 1.0, 0.30]
const RAIN_AMOUNT := [0.0, 0.0, 0.0, 0.68, 1.0, 0.0]

@export_range(1.0, 120.0) var day_minutes := 40.0
@export_range(0.0, 24.0) var start_hour := 10.0
@export_range(0, 5) var start_weather := 0
@export var sky_y := -4600.0
@export var waterline_y := 0.0
@export var review_controls := true
@export var ambience_enabled := true

var hour := 10.0
var time_scale := 1.0
var automatic_weather := true
var weather_index := 0
var cloud_cover := 0.05
var rain_amount := 0.0
var weather_remaining := 480.0
var weather_transition_seconds := 45.0
var sun_slope := 0.0
var daylight := 1.0
var _elapsed := 0.0
var _flash := 0.0
var _thunder_delay := -1.0
var _storm_remaining := 18.0
var _mask_timer := 0.0
var _last_slope := 100.0
var _previous_hdr := false
var _polygons: Array[PackedVector2Array] = []
var _rain_heights := PackedFloat32Array()
var _light_heights := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _rain_material: ShaderMaterial
var _shaft_material: ShaderMaterial
var _cloud_material: ShaderMaterial
var _rain_texture: ImageTexture
var _light_texture: ImageTexture
var _status: Label
var _hour_slider: HSlider
var _slider_dragging := false
var _weather_picker: OptionButton
var _speed_picker: OptionButton
var _lamps: Array[PointLight2D] = []
var _rain_audio: AudioStreamPlayer
var _thunder_audio: AudioStreamPlayer
var _lake_materials: Array[ShaderMaterial] = []
var _room: Node2D
var _player_display: Sprite2D


func _ready() -> void:
	_room = get_parent() as Node2D
	_rng.randomize()
	hour = start_hour
	weather_index = start_weather
	cloud_cover = CLOUD_COVER[weather_index]
	rain_amount = RAIN_AMOUNT[weather_index]
	weather_remaining = _rng.randf_range(360.0, 900.0)
	_previous_hdr = get_viewport().use_hdr_2d
	if DisplayServer.get_name() != "headless":
		get_viewport().use_hdr_2d = true
	_setup_materials()
	$Sun.texture = _body_texture(false)
	$Moon.texture = _body_texture(true)
	rebuild_shelter()
	_add_lamp(Vector2(-1070, -1500), 0.66, 0.85)
	_add_lamp(Vector2(-1150, -2170), 0.48, 0.65)
	_add_lamp(Vector2(4550, -1765), 0.85, 1.0)
	# The water deliberately has its own unshaded presentation. Duplicate only
	# these instance materials, then grade after their reflection calculation.
	var lake := _room.get_node_or_null("Lake")
	if lake:
		for child in lake.get_children():
			if child is Polygon2D and child.material is ShaderMaterial:
				var local_material: ShaderMaterial = child.material.duplicate()
				local_material.shader = local_material.shader.duplicate()
				var code := local_material.shader.code
				code = code.replace("void fragment() {", "uniform vec4 atmosphere_tint : source_color = vec4(1.0);\nvoid fragment() {")
				var end := code.rfind("}")
				code = code.insert(end, "\nCOLOR.rgb *= atmosphere_tint.rgb;\n")
				local_material.shader.code = code
				child.material = local_material
				_lake_materials.append(local_material)
	if review_controls:
		_build_controls()
	if ambience_enabled and DisplayServer.get_name() != "headless":
		_build_audio()
	_apply_lighting()
	_update_view()


func _exit_tree() -> void:
	if is_inside_tree():
		get_viewport().use_hdr_2d = _previous_hdr


func _setup_materials() -> void:
	_cloud_material = ShaderMaterial.new()
	_cloud_material.shader = CLOUD_SHADER
	$CloudVeil.material = _cloud_material
	_rain_material = ShaderMaterial.new()
	_rain_material.shader = RAIN_SHADER
	$Rain.material = _rain_material
	_shaft_material = ShaderMaterial.new()
	_shaft_material.shader = SHAFT_SHADER
	$Shafts.material = _shaft_material
	var backgrounds := _room.get_node_or_null("Backgrounds")
	if backgrounds:
		_unshade_background(backgrounds)


func _unshade_background(node: Node) -> void:
	# Distant painted scenery is graded by time/weather; nearby solids must
	# never project their enormous 2D shadows onto the sky or far village.
	if node is Sprite2D or node is Polygon2D:
		var unshaded := CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		node.material = unshaded
	for child in node.get_children():
		_unshade_background(child)


func _process(delta: float) -> void:
	advance(delta)
	_apply_lighting()
	_update_view()


func advance(delta: float) -> void:
	var step := delta * time_scale
	_elapsed += delta
	hour = fposmod(hour + step * 24.0 / (day_minutes * 60.0), 24.0)
	if automatic_weather:
		weather_remaining -= step
		while weather_remaining <= 0.0:
			var choices: Array = NEXT_WEATHER[weather_index]
			weather_index = choices[_rng.randi_range(0, choices.size() - 1)]
			weather_remaining += _rng.randf_range(360.0, 900.0)
	var blend := 1.0 - exp(-step / maxf(weather_transition_seconds / 3.0, 0.01))
	cloud_cover = lerpf(cloud_cover, CLOUD_COVER[weather_index], blend)
	rain_amount = lerpf(rain_amount, RAIN_AMOUNT[weather_index], blend)
	_flash = maxf(0.0, _flash - delta * 1.8)
	if weather_index == 4 and rain_amount > 0.7 and time_scale > 0.0:
		_storm_remaining -= step
		if _storm_remaining <= 0.0:
			_flash = _rng.randf_range(0.32, 0.72)
			_thunder_delay = _rng.randf_range(1.0, 3.5)
			_storm_remaining = _rng.randf_range(18.0, 45.0)
	if _thunder_delay >= 0.0:
		_thunder_delay -= delta
		if _thunder_delay < 0.0 and _thunder_audio:
			_thunder_audio.play()
	_mask_timer -= delta


func set_preview(new_hour: float, new_weather: int) -> void:
	## Immediate comparison; regular weather changes always blend.
	hour = fposmod(new_hour, 24.0)
	weather_index = clampi(new_weather, 0, WEATHER.size() - 1)
	automatic_weather = false
	_apply_weather_now()


func _cycle_weather() -> void:
	set_preview(hour, (weather_index + 1) % WEATHER.size())


func _cycle_time() -> void:
	# Step through midnight, dawn, noon and dusk independently of the weather.
	hour = fposmod((floorf(hour / 6.0) + 1.0) * 6.0, 24.0)
	_refresh_preview()


func _apply_weather_now() -> void:
	cloud_cover = CLOUD_COVER[weather_index]
	rain_amount = RAIN_AMOUNT[weather_index]
	_flash = 0.0
	_thunder_delay = -1.0
	_storm_remaining = 18.0
	if _thunder_audio:
		_thunder_audio.stop()
	_refresh_preview()


func _refresh_preview() -> void:
	_mask_timer = 0.0
	_apply_lighting()
	_update_view()


func _apply_lighting() -> void:
	# Longer daylight: sunrise at 05:00, sunset at 19:00. Both arcs meet
	# below the horizon, where their discs disappear instead of teleporting.
	var is_day := hour >= 5.0 and hour <= 19.0
	var arc := (hour - 5.0) / 14.0 if is_day else fposmod(hour - 19.0, 24.0) / 10.0
	var altitude := sin(arc * PI)
	daylight = smoothstep(4.5, 6.5, hour) * (1.0 - smoothstep(17.5, 19.5, hour))
	var dusk := maxf(exp(-pow((hour - 5.8) / 1.1, 2.0)), exp(-pow((hour - 18.3) / 1.1, 2.0)))
	var overcast := smoothstep(0.27, 0.96, cloud_cover)
	var ambient := Color(0.53, 0.60, 0.74).lerp(Color(0.74, 0.78, 0.84), daylight)
	var overcast_ambient := Color(0.44, 0.50, 0.64).lerp(Color(0.57, 0.63, 0.72), daylight)
	ambient = ambient.lerp(overcast_ambient, overcast)
	$Ambient.color = ambient
	var light_color := Color(0.57, 0.73, 1.0).lerp(Color(1.0, 0.96, 0.85), daylight)
	light_color = light_color.lerp(Color(1.0, 0.68, 0.42), dusk * (1.0 - cloud_cover) * 0.48)
	$SkyLight.color = light_color
	$SkyLight.energy = lerpf(0.22, 0.36, daylight) * lerpf(1.0, 0.22, cloud_cover)
	sun_slope = cos(arc * PI) * 0.55
	$SkyLight.rotation = -atan(sun_slope)
	var sky_color := Color(0.035, 0.07, 0.17).lerp(Color(0.37, 0.70, 0.88), daylight)
	sky_color = sky_color.lerp(Color(0.61, 0.38, 0.48), dusk * 0.48)
	var overcast_sky := Color(0.025, 0.045, 0.095).lerp(Color(0.18, 0.26, 0.35), daylight)
	sky_color = sky_color.lerp(overcast_sky, overcast * 0.80)
	var sky := _room.get_node_or_null("Backgrounds/Sky") as Polygon2D
	if sky:
		sky.color = sky_color
	var backdrop_grade := Color.WHITE.lerp(Color(0.64, 0.70, 0.78), overcast * lerpf(0.52, 0.88, daylight))
	var backdrop_color := Color(0.36, 0.40, 0.53).lerp(Color(0.93, 0.95, 0.97), daylight)
	backdrop_color = backdrop_color.lerp(Color(0.85, 0.65, 0.65), dusk * 0.28)
	for path in ["Backgrounds/FarSkyCliffs", "Backgrounds/LakeVillage"]:
		var background := _room.get_node_or_null(path) as CanvasItem
		if background:
			background.modulate = backdrop_color * backdrop_grade
	var old_clouds := _room.get_node_or_null("Backgrounds/Clouds") as CanvasItem
	if old_clouds:
		old_clouds.modulate = Color(0.46, 0.55, 0.72).lerp(Color.WHITE, daylight) * backdrop_grade
		old_clouds.modulate.a = 1.0 - cloud_cover * 0.65
	_cloud_material.set_shader_parameter("coverage", cloud_cover)
	_cloud_material.set_shader_parameter("clock", _elapsed)
	_cloud_material.set_shader_parameter("flash", _flash)
	var cloud_color := Color(0.09, 0.13, 0.23).lerp(Color(0.73, 0.79, 0.83), daylight)
	var overcast_clouds := Color(0.085, 0.12, 0.21).lerp(Color(0.21, 0.27, 0.36), daylight)
	_cloud_material.set_shader_parameter("cloud_color", cloud_color.lerp(overcast_clouds, overcast * 0.84))
	_rain_material.set_shader_parameter("clock", _elapsed)
	_rain_material.set_shader_parameter("amount", rain_amount)
	_rain_material.set_shader_parameter("rain_color", Color(0.36, 0.51, 0.67).lerp(Color(0.62, 0.74, 0.84), daylight))
	_shaft_material.set_shader_parameter("clock", _elapsed)
	_shaft_material.set_shader_parameter("strength", lerpf(0.28, 0.66, daylight) * altitude * (1.0 - cloud_cover))
	_shaft_material.set_shader_parameter("shaft_color", light_color)
	if _mask_timer <= 0.0 and absf(sun_slope - _last_slope) > 0.008:
		_light_heights = _shelter_heights(sun_slope, false)
		_light_texture = _upload_mask(_light_heights, _light_texture)
		_shaft_material.set_shader_parameter("shelter", _light_texture)
		_shaft_material.set_shader_parameter("slope", sun_slope)
		_last_slope = sun_slope
		_mask_timer = 0.2
	for lamp in _lamps:
		lamp.energy = float(lamp.get_meta("base_energy")) * lerpf(1.0, 0.24, daylight) * (0.97 + sin(_elapsed * 2.3 + lamp.position.x) * 0.03)
	var lake_tint := Color(0.24, 0.36, 0.58).lerp(Color(0.95, 0.97, 1.0), daylight)
	var lake_weather_grade := Color.WHITE.lerp(Color(0.62, 0.71, 0.83), overcast * lerpf(0.40, 0.75, daylight))
	lake_tint *= lake_weather_grade
	for lake_material in _lake_materials:
		lake_material.set_shader_parameter("atmosphere_tint", lake_tint)
	if _rain_audio:
		var player := _room.get_node_or_null("Player") as Node2D
		var exposed := true if not player else is_exposed(player.global_position, true)
		_rain_audio.volume_db = linear_to_db(maxf(0.0001, rain_amount * (0.30 if exposed else 0.09)))
	if _status:
		_status.text = "%02d:%02d  ·  %s  ·  %s" % [int(hour), int(fmod(hour, 1.0) * 60.0), WEATHER[weather_index], "Auto" if automatic_weather else "Preview"]
		if not _slider_dragging:
			_hour_slider.set_value_no_signal(hour)
		_weather_picker.select(0 if automatic_weather else weather_index + 1)
		_speed_picker.select(0 if time_scale == 1.0 else (1 if time_scale > 1.0 else 2))
	if not is_instance_valid(_player_display):
		_player_display = _room.get_node_or_null("Player/Live3DComposite") as Sprite2D
		if _player_display and _player_display.material is ShaderMaterial:
			# Scene-local exposure restores readable model values while its
			# existing composite still receives both ambient and local lights.
			_player_display.material.set_shader_parameter("exposure", 0.95)


func _update_view() -> void:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var size := get_viewport_rect().size
	var bounds := Rect2(inverse * Vector2.ZERO, Vector2.ZERO).expand(inverse * size).grow(100.0)
	var corners := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	$CloudVeil.polygon = corners
	$Rain.polygon = corners
	$Shafts.polygon = corners
	# A stable horizon responds gently to vertical exploration. It does not
	# follow individual jumps, and celestial bodies have no horizontal parallax.
	var center := bounds.get_center()
	var horizon := -650.0 + (center.y + 1500.0) * 0.10
	var is_day := hour >= 5.0 and hour <= 19.0
	var arc := (hour - 5.0) / 14.0 if is_day else fposmod(hour - 19.0, 24.0) / 10.0
	var celestial := Vector2(center.x - cos(arc * PI) * bounds.size.x * 0.43, horizon - sin(arc * PI) * 1260.0)
	$Sun.position = celestial
	$Moon.position = celestial
	$Sun.visible = is_day
	$Moon.visible = not is_day
	$Sun.modulate = Color(1.95, 1.65, 1.23, 1.0 - cloud_cover * 0.94)
	$Moon.modulate = Color(1.45, 1.8, 2.5, 1.0 - cloud_cover * 0.94)
	$Sun.scale = Vector2.ONE * 1.25
	$Moon.scale = Vector2.ONE * 0.90


func rebuild_shelter() -> void:
	_polygons.clear()
	for child in $SolidLightOccluders.get_children():
		child.free()
	var geometry := _room.get_node_or_null("Geometry")
	if geometry:
		_collect_solids(geometry)
	for points in _polygons:
		var occluder := LightOccluder2D.new()
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.polygon = points
		occluder.occluder.cull_mode = OccluderPolygon2D.CULL_DISABLED
		occluder.occluder_light_mask = 3
		$SolidLightOccluders.add_child(occluder)
	_rain_heights = _shelter_heights(RAIN_SLOPE, true)
	_rain_texture = _upload_mask(_rain_heights, _rain_texture)
	for mat in [_rain_material, _shaft_material]:
		mat.set_shader_parameter("mask_left", MASK_LEFT)
		mat.set_shader_parameter("mask_width", MASK_WIDTH)
		mat.set_shader_parameter("sky_y", sky_y)
		mat.set_shader_parameter("mask_depth", MASK_DEPTH)
	_rain_material.set_shader_parameter("shelter", _rain_texture)
	_rain_material.set_shader_parameter("slope", RAIN_SLOPE)
	_last_slope = 100.0
	_mask_timer = 0.0


func _collect_solids(node: Node) -> void:
	var points := PackedVector2Array()
	if node is CollisionPolygon2D and not node.disabled and not node.one_way_collision and node.get_parent() is StaticBody2D:
		for point in node.polygon:
			points.append(node.to_global(point))
	elif node is CollisionShape2D and not node.disabled and not node.one_way_collision and node.get_parent() is StaticBody2D and node.shape:
		var shape: Shape2D = node.shape
		if shape is ConvexPolygonShape2D:
			points = shape.points
		elif shape is RectangleShape2D:
			var half: Vector2 = shape.size * 0.5
			points = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
		elif shape is SegmentShape2D:
			points = PackedVector2Array([shape.a, shape.b])
		for index in points.size():
			points[index] = node.to_global(points[index])
	if points.size() >= 2:
		_polygons.append(points)
	for child in node.get_children():
		_collect_solids(child)


func _shelter_heights(slope: float, stop_at_water: bool) -> PackedFloat32Array:
	# Rasterize projected collision edges into a one-row float texture. Each
	# texel is the first solid hit by a parallel sky ray. Work depends on edge
	# span, not rain particle count; roofs above the camera still shelter it.
	var heights := PackedFloat32Array()
	heights.resize(MASK_SIZE)
	heights.fill(waterline_y if stop_at_water else sky_y + MASK_DEPTH)
	var pitch := MASK_WIDTH / MASK_SIZE
	for polygon in _polygons:
		for index in polygon.size():
			var a := polygon[index]
			var b := polygon[(index + 1) % polygon.size()]
			var ax := a.x - slope * (a.y - sky_y)
			var bx := b.x - slope * (b.y - sky_y)
			if absf(bx - ax) < 0.001:
				continue
			var first := maxi(0, ceili((minf(ax, bx) - MASK_LEFT) / pitch - 0.5))
			var last := mini(MASK_SIZE - 1, floori((maxf(ax, bx) - MASK_LEFT) / pitch - 0.5))
			for sample_index in range(first, last + 1):
				var x := MASK_LEFT + (sample_index + 0.5) * pitch
				var y := lerpf(a.y, b.y, (x - ax) / (bx - ax))
				if y >= sky_y:
					heights[sample_index] = minf(heights[sample_index], y)
	return heights


func _upload_mask(heights: PackedFloat32Array, texture: ImageTexture) -> ImageTexture:
	var normalized := PackedFloat32Array()
	for height in heights:
		normalized.append(clampf((height - sky_y) / MASK_DEPTH, 0.0, 1.0))
	var image := Image.create_from_data(MASK_SIZE, 1, false, Image.FORMAT_RF, normalized.to_byte_array())
	if texture:
		texture.update(image)
		return texture
	return ImageTexture.create_from_image(image)


func is_exposed(point: Vector2, rain: bool = false) -> bool:
	var slope := RAIN_SLOPE if rain else sun_slope
	var heights := _rain_heights if rain else _light_heights
	if heights.is_empty():
		return true
	var ray_x := point.x - slope * (point.y - sky_y)
	var index := clampi(int((ray_x - MASK_LEFT) / MASK_WIDTH * MASK_SIZE), 0, MASK_SIZE - 1)
	return point.y < heights[index] - 3.0


func _body_texture(moon: bool) -> ImageTexture:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBAH)
	for y in 256:
		for x in 256:
			var distance := Vector2(x - 127.5, y - 127.5).length() / 128.0
			var disc := 1.0 - smoothstep(0.23 if moon else 0.21, 0.28, distance)
			var halo := exp(-distance * distance * 7.5) * 0.20
			var alpha := clampf(disc + halo, 0.0, 1.0) * (1.0 - smoothstep(0.8, 1.0, distance))
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _add_lamp(at: Vector2, radius: float, energy: float) -> void:
	var light := PointLight2D.new()
	light.name = "WarmLamp%d" % _lamps.size()
	light.position = at
	light.range_item_cull_mask = 3
	light.color = Color(1.0, 0.65, 0.30)
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.set_meta("base_energy", energy)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = 1024
	texture.height = 1024
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	light.texture = texture
	light.texture_scale = radius
	add_child(light)
	_lamps.append(light)


func _build_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "AtmosphereReview"
	$Review.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 18
	panel.offset_right = 790
	panel.offset_top = -145
	panel.offset_bottom = -18
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	_status = Label.new()
	rows.add_child(_status)
	var row := HBoxContainer.new()
	rows.add_child(row)
	_hour_slider = HSlider.new()
	_hour_slider.min_value = 0.0
	_hour_slider.max_value = 23.99
	_hour_slider.step = 0.01
	_hour_slider.custom_minimum_size.x = 180
	_hour_slider.value_changed.connect(func(value: float): hour = value)
	_hour_slider.drag_started.connect(func(): _slider_dragging = true)
	_hour_slider.drag_ended.connect(func(_changed: bool): _slider_dragging = false)
	row.add_child(_hour_slider)
	_weather_picker = OptionButton.new()
	_weather_picker.add_item("Weather: automatic")
	for name_text in WEATHER:
		_weather_picker.add_item(name_text)
	_weather_picker.item_selected.connect(func(index: int):
		automatic_weather = index == 0
		if index > 0:
			weather_index = index - 1
	)
	row.add_child(_weather_picker)
	_speed_picker = OptionButton.new()
	for speed_name in ["Clock: 1x", "Clock: 60x", "Clock: paused"]:
		_speed_picker.add_item(speed_name)
	_speed_picker.item_selected.connect(func(index: int): time_scale = [1.0, 60.0, 0.0][index])
	row.add_child(_speed_picker)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	for entry in [
		["NextWeather", "Next Weather", _cycle_weather, "Cycle weather immediately at the current time."],
		["NextTime", "Next Time", _cycle_time, "Cycle dawn, noon, dusk and midnight with the current weather."],
		["ApplyWeather", "Apply Weather Now", _apply_weather_now, "Skip the transition to the selected weather."],
	]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.tooltip_text = entry[3]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[2])
		actions.add_child(button)
	var hint := Label.new()
	hint.text = "40-minute day · time presets 06:00, 12:00, 18:00, 00:00"
	hint.add_theme_font_size_override("font_size", 14)
	rows.add_child(hint)


func _build_audio() -> void:
	# Temporary procedural ambience for the art trial, with no external assets.
	_rain_audio = AudioStreamPlayer.new()
	_rain_audio.stream = _noise_sound(false)
	_rain_audio.volume_db = -80.0
	add_child(_rain_audio)
	_rain_audio.play()
	_thunder_audio = AudioStreamPlayer.new()
	_thunder_audio.stream = _noise_sound(true)
	_thunder_audio.volume_db = -12.0
	add_child(_thunder_audio)


func _noise_sound(thunder: bool) -> AudioStreamWAV:
	var rate := 22050
	var seconds := 4
	var data := PackedByteArray()
	data.resize(rate * seconds * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 8173 if thunder else 2509
	var low := 0.0
	for index in rate * seconds:
		var white := random.randf_range(-1.0, 1.0)
		low = lerpf(low, white, 0.018 if thunder else 0.12)
		var envelope := pow(1.0 - float(index) / (rate * seconds), 1.6) if thunder else 1.0
		if thunder:
			envelope *= smoothstep(0.0, 0.15, float(index) / rate)
		var sample := (low * 4.5 if thunder else white * 0.18 + low * 0.65) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 28000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	if not thunder:
		sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sound.loop_end = rate * seconds
	return sound
