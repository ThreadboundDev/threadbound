extends Node2D
## Isolated lighting study for the earlier equipped doll's wooden body.

const GRIP := preload("res://tools/fixtures/doll_lighting/wooden_doll_grip.gd")
const WEAPON_MESH_NAMES := [&"Threadborne_Sword", &"Threadborne_Shield_Combined_Test"]
const HILT_CENTER := Vector3(0.032, 0.042, -0.043)
const HILT_OFFSET := Vector3(0.0, 0.043, 0.009)
const HILT_TILT := -17.0
const PRESETS := [
	"Neutral | Soft white reference",
	"Sun | Warm directional light from above and in front",
	"Bulb | Steady soft-white point light",
	"Torch | Warm flickering cave-wall light",
]
const AMBIENT := [
	Color(0.82, 0.85, 0.90),
	Color(0.63, 0.73, 0.90),
	Color(0.60, 0.65, 0.76),
	Color(0.50, 0.54, 0.68),
]
const FILL := [0.84, 0.42, 0.31, 0.29]
const BACKDROP := [
	Color(0.22, 0.25, 0.28),
	Color(0.28, 0.29, 0.30),
	Color(0.14, 0.16, 0.19),
	Color(0.10, 0.11, 0.14),
]

@onready var player: CharacterBody2D = $Player
@onready var view: Camera2D = $RoomCamera
@onready var status: Label = $HUD/Status
@onready var hand_status: Label = $HUD/Hands
@onready var backdrop: Polygon2D = $Backdrop
@onready var fixtures: Array[CanvasItem] = [$RoomLights/Sun, $RoomLights/Bulb, $RoomLights/Torch]
@onready var bulb_source: Node2D = $RoomLights/Bulb
@onready var torch_source: Node2D = $RoomLights/Torch
@onready var torch_world: PointLight2D = $RoomLights/Torch/WallGlow
@onready var flame: Node2D = $RoomLights/Torch/Flame
@onready var actor_rig: Node3D = $ActorLights
@onready var sun: DirectionalLight3D = $ActorLights/SunKey
@onready var bulb: OmniLight3D = $ActorLights/BulbKey
@onready var torch: OmniLight3D = $ActorLights/TorchKey

var visual
var environment: Environment
var preset := 0
var elapsed := 0.0
var torch_actor_energy := 0.0
var torch_world_energy := 0.0
var test_pose := false
var grip: GRIP
var compact_grip := true
var weapons: Array[MeshInstance3D] = []
var sword: MeshInstance3D
var sword_rest_transform: Transform3D
var sword_fitted_transform: Transform3D
var has_sword_fit := false


func _enter_tree() -> void:
	var presentation = get_node("Player/Live3DVisual")
	if ResourceLoader.exists(presentation.DOLL_PREVIEW_PATH):
		presentation.model_scene = load(presentation.DOLL_PREVIEW_PATH)
	else:
		presentation.enabled = false


