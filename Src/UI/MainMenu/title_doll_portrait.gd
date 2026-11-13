extends TextureRect
## A seated copy of the modular doll, rendered separately from the painted seat.

const VIEWPORT_SIZE := Vector2i(1440, 1611)
const SEAT_CLIP := "stand_to_sit_1"
const SWORD_REST := Vector2(492, 546)
const SHIELD_REST := Vector2(435, 516)

var _thread_ends := PackedVector2Array()
var _thread_time := 0.0
var _hearth_light: OmniLight3D
var _hearth_time := 0.0


func _ready() -> void:
	var model_path := PlayerLive3DVisual.MODULAR_DOLL_PATH
	if not ResourceLoader.exists(model_path) or not PlayerEquipmentVisuals.default_assets_available():
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

	var equipment := PlayerEquipmentVisuals.new()
	equipment.name = "EquipmentVisuals"
	model.add_child(equipment)
	if not equipment.initialize(skeleton):
		viewport.queue_free()
		return
	var loadout := DemoProgress.get_checkpoint_loadout()
	for slot_type in loadout.size():
		equipment._on_gameplay_equipment_changed(slot_type, loadout[slot_type])
	var styling := PlayerLive3DVisual.new()
	styling._apply_toon_materials(model, 1.5)
	styling.free()
	equipment.item_changed.connect(_on_gear_changed.bind(equipment))

	var seated := false
	for clip in player.get_animation_list():
		if String(clip).to_lower().ends_with(SEAT_CLIP):
			player.play(clip)
			player.seek(maxf(0.0, player.get_animation(clip).length - 0.034), true)
			player.pause()
			seated = true
			break
	if not seated:
		viewport.queue_free()
		return
	_raise_forearm(skeleton, "R", Vector3(-0.14, 0.20, 0.06))
	_raise_forearm(skeleton, "L", Vector3(0.09, 0.11, 0.02))

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.77, 0.81, 0.91)
	environment.ambient_light_energy = 0.29
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	viewport.add_child(world)
	_add_light(viewport, Vector3(-2, 3, 4), Color(0.86, 0.90, 1.0), 0.43)
	_add_light(viewport, Vector3(2, 2, -4), Color(1.0, 0.73, 0.48), 0.53)
	_hearth_light = OmniLight3D.new()
	_hearth_light.name = "BlossomGlow"
	_hearth_light.position = Vector3(0.20, 0.37, 0.84)
	_hearth_light.light_color = Color(1.0, 0.64, 0.34)
	_hearth_light.light_energy = 0.52
	_hearth_light.omni_range = 1.85
	viewport.add_child(_hearth_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.99 * 604.0 / 450.0
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(2.6, 1.55, 5.8), Vector3(0, 0.65, 0), Vector3.UP)
	camera.current = true
	var equipped_weapon := equipment._roots.get(&"weapon") as Node3D
	if equipped_weapon:
		equipped_weapon.hide()
	texture = viewport.get_texture()
	# Projection is stable once the viewport has drawn with its own camera.
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	if equipped_weapon:
		_stage_resting_weapons(viewport, camera, equipped_weapon)
		equipment.clear_slot(&"weapon")
	for side in ["R", "L"]:
		var hand := skeleton.find_bone("hand." + side)
		var fingertip := skeleton.find_bone("f_index.03." + side)
		if hand >= 0:
			var point := skeleton.to_global(skeleton.get_bone_global_pose(fingertip if fingertip >= 0 else hand).origin)
			_thread_ends.append(camera.unproject_position(point) / Vector2(VIEWPORT_SIZE))


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
		prop.mesh = source.mesh
		for surface in prop.mesh.get_surface_count():
			prop.set_surface_override_material(surface, source.get_active_material(surface))
		resting.add_child(prop)
		var anchor := SWORD_REST if is_sword else SHIELD_REST
		var origin := Vector3(-0.79, 1.48, 0.69) if is_sword else Vector3(0.61, 1.61, -0.024)
		var rotation := Basis(Vector3.RIGHT, deg_to_rad(82.0 if is_sword else 77.0))
		var lean := Basis(Vector3.BACK, deg_to_rad(17.0 if is_sword else -11.0))
		var facing := Basis(Vector3.UP, deg_to_rad(-19.0 if is_sword else 22.0))
		var basis := camera.global_basis * lean * facing * rotation
		var screen_point := anchor * Vector2(VIEWPORT_SIZE) / size
		var world_point := camera.project_position(screen_point, 5.8)
		prop.global_transform = Transform3D(basis, world_point - basis * origin)
		styling._install_object_outline(prop, 1.5)
	styling.free()


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
		_hearth_light.light_energy = 0.52 + 0.027 * sin(_hearth_time * 1.15) + 0.015 * sin(_hearth_time * 3.45)
	if _thread_ends.size() != 2:
		return
	_thread_time = fmod(_thread_time + delta, 6.0)
	queue_redraw()


func _draw() -> void:
	if _thread_ends.size() != 2:
		return
	var start := _thread_ends[0] * size
	var end := _thread_ends[1] * size
	var bend := 23.0 + 3.5 * sin(_thread_time * TAU / 6.0)
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
