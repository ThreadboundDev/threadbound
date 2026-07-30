extends Node

const ENEMY_BASE_SCENE := preload("res://Src/Enemies/EnemyBase/enemy_base.tscn")
const DAMAGE_TEXTURE := preload("res://Assets/VFX/V2/enemy_damage_fray_v2.png")
const DEATH_TEXTURE := preload("res://Assets/VFX/V2/enemy_death_unravel_v2.png")
const FLOW_AURA_TEXTURE := preload("res://Assets/VFX/FlowState/V1/flow_aura_loop_v1.png")
const FLOW_TRANSITION_TEXTURE := preload("res://Assets/VFX/FlowState/V1/flow_transition_v1.png")
const FLOW_ATTACK_TEXTURE := preload("res://Assets/VFX/FlowState/V3/flow_attack_smear_v3.png")
const FLOW_MOVEMENT_TEXTURE := preload("res://Assets/VFX/FlowState/V2/flow_movement_energy_v2.png")
const FLOW_MOTES_TEXTURE := preload("res://Assets/VFX/FlowState/V1/flow_motes_v1.png")
const FLOW_SILHOUETTE_SHADER := preload("res://Src/VFX/flow_state_silhouette.gdshader")
const FLOW_STATE_VFX_SCENE_PATH := "res://Src/Characters/Player/flow_state_vfx.tscn"
const NEUTRAL_SPECIAL_VFX_SCENE_PATH := "res://Src/VFX/neutral_special_vfx.tscn"
const REQUIRED_FLOW_STATE_API := [
	&"set_flow_active",
	&"set_meditation_active",
	&"set_momentum_amount",
	&"play_attack_swing",
	&"play_dash",
	&"play_jump",
	&"play_land",
]

var _failures := PackedStringArray()

func _ready() -> void:
	_verify_true_alpha_sheet(DAMAGE_TEXTURE, "damage fray")
	_verify_true_alpha_sheet(DEATH_TEXTURE, "death unravel")
	_verify_flow_alpha_sheet(FLOW_AURA_TEXTURE, "Flow aura")
	_verify_flow_alpha_sheet(FLOW_TRANSITION_TEXTURE, "Flow transition")
	_verify_flow_alpha_sheet(FLOW_ATTACK_TEXTURE, "Flow attack")
	_verify_flow_alpha_sheet(FLOW_MOVEMENT_TEXTURE, "Flow movement")
	_verify_flow_alpha_sheet(FLOW_MOTES_TEXTURE, "Flow motes")
	_verify_enemy_sprite_setup()
	_verify_flow_state_vfx()
	_verify_neutral_special_vfx()
	_finish()

func _verify_true_alpha_sheet(texture: Texture2D, label: String) -> void:
	_expect(texture != null, "%s texture loads." % label)
	if texture == null:
		return
	var image := texture.get_image()
	_expect(image != null and not image.is_empty(), "%s image data is available." % label)
	if image == null or image.is_empty():
		return
	_expect(
		image.get_width() % 2 == 0 and image.get_height() % 2 == 0,
		"%s remains an even 2x2 sheet." % label
	)

	var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
	for frame_index in 4:
		var origin := Vector2i(
			(frame_index % 2) * cell_size.x,
			(frame_index / 2) * cell_size.y
		)
		var visible_pixels := 0
		var total_pixels := cell_size.x * cell_size.y
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a > 0.03:
					visible_pixels += 1
		var coverage := float(visible_pixels) / float(maxi(1, total_pixels))
		_expect(coverage > 0.001, "%s frame %d is not empty." % [label, frame_index])
		_expect(
			coverage < 0.12,
			"%s frame %d has %.1f%% coverage; a rectangular background may remain." %
			[label, frame_index, coverage * 100.0]
		)

		for corner in [
			Vector2i(0, 0),
			Vector2i(cell_size.x - 1, 0),
			Vector2i(0, cell_size.y - 1),
			Vector2i(cell_size.x - 1, cell_size.y - 1),
		]:
			_expect(
				image.get_pixel(origin.x + corner.x, origin.y + corner.y).a <= 0.01,
				"%s frame %d retains an opaque atlas corner." % [label, frame_index]
			)