func _ready() -> void:
	get_window().title = "Threadbound - Wooden Doll Lighting"
	var debug_ui = get_node_or_null("/root/DebugUI")
	if debug_ui and debug_ui.debug_label:
		debug_ui.debug_label.hide()
	visual = player.get_node("Live3DVisual")
	if not visual.enabled:
		status.text = "Wooden doll export is missing. Load the slot 5 export in LocalDoll."
		set_process(false)
		if OS.get_cmdline_user_args().has("--verify"):
			get_tree().quit(1)
		return
	var body: MeshInstance3D = visual._model_root.find_child("Threadborne_Doll", true, false)
	if not body:
		push_error("The slot 5 scene does not contain Threadborne_Doll.")
		set_process(false)
		if OS.get_cmdline_user_args().has("--verify"):
			get_tree().quit(1)
		return
	for mesh_name in WEAPON_MESH_NAMES:
		var mesh: MeshInstance3D = visual._model_root.find_child(mesh_name, true, false)
		if mesh:
			weapons.append(mesh)
	sword = visual._model_root.find_child("Threadborne_Sword", true, false)
	if sword:
		sword_rest_transform = sword.transform
		var parent := sword.get_parent() as Node3D
		var parent_in_hand := Transform3D.IDENTITY
		while parent and not parent is BoneAttachment3D:
			parent_in_hand = parent.transform * parent_in_hand
			parent = parent.get_parent() as Node3D
		if parent is BoneAttachment3D and parent.bone_name == &"hand.R":
			var tilt := Basis(Vector3.BACK, deg_to_rad(HILT_TILT))
			var fit := Transform3D(tilt, HILT_CENTER + HILT_OFFSET - tilt * HILT_CENTER)
			sword_fitted_transform = parent_in_hand.affine_inverse() * fit * parent_in_hand * sword_rest_transform
			has_sword_fit = true
	for node in visual._model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var source := mesh.get_parent() if mesh.get_meta("outline_only", false) else mesh
		if source != body and not weapons.has(source):
			mesh.hide()
	for node in player.find_children("*", "Light2D", true, false):
		node.range_item_cull_mask = 0
	visual.sword_smear_enabled = false
	grip = GRIP.new()
	grip.name = "CompactGripPreview"
	visual._skeleton.add_child(grip)
	process_priority = visual.process_priority + 1
	set_compact_grip(true)
	set_weapons_visible(true)
	for node in visual._viewport.get_children():
		if node is Light3D:
			node.hide()
		if node is WorldEnvironment:
			environment = node.environment
	actor_rig.reparent(visual._viewport, false)
	torch_actor_energy = torch.light_energy
	torch_world_energy = torch_world.energy
	select_preset(0)
	print("DOLL_LIGHTING_READY ", visual.model_scene.resource_path)
	if OS.get_cmdline_user_args().has("--verify"):
		await verify()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_instance_valid(grip) or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			select_preset(event.physical_keycode - KEY_1)
		KEY_H:
			set_compact_grip(not compact_grip)
		KEY_B:
			if not weapons.is_empty():
				set_weapons_visible(not weapons[0].visible)
		KEY_R:
			player.position = $ReferenceMark.position + Vector2(0, -75)
			player.velocity = Vector2.ZERO
			player.reset_physics_interpolation()
		_:
			return
	get_viewport().set_input_as_handled()


func select_preset(index: int) -> void:
	preset = index
	status.text = PRESETS[index]
	backdrop.color = BACKDROP[index]
	environment.ambient_light_color = AMBIENT[index]
	environment.ambient_light_energy = FILL[index]
	for i in fixtures.size():
		fixtures[i].visible = i + 1 == index
	for i in actor_rig.get_child_count():
		actor_rig.get_child(i).visible = i == index
	update_lights()


func _process(delta: float) -> void:
	if not visual.enabled or not is_instance_valid(visual._display):
		return
	if not test_pose:
		elapsed += delta
		var weight := 1.0 if compact_grip and visual._current_action in GRIP.GRIP_ACTIONS else 0.0
		grip.influence = move_toward(grip.influence, weight, delta * 12.0)
		update_sword_grip(move_toward(grip.sword_grip_weight, sword_grip_target(), delta * 12.0))
	update_lights()


func set_compact_grip(enabled: bool) -> void:
	compact_grip = enabled
	grip.influence = 1.0 if enabled and visual._current_action in GRIP.GRIP_ACTIONS else 0.0
	hand_status.text = "H  Hands: " + ("Compact grip" if enabled else "Original grip")
	update_sword_grip(sword_grip_target())


func set_weapons_visible(enabled: bool) -> void:
	for weapon in weapons:
		weapon.visible = enabled
	$HUD/Weapons.text = "B  Sword and shield: " + ("Shown" if enabled else "Hidden")
	update_sword_grip(sword_grip_target())


func sword_grip_target() -> float:
	return 1.0 if compact_grip and has_sword_fit and sword.visible and visual._current_action in GRIP.GRIP_ACTIONS else 0.0


func update_sword_grip(weight: float) -> void:
	grip.sword_grip_weight = weight
	if has_sword_fit:
		sword.transform = sword_rest_transform.interpolate_with(sword_fitted_transform, weight)


func _physics_process(_delta: float) -> void:
	view.position.x = clampf(player.position.x * 0.65, -210.0, 210.0)


