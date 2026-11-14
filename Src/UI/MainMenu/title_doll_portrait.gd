extends TextureRect
## A seated copy of the modular doll, rendered separately from the painted seat.

const VIEWPORT_SIZE := Vector2i(1440, 1611)
const TITLE_DOLL := "res://Assets/Threadborne/Player/LocalDoll/title_master_doll.glb"
const SEAT_CLIP := &"Animation"
const WRIST_CENTERS := {&"hand.R": Vector3(-0.7056, 1.5266, -0.0156), &"hand.L": Vector3(0.7064, 1.5266, -0.0156)}
const SWORD_REST := Vector2(480, 568)
const SHIELD_REST := Vector2(416, 516)
const STITCH_CYCLE := 6.8
const SEAT_OFFSET := Vector2(-26, 59)
const HEARTH_ENERGY := 0.66

@export var show_gear := true

var _thread_ends := PackedVector2Array()
var _idle_time := 0.0
var _thread_pull := 0.0
var _skeleton: Skeleton3D
var _camera: Camera3D
var _seated_rotations: Dictionary[StringName, Quaternion] = {}
var _seated_wrist_positions: Dictionary[StringName, Vector3] = {}
var _wrist_pivots: Dictionary[StringName, Vector3] = {}
var _hearth_light: OmniLight3D
var _hearth_time := 0.0


func _ready() -> void:
	var model_path := TITLE_DOLL
	if not ResourceLoader.exists(model_path):
		return
	var model_scene := load(model_path) as PackedScene
	if not model_scene:
		return
	var model := model_scene.instantiate() as Node3D
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if skeletons.is_empty() or players.is_empty():
		model.free()
		return
	var skeleton := skeletons[0] as Skeleton3D
	var player := players[0] as AnimationPlayer

	var viewport := SubViewport.new()
	viewport.name = "SeatedDollViewport"
	viewport.size = VIEWPORT_SIZE
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_8X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.mesh_lod_threshold = 0.0
	add_child(viewport)
	viewport.add_child(model)

	var equipment: PlayerEquipmentVisuals
	if show_gear and PlayerEquipmentVisuals.default_assets_available():
		equipment = PlayerEquipmentVisuals.new()
		equipment.name = "EquipmentVisuals"
		model.add_child(equipment)
		if not equipment.initialize(skeleton):
			viewport.queue_free()
			return
		var loadout := DemoProgress.get_checkpoint_loadout()
		for slot_type in loadout.size():
			equipment._on_gameplay_equipment_changed(slot_type, loadout[slot_type])
		equipment.item_changed.connect(_on_gear_changed.bind(equipment))
	var styling := PlayerLive3DVisual.new()
	styling._apply_toon_materials(model, 1.5)
	styling.free()

	if not player.has_animation(SEAT_CLIP):
		viewport.queue_free()
		return
	player.play(SEAT_CLIP)
	player.seek(player.get_animation(SEAT_CLIP).length, true)
	player.pause()
	_skeleton = skeleton
	for bone_name: StringName in [&"spine", &"chest", &"head", &"forearm.R", &"forearm.L", &"hand.R", &"hand.L"]:
		var bone := skeleton.find_bone(bone_name)
		if bone >= 0:
			_seated_rotations[bone_name] = skeleton.get_bone_pose_rotation(bone)
	for bone_name: StringName in WRIST_CENTERS:
		var bone := skeleton.find_bone(bone_name)
		if bone >= 0:
			_seated_wrist_positions[bone_name] = skeleton.get_bone_pose_position(bone)
			_wrist_pivots[bone_name] = skeleton.get_bone_global_rest(bone).affine_inverse() * WRIST_CENTERS[bone_name]

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.77, 0.81, 0.91)
	environment.ambient_light_energy = 0.24
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	viewport.add_child(world)
	_add_light(viewport, Vector3(-2, 3, 4), Color(0.86, 0.90, 1.0), 0.34)
	_add_light(viewport, Vector3(2, 2, -4), Color(1.0, 0.73, 0.48), 0.53)
	_hearth_light = OmniLight3D.new()
	_hearth_light.name = "BlossomGlow"
	_hearth_light.position = Vector3(0.17, 0.31, 0.66)
	_hearth_light.light_color = Color(1.0, 0.64, 0.34)
	_hearth_light.light_energy = HEARTH_ENERGY
	_hearth_light.omni_range = 1.85
	viewport.add_child(_hearth_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.99 * 604.0 / 450.0
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(2.6, 1.55, 5.8), Vector3(0, 0.65, 0), Vector3.UP)
	camera.current = true
	_camera = camera
	_place_doll_on_seat(model)
	var equipped_weapon := equipment._roots.get(&"weapon") as Node3D if equipment else null
	if equipped_weapon:
		_stage_resting_weapons(viewport, camera, equipped_weapon)
		equipment.clear_slot(&"weapon")
	texture = viewport.get_texture()
	_pose_idle()