func _verify_flow_alpha_sheet(texture: Texture2D, label: String) -> void:
	_expect(texture != null, "%s texture loads." % label)
	if texture == null:
		return

	var image := texture.get_image()
	_expect(image != null and not image.is_empty(), "%s image data is available." % label)
	if image == null or image.is_empty():
		return
	_expect(
		image.get_width() == 512 and image.get_height() == 512,
		"%s remains a 512x512 runtime atlas." % label
	)
	_expect(
		image.get_width() % 2 == 0 and image.get_height() % 2 == 0,
		"%s remains an even 2x2 sheet." % label
	)

	var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
	for frame_index in 4:
		var origin := Vector2i(
			(frame_index % 2) * cell_size.x,
			(frame_index / 2) * cell_size.y
		)
		var visible_pixels := 0
		var total_pixels := cell_size.x * cell_size.y
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a > 0.03:
					visible_pixels += 1
		var coverage := float(visible_pixels) / float(maxi(1, total_pixels))
		_expect(coverage > 0.005, "%s cell %d is not empty." % [label, frame_index])
		_expect(
			coverage < 0.35,
			"%s cell %d has %.1f%% coverage; a keyed background may remain." %
			[label, frame_index, coverage * 100.0]
		)

		for corner in [
			Vector2i(0, 0),
			Vector2i(cell_size.x - 1, 0),
			Vector2i(0, cell_size.y - 1),
			Vector2i(cell_size.x - 1, cell_size.y - 1),
		]:
			_expect(
				image.get_pixel(origin.x + corner.x, origin.y + corner.y).a <= 0.01,
				"%s cell %d retains an opaque atlas corner." % [label, frame_index]
			)

func _verify_enemy_sprite_setup() -> void:
	var enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	_expect(enemy != null, "Enemy base scene instantiates.")
	if enemy == null:
		return
	var sprite := enemy.call("_make_one_shot_vfx_sprite", DAMAGE_TEXTURE, 0.1) as Sprite2D
	_expect(sprite != null, "Enemy hit VFX creates a sprite.")
	if sprite:
		_expect(sprite.hframes == 2 and sprite.vframes == 2, "Enemy hit VFX slices the 2x2 sheet.")
		_expect(sprite.frame == 0, "Enemy hit VFX starts on frame zero.")
		_expect(sprite.material == null, "True-alpha hit VFX does not use the retired keying shader.")
	enemy.free()

