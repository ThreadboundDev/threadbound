class_name BaseEquipment
extends Node

var player: CharacterBody2D
var slot_name: String = "None"
var last_input_source: String = "mouse"  # "mouse" or "controller"
var input_switch_cooldown: float = 0.0   # prevents rapid flipping

func _init(_player: CharacterBody2D = null):
	player = _player

func on_equipped() -> void: pass
func on_unequipped() -> void: pass

func handle_primary(_delta: float, _state: BaseArchetype.ActionState) -> void: pass
func handle_secondary(_delta: float, _state: BaseArchetype.ActionState) -> void: pass
func thread_mechanic(_delta: float) -> void: pass
func process_passive(_delta: float) -> void: pass

## Returns normalized aim direction. 
## Right stick (controller) takes priority → mouse fallback → last facing direction.
## Deadzone prevents jitter. Expose as @export if you want per-equip tuning later.
func get_aim_direction() -> Vector2:
	if input_switch_cooldown > 0.0:
		input_switch_cooldown -= get_process_delta_time()  # or use a real delta if you prefer

	# === CONTROLLER RIGHT STICK ===
	var right_stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	const DEADZONE := 0.22
	if right_stick.length_squared() > DEADZONE * DEADZONE:
		if last_input_source != "controller":
			last_input_source = "controller"
			input_switch_cooldown = 0.3
		return right_stick.normalized()

	# === MOUSE FALLBACK (only if mouse was recently used or we are in mouse mode) ===
	if last_input_source == "mouse" or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_dir := player.get_global_mouse_position() - player.global_position
		if mouse_dir.length() > 20.0:
			if last_input_source != "mouse":
				last_input_source = "mouse"
				input_switch_cooldown = 0.3
		return mouse_dir.normalized()

	# === ULTIMATE FALLBACK: last facing direction (no more stuck on old mouse position) ===
	return Vector2(player.last_direction, 0).normalized()