func _place_doll_on_seat(model: Node3D) -> void:
	# The cushion is painted, so match the pelvis and boot contacts in screen space.
	model.global_position += _screen_offset(SEAT_OFFSET)
	_pose_leg("R", Vector2(-31, 40), -0.02)
	_pose_leg("L", Vector2(9, -41), -0.025)
	var hips := _project_bone(&"pelvis")
	# Spread the soft shadow across the cushion and keep the dense part at contact.
	_add_contact_shadow(hips + Vector2(-10, 16), Vector2(174, 66), Color(0.032, 0.039, 0.065, 0.66))
	_add_contact_shadow(hips + Vector2(-3, 9), Vector2(105, 35), Color(0.019, 0.023, 0.039, 0.88))
	var right_knee := _project_bone(&"shin.R")
	_add_contact_shadow(hips.lerp(right_knee, 0.46) + Vector2(-2, 9), Vector2(96, 29),
		Color(0.023, 0.032, 0.054, 0.82), Vector2.RIGHT.angle_to(right_knee - hips))
	_add_contact_shadow(hips + Vector2(22, 12), Vector2(65, 30), Color(0.021, 0.029, 0.050, 0.72))
	var floor_contact := _project_bone(&"toe.R") + Vector2(7, 8)
	_add_contact_shadow(floor_contact + Vector2(7, 1), Vector2(94, 27), Color(0.11, 0.074, 0.049, 0.49), -0.12)
	_add_contact_shadow(floor_contact, Vector2(56, 13), Color(0.09, 0.055, 0.033, 0.86), -0.12)
	_add_contact_shadow(_project_bone(&"toe.L") + Vector2(1, 9), Vector2(49, 15), Color(0.066, 0.054, 0.06, 0.55))


func _project_bone(name: StringName) -> Vector2:
	var pose := _skeleton.get_bone_global_pose(_skeleton.find_bone(name))
	return _camera.unproject_position(_skeleton.to_global(pose.origin)) * size / Vector2(VIEWPORT_SIZE)


func _screen_offset(pixels: Vector2) -> Vector3:
	return _camera.global_basis * Vector3(pixels.x, -pixels.y, 0.0) * (_camera.size / size.y)


func _pose_leg(side: String, ankle_offset: Vector2, depth: float) -> void:
	var thigh := _skeleton.find_bone("thigh." + side)
	var shin := _skeleton.find_bone("shin." + side)
	var foot := _skeleton.find_bone("foot." + side)
	if thigh < 0 or shin < 0 or foot < 0:
		return

	var hip := _skeleton.get_bone_global_pose(thigh).origin
	var knee := _skeleton.get_bone_global_pose(shin).origin
	var ankle_pose := _skeleton.get_bone_global_pose(foot)
	var ankle := ankle_pose.origin
	var upper_length := hip.distance_to(knee)
	var lower_length := knee.distance_to(ankle)
	var offset := _screen_offset(ankle_offset) + _camera.global_basis.z * depth
	var target := ankle + _skeleton.global_basis.inverse() * offset
	var axis := (target - hip).normalized()
	var distance := clampf(hip.distance_to(target), absf(upper_length - lower_length) + 0.001, upper_length + lower_length - 0.001)
	# Keep the knee bending along the side of the original sit pose.
	var bend := (knee - hip).slide(axis).normalized()
	var along := (upper_length * upper_length + distance * distance - lower_length * lower_length) / (2.0 * distance)
	var rise := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var new_knee := hip + axis * along + bend * rise
	var new_ankle := hip + axis * distance
	_aim_bone(thigh, knee - hip, new_knee - hip)
	_aim_bone(shin, _skeleton.get_bone_global_pose(foot).origin - new_knee, new_ankle - new_knee)
	_skeleton.set_bone_global_pose(foot, Transform3D(ankle_pose.basis, _skeleton.get_bone_global_pose(foot).origin))