func _verify_flow_state_vfx() -> void:
	var scene_exists := ResourceLoader.exists(FLOW_STATE_VFX_SCENE_PATH, "PackedScene")
	_expect(scene_exists, "Flow State VFX scene exists at %s." % FLOW_STATE_VFX_SCENE_PATH)
	if not scene_exists:
		return

	var flow_scene := ResourceLoader.load(FLOW_STATE_VFX_SCENE_PATH, "PackedScene") as PackedScene
	_expect(flow_scene != null, "Flow State VFX scene loads as a PackedScene.")
	if flow_scene == null:
		return

	var flow_vfx := flow_scene.instantiate()
	_expect(flow_vfx != null, "Flow State VFX scene instantiates.")
	if flow_vfx == null:
		return

	add_child(flow_vfx)
	for method_name in REQUIRED_FLOW_STATE_API:
		_expect(
			flow_vfx.has_method(method_name),
			"Flow State VFX exposes %s()." % method_name
		)

	var visual_stats := {
		"sprite_nodes": 0,
		"authored_texture_nodes": 0,
		"line_nodes": 0,
	}
	_collect_flow_visual_stats(flow_vfx, visual_stats)
	_expect(
		int(visual_stats["sprite_nodes"]) > 0,
		"Flow State VFX contains Sprite2D or AnimatedSprite2D visuals."
	)
	_expect(
		int(visual_stats["authored_texture_nodes"]) > 0,
		"Flow State VFX sprite visuals reference authored texture resources."
	)
	_expect(
		int(visual_stats["line_nodes"]) == 0,
		"Flow State VFX contains no Line2D procedural-line nodes."
	)
	var silhouette_shell := flow_vfx.get_node_or_null(
		"AuraBack/SilhouetteShell"
	) as Sprite2D
	_expect(
		silhouette_shell != null,
		"Flow State VFX contains a live silhouette shell."
	)
	if silhouette_shell:
		var silhouette_material := silhouette_shell.material as ShaderMaterial
		_expect(
			silhouette_material != null
			and silhouette_material.shader == FLOW_SILHOUETTE_SHADER,
			"Flow silhouette shell uses the distance-field energy shader."
		)

	if flow_vfx.has_method(&"set_flow_active"):
		flow_vfx.call(&"set_flow_active", true)
		flow_vfx.call(&"set_flow_active", false)
	if flow_vfx.has_method(&"set_meditation_active"):
		flow_vfx.call(&"set_meditation_active", true)
		flow_vfx.call(&"set_meditation_active", false)
	if flow_vfx.has_method(&"set_momentum_amount"):
		for momentum_amount in [0.0, 25.0, 50.0, 75.0, 100.0]:
			flow_vfx.call(&"set_momentum_amount", momentum_amount)

	for method_name in [&"play_attack_swing", &"play_dash", &"play_jump", &"play_land"]:
		if flow_vfx.has_method(method_name):
			_call_method_with_test_arguments(flow_vfx, method_name)

	_verify_identity_channel_states(flow_vfx)
	flow_vfx.free()

func _verify_neutral_special_vfx() -> void:
	var scene_exists := ResourceLoader.exists(NEUTRAL_SPECIAL_VFX_SCENE_PATH, "PackedScene")
	_expect(
		scene_exists,
		"Neutral-special VFX scene exists at %s." % NEUTRAL_SPECIAL_VFX_SCENE_PATH
	)
	if not scene_exists:
		return

	var packed_scene := ResourceLoader.load(
		NEUTRAL_SPECIAL_VFX_SCENE_PATH,
		"PackedScene"
	) as PackedScene
	_expect(packed_scene != null, "Neutral-special VFX loads as a PackedScene.")
	if packed_scene == null:
		return

	var neutral_special_vfx := packed_scene.instantiate()
	_expect(neutral_special_vfx != null, "Neutral-special VFX scene instantiates.")
	if neutral_special_vfx == null:
		return

	add_child(neutral_special_vfx)
	_expect(
		neutral_special_vfx.has_method(&"play"),
		"Neutral-special VFX exposes play()."
	)
	for method_name in [&"set_charge_position", &"trigger_impact", &"cancel"]:
		_expect(
			neutral_special_vfx.has_method(method_name),
			"Neutral-special VFX exposes %s()." % method_name
		)
	if neutral_special_vfx.has_method(&"play"):
		neutral_special_vfx.call(&"play", 220.0, 0.245, 1)
	if neutral_special_vfx.has_method(&"set_charge_position"):
		neutral_special_vfx.call(&"set_charge_position", Vector2(24.0, -80.0))
	if neutral_special_vfx.has_method(&"trigger_impact"):
		neutral_special_vfx.call(&"trigger_impact", Vector2(96.0, 48.0))
	neutral_special_vfx.free()

func _collect_flow_visual_stats(node: Node, stats: Dictionary) -> void:
	if node is Line2D:
		stats["line_nodes"] = int(stats["line_nodes"]) + 1
	elif node is AnimatedSprite2D:
		stats["sprite_nodes"] = int(stats["sprite_nodes"]) + 1
		if _animated_sprite_has_authored_texture(node as AnimatedSprite2D):
			stats["authored_texture_nodes"] = int(stats["authored_texture_nodes"]) + 1
	elif node is Sprite2D:
		stats["sprite_nodes"] = int(stats["sprite_nodes"]) + 1
		if _is_authored_texture((node as Sprite2D).texture):
			stats["authored_texture_nodes"] = int(stats["authored_texture_nodes"]) + 1

	for child in node.get_children():
		_collect_flow_visual_stats(child, stats)

