@tool
extends Node3D
## Character turns independently of the reusable workstation.
@export var work_yaw := 0.0
@export var show_workstation := true:
	set(value):
		show_workstation = value
		if is_node_ready():
			$Workstation.visible = value

var animation_player: AnimationPlayer
var interacting := false
var target_yaw := 0.0
var _transition_time := 0.0
var _working := true

func _ready() -> void:
	$Workstation.visible = show_workstation
	# Preserve authored face/hand paint and anisotropic surface detail. V2 uses
	# baked skin maps; legacy meshes still use their original vertex paint.
	for mesh_node: MeshInstance3D in $ActorPivot.find_children("*", "MeshInstance3D", true, false):
		mesh_node.lod_bias = 8.0
		for index in mesh_node.mesh.get_surface_count():
			var material := mesh_node.mesh.surface_get_material(index) as StandardMaterial3D
			if material:
				var surface := material.duplicate() as StandardMaterial3D
				surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				# V2 skin paint is baked into a 4K UV map. Legacy models retain paint.
				if material.resource_name.contains("warm skin"):
					surface.vertex_color_use_as_albedo = material.albedo_texture == null
				mesh_node.set_surface_override_material(index, surface)
	target_yaw = work_yaw
	$ActorPivot.rotation.y = work_yaw
	for node: Node in $ActorPivot.find_children("*", "AnimationPlayer", true, false):
		animation_player = node as AnimationPlayer
		break
	if animation_player:
		var library := AnimationLibrary.new()
		for key: StringName in animation_player.get_animation_list():
			var clip: Animation = animation_player.get_animation(key)
			for source_name: String in ["WorkIdle", "TalkIdle"]:
				if String(key).contains(source_name) and not library.has_animation(source_name):
					var copy := clip.duplicate() as Animation
					copy.loop_mode = Animation.LOOP_LINEAR
					library.add_animation(source_name, copy)
		animation_player.add_animation_library("worker", library)
		_play("WorkIdle")
		var clock := RandomNumberGenerator.new()
		clock.seed = String(get_path()).hash()
		animation_player.seek(clock.randf_range(0.0, 3.8), true)
	set_process(not Engine.is_editor_hint())

func begin_interaction(side: float) -> void:
	interacting = true
	_transition_time = 0.0
	_working = false
	face_player(side)
	_play("TalkIdle")

func face_player(side: float) -> void:
	if absf(side) > 12:
		target_yaw = signf(side) * PI * 0.5

func end_interaction() -> void:
	if not interacting:
		return
	interacting = false
	_transition_time = 0.0
	target_yaw = work_yaw

func _process(delta: float) -> void:
	_transition_time += delta
	# Lower the tool before turning away from its work surface.
	if not interacting or _transition_time >= 0.25:
		$ActorPivot.rotation.y = lerp_angle($ActorPivot.rotation.y, target_yaw, 1.0 - exp(-7.0 * delta))
	if not interacting and not _working and absf(angle_difference($ActorPivot.rotation.y, work_yaw)) < 0.045:
		_working = true
		_play("WorkIdle")

func _play(clip: String) -> void:
	if animation_player and animation_player.has_animation("worker/" + clip):
		animation_player.play("worker/" + clip, 0.25)
