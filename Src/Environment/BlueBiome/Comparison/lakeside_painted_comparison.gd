extends Node
## Reversible presentation experiment; the inherited room owns all gameplay.
const ASSETS := "res://Assets/BlueBiome/Art/PaintedComparison/"
const SOURCES := "res://work/painted-2d-comparison-2026-10-22/source_manifest.json"
const CONTACT_SHADER := preload("res://Src/Environment/BlueBiome/Comparison/painted_contact_registration.gdshader")
const BULB_CURRENT := preload("res://Src/Environment/BlueBiome/Comparison/painted_bulb_current.gdshader")
var buildings_enabled := true
var tower_painted_enabled := false
var actors_enabled := true
var enemies_enabled := false
var bulbs_enabled := true
var placements: Array[Dictionary] = []
var actors: Array[Dictionary] = []
var bulbs: Array[Dictionary] = []
var room: Node2D
var stage: Node2D
var manifest: Dictionary
var source_manifest: Dictionary
var grades: Array[CanvasModulate] = []
var _rescan := 0.0
var controls: CanvasLayer
var _textures := {}
var _clock := 0.0
var resident_view: SubViewport
var resident_camera: Camera3D
var resident_image: Sprite2D
var contact_registration: Dictionary
var _contact_materials := {}

func _ready() -> void:
	process_priority = 100
	room = get_parent()
	stage = room.get_node("LakesideArtStage")
	source_manifest = JSON.parse_string(FileAccess.get_file_as_string(SOURCES))
	if FileAccess.file_exists(ASSETS+"manifest.json"):
		manifest = JSON.parse_string(FileAccess.get_file_as_string(ASSETS+"manifest.json"))
	contact_registration = JSON.parse_string(FileAccess.get_file_as_string(ASSETS+"contact_registration.json"))
	call_deferred("_setup")

func _setup() -> void:
	for view: SubViewport in [stage.far_view,stage.near_view]:
		var grade := CanvasModulate.new()
		view.add_child(grade)
		grades.append(grade)
	for key: String in source_manifest:
		var entry: Dictionary = source_manifest[key]
		var asset_key := "lantern" if key.ends_with("lantern") else key
		if not manifest.has(asset_key) or not entry.has("position"):
			continue
		var placement := room.get_node(entry.path) as Node2D
		var far := _sprite(asset_key,0)
		var near := _sprite(asset_key,0)
		stage.far_view.add_child(far)
		stage.near_view.add_child(near)
		if asset_key in ["net_mender","boatwright"]:
			far.z_index = 10
			near.z_index = 10
		if asset_key == "lantern":
			for view: SubViewport in [stage.far_view,stage.near_view]:
				var light := placement.get_node("ActorWarmth").duplicate() as PointLight2D
				view.add_child(light)
				light.position = placement.global_position
		placements.append({"node":placement,"key":asset_key,"far":far,"near":near,"bounds":_rect(entry.bounds)})
	_setup_resident_pass()
	# These are screen composites, positioned from the already smoothed canvas
	# each render frame. Interpolating them again makes the artwork swim away
	# from world collision whenever the main camera moves between physics ticks.
	for image: Sprite2D in [stage.far_sprite,stage.near_sprite,resident_image]:
		image.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for camera: Camera3D in [stage.far_camera,stage.near_camera]:
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build_controls()
	_scan_actors()
	_process(0)

func _setup_resident_pass() -> void:
	# In mixed mode the current resident meshes need to draw over painted rear
	# walls. Their existing shared 3D animation/light world stays intact.
	for light: Light3D in stage.world_stage.find_children("*","Light3D",true,false):
		light.layers |= 4
		light.light_cull_mask |= 4
	resident_view = SubViewport.new()
	resident_view.name = "ComparisonModelResidents"
	resident_view.world_3d = stage.far_view.world_3d
	resident_view.transparent_bg = true
	resident_view.msaa_3d = stage.far_view.msaa_3d
	resident_view.handle_input_locally = false
	add_child(resident_view)
	resident_camera = stage.far_camera.duplicate() as Camera3D
	resident_camera.cull_mask = 4
	resident_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	resident_view.add_child(resident_camera)
	resident_camera.current = true
	resident_image = Sprite2D.new()
	resident_image.texture = resident_view.get_texture()
	resident_image.z_as_relative = false
	resident_image.z_index = -9
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	resident_image.material = unshaded
	room.add_child(resident_image)

