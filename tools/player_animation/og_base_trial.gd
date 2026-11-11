extends SceneTree
## Cycle player appearances on one controller in the isolated Chamber.

const CHAMBER := "res://Src/Environment/World/Chamber Of The First Weave.tscn"
const TRIAL_DIR := "LocalOnly/OG_Export_Trial"
const LABELS := {
	&"og": "OG Base (live 3D)",
	&"legacy": "Original 2D sprites",
	&"baked": "Baked OG sprites (movement only)",
	&"modular": "Current modular doll",
	&"equipped": "Earlier equipped doll",
	&"original": "Original 3D player",
}
const SPRITES := preload("res://tools/player_animation/player_comparison_sprites.gd")
var player
var visual
var trial: MeshInstance3D
var hidden_layers: Dictionary
var status: Label
var models: Array[StringName] = []
var selected := 0
var alternate_visuals: Dictionary
var legacy: Sprite2D
var baked: AnimatedSprite2D
var repository: String


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	if not ProjectSettings.get_setting("application/config/name").begins_with("Threadbound Sprite Study"):
		fail("Run this comparison from the isolated Threadbound Sprite Study project.")
		return
	root.title = "Threadbound - Player Model Comparison"
	repository = ProjectSettings.globalize_path("res://").path_join("../../..").simplify_path()
	var room: Node = load(CHAMBER).instantiate()
	room.get_node("TutorialController").tutorial_enabled = false
	var welcome := room.get_node_or_null("PlaytestWelcome")
	if welcome:
		welcome.free()
	player = room.get_node("Player")
	visual = player.get_node("Live3DVisual")
	if not OS.get_cmdline_user_args().has("--original-player"):
		fail("Launch with start_og_base_trial.ps1 so the original model can be loaded.")
		return
	var default_model: PackedScene = visual.MODEL
	if ResourceLoader.exists(visual.MODULAR_DOLL_PATH) and visual.EQUIPMENT_VISUALS.default_assets_available():
		visual.model_scene = load(visual.MODULAR_DOLL_PATH)
	elif ResourceLoader.exists(visual.DOLL_PREVIEW_PATH):
		visual.model_scene = load(visual.DOLL_PREVIEW_PATH)
	root.add_child(room)
	current_scene = room
	if visual.equipment_visuals and FileAccess.file_exists(repository.path_join(TRIAL_DIR).path_join("OG_Base_Trial.glb")):
		if install_trial():
			models.append(&"og")
		visual.equipment_visuals.item_changed.connect(_on_equipment_changed)
	legacy = SPRITES.make_legacy(repository.path_join(TRIAL_DIR).path_join("legacy_sprites"))
	baked = SPRITES.make_baked(repository.path_join("LocalOnly/OG_Material_Review"))
	if legacy:
		player.add_child(legacy)
		models.append(&"legacy")
	if baked:
		player.add_child(baked)
		models.append(&"baked")
	if visual.equipment_visuals:
		models.append(&"modular")
	if ResourceLoader.exists(visual.DOLL_PREVIEW_PATH):
		add_alternate(&"equipped", load(visual.DOLL_PREVIEW_PATH))
	add_alternate(&"original", default_model)
	# The live composites are added deferred by the normal presentation script.
	await process_frame

	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	status = Label.new()
	status.position = Vector2(24, 1010)
	status.add_theme_font_size_override("font_size", 20)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x", 2)
	status.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(status)
	root.window_input.connect(_on_window_input)
	process_frame.connect(refresh_appearance)
	update_comparison()

	print("OG_TRIAL_READY bones=", visual._skeleton.get_bone_count(),
		" clips=", visual._animation_player.get_animation_list().size(),
		" viewport=", visual._viewport.size, " models=", models)
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
		selected = posmod(selected + (-1 if event.shift_pressed else 1), models.size())
		update_comparison()


func _on_equipment_changed(_slot: StringName, _item: Resource) -> void:
	if models[selected] == &"og":
		update_comparison.call_deferred()


func update_comparison() -> void:
	for instance in hidden_layers:
		var mesh := instance_from_id(instance) as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.layers = hidden_layers[instance]
	hidden_layers.clear()
	var model := models[selected]
	if trial:
		trial.visible = model == &"og"
	if legacy:
		legacy.visible = model == &"legacy"
	if baked:
		baked.visible = model == &"baked"
		if not baked.visible:
			baked.stop()
			baked.animation = &"idle"
	var active = alternate_visuals.get(model, visual)
	for alternate in alternate_visuals.values():
		alternate._viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if alternate == active else SubViewport.UPDATE_DISABLED
	visual._display.visible = model != &"legacy" and model != &"baked"
	visual._viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active == visual and visual._display.visible else SubViewport.UPDATE_DISABLED
	visual._display.texture = active._viewport.get_texture()
	status.text = "%d/%d  %s   |   F7 next · Shift+F7 previous" % [selected + 1, models.size(), LABELS[model]]
	refresh_appearance()
	if model != &"og":
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


