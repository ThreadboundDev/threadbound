extends "res://scripts/study_hud.gd"
var objective: Label
var dialogue: PanelContainer
var dialogue_text: Label
var choices: VBoxContainer
var ending := false

func _ready() -> void:
	super._ready()
	objective=label(self,"",Vector2(1040,25),16)
	objective.size=Vector2(375,150)
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color(0.055,0.09,0.1,0.97)
	panel_style.border_color=Color("b9a578")
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left=28
	panel_style.content_margin_right=28
	panel_style.content_margin_top=24
	panel_style.content_margin_bottom=24
	dialogue=PanelContainer.new()
	dialogue.position=Vector2(390,230)
	dialogue.size=Vector2(660,390)
	dialogue.add_theme_stylebox_override("panel",panel_style)
	add_child(dialogue)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	dialogue.add_child(column)
	dialogue_text=Label.new()
	dialogue_text.add_theme_font_size_override("font_size",20)
	dialogue_text.add_theme_color_override("font_color",Color("e4dac1"))
	dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size=Vector2(600,180)
	column.add_child(dialogue_text)
	choices=VBoxContainer.new()
	choices.add_theme_constant_override("separation",10)
	column.add_child(choices)
	dialogue.visible=false

func close_dialogue() -> void:
	dialogue.visible=false
	set_pause(false)

func show_dialogue(text: String, buttons: Array) -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	dialogue_text.text=text
	for entry in buttons:
		var button:=Button.new()
		button.text=entry[0]
		button.custom_minimum_size=Vector2(0,42)
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(entry[1])
		choices.add_child(button)
	dialogue.visible=true
	set_pause(true)
	pause_label.visible=false
	if choices.get_child_count()>0: choices.get_child(0).grab_focus()

func show_ending_offer() -> void:
	show_dialogue("The chamber is quiet.\n\nContinue to End Demo, or keep exploring the three wings.",[
		["Keep Exploring",close_dialogue],["Continue to End Demo",show_ending]])

func show_ending() -> void:
	ending=true
	show_dialogue("Thank you for playing THREADBOUND\n\nChamber of the First Weave · 3D demo\n\nA separate experiment with Ruin's movement, the three wings, and combat. Your original 2D game is preserved.",[
		["Keep Exploring",close_dialogue],["Restart 3D Demo",restart_demo]])

func restart_demo() -> void:
	ending=false
	close_dialogue()
	world.reset_playtest()

func _unhandled_input(event: InputEvent) -> void:
	if dialogue.visible and (event.is_action_pressed("release_mouse") or event.is_action_pressed("interact")):
		close_dialogue()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(world.actor): return
	status.text="RUIN   %d / 100" % world.actor.combat.health
	objective.text="CHAMBER OF THE FIRST WEAVE\n\n"
	for key in ["Power","Balance","Essence"]:
		objective.text+=("◆  " if world.collected.has(key) else "◇  ")+key+"\n"
	objective.text+="\nG · interact / shrine / blossom"
	if world.nearby_label!="" and not dialogue.visible: context.text="G  ·  "+world.nearby_label