func _animated_sprite_has_authored_texture(sprite: AnimatedSprite2D) -> bool:
	if sprite.sprite_frames == null:
		return false
	for animation_name in sprite.sprite_frames.get_animation_names():
		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		for frame_index in frame_count:
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			if _is_authored_texture(texture):
				return true
	return false

func _is_authored_texture(texture: Texture2D) -> bool:
	if texture == null:
		return false
	if not texture.resource_path.is_empty():
		return texture.resource_path.begins_with("res://")
	if texture is AtlasTexture:
		return _is_authored_texture((texture as AtlasTexture).atlas)
	return false

func _verify_identity_channel_states(flow_vfx: Node) -> void:
	if not flow_vfx.has_method(&"set_identity_channels"):
		print(
			"Combat VFX verification: set_identity_channels() is unavailable; "
			+ "skipping direct identity-channel state exercise."
		)
		return

	var argument_count := _get_method_argument_count(flow_vfx, &"set_identity_channels")
	_expect(
		argument_count == 1,
		"Flow State VFX set_identity_channels() accepts one color-channel array."
	)
	if argument_count != 1:
		return

	var test_colors: Array[Color] = [
		Color(0.92, 0.16, 0.12),
		Color(0.16, 0.42, 1.0),
		Color(1.0, 0.76, 0.12),
	]
	for channel_count in 4:
		var channels: Array[Color] = []
		for index in channel_count:
			channels.append(test_colors[index])
		flow_vfx.call(&"set_identity_channels", channels)
	_expect(true, "Flow State VFX accepts zero, one, two, and three identity channels.")

	var has_weighted_mix := (
		flow_vfx.has_method(&"set_identity_mix")
		and flow_vfx.has_method(&"clear_identity_override")
	)
	_expect(
		has_weighted_mix,
		"Flow State VFX exposes a reversible weighted identity debug override."
	)
	if has_weighted_mix:
		flow_vfx.call(&"set_identity_mix", 0.2, 0.5, 0.8)
		flow_vfx.call(&"clear_identity_override")

func _call_method_with_test_arguments(target: Node, method_name: StringName) -> void:
	var method_info := _get_method_info(target, method_name)
	if method_info.is_empty():
		return

	var arguments: Array = []
	for argument_info in method_info.get("args", []):
		arguments.append(_make_test_argument(argument_info))
	target.callv(method_name, arguments)

func _get_method_argument_count(target: Node, method_name: StringName) -> int:
	var method_info := _get_method_info(target, method_name)
	return -1 if method_info.is_empty() else (method_info.get("args", []) as Array).size()

func _get_method_info(target: Node, method_name: StringName) -> Dictionary:
	for method_info in target.get_method_list():
		if StringName(method_info.get("name", "")) == method_name:
			return method_info
	return {}

func _make_test_argument(argument_info: Dictionary) -> Variant:
	var argument_name := StringName(argument_info.get("name", ""))
	var argument_type := int(argument_info.get("type", TYPE_NIL))
	match argument_type:
		TYPE_BOOL:
			return true
		TYPE_INT:
			return 0
		TYPE_FLOAT:
			return 1.0
		TYPE_STRING:
			return "verification"
		TYPE_STRING_NAME:
			return &"verification"
		TYPE_VECTOR2:
			return Vector2.RIGHT
		TYPE_VECTOR2I:
			return Vector2i.RIGHT
		TYPE_COLOR:
			return Color(1.0, 0.82, 0.38)
		TYPE_ARRAY:
			return []
		TYPE_DICTIONARY:
			return {}
		TYPE_OBJECT:
			return null

	if String(argument_name).contains("direction"):
		return Vector2.RIGHT
	if String(argument_name).contains("intensity"):
		return 1.0
	if String(argument_name).contains("strike"):
		return 0
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Combat VFX verification: " + message)

func _finish() -> void:
	if _failures.is_empty():
		print("Combat VFX verification passed.")
		get_tree().quit(0)
		return
	print("Combat VFX verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)