func _aim_bone(bone: int, from: Vector3, toward: Vector3) -> void:
	var pose := _skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(Quaternion(from.normalized(), toward.normalized())) * pose.basis
	_skeleton.set_bone_global_pose(bone, pose)


func _add_contact_shadow(center: Vector2, extent: Vector2, tint: Color, angle := 0.0) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([tint, Color(tint, tint.a * 0.55), Color(tint, 0.0)])
	var soft_shadow := GradientTexture2D.new()
	soft_shadow.gradient = gradient
	soft_shadow.fill = GradientTexture2D.FILL_RADIAL
	soft_shadow.fill_from = Vector2(0.5, 0.5)
	soft_shadow.fill_to = Vector2(1.0, 0.5)
	var shadow := TextureRect.new()
	shadow.texture = soft_shadow
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.show_behind_parent = true
	shadow.size = extent
	shadow.position = center - extent * 0.5
	shadow.pivot_offset = extent * 0.5
	shadow.rotation = angle
	add_child(shadow)


func _stage_resting_weapons(viewport: SubViewport, camera: Camera3D, equipped_weapon: Node3D) -> void:
	var resting := Node3D.new()
	resting.name = "RestingWeapons"
	viewport.add_child(resting)
	var styling := PlayerLive3DVisual.new()
	for child in equipped_weapon.get_children():
		var source := child as MeshInstance3D
		if not source or not source.mesh:
			continue
		var is_sword := source.name == &"Threadborne_Sword"
		var is_shield := String(source.name).begins_with("Shield_")
		if not is_sword and not is_shield:
			continue
		# Use the same mesh and styled materials, with a rigid pose independent of the hands.
		var prop := MeshInstance3D.new()
		prop.name = source.name
		prop.mesh = _rigid_mesh(source.mesh)
		for surface in prop.mesh.get_surface_count():
			prop.set_surface_override_material(surface, source.get_active_material(surface))
		resting.add_child(prop)
		var anchor := SWORD_REST if is_sword else SHIELD_REST
		var origin := Vector3(-0.79, 1.48, 0.7593) if is_sword else Vector3(0.61, 1.61, -0.024)
		var rotation := Basis(Vector3.RIGHT, deg_to_rad(82.0 if is_sword else 77.0))
		var lean := Basis(Vector3.BACK, deg_to_rad(-8.0 if is_sword else -11.0))
		var facing := Basis(Vector3.UP, deg_to_rad(-6.0 if is_sword else 22.0))
		var basis := camera.global_basis * lean * facing * rotation
		# Use the portrait's own dimensions. Camera projection can still use the
		# root viewport until the first SubViewport frame has been submitted.
		var frame := anchor / size - Vector2(0.5, 0.5)
		var span := Vector2(camera.size * VIEWPORT_SIZE.aspect(), camera.size)
		var world_point := camera.to_global(Vector3(frame.x * span.x, -frame.y * span.y, -5.8))
		prop.global_transform = Transform3D(basis, world_point - basis * origin)
		styling._install_object_outline(prop, 1.5)
	styling.free()


func _rigid_mesh(source: Mesh) -> ArrayMesh:
	var rigid := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		arrays[Mesh.ARRAY_BONES] = null
		arrays[Mesh.ARRAY_WEIGHTS] = null
		rigid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return rigid