func _rect(values: Array) -> Rect2:
	return Rect2(float(values[0]),float(values[1]),float(values[2]),float(values[3]))

func _texture(key: String, frame: int) -> AtlasTexture:
	var cache_key := key+":"+str(frame)
	if _textures.has(cache_key):
		return _textures[cache_key]
	var entry: Dictionary = manifest[key]
	var texture := AtlasTexture.new()
	texture.atlas = load(ASSETS+str(entry.get("file",key+".png")))
	texture.region = _rect(entry.frames[clampi(frame,0,entry.frames.size()-1)])
	texture.filter_clip = true
	_textures[cache_key] = texture
	return texture

func _sprite(key: String, frame: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Painted_"+key
	sprite.texture = _texture(key,frame)
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

func _fit(sprite: Sprite2D, bounds: Rect2, transform: Transform2D) -> void:
	sprite.transform = transform
	sprite.position = transform * bounds.position
	sprite.scale = transform.get_scale() * bounds.size / sprite.texture.get_size()

func _fit_pose(sprite: Sprite2D, key: String, bounds: Rect2, transform: Transform2D, frame := 0) -> void:
	var used := _rect(manifest[key].initial_alpha_bounds)
	var scale_to_world := bounds.size/used.size
	sprite.transform = transform
	sprite.position = transform*(bounds.position-used.position*scale_to_world)
	if manifest[key].has("pose_offsets"):
		var offset: Array = manifest[key].pose_offsets[frame]
		sprite.position += transform.basis_xform(Vector2(offset[0],offset[1])*scale_to_world)
	sprite.scale = transform.get_scale()*scale_to_world

func _process(delta: float) -> void:
	if not is_instance_valid(resident_image):
		return
	_clock += delta
	var canvas := room.get_viewport().get_canvas_transform()
	# No second Camera2D: its physics update/interpolation can overwrite the
	# render-time transform. Both passes sample the same canvas as the room.
	var supersample := Transform2D.IDENTITY.scaled(Vector2.ONE*stage.render_scale)
	stage.far_view.canvas_transform = supersample*canvas
	stage.near_view.canvas_transform = supersample*canvas
	stage._sync_camera()
	for grade: CanvasModulate in grades:
		grade.color = Color(.44,.57,.76) if room.lighting_preset == 1 else Color(.82,.89,.97)
	var mixed := buildings_enabled and not actors_enabled
	resident_image.visible = mixed
	resident_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if mixed else SubViewport.UPDATE_DISABLED
	resident_view.size = stage.far_view.size
	resident_camera.transform = stage.far_camera.transform
	resident_camera.size = stage.far_camera.size
	resident_image.global_transform = stage.far_sprite.global_transform
	for placement_index in range(placements.size()-1,-1,-1):
		var entry: Dictionary = placements[placement_index]
		if not is_instance_valid(entry.node):
			entry.far.queue_free()
			entry.near.queue_free()
			placements.remove_at(placement_index)
			continue
		var node: Node2D = entry.node
		var model: Node3D = node.render_model
		var is_actor: bool = entry.key in ["net_mender","boatwright"]
		var enabled := actors_enabled if is_actor else buildings_enabled
		if entry.key == "tower":
			enabled = tower_painted_enabled
		model.visible = node.is_visible_in_tree() and not enabled
		if entry.key == "lantern":
			# Keep its existing light for any model actors in a mixed comparison;
			# suppress only the lantern meshes when the drawn prop is selected.
			model.visible = node.is_visible_in_tree()
			for mesh: GeometryInstance3D in model.find_children("*","GeometryInstance3D",true,false):
				mesh.visible = not enabled
		if is_actor and not node.house_path.is_empty():
			var house: Node2D = node.get_node_or_null(node.house_path)
			if not is_instance_valid(house):
				model.visible = false
				entry.far.visible = false
				entry.near.visible = false
				continue
			if buildings_enabled:
				model.visible = model.visible and house.render_model.is_cutaway
		if is_actor:
			for mesh: GeometryInstance3D in model.find_children("*","GeometryInstance3D",true,false):
				mesh.layers = 4 if mixed else 1
		entry.far.visible = false
		entry.near.visible = false
		if not enabled or not node.is_visible_in_tree():
			continue
		var inside := bool(model.get("is_cutaway")) if model.get("is_cutaway") != null else false
		var front := bool(model.get("facade_foreground")) if model.get("facade_foreground") != null else false
		var frame := 1 if inside and manifest[entry.key].frames.size()>1 else 0
		var target: Sprite2D = entry.near if front and not inside else entry.far
		target.texture = _texture(entry.key,frame)
		_fit(target,entry.bounds,node.global_transform)
		_register_contacts(entry,target,frame)
		target.visible = true
		if is_actor and manifest[entry.key].frames.size()>1:
			_update_worker(entry,target)
	_rescan += delta
	if _rescan >= .25:
		_rescan = 0
		_scan_actors()
	_update_actors(delta)
	_update_bulbs(delta)

func _contact_bounds(entry: Dictionary, collision: String) -> Rect2:
	var shape: CollisionPolygon2D = room.get_node("Geometry/BuildingCollision/"+collision+"/Outline")
	var points := PackedVector2Array()
	for point: Vector2 in shape.polygon:
		points.append(entry.node.to_local(shape.to_global(point)))
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	return bounds

func _register_contacts(entry: Dictionary, sprite: Sprite2D, frame: int) -> void:
	sprite.material = null
	if not contact_registration.has(entry.key) or not contact_registration[entry.key].has(str(frame)):
		return
	var cache_key := str(entry.node.get_instance_id())+":"+str(frame)
	if _contact_materials.has(cache_key):
		sprite.material = _contact_materials[cache_key]
		return
	var spec: Dictionary = contact_registration[entry.key][str(frame)]
	var region := _rect(manifest[entry.key].frames[frame])
	var bounds: Rect2 = entry.bounds
	# Each row contains source/destination normalized coordinates. Keep frame
	# edges fixed; interior contacts follow the physical surface and endpoints.
	var grid: Array[Dictionary] = [{"y":Vector2.ZERO,"x":[Vector2.ZERO,Vector2.ONE]},
		{"y":Vector2.ONE,"x":[Vector2.ZERO,Vector2.ONE]}]
	for contact: Dictionary in spec.rows:
		var physical := _contact_bounds(entry,contact.collision)
		var source_y := (float(contact.y)-region.position.y)/region.size.y
		var target_y := (physical.position.y-bounds.position.y)/bounds.size.y
		var row: Dictionary = {}
		for existing: Dictionary in grid:
			if is_equal_approx(existing.y.x,target_y):
				row = existing
				break
		if row.is_empty():
			row = {"y":Vector2(target_y,source_y),"x":[Vector2.ZERO,Vector2.ONE]}
			grid.append(row)
		if spec.get("vertical_only",false):
			continue
		row.x.append(Vector2((physical.position.x-bounds.position.x)/bounds.size.x,
			(float(contact.span[0])-region.position.x)/region.size.x))
		row.x.append(Vector2((physical.end.x-bounds.position.x)/bounds.size.x,
			(float(contact.span[1])-region.position.x)/region.size.x))
		if spec.has("walls"):
			# The playable inner wall lies slightly inside the floor's overhang.
			for edge in 2:
				var wall: float = entry.node.entry_rect.position.x if edge == 0 else entry.node.entry_rect.end.x
				row.x.append(Vector2((wall-bounds.position.x)/bounds.size.x,
					(float(spec.walls[edge])-region.position.x)/region.size.x))
		if spec.has("door_x"):
			row.x.append(Vector2((entry.node.get_node("Door").position.x-bounds.position.x)/bounds.size.x,
				(float(spec.door_x)-region.position.x)/region.size.x))
	# Houses use one horizontal registration through their entire height, so
	# straight posts stay straight while door/floor anchors line up.
	for row: Dictionary in grid:
		row.x = grid[2].x
	grid.sort_custom(func(a: Dictionary,b: Dictionary): return a.y.x<b.y.x)
	var rows := PackedVector2Array()
	var columns := PackedVector2Array()
	for row: Dictionary in grid:
		rows.append(row.y)
		row.x.sort_custom(func(a: Vector2,b: Vector2): return a.x<b.x)
		for index in 8:
			columns.append(row.x[mini(index,row.x.size()-1)])
	while rows.size()<24:
		rows.append(Vector2.ONE)
	while columns.size()<192:
		columns.append(Vector2.ONE)
	var material := ShaderMaterial.new()
	material.shader = CONTACT_SHADER
	material.set_shader_parameter("atlas_region",Vector4(region.position.x,region.position.y,region.size.x,region.size.y))
	material.set_shader_parameter("atlas_size",_texture(entry.key,frame).atlas.get_size())
	material.set_shader_parameter("row_count",grid.size())
	material.set_shader_parameter("rows",rows)
	material.set_shader_parameter("columns",columns)
	material.set_meta("contact_grid",grid)
	_contact_materials[cache_key] = material
	sprite.material = material

func _scan_actors() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var exists := false
		for entry: Dictionary in actors:
			if is_instance_valid(entry.enemy) and entry.enemy == enemy:
				exists = true
				break
		# F2 restores runtime-packed snapshots, which intentionally have no
		# scene_file_path. The unchanged enemy script remains a stable identity.
		var source: Script = enemy.get_script()
		var key: String = source.resource_path.get_file().get_basename()
		if exists or not manifest.has(key) or not source_manifest.has(key):
			continue
		for image: Sprite2D in enemy.find_children("*","Sprite2D",true,false):
			if not image.texture is ViewportTexture:
				continue
			var model := image.get_parent() as Node2D
			var painted := _sprite(key,0)
			model.add_child(painted)
			var entry := {"enemy":enemy,"key":key,"model":model,"original":image,"painted":painted,"bounds":_rect(source_manifest[key].bounds)}
			actors.append(entry)
			_fit_pose(painted,key,entry.bounds,Transform2D.IDENTITY)
			break
	if manifest.has("water_bulb"):
		for node: Node in room.find_children("*","",true,false):
			if not node is GreyboxBumper2D or node.has_meta("painted_comparison_bound"):
				continue
			node.set_meta("painted_comparison_bound",true)
			var painted := _sprite("water_bulb",0)
			var current := ShaderMaterial.new()
			current.shader = BULB_CURRENT
			current.set_shader_parameter("atlas_size",_texture("water_bulb",0).atlas.get_size())
			painted.material = current
			node.add_child(painted)
			bulbs.append({"node":node,"painted":painted})

func _update_actors(_delta: float) -> void:
	for index in range(actors.size()-1,-1,-1):
		var entry: Dictionary = actors[index]
		if not is_instance_valid(entry.enemy):
			actors.remove_at(index)
			continue
		entry.original.visible = not enemies_enabled
		entry.painted.visible = enemies_enabled
		for view: SubViewport in entry.model.find_children("*","SubViewport",true,false):
			view.render_target_update_mode = SubViewport.UPDATE_DISABLED if enemies_enabled else SubViewport.UPDATE_ALWAYS
		if not enemies_enabled:
			continue
		# Animation/bone anchors continue to serve existing gameplay, while only
		# the painted sprite is rendered. No AI/combat state is replaced.
		var animator: AnimationPlayer = entry.model.get("animator")
		var clip := String(animator.current_animation).to_lower() if animator else "idle"
		var frame := 0
		if "hurt" in clip or "dead" in clip or entry.enemy.is_dead:
			frame = 5
		elif "windup" in clip or "charge" in clip or "aim" in clip or "curl" in clip or "wall_perch" in clip:
			frame = 2
		elif "fire" in clip or "release" in clip or "slash" in clip or "sweep" in clip or "jab" in clip or "cross" in clip or "smash" in clip or "dash" in clip or "launch" in clip:
			frame = 3
		elif "recover" in clip or "land" in clip:
			frame = 4
		elif "run" in clip or "walk" in clip or "flight" in clip or "swim" in clip:
			frame = int(_clock*6.0)%2
		if entry.key == "tide_duelist" and (clip in ["life/hover","still","life/dash_glide"] or clip.is_empty()) and not entry.enemy.is_dead:
			var swim_key := "tide_duelist_swim_v2"
			var swim_frame := int(_clock*(20.0 if clip == "life/dash_glide" else 16.0))%12
			entry.painted.texture = _texture(swim_key,swim_frame)
			_fit_pose(entry.painted,swim_key,entry.bounds,Transform2D.IDENTITY,swim_frame)
			continue
		entry.painted.texture = _texture(entry.key,frame)
		var bounds: Rect2 = entry.bounds
		_fit_pose(entry.painted,entry.key,bounds,Transform2D.IDENTITY,frame)
		if entry.key == "bellstriker":
			var pivot := Vector2(0,-54)
			entry.painted.position = pivot+(entry.painted.position-pivot).rotated(entry.original.rotation)
			entry.painted.rotation = entry.original.rotation

func _update_worker(entry: Dictionary, sprite: Sprite2D) -> void:
	var worker: Node2D = entry.node
	if not worker.house_path.is_empty():
		var house = worker.get_node(worker.house_path)
		sprite.visible = house.render_model.is_cutaway
	var greeting := bool(worker.render_model.interacting)
	sprite.texture = _texture(entry.key,1 if greeting else 0)
	_fit_pose(sprite,entry.key,entry.bounds,worker.global_transform,1 if greeting else 0)

func _update_bulbs(_delta: float) -> void:
	for entry: Dictionary in bulbs:
		var bulb: GreyboxBumper2D = entry.node
		var painted: Sprite2D = entry.painted
		bulb._bulb_visual.visible = not bulbs_enabled
		painted.visible = bulbs_enabled
		if not bulbs_enabled:
			continue
		var original: AnimatedSprite2D = bulb._bulb_visual
		var frame := 0
		match original.animation:
			&"pop": frame = 2
			&"spent": frame = 3
			&"refill": frame = 4+int(_clock*6.0)%2
			# Idle frames are separate drawings, not registered in-between frames.
			# Keep the contact sac steady until the actual lifecycle changes.
			_: frame = 0
		painted.texture = _texture("water_bulb",frame)
		var region := _rect(manifest.water_bulb.frames[frame])
		painted.material.set_shader_parameter("atlas_region",Vector4(region.position.x,region.position.y,region.size.x,region.size.y))
		painted.material.set_shader_parameter("current_time",_clock+float(bulb.get_instance_id()%29)*0.21)
		painted.material.set_shader_parameter("idle_energy",1.0 if frame == 0 else 0.0)
		# Register the sac itself to the existing hit/grapple square. Stem/petals
		# may have different illustrated contours, but the active bulb stays 1:1.
		painted.scale = Vector2.ONE*(bulb.size.x/286.0)
		var offset: Array = manifest.water_bulb.pose_offsets[frame]
		painted.position = (Vector2(-285,-404)+Vector2(offset[0],offset[1]))*painted.scale

func set_all(enabled: bool) -> void:
	buildings_enabled = enabled
	actors_enabled = enabled
	enemies_enabled = enabled
	bulbs_enabled = enabled
	_sync_buttons()
	_process(0)

func set_tower_painted(enabled: bool) -> void:
	tower_painted_enabled = enabled
	_sync_buttons()
	_process(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		set_all(not (buildings_enabled and actors_enabled and enemies_enabled and bulbs_enabled))
		get_viewport().set_input_as_handled()

func _build_controls() -> void:
	controls = CanvasLayer.new()
	controls.name = "ComparisonControls"
	controls.layer = 50
	add_child(controls)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(24,976)
	controls.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := Label.new()
	label.text = "F7: compare all 2D / 3D • Tower switches separately"
	column.add_child(label)
	var row := HBoxContainer.new()
	column.add_child(row)
	for category: String in ["Buildings","Tower","Villagers","Enemies","Bulbs"]:
		var button := CheckButton.new()
		button.name = category
		button.text = category+": painted 2D"
		button.button_pressed = category not in ["Tower","Enemies"]
		row.add_child(button)
		button.toggled.connect(func(enabled: bool):
			match category:
				"Buildings": buildings_enabled = enabled
				"Tower": tower_painted_enabled = enabled
				"Villagers": actors_enabled = enabled
				"Enemies": enemies_enabled = enabled
				"Bulbs": bulbs_enabled = enabled
			_sync_buttons()
			_process(0))
	_sync_buttons()

func _sync_buttons() -> void:
	if not controls:
		return
	for button: CheckButton in controls.find_children("*","CheckButton",true,false):
		var enabled := buildings_enabled if button.name == "Buildings" else actors_enabled if button.name == "Villagers" else enemies_enabled if button.name == "Enemies" else bulbs_enabled
		if button.name == "Tower":
			enabled = tower_painted_enabled
		button.set_pressed_no_signal(enabled)
		button.text = String(button.name)+": "+("painted 2D" if enabled else "rendered" if button.name == "Bulbs" else "current 3D")