func update_lights() -> void:
	var facing := -1.0 if player.get_presentation_facing() < 0 else 1.0
	var sun_from := Vector3(-3.8, 4.4, -2.5 * facing)
	sun.look_at_from_position(sun_from, Vector3(0, 1.1, 0), Vector3.UP)
	var camera: Camera3D = visual._camera
	var pixels := camera.unproject_position(Vector3.ZERO).distance_to(camera.unproject_position(Vector3.UP))
	var scale_in_room: float = pixels * visual.display_scale.y
	var feet: Vector2 = visual._display.global_position if visual._display.is_inside_tree() else player.position + Vector2(0, 69)
	var bulb_offset := (bulb_source.position - feet) / scale_in_room
	var torch_offset := (torch_source.position - feet) / scale_in_room
	bulb.position = Vector3(-1.0, -bulb_offset.y, bulb_offset.x * facing)
	torch.position = Vector3(-0.8, -torch_offset.y, torch_offset.x * facing)
	if preset == 3:
		var flicker := 1.0 + 0.13 * sin(elapsed * 13.0) + 0.08 * sin(elapsed * 23.0 + 0.8) + 0.045 * sin(elapsed * 38.0)
		torch.light_energy = torch_actor_energy * flicker
		torch_world.energy = torch_world_energy * flicker
		flame.scale = Vector2(1.0 + (flicker - 1.0) * 0.25, flicker)


func frames(count: int) -> void:
	for frame in count:
		await get_tree().physics_frame


func verify() -> void:
	await frames(45)
	var body: MeshInstance3D = visual._model_root.find_child("Threadborne_Doll", true, false)
	if not player.is_on_floor() or visual.model_scene.resource_path != visual.DOLL_PREVIEW_PATH or not body.is_visible_in_tree():
		fail("The exact slot 5 wooden doll must start on the greybox floor.")
		return
	if weapons.size() != WEAPON_MESH_NAMES.size():
		fail("The slot 5 sword and shield must both load.")
		return
	var grapple: MeshInstance3D = visual._model_root.find_child("Base_Grapple_Braided_Strand_1", true, false)
	if grapple and grapple.is_visible_in_tree():
		fail("The grapple coil must stay hidden in the weapon preview.")
		return
	for step in 3:
		if step > 0:
			await tap_key(KEY_B)
			await frames(2)
		for weapon in weapons:
			if weapon.is_visible_in_tree() != (step != 1):
				fail("B must toggle the sword and shield together on step %d." % step)
				return
	var idle_delay: float = visual.idle_variation_delay
	visual.idle_variation_delay = 0.1
	for frame in 20:
		if visual._current_action != &"idle_4":
			break
		await frames(1)
	visual.idle_variation_delay = idle_delay
	if visual._current_action not in [&"idle_1", &"idle_2", &"idle_3"]:
		fail("The movement check must start during an idle variation.")
		return
	var start := player.position.x
	Input.action_press("move_right")
	await frames(3)
	if visual._current_action != &"run_1" or visual._queued_action != &"":
		Input.action_release("move_right")
		fail("Running must interrupt the idle variation and clear its queued return to idle.")
		return
	await frames(11)
	Input.action_release("move_right")
	if player.position.x < start + 12:
		fail("The player cannot move on the greybox floor.")
		return
	Input.action_press("Jump")
	await frames(9)
	Input.action_release("Jump")
	if player.is_on_floor():
		fail("The player cannot jump.")
		return
	await frames(80)
	await tap_key(KEY_R)
	await frames(30)
	if not is_equal_approx(player.position.x, $ReferenceMark.position.x):
		fail("R did not return the player to the reference mark.")
		return
	test_pose = true
	visual.set_process(false)
	visual._animation_player.pause()
	var rendered := DisplayServer.get_name() != "headless"
	var out := ProjectSettings.globalize_path("res://LocalOnly/Doll_Lighting")
	if rendered:
		DirAccess.make_dir_recursive_absolute(out)
	var hashes: Dictionary
	for i in PRESETS.size():
		await tap_key(KEY_1 + i)
		if preset != i or not actor_rig.get_child(i).visible or actor_rig.get_children().filter(func(light): return light.visible).size() != 1:
			fail("Preset must enable exactly one actor light.")
			return
		if rendered:
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var actor: Image = visual._viewport.get_texture().get_image()
			hashes[hash(actor.get_data())] = true
			var image := get_viewport().get_texture().get_image()
			if image.save_png(out.path_join(["armed_neutral", "armed_sun", "armed_bulb", "armed_torch"][i] + ".png")) != OK:
				fail("Could not save the lighting comparison.")
				return
	var before := torch.light_energy
	elapsed += .12
	update_lights()
	if is_equal_approx(before, torch.light_energy) or rendered and hashes.size() != PRESETS.size():
		fail("The torch must flicker and the actor renders must differ.")
		return
	if not await verify_grip(rendered, out):
		return
	if not await verify_hilt_in_motion():
		return
	print("DOLL_LIGHTING_VERIFIED sword and shield, movement, lighting and hilt contact across motion")
	get_tree().quit()


