extends CanvasLayer
var world
var status: Label
var ap: Label
var context: Label
var message: Label
var boss_label: Label
var health_bar: ProgressBar
var boss_bar: ProgressBar
var help: PanelContainer
var pause_label: Label
var marker: Label
var clock := 0.0
var flow_label: Label
var flow_bar: ProgressBar

func style_bar(bar: ProgressBar, color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("203438")
	background.corner_radius_top_left = 4
	background.corner_radius_top_right = 4
	background.corner_radius_bottom_left = 4
	background.corner_radius_bottom_right = 4
	var fill: StyleBoxFlat = background.duplicate()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func label(parent: Node, text: String, pos: Vector2, size := 16) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", Color("e5ddc9"))
	node.add_theme_color_override("font_shadow_color", Color("18282b"))
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(node)
	return node

func _ready() -> void:
	world = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := Panel.new()
	panel.position = Vector2(16,14)
	panel.size = Vector2(410,218)
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.055,0.09,0.10,0.82)
	backdrop.border_color = Color(0.57,0.50,0.35,0.5)
	backdrop.border_width_left = 2
	backdrop.corner_radius_top_right = 8
	backdrop.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel",backdrop)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	label(self, "THREADBOUND  ·  3D STUDY", Vector2(28, 22), 19)
	status = label(self, "", Vector2(28, 56))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(28, 83)
	health_bar.size = Vector2(240, 10)
	health_bar.max_value = 100
	health_bar.show_percentage = false
	style_bar(health_bar, Color("8ab5a2"))
	add_child(health_bar)
	ap = label(self, "", Vector2(28, 102), 20)
	label(self, "Village → rooftops → river → guardian\nGrapple solid surfaces · C + air attack: pogo", Vector2(28, 142), 14)
	flow_label = label(self, "", Vector2(28, 188), 14)
	flow_bar = ProgressBar.new()
	flow_bar.position = Vector2(28, 214)
	flow_bar.size = Vector2(240, 5)
	flow_bar.max_value = 100
	flow_bar.show_percentage = false
	style_bar(flow_bar, Color("c4ad75"))
	add_child(flow_bar)
	context = label(self, "", Vector2(520, 512), 16)
	context.size = Vector2(400,75)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker = label(self, "+", Vector2(711, 434), 24)
	message = label(self, "", Vector2(450, 740), 17)
	label(self, "LMB attack   RMB guard/parry   Q special (+ movement: spin)   E grapple / release   Ctrl dash   Tab lock", Vector2(28, 813), 14)
	label(self, "WASD / mouse   Space jump / grapple release   Shift run   R reset all   V weapons   H help   M mute   Esc pause", Vector2(28, 839), 14)
	boss_label = label(self, "", Vector2(510, 28), 19)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(480, 58)
	boss_bar.size = Vector2(480, 12)
	boss_bar.show_percentage = false
	style_bar(boss_bar, Color("b88b66"))
	add_child(boss_bar)
	help = PanelContainer.new()
	help.position = Vector2(380, 155)
	help.size = Vector2(720, 570)
	add_child(help)
	var instructions := Label.new()
	instructions.text = "THREAD & STONE · PLAYTEST CONTROLS\n\nWASD / left stick — move relative to camera\nMouse / right stick — look     Wheel — camera distance\nSpace / A — jump / air jump; jump releases grapple\nShift / LB — run     Ctrl / B — dash with brief invulnerability\nLMB / RT — tap-to-buffer sword combo; air strike when jumping\nRMB / LT — hold shield; fresh press can parry frontal strikes\nQ / X — neutral burst; hold movement for directional spin (2 AP)\nE / RB — fire/release grapple at any solid surface or enemy\nTab / right-stick click — lock/unlock nearest visible enemy\nV / Y — compare original and new sword/shield\nR / Back — reset enemies, health, AP and traversal\nM — mute all sound     H / Esc — close help and resume\n\nAP recharges independently; Momentum and meditation affect speed.\nC / left-stick click — down air attack / swim down\nHold Space + air attack — upward attack\nHold F / D-pad down — meditate; trade Momentum for healing\nFalls return to the last thread-marked landing."
	instructions.add_theme_font_size_override("font_size", 16)
	help.add_child(instructions)
	help.visible = false
	pause_label = label(self, "PAUSED · Esc to resume", Vector2(590, 430), 24)
	pause_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("help"):
		help.visible = not help.visible
		set_pause(help.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("release_mouse"):
		help.visible = false
		set_pause(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("mute"):
		world.audio.toggle_mute()
		world.notice("Sound muted" if world.audio.muted else "Sound on")

func set_pause(value: bool) -> void:
	get_tree().paused = value
	pause_label.visible = value and not help.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not is_instance_valid(world.actor): return
	var actor = world.actor
	var combat = actor.combat
	clock += delta
	flow_label.text = ("FLOW" if actor.momentum.flow else "MOMENTUM") + "  %d / 100" % actor.momentum.amount
	flow_bar.value = actor.momentum.amount
	health_bar.value = combat.health
	status.text = "THREADBORNE   %d / 100" % combat.health
	var count: int = combat.available_ap()
	ap.text = "◆ ".repeat(count) + "◇ ".repeat(6-count) + "  AP"
	ap.modulate = Color("c4ad75") if count >= 2 else Color("9ba9a6")
	context.text = ""
	if actor.grapple.active:
		context.text = "THREAD ATTACHED · E or Space to release"
	elif is_instance_valid(actor.grapple.candidate):
		var node = actor.grapple.candidate
		context.text = "E  ·  " + (node.display_name if node.is_in_group("study_enemies") else "Solid surface")
	if is_instance_valid(actor.lock_target):
		context.text += "\nLOCKED  " + actor.lock_target.display_name
	marker.modulate = Color("edcd8b") if is_instance_valid(actor.grapple.candidate) else Color("b8c4bc")
	message.text = world.notification_text if world.notification_time > 0 else ""
	if not get_tree().paused: world.notification_time = maxf(0, world.notification_time-delta)
	var boss = world.boss
	var show_boss: bool = is_instance_valid(boss) and not boss.dead and actor.global_position.distance_to(boss.global_position) < 21
	boss_bar.visible = show_boss
	boss_label.visible = show_boss
	if show_boss:
		boss_label.text = boss.display_name
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
