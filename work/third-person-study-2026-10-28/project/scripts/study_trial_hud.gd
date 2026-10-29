extends "res://scripts/study_demo_hud.gd"
var weapon_label: Label
func _ready() -> void:
	super._ready()
	for item in get_children():
		if item is Label and item.text.begins_with("Explore the three wings"): item.text="Village → spools → river → guardian"
	weapon_label=label(self,"",Vector2(28,260),17)
func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(world.actor): return
	weapon_label.text=world.actor.kit.weapon_names[world.actor.kit.slot]+"\n1 / 2 / 3 equip · V / Y cycle"
	if world.practice_mode: return
	objective.text="THREADBOUND · THE LOOM CROSSING\n\n"
	objective.text+="Spool sequence: GOLD → BLUE → RED\nMatched: %d / 3\n" % world.puzzle_progress
	objective.text+=("◆ Bridge woven\n" if world.puzzle_solved else "◇ Weave the optional bridge\n")
	objective.text+=("◆ Guardian defeated\n" if world.boss.dead else "◇ Reach the guardian across the river\n")
	objective.text+="\nE zip · Shift+E swing · Space release\nG interact · F2 combat practice"
func show_ending() -> void:
	ending=true
	show_dialogue("THANK YOU FOR PLAYING\n\nThreadbound · 3D combat trial\n\nThis experiment is ready for your verdict on movement, weapon roles and contact weight.",[["Keep exploring",close_dialogue],["Restart the trial",restart_demo]])