func _pose_idle() -> void:
	for bone_name in _seated_rotations:
		var bone := _skeleton.find_bone(bone_name)
		_skeleton.set_bone_pose_rotation(bone, _seated_rotations[bone_name])

	# One pass reaches toward the other hand, draws the thread out, then settles.
	var phase := _idle_time / STITCH_CYCLE
	var reach := smoothstep(0.08, 0.25, phase) * (1.0 - smoothstep(0.34, 0.49, phase))
	var pull := smoothstep(0.34, 0.56, phase) * (1.0 - smoothstep(0.65, 0.87, phase))
	var breath := sin(phase * TAU * 2.0)
	_thread_pull = pull
	_rotate_from_seat(&"spine", Vector3.RIGHT, breath * 0.027 + reach * 0.024)
	_rotate_from_seat(&"chest", Vector3.RIGHT, breath * 0.023)
	_rotate_from_seat(&"head", Vector3.RIGHT, 0.045 + reach * 0.095 - pull * 0.035)
	_raise_forearm(_skeleton, "R", Vector3(-0.14 + reach * 0.24 - pull * 0.13, 0.20 + pull * 0.11, 0.06 + reach * 0.075))
	_raise_forearm(_skeleton, "L", Vector3(0.09 - reach * 0.06 + pull * 0.024, 0.11 + reach * 0.062, 0.02))
	_rotate_from_seat(&"hand.R", Vector3.UP, reach * 0.20 - pull * 0.12)
	_rotate_from_seat(&"hand.L", Vector3.UP, -reach * 0.10)

	_thread_ends.clear()
	for side in ["R", "L"]:
		var index := _skeleton.find_bone("index.03." + side)
		var thumb := _skeleton.find_bone("thumb.03." + side)
		var hand := _skeleton.find_bone("hand." + side)
		if hand < 0:
			return
		var pinch := _skeleton.get_bone_global_pose(hand).origin
		if index >= 0 and thumb >= 0:
			pinch = _skeleton.get_bone_global_pose(index).origin.lerp(_skeleton.get_bone_global_pose(thumb).origin, 0.4)
		_thread_ends.append(_camera.unproject_position(_skeleton.to_global(pinch)) / Vector2(VIEWPORT_SIZE))
	queue_redraw()


func _rotate_from_seat(bone_name: StringName, axis: Vector3, radians: float) -> void:
	if _seated_rotations.has(bone_name):
		var bone := _skeleton.find_bone(bone_name)
		var rest := _seated_rotations[bone_name]
		var rotation := rest * Quaternion(axis, radians)
		_skeleton.set_bone_pose_rotation(bone, rotation)
		if _wrist_pivots.has(bone_name):
			var pivot := _wrist_pivots[bone_name] * _skeleton.get_bone_pose_scale(bone)
			_skeleton.set_bone_pose_position(bone, _seated_wrist_positions[bone_name] + rest * pivot - rotation * pivot)


func _raise_forearm(skeleton: Skeleton3D, side: String, lift: Vector3) -> void:
	var forearm := skeleton.find_bone("forearm." + side)
	var hand := skeleton.find_bone("hand." + side)
	if forearm < 0 or hand < 0:
		return
	var pose := skeleton.get_bone_global_pose(forearm)
	var direction := skeleton.get_bone_global_pose(hand).origin - pose.origin
	var target := direction + lift
	pose.basis = Basis(Quaternion(direction.normalized(), target.normalized())) * pose.basis
	skeleton.set_bone_global_pose(forearm, pose)


func _process(delta: float) -> void:
	if _hearth_light:
		_hearth_time = fmod(_hearth_time + delta, TAU / 1.15)
		_hearth_light.light_energy = HEARTH_ENERGY + 0.027 * sin(_hearth_time * 1.15) + 0.015 * sin(_hearth_time * 3.45)
	if not _skeleton or not _camera:
		return
	_idle_time = fmod(_idle_time + delta, STITCH_CYCLE)
	_pose_idle()


func _draw() -> void:
	if _thread_ends.size() != 2:
		return
	var start := _thread_ends[0] * size
	var end := _thread_ends[1] * size
	var bend := lerpf(23.0, 4.0, _thread_pull)
	var middle := (start + end) * 0.5 + Vector2(0.0, bend * 2.0)
	var points := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		points.append(start.lerp(middle, t).lerp(middle.lerp(end, t), t))
	draw_polyline(points, Color(0.18, 0.10, 0.06, 0.7), 3.0, true)
	draw_polyline(points, Color(1.0, 0.88, 0.65), 1.45, true)


func _add_light(viewport: SubViewport, position: Vector3, color: Color, energy: float) -> void:
	var light := DirectionalLight3D.new()
	light.light_color = color
	light.light_energy = energy
	viewport.add_child(light)
	light.look_at_from_position(position, Vector3(0, 0.6, 0), Vector3.UP)


func _on_gear_changed(slot: StringName, _item: EquipmentVisualDefinition, equipment: PlayerEquipmentVisuals) -> void:
	var part := equipment._roots.get(slot) as Node3D
	if part:
		var styling := PlayerLive3DVisual.new()
		styling._apply_toon_materials(part, 1.5)
		styling.free()
