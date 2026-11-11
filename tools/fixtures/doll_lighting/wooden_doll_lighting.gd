extends Node2D
## Isolated lighting study for the earlier equipped doll's wooden body.

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
	for node in visual._model_root.find_children("*", "MeshInstance3D", true, false):
		if node != body and not body.is_ancestor_of(node):
			node.hide()
	for node in player.find_children("*", "Light2D", true, false):
		node.range_item_cull_mask = 0
	visual.sword_smear_enabled = false
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
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			select_preset(event.physical_keycode - KEY_1)
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
	update_lights()


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
	for part in ["Threadborne_Sword", "Threadborne_Shield_Combined_Test", "Base_Grapple_Braided_Strand_1"]:
		if visual._model_root.find_child(part, true, false).is_visible_in_tree():
			fail("Equipment is still visible: " + part)
			return
	var start := player.position.x
	Input.action_press("move_right")
	await frames(14)
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
			if image.save_png(out.path_join(["neutral", "sun", "bulb", "torch"][i] + ".png")) != OK:
				fail("Could not save the lighting comparison.")
				return
	var before := torch.light_energy
	elapsed += .12
	update_lights()
	if is_equal_approx(before, torch.light_energy) or rendered and hashes.size() != PRESETS.size():
		fail("The torch must flicker and the actor renders must differ.")
		return
	print("DOLL_LIGHTING_VERIFIED model, equipment hidden, movement, jump, four presets and torch flicker")
	get_tree().quit()


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
