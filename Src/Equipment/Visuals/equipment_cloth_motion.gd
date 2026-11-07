@tool
class_name EquipmentClothMotion
extends RefCounted
## Restrained outfit cloth on the existing animation rig. No gameplay state.

const PREFIX := "cloth_"
const ROOT_BONE := "cloth_sleeve_L_front_0"
const BASE_ROOT := "cloth_base_hem_L_front_0"
var skeleton: Skeleton3D
var simulator: SpringBoneSimulator3D
var _bones: Array[int] = []
var _previous_position := Vector2.INF
var _previous_velocity := Vector2.ZERO
var reset_count := 0
var profile: StringName = &""
var warming_up := false


static func register_bones(target: Skeleton3D, donor: Skeleton3D) -> bool:
	# Appending named bones keeps existing animation tracks and skin indices.
	for index in donor.get_bone_count():
		var name := donor.get_bone_name(index)
		if target.find_bone(name) >= 0:
			continue
		if not String(name).begins_with(PREFIX):
			return false
		var parent := donor.get_bone_parent(index)
		if parent < 0:
			return false
		var parent_name := donor.get_bone_name(parent)
		var target_parent := target.find_bone(parent_name)
		if target_parent < 0 or not (String(parent_name).begins_with(PREFIX) or parent_name in [&"upper_arm.L",&"upper_arm.R",&"chest",&"pelvis"]):
			return false
		target.add_bone(name)
		var added := target.find_bone(name)
		target.set_bone_parent(added,target_parent)
		target.set_bone_rest(added,donor.get_bone_rest(index))
		target.reset_bone_pose(added)
	return true


func initialize(target: Skeleton3D) -> void:
	skeleton = target
	simulator = SpringBoneSimulator3D.new()
	simulator.name = "EquipmentClothMotion"
	simulator.active = false
	skeleton.add_child(simulator)
	_add_capsule("SleeveTorsoCollider", "chest", Vector3(0,1.32,.005), .50, .155)
	_add_capsule("ClothHipCollider", "pelvis", Vector3(0,1.055,0), .27, .125)
	for side: String in ["L","R"]:
		var x := .14 if side == "L" else -.14
		_add_capsule("ClothThighCollider"+side, "thigh."+side, Vector3(x,.79,0), .40, .085)


func _add_capsule(label: String, bone: String, center: Vector3, height: float, radius: float) -> void:
	var rest := skeleton.get_bone_global_rest(skeleton.find_bone(bone))
	var collider := SpringBoneCollisionCapsule3D.new()
	collider.name = label
	simulator.add_child(collider)
	collider.bone_name = bone
	collider.height = height
	collider.radius = radius
	collider.position_offset = rest.affine_inverse()*center
	collider.rotation_offset = rest.basis.inverse().get_rotation_quaternion()


func configure(next_profile: StringName) -> void:
	if profile == next_profile:
		return
	simulator.active = false
	reset()
	profile = next_profile
	_bones.clear()
	var chains: Array[String] = []
	if profile == &"blue":
		for side: String in ["L","R"]:
			for rail: String in ["front","back"]:
				chains.append("cloth_sleeve_"+side+"_"+rail+"_")
		chains.append_array(["cloth_blue_ribbon_","cloth_blue_sash_front_","cloth_blue_sash_left_","cloth_blue_sash_back_"])
	elif profile == &"base":
		for side: String in ["L","R"]:
			for rail: String in ["front","back"]:
				chains.append("cloth_base_hem_"+side+"_"+rail+"_")
	# Older local imports can have only the original sleeve prototype.
	chains = chains.filter(func(prefix: String) -> bool: return skeleton.find_bone(prefix+"3") >= 0)
	# Discard old root/end pairs before selecting a different outfit's chains.
	# Reusing a setting temporarily pairs a new root with the old unrelated end.
	simulator.setting_count = 0
	simulator.setting_count = chains.size()
	for chain in chains.size():
		var prefix := chains[chain]
		var sleeve := prefix.begins_with("cloth_sleeve_")
		var base := profile == &"base"
		simulator.set_root_bone_name(chain,prefix+"0")
		simulator.set_end_bone_name(chain,prefix+"3")
		simulator.set_extend_end_bone(chain,false)
		simulator.set_center_from(chain,SpringBoneSimulator3D.CENTER_FROM_NODE)
		simulator.set_stiffness(chain,30.0 if base else (4.0 if sleeve else 18.0))
		simulator.set_drag(chain,.96 if base else (.86 if sleeve else .92))
		simulator.set_gravity(chain,.04 if base else (.05 if sleeve else .08))
		simulator.set_gravity_direction(chain,Vector3.DOWN)
		simulator.set_radius(chain,.02 if base else (.05 if sleeve else .025))
		simulator.set_enable_all_child_collisions(chain,false)
		var collisions: Array = ["SleeveTorsoCollider"] if sleeve else ["SleeveTorsoCollider","ClothHipCollider","ClothThighColliderL","ClothThighColliderR"]
		simulator.set_collision_count(chain,collisions.size())
		for index in collisions.size():
			simulator.set_collision_path(chain,index,NodePath(collisions[index]))
		for joint in 4:
			_bones.append(skeleton.find_bone(prefix+str(joint)))
	set_equipped(not chains.is_empty())


func set_equipped(enabled: bool) -> void:
	var active := enabled and not Engine.is_editor_hint()
	if simulator.active != active:
		simulator.active = active
		reset()


func reset() -> void:
	# Also clear the previous outfit's unused chains after a swap.
	for bone in skeleton.get_bone_count():
		if String(skeleton.get_bone_name(bone)).begins_with(PREFIX):
			skeleton.reset_bone_pose(bone)
	simulator.external_force = Vector3.ZERO
	simulator.reset()
	_previous_position = Vector2.INF
	_previous_velocity = Vector2.ZERO
	reset_count += 1
	if simulator.active and not warming_up:
		# Resolve the initial collision chain before its first visible submission.
		# advance() normally defers; the documented skeleton update notification
		# flushes each short warm-up step without advancing authored animation.
		warming_up = true
		for step in 3:
			skeleton.advance(1.0/60.0)
			skeleton.notification(Skeleton3D.NOTIFICATION_UPDATE_SKELETON)
		warming_up = false


func advance(delta: float, position: Vector2, velocity: Vector2, facing: float) -> void:
	if not simulator.active:
		return
	if not _previous_position.is_finite() or _previous_position.distance_to(position)>256.0 or delta>.15:
		reset()
	else:
		# Gameplay translation happens outside the 3D viewport. Supply its inertia.
		var acceleration := (velocity-_previous_velocity)/maxf(delta,.001)
		var strength := .000015 if profile == &"base" else .00004
		simulator.external_force = Vector3(0,-acceleration.y,-acceleration.x*facing).limit_length(4000)*strength
	_previous_position = position
	_previous_velocity = velocity