func verify_grip(rendered: bool, out: String) -> bool:
	player.set_physics_process(false)
	select_preset(0)
	set_process(false)
	var skeleton: Skeleton3D = visual._skeleton
	var camera: Camera3D = visual._camera
	var animation: AnimationPlayer = visual._animation_player
	visual._play_action(&"idle_4", &"", 0.25, true)
	animation.advance(0.0)
	animation.pause()
	visual._viewport.size = Vector2i(700, 800)
	for side in ["R", "L"]:
		var hand := skeleton.find_bone("hand." + side)
		var target := skeleton.to_global(skeleton.get_bone_global_pose(hand) * Vector3(0, 0.10, 0))
		camera.size = 0.32
		camera.look_at_from_position(target + Vector3(-2, 0.7, 0.6), target, Vector3.UP)
		var spans: Array[float] = []
		var pinky_angles: Array[float] = []
		var hilt_contact: Array[bool] = []
		for compact in [false, true]:
			await tap_key(KEY_H)
			if compact_grip != compact:
				fail("H must switch the hand comparison.")
				return false
			skeleton.skeleton_updated.connect(func():
				var palm := skeleton.get_bone_global_pose(hand).affine_inverse()
				var index := skeleton.find_bone("index.03." + side)
				var pinky := skeleton.find_bone("pinky.03." + side)
				var a := palm * skeleton.get_bone_global_pose(index).origin
				var b := palm * skeleton.get_bone_global_pose(pinky).origin
				spans.append(absf(b.x - a.x))
				if compact:
					var ring := skeleton.find_bone("ring.03." + side)
					var pinky_tip := GRIP.segment_direction(skeleton, pinky, -1)
					var ring_tip := GRIP.segment_direction(skeleton, ring, -1)
					if side == "R":
						pinky_tip = GRIP.carved_tip_direction(skeleton, skeleton.find_bone("pinky.02.R"), pinky)
						ring_tip = GRIP.carved_tip_direction(skeleton, skeleton.find_bone("ring.02.R"), ring)
						hilt_contact.append(verify_finger_contact(skeleton, palm))
					pinky_angles.append(rad_to_deg(pinky_tip.angle_to(ring_tip)))
			, CONNECT_ONE_SHOT)
			skeleton.advance(0.0)
			await get_tree().process_frame
			if rendered:
				await RenderingServer.frame_post_draw
				var label := "compact" if compact else "original"
				var closeup: Image = visual._viewport.get_texture().get_image()
				closeup.save_png(out.path_join("armed_grip_%s_%s.png" % [label, side]))
		if spans.size() != 2 or spans[1] > 0.85 * spans[0]:
			fail("The revised grip must reduce finger spread on hand " + side)
			return false
		if pinky_angles.size() != 1 or pinky_angles[0] > 12.0:
			fail("The pinky tip must follow the ring finger on hand " + side)
			return false
		if side == "R" and hilt_contact != [true]:
			fail("The fitted sword fingers must wrap around the hilt.")
			return false
		if side == "R" and rendered:
			var palm_pose := skeleton.get_bone_global_pose(hand)
			var inside := skeleton.to_global(palm_pose * Vector3(0.07, 0.19, -0.70))
			camera.look_at_from_position(inside, target, Vector3.UP)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var closeup: Image = visual._viewport.get_texture().get_image()
			closeup.save_png(out.path_join("armed_grip_palm_R.png"))
		print("DOLL_GRIP ", side, " span ", spans[0], " -> ", spans[1], " pinky angle=", pinky_angles[0])
	visual._play_action(&"casting_2", &"", 0.1, true)
	set_compact_grip(true)
	if not is_zero_approx(grip.influence):
		fail("The grapple cast must retain its open-hand animation.")
		return false
	return true


