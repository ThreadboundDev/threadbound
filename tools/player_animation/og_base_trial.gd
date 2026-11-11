extends SceneTree
## Opt-in OG Base mesh comparison on the Chamber's live player skeleton.

const CHAMBER := "res://Src/Environment/World/Chamber Of The First Weave.tscn"
const TRIAL_DIR := "LocalOnly/OG_Export_Trial"
var player
var visual
var trial: MeshInstance3D
var hidden_layers: Dictionary
var status: Label
var show_trial := true
var repository: String


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if not ProjectSettings.get_setting("application/config/name").begins_with("Threadbound Sprite Study"):
		fail("Run this comparison from the isolated Threadbound Sprite Study project.")
		return
	repository = ProjectSettings.globalize_path("res://").path_join("../../..").simplify_path()
	var room: Node = load(CHAMBER).instantiate()
	room.get_node("TutorialController").tutorial_enabled = false
	var welcome := room.get_node_or_null("PlaytestWelcome")
	if welcome:
		welcome.free()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	visual = player.live_3d_visual
	if not visual.equipment_visuals or not install_trial():
		fail("The OG fit requires the current modular doll and its Base equipment exports.")
		return

	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	status = Label.new()
	status.position = Vector2(24, 1010)
	status.add_theme_font_size_override("font_size", 20)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x", 2)
	status.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(status)
	visual.equipment_visuals.item_changed.connect(_on_equipment_changed)
	root.window_input.connect(_on_window_input)
	update_comparison()

	print("OG_TRIAL_READY bones=", visual._skeleton.get_bone_count(),
		" clips=", visual._animation_player.get_animation_list().size(),
		" viewport=", visual._viewport.size)
	if OS.get_cmdline_user_args().has("--verify"):
		await verify()


func install_trial() -> bool:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(repository.path_join(TRIAL_DIR).path_join("OG_Base_Trial.glb"), state) != OK:
		return false
	var source := document.generate_scene(state)
	if not source:
		return false
	var mesh := source.find_child("OG_Base_Trial", true, false) as MeshInstance3D
	if not mesh or not mesh.skin:
		source.free()
		return false
	var donor := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
	if not donor:
		source.free()
		return false
	var target: Skeleton3D = visual._skeleton
	var skin := Skin.new()
	for index in mesh.skin.get_bind_count():
		var bone_name := mesh.skin.get_bind_name(index)
		if bone_name.is_empty():
			var bone := mesh.skin.get_bind_bone(index)
			if bone < 0 or bone >= donor.get_bone_count():
				source.free()
				return false
			bone_name = donor.get_bone_name(bone)
		var donor_index := donor.find_bone(bone_name)
		var target_index := target.find_bone(bone_name)
		if donor_index < 0 or target_index < 0 or not donor.get_bone_global_rest(donor_index).is_equal_approx(
			target.get_bone_global_rest(target_index)
		):
			push_error("OG Base trial rest pose mismatch at " + String(bone_name))
			source.free()
			return false
		skin.add_named_bind(bone_name, mesh.skin.get_bind_pose(index))
	var wrapper := Node3D.new()
	wrapper.name = "OGBaseComparison"
	visual._model_root.add_child(wrapper)
	var authored_transform := mesh.transform
	var ancestor := mesh.get_parent() as Node3D
	while ancestor:
		authored_transform = ancestor.transform * authored_transform
		ancestor = ancestor.get_parent() as Node3D
	mesh.owner = null
	mesh.reparent(wrapper, false)
	mesh.transform = authored_transform
	mesh.skin = skin
	mesh.skeleton = mesh.get_path_to(target)
	source.free()
	trial = mesh
	# The existing light rig can blow out matte vertex paint with toon specular.
	for surface in trial.mesh.get_surface_count():
		var material := trial.get_active_material(surface) as StandardMaterial3D
		if material:
			material.vertex_color_use_as_albedo = true
			material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			material.cull_mode = BaseMaterial3D.CULL_BACK
	visual._install_object_outline(trial, 6.0)
	return true


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_F7 and event.pressed and not event.echo:
		show_trial = not show_trial
		update_comparison()


func _on_equipment_changed(_slot: StringName, _item: Resource) -> void:
	update_comparison.call_deferred()


func update_comparison() -> void:
	for instance in hidden_layers:
		var mesh := instance_from_id(instance) as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.layers = hidden_layers[instance]
	hidden_layers.clear()
	trial.visible = show_trial
	status.text = "F7  |  " + ("OG Base fit" if show_trial else "Current player")
	if not show_trial:
		return
	for node in visual._model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh == trial or trial.is_ancestor_of(mesh):
			continue
		var part := mesh.get_parent() if mesh.get_meta("outline_only", false) else mesh
		var part_name := String(part.name)
		if part_name == "Threadborne_Sword" or "Grapple" in part_name or "Shield" in part_name:
			continue
		hidden_layers[mesh.get_instance_id()] = mesh.layers
		mesh.layers = 0


func frames(count: int) -> void:
	for index in count:
		await physics_frame


func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var out := repository.path_join(TRIAL_DIR)
	var image := root.get_texture().get_image()
	assert(image.save_png(out.path_join(label + ".png")) == OK)
	if label == "Chamber_OG_Base_Idle":
		var native: Image = visual._viewport.get_texture().get_image()
		assert(native.get_size() == visual._viewport.size)
		assert(native.save_png(out.path_join("OG_Base_Idle_Native.png")) == OK)


func verify() -> void:
	await frames(100)
	if not player.is_on_floor() or trial.get_node(trial.skeleton) != visual._skeleton:
		fail("The candidate must use the live player skeleton and start on the Chamber floor.")
		return
	await capture("Chamber_OG_Base_Idle")
	var start: float = player.position.x
	Input.action_press("move_right")
	await frames(30)
	if player.position.x < start + 20 or visual._current_action != &"run_1":
		fail("The normal movement and run clip did not play.")
		return
	await capture("Chamber_OG_Base_Run")
	Input.action_release("move_right")
	await frames(30)
	Input.action_press("Jump")
	await frames(10)
	Input.action_release("Jump")
	if player.is_on_floor():
		fail("The player did not jump.")
		return
	await capture("Chamber_OG_Base_Jump")
	await frames(90)
	if not player.is_on_floor():
		fail("The player did not land.")
		return
	Input.action_press("Attack")
	await frames(4)
	Input.action_release("Attack")
	if not player.is_attacking:
		fail("The normal attack did not start.")
		return
	await capture("Chamber_OG_Base_Attack")
	await frames(60)
	Input.action_press("move_left")
	await frames(14)
	Input.action_release("move_left")
	if not visual._display.flip_h:
		fail("The player did not mirror on direction change.")
		return
	show_trial = false
	update_comparison()
	if trial.visible or not hidden_layers.is_empty():
		fail("The comparison did not restore the current player.")
		return
	await capture("Chamber_Current_Player")
	var toggle := InputEventKey.new()
	toggle.physical_keycode = KEY_F7
	toggle.pressed = true
	_on_window_input(toggle)
	if not trial.visible or hidden_layers.is_empty():
		fail("F7 did not restore the OG Base comparison.")
		return
	Input.action_press("Grapple")
	await frames(5)
	Input.action_release("Grapple")
	if not player.current_gloves.active_grapple_root.visible:
		fail("The separate grapple rope and needle did not deploy.")
		return
	await capture("Chamber_OG_Base_Grapple")
	print("OG_TRIAL_VERIFIED live skeleton, idle, run, jump, landing, attack, facing, grapple cast, comparison")
	quit()


func fail(message: String) -> void:
	push_error(message)
	quit(1)
