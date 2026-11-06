class_name InventoryCharacterPreview
extends TextureRect
## An independent idle portrait; the paused gameplay skeleton is never posed here.

var viewport: SubViewport
var model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var equipment: PlayerEquipmentVisuals
var _source: PlayerLive3DVisual
var _active := false


func initialize(source: PlayerLive3DVisual) -> bool:
	if not source or not source._animation_player or not source._clips.has(&"idle_4"):
		return false
	_source = source
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	light_mask = 0
	viewport = SubViewport.new()
	viewport.name = "InventoryCharacterViewport"
	viewport.size = Vector2i(500, 700)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	for child in source._viewport.get_children():
		if child is WorldEnvironment or child is DirectionalLight3D:
			viewport.add_child(child.duplicate())
	model = source.model_scene.instantiate() as Node3D
	viewport.add_child(model)
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if skeletons.is_empty() or players.is_empty():
		return false
	skeleton = skeletons[0] as Skeleton3D
	animation_player = players[0] as AnimationPlayer
	# Share immutable animation resources, with a separate player and skeleton.
	for library in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(library)
	for library in source._animation_player.get_animation_library_list():
		animation_player.add_animation_library(library, source._animation_player.get_animation_library(library))
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_player.play(source._clips[&"idle_4"])
	animation_player.advance(0)
	if source.equipment_visuals:
		equipment = PlayerEquipmentVisuals.new()
		model.add_child(equipment)
		if not equipment.initialize(skeleton):
			return false
		equipment.item_changed.connect(_on_preview_item_changed)
		for slot in source.equipment_visuals.equipped:
			_mirror_item(slot, source.equipment_visuals.equipped[slot])
		source.equipment_visuals.item_changed.connect(_mirror_item)
	source._apply_toon_materials(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 2.1
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(-6.0, 1.1, 2.0), Vector3(0, .96, 0), Vector3.UP)
	camera.current = true
	texture = viewport.get_texture()
	var outline := source._display.material.duplicate() as ShaderMaterial
	outline.set_shader_parameter("outline_source_pixels", 2.0)
	outline.set_shader_parameter("exposure", .9)
	material = outline
	set_active(true)
	return true


func set_active(active: bool) -> void:
	if not viewport or _active == active:
		return
	_active = active
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	model.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if equipment and equipment.cloth_motion:
		equipment.cloth_motion.reset()


func _process(delta: float) -> void:
	if _active and animation_player and is_visible_in_tree():
		skeleton.clear_bones_global_pose_override()
		animation_player.advance(delta)
		# The frontal portrait needs the blade biased to the other side of the face.
		PlayerLive3DVisual.apply_idle_sword_clearance_pose(skeleton, -1.0)


func _mirror_item(slot: StringName, item: EquipmentVisualDefinition) -> void:
	if item:
		if equipment.equipped.get(slot) != item:
			equipment.equip(item)
	else:
		equipment.clear_slot(slot)


func _on_preview_item_changed(slot: StringName, _item: EquipmentVisualDefinition) -> void:
	# New gear meshes get the same material treatment as the gameplay character.
	_source._apply_toon_materials(equipment._roots[slot] if equipment._roots.has(slot) else model)