func verify_finger_contact(skeleton: Skeleton3D, palm: Transform3D) -> bool:
	# Cross-sections measured at the four fingers on the fitted hilt. Radii
	# include the thickness of the finger, so 1.0 represents contact.
	var sections := {
		"index": [Vector2(0.1006, -0.0368), Vector2(0.0354, 0.0346)],
		"middle": [Vector2(0.0916, -0.0338), Vector2(0.0340, 0.0339)],
		"ring": [Vector2(0.0832, -0.0328), Vector2(0.0314, 0.0333)],
		"pinky": [Vector2(0.0764, -0.0313), Vector2(0.0293, 0.0298)],
	}
	for digit in sections:
		var middle := skeleton.find_bone(digit + ".02.R")
		var tip := skeleton.find_bone(digit + ".03.R")
		var middle_position := palm * skeleton.get_bone_global_pose(middle).origin
		var tip_position := palm * skeleton.get_bone_global_pose(tip).origin
		var tip_length := skeleton.get_bone_global_rest(tip).origin.distance_to(
			skeleton.get_bone_global_rest(middle).origin
		)
		var end := tip_position + palm.basis * GRIP.carved_tip_direction(skeleton, middle, tip) * tip_length
		var center: Vector2 = sections[digit][0]
		var radii: Vector2 = sections[digit][1]
		var middle_section := (Vector2(middle_position.y, middle_position.z) - center) / radii
		var tip_section := (Vector2(tip_position.y, tip_position.z) - center) / radii
		var end_section := (Vector2(end.y, end.z) - center) / radii
		var middle_clearance := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, middle_section, tip_section).length()
		var tip_clearance := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, tip_section, end_section).length()
		if not (middle_clearance >= 0.90 and tip_clearance >= 0.90 and tip_clearance <= 1.12 and end_section.x < 0.15 and end_section.y < 0.0):
			print("HILT_CONTACT ", digit, " clearance ", middle_clearance, " ", tip_clearance, " end ", end_section)
			return false
	return true


func verify_hilt_in_motion() -> bool:
	var skeleton: Skeleton3D = visual._skeleton
	var hand := skeleton.find_bone("hand.R")
	var animation: AnimationPlayer = visual._animation_player
	for action: StringName in [&"idle_1", &"idle_2", &"idle_3", &"idle_4", &"run_1", &"jump_1", &"slash_2"]:
		var reference := Vector3.ZERO
		var length: float = visual.get_action_duration(action)
		if length <= 0.0:
			fail("Missing grip verification clip " + String(action))
			return false
		for frame in 12:
			visual._play_action(action, &"", length * frame / 12.0, true)
			animation.advance(0.0)
			animation.pause()
			set_compact_grip(true)
			var contacts: Array[bool] = []
			skeleton.skeleton_updated.connect(func():
				var palm := skeleton.get_bone_global_pose(hand).affine_inverse()
				contacts.append(verify_finger_contact(skeleton, palm))
			, CONNECT_ONE_SHOT)
			skeleton.advance(0.0)
			await get_tree().process_frame
			var hand_pose := skeleton.global_transform * skeleton.get_bone_global_pose(hand)
			var hilt := hand_pose.affine_inverse() * sword.global_position
			if frame == 0:
				reference = hilt
			if grip.sword_grip_weight != 1.0 or hilt.distance_to(reference) > 0.001 or contacts != [true]:
				fail("The sword must stay seated during " + String(action))
				return false
	set_compact_grip(false)
	if grip.sword_grip_weight != 0.0 or not sword.transform.is_equal_approx(sword_rest_transform):
		fail("The original comparison must restore the authored sword position.")
		return false
	return true


func tap_key(code: Key) -> void:
	var input := InputEventKey.new()
	input.physical_keycode = code
	input.pressed = true
	Input.parse_input_event(input)
	await get_tree().process_frame
	var release := input.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)


func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