func add_alternate(id: StringName, scene: PackedScene) -> void:
	models.append(id)
	if scene == visual.model_scene:
		return
	var alternate = visual.get_script().new()
	alternate.name = "Comparison_" + String(id)
	alternate.model_scene = scene
	alternate.viewport_size = visual.viewport_size
	alternate.camera_size = visual.camera_size
	alternate.display_scale = visual.display_scale
	alternate.sword_smear_enabled = false
	player.add_child(alternate)
	alternate.set_process(false)
	alternate._viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	alternate._display.hide()
	alternate._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	alternate._lower_sampler_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	alternate_visuals[id] = alternate


func refresh_appearance() -> void:
	match models[selected]:
		&"legacy":
			SPRITES.sync_legacy(legacy, player.animation_clock, player.get_presentation_facing() < 0)
		&"baked":
			SPRITES.sync_baked(baked, player, visual._display)
		_:
			var alternate = alternate_visuals.get(models[selected])
			if alternate:
				sync_alternate(alternate)


func sync_alternate(alternate) -> void:
	# Sample the same logical clip and time while leaving gameplay on the live rig.
	var action: StringName = visual._current_action
	var animation: AnimationPlayer = alternate._animation_player
	var clip: StringName = alternate._clips.get(action, &"")
	if clip.is_empty():
		return
	if alternate._current_action != action:
		alternate._play_action(action, &"", 0.0, true)
	animation.seek(minf(visual.get_current_action_position(), animation.current_animation_length), true)
	alternate._logical_animation = visual._logical_animation
	alternate._idle_elapsed = 0.0
	alternate._upper_body_overlay_active = visual._upper_body_overlay_active
	if alternate._upper_body_overlay_active:
		alternate._sync_lower_body_sampler()
		var sampler: AnimationPlayer = alternate._lower_sampler_player
		var live_sampler: AnimationPlayer = visual._lower_sampler_player
		if not sampler.current_animation.is_empty() and not live_sampler.current_animation.is_empty():
			sampler.seek(minf(live_sampler.current_animation_position, sampler.current_animation_length), true)
	alternate._process(visual.get_process_delta_time())


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
	if not player.is_on_floor() or not trial or trial.get_node(trial.skeleton) != visual._skeleton:
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
	Input.action_press("Grapple")
	await frames(5)
	Input.action_release("Grapple")
	if not player.current_gloves.active_grapple_root.visible:
		fail("The separate grapple rope and needle did not deploy.")
		return
	await capture("Chamber_OG_Base_Grapple")
	await frames(90)
	if not await verify_cycle():
		return
	print("OG_TRIAL_VERIFIED live skeleton, movement, attack, grapple and model cycle")
	quit()


func verify_cycle() -> bool:
	var expected: Array[StringName] = [&"og", &"legacy", &"baked", &"modular", &"equipped", &"original"]
	if models != expected:
		fail("The local comparison is missing appearances: " + str(models))
		return false
	var toggle := InputEventKey.new()
	toggle.physical_keycode = KEY_F7
	toggle.pressed = true
	for index in range(1, models.size()):
		var position: Vector2 = player.position
		_on_window_input(toggle)
		if player.position != position or player.live_3d_visual != visual or selected != index or trial.visible or not hidden_layers.is_empty():
			fail("Switching appearances must preserve the player and clear the prior outfit.")
			return false
		await frames(3)
		var model := models[selected]
		var active = alternate_visuals.get(model, visual)
		if model == &"legacy" and (not legacy.visible or not legacy.texture) \
			or model == &"baked" and (not baked.visible or not baked.is_playing()) \
			or visual._display.texture != active._viewport.get_texture():
			fail("The appearance did not display: " + String(model))
			return false
		await capture("Cycle_" + String(model) + "_Idle")
		Input.action_press("move_right")
		await frames(20)
		if visual._current_action != &"run_1" or (active != visual and active._current_action != &"run_1"):
			fail("Run playback did not reach " + String(model))
			return false
		if model == &"legacy" and player.animation_clock.animation != &"Run" \
			or model == &"baked" and baked.animation != &"run":
			fail("The sprite appearance did not enter its run clip.")
			return false
		await capture("Cycle_" + String(model) + "_Run")
		Input.action_release("move_right")
		Input.action_press("Jump")
		await frames(10)
		Input.action_release("Jump")
		if player.is_on_floor():
			fail("Jump failed with " + String(model))
			return false
		if model == &"legacy" and not String(player.animation_clock.animation).begins_with("Jump_") \
			or model == &"baked" and baked.animation != &"jump":
			fail("The sprite appearance did not enter its jump clip.")
			return false
		await capture("Cycle_" + String(model) + "_Jump")
		await frames(85)
		Input.action_press("move_left")
		await frames(20)
		Input.action_release("move_left")
		await frames(25)
	_on_window_input(toggle)
	if selected != 0 or not trial.visible:
		fail("Forward cycle did not wrap to OG Base.")
		return false
	toggle.shift_pressed = true
	_on_window_input(toggle)
	if selected != models.size() - 1 or trial.visible:
		fail("Reverse cycle did not wrap to the original 3D player.")
		return false
	print("PLAYER_MODEL_CYCLE_VERIFIED ", models)
	return true


func fail(message: String) -> void:
	push_error(message)
	quit(1)
