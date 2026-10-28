extends SceneTree
func _initialize() -> void:
	var failures := 0
	for name in ["study_fx", "study_audio", "study_combat", "study_grapple", "study_enemy", "study_hud", "study_actor", "study_playtest_world"]:
		var script = load("res://scripts/"+name+".gd")
		if not script or not script.can_instantiate(): failures += 1
	print("PLAYTEST_SCRIPT_FAILURES ", failures)
	quit(failures)
