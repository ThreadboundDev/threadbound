extends Node
## Presentation observer for the isolated capture, using the public attack API.
var player
var effect
var candidate := false
var elapsed := 0.0
var frames := []
var last_step := -1
var contact_done := false
var queued_step := -1
var finished := false

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	var state: Dictionary = player.get_sword_sweep_state()
	var blade: PackedVector2Array = player.live_3d_visual._get_blade_world_points()
	var step: int = player.ground_combo_step
	if step != last_step:
		contact_done = false
		effect.samples.clear()
		last_step = step
	var emitting := not state.is_empty() and float(state.phase) >= 0.0 and float(state.phase) <= 1.0
	effect.advance(delta, emitting and candidate, blade)
	if emitting and not contact_done and float(state.phase) >= (0.78 if step == 0 else 0.55):
		# Illustrative contact, deliberately distinct from a hit confirmation.
		if candidate: effect.impact(blade[1],Vector2(float(player.last_direction),0))
		contact_done = true
	if candidate: player.live_3d_visual._sword_sweep.hide()
	var damage_polygon := []
	for point in player.attack_collision_polygon.polygon:
		var screen_point: Vector2 = player.get_canvas_transform()*player.attack_collision_polygon.to_global(point)
		damage_polygon.append([screen_point.x,screen_point.y])
	frames.append({"step":step,"facing":player.last_direction,"phase":state.get("phase",-99),"source_seconds":player.live_3d_visual.get_current_action_position(),"emitting":emitting,"blade":[[blade[0].x,blade[0].y],[blade[1].x,blade[1].y]],"damage_polygon_screen":damage_polygon,"damage_active":player.ground_combo_active_strike>=0,"time":elapsed,"delta":delta})
	elapsed += delta
	if player.is_attacking and step < 2 and player.attack_timer > 0.2 and queued_step != step:
		player.start_attack(false)
		queued_step = step
	if not player.is_attacking and queued_step == 1: finished = true
