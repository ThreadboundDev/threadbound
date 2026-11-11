extends SkeletonModifier3D
## A pose comparison for the carved hands on the slot 5 rig.

const SPREAD := {
	"index": [-12.0, 0.0],
	"middle": [0.0, 0.0],
	"ring": [11.0, 0.0],
	"pinky": [25.0, 0.0],
	"thumb": [-18.0, 0.0, 0.0],
}
const CURL := {
	"index": [-6.0, -3.0],
	"middle": [-4.0, -2.0],
	"ring": [-5.0, -3.0],
	"pinky": [-7.0, -2.0],
	"thumb": [-12.0, -7.0, -20.0],
}
const GRIP_ACTIONS := [
	&"idle_1", &"idle_2", &"idle_3", &"idle_4",
	&"run_1", &"run_2", &"walk_1", &"walk_2", &"jump_1", &"jump_2",
	&"crouch_1", &"crouch_idle_1", &"crouching_1",
	&"block_1", &"block_idle_1", &"crouch_block_1", &"crouch_block_idle_1",
	&"slash_1", &"slash_2", &"slash_3", &"slash_4", &"slash_5",
	&"air_attack_forward", &"air_attack_up", &"air_attack_down",
]

var joint_corrections: Dictionary


func _ready() -> void:
	var skeleton := get_skeleton()
	for side in ["R", "L"]:
		var mirror := 1.0 if side == "R" else -1.0
		for digit in SPREAD:
			for segment in SPREAD[digit].size():
				var bone := skeleton.find_bone("%s.%02d.%s" % [digit, segment + 1, side])
				if bone < 0:
					continue
				var axis := Vector3.BACK if digit == "thumb" else Vector3.UP
				var correction := 0.55 if digit == "thumb" and side == "R" else 1.0
				var fan := Quaternion(axis, deg_to_rad(mirror * correction * SPREAD[digit][segment]))
				var curl := Quaternion(Vector3.RIGHT, deg_to_rad(correction * CURL[digit][segment]))
				joint_corrections[bone] = [fan, curl]


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	for bone in joint_corrections:
		var angles: Array = joint_corrections[bone]
		var animated := skeleton.get_bone_pose_rotation(bone)
		# Adduct the flexed fingers around the palm's length, then curl locally.
		skeleton.set_bone_pose_rotation(bone, (angles[0] * animated * angles[1]).normalized())
