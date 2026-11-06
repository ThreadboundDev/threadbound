@tool
class_name EquipmentClothMotion
extends RefCounted
## Secondary motion for the lower Blue sleeves, on the existing animation rig.

const PREFIX := "cloth_sleeve_"
const ROOT_BONE := "cloth_sleeve_L_front_0"
var skeleton: Skeleton3D
var simulator: SpringBoneSimulator3D
var _bones: Array[int] = []
var _previous_position := Vector2.INF
var _previous_velocity := Vector2.ZERO
var reset_count := 0


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
		if target_parent < 0 or not (String(parent_name).begins_with(PREFIX) or parent_name in [&"upper_arm.L",&"upper_arm.R"]):
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
	simulator.name = "BlueSleeveMotion"
	simulator.active = false
	skeleton.add_child(simulator)
	simulator.setting_count = 4
	var chain := 0
	for side: String in ["L","R"]:
		for rail: String in ["front","back"]:
			var prefix := PREFIX+side+"_"+rail+"_"
			simulator.set_root_bone_name(chain,prefix+"0")
			simulator.set_end_bone_name(chain,prefix+"3")
			simulator.set_extend_end_bone(chain,false)
			# Keep inertia in skeleton space; the collision capsule follows the chest.
			simulator.set_center_from(chain,SpringBoneSimulator3D.CENTER_FROM_NODE)
			simulator.set_stiffness(chain,3.5)
			simulator.set_drag(chain,.8)
			simulator.set_gravity(chain,.05)
			simulator.set_gravity_direction(chain,Vector3.DOWN)
			simulator.set_radius(chain,.05)
			simulator.set_enable_all_child_collisions(chain,true)
			for joint in 4:
				_bones.append(skeleton.find_bone(prefix+str(joint)))
			chain += 1
	var chest := skeleton.find_bone("chest")
	var chest_rest := skeleton.get_bone_global_rest(chest)
	var collider := SpringBoneCollisionCapsule3D.new()
	collider.name = "SleeveTorsoCollider"
	simulator.add_child(collider)
	collider.bone_name = "chest"
	collider.height = .50
	collider.radius = .155
	collider.position_offset = chest_rest.affine_inverse()*Vector3(0,1.32,.005)
	collider.rotation_offset = chest_rest.basis.inverse().get_rotation_quaternion()


func set_equipped(enabled: bool) -> void:
	var active := enabled and not Engine.is_editor_hint()
	if simulator.active != active:
		simulator.active = active
		reset()


func reset() -> void:
	for bone in _bones:
		skeleton.reset_bone_pose(bone)
	simulator.external_force = Vector3.ZERO
	simulator.reset()
	_previous_position = Vector2.INF
	_previous_velocity = Vector2.ZERO
	reset_count += 1


func advance(delta: float, position: Vector2, velocity: Vector2, facing: float) -> void:
	if not simulator.active:
		return
	if not _previous_position.is_finite() or _previous_position.distance_to(position)>256.0 or delta>.15:
		reset()
	else:
		# Gameplay translation happens outside the 3D viewport. Supply its inertia.
		var acceleration := (velocity-_previous_velocity)/maxf(delta,.001)
		simulator.external_force = Vector3(0,-acceleration.y,-acceleration.x*facing).limit_length(4000)*.00005
	_previous_position = position
	_previous_velocity = velocity
