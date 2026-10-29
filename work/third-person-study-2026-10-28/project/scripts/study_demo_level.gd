extends "res://scripts/study_playtest_world.gd"
const DEMO_HUD=preload("res://scripts/study_demo_hud.gd")
var initializing := true
var collected := {}
var thread_markers: Array[Node3D] = []
var nearby_label := ""
var nearby_kind := ""
var blossom: Node3D
var shrine_position := Vector3(2.8,0,-3.7)
var workshop_position := Vector3(0.6,0,-5.8)
var time := 0.0

func hud() -> void:
	hud_layer=DEMO_HUD.new()
	add_child(hud_layer)

func build_navigation() -> void:
	if not initializing: super.build_navigation()

func _ready() -> void:
	super._ready()
	actor.spawn=Vector3(0,0.3,6)
	actor.reset_to_spawn()
	var fields=get_tree().get_nodes_in_group("study_enemies").filter(func(e):return e.kind!="boss")
	var homes=[Vector3(-18,0.1,-10),Vector3(-14,0.1,-15),Vector3(-10,0.1,18),Vector3(23,0.1,-1)]
	for i in range(fields.size()):
		fields[i].home=homes[i]
		fields[i].reset_enemy()
	if not InputMap.has_action("interact"): InputMap.add_action("interact")
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_G
	InputMap.action_add_event("interact",event)
	var pad:=InputEventJoypadButton.new()
	pad.button_index=JOY_BUTTON_DPAD_UP
	InputMap.action_add_event("interact",pad)
	compose_chamber()
	thread_pickup("Power",Vector3(-21,0.8,-16),Color("b46e5e"))
	thread_pickup("Balance",Vector3(8,0.8,-17),Color("719db2"))
	thread_pickup("Essence",Vector3(-8,1.0,22),Color("cfb66b"))
	initializing=false
	build_navigation()
	hud_layer.show_dialogue("CHAMBER OF THE FIRST WEAVE\n\nExplore the Red, Blue and Yellow wings in any order. Ruin runs by default. Basic abilities reach every thread; the higher routes reward movement.\n\nReturn to the workshop shrine to rest, then test the guardian in the far clearing. H shows controls; G interacts.",[["Begin 3D Demo",hud_layer.close_dialogue]])

func compose_chamber() -> void:
	# Downloaded stonework frames a sunlit grotto rather than an empty test field.
	for item in [[Vector3(-28,0,-22),10.0,.3],[Vector3(-28,0,16),8.0,-.7],[Vector3(30,0,-20),11.0,.8],[Vector3(1,0,-29),13.0,0.1],[Vector3(-6,0,29),8.0,.8]]:
		licensed_prop("rock_b",item[0],item[1],item[2])
	licensed_prop("ruin_arch",Vector3(0,0,13),5.8,PI/2)
	licensed_prop("ruin_wall",Vector3(-24,0,-13),3.3,.5)
	licensed_prop("ruin_arch",Vector3(-20,0,-18.4),4.0,.2)
	licensed_prop("ruin_wall",Vector3(-12,0,23),2.4,-.4)
	licensed_prop("ruin_block",Vector3(-8,0,22),0.3,0)
	village_prop("demo_tower",Vector3(12.5,-1.4,-19),11.5,0,true)
	ramp(Vector3(8.2,0.03,-16),Vector3(10.8,0.45,-17),2.2)
	box("TowerLanding",Vector3(11.4,.38,-17),Vector3(2,.2,2),palette.planks,true)
	for i in range(3):
		var p:=Vector3(12.5+(1.7 if i%2==0 else -1.7),2.1+i*2.1,-18.5)
		box("TowerBalcony",p,Vector3(2.0,.18,2.0),palette.planks,true)
		thread_ring(p+Vector3.UP*.12,.45)
	sign_at("TUTORIAL AREA\nWorkshop / shrine",Vector3(2.4,1.2,4.4))
	sign_at("RED WING\nPower",Vector3(-9,1.2,-8))
	sign_at("BLUE WING\nBalance / lake tower",Vector3(6.7,1.2,-11))
	sign_at("YELLOW WING\nEssence",Vector3(-4,1.2,13))
	thread_ring(shrine_position+Vector3.UP*.08,.65)
	var core:=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=.15;sphere.height=.3
	core.mesh=sphere;core.material_override=fx.glow(Color("dfce9c"))
	add_child(core);core.position=shrine_position+Vector3.UP*.7

func thread_pickup(key: String, point: Vector3, color: Color) -> void:
	var marker:=Node3D.new()
	marker.name="ThreadOf"+key
	marker.position=point
	marker.set_meta("key",key)
	marker.set_meta("base_y",point.y)
	add_child(marker)
	for i in range(4):
		var strand:=MeshInstance3D.new()
		var ring:=TorusMesh.new()
		ring.inner_radius=.17;ring.outer_radius=.21
		ring.rings=24;ring.ring_segments=6
		strand.mesh=ring;strand.material_override=fx.glow(color if i>0 else Color("f2e5bd"))
		strand.rotation=Vector3(i*.7,i*.8,i*.5)
		marker.add_child(strand)
	thread_markers.append(marker)

func _process(delta: float) -> void:
	time+=delta
	if not is_instance_valid(actor) or actor.combat.dead: return
	for marker in thread_markers:
		marker.position.y=marker.get_meta("base_y")+sin(time*1.5)*.08
		marker.rotation.y+=delta*.35
		var key: String=marker.get_meta("key")
		if not collected.has(key) and marker.global_position.distance_to(actor.global_position+Vector3.UP*.8)<1.1: collect_thread(key)
	nearby_kind="";nearby_label=""
	if actor.global_position.distance_to(shrine_position)<2:
		nearby_kind="shrine";nearby_label="Rest at the workshop shrine"
	elif actor.global_position.distance_to(workshop_position)<2:
		nearby_kind="worker";nearby_label="Workshop guidance"
	elif is_instance_valid(blossom) and blossom.visible and actor.global_position.distance_to(blossom.global_position)<2:
		nearby_kind="ending";nearby_label="Ending blossom"

func collect_thread(key: String) -> void:
	if collected.has(key): return
	collected[key]=true
	for marker in thread_markers:
		if marker.get_meta("key")==key: marker.visible=false
	actor.report_momentum("utility")
	audio.play("grapple_connect",actor.global_position,-14,1.2)
	notice("Thread of "+key+" collected · every wing remains open")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_kind!="": interact_nearby()

func interact_nearby() -> void:
	match nearby_kind:
		"shrine":
			actor.checkpoint=shrine_position+Vector3(0,0.2,1.4)
			actor.combat.reset()
			notice("Checkpoint rested · health and AP restored")
		"worker": hud_layer.show_dialogue("WORKSHOP / MERCHANT ROOM\n\nThe three marked wings are open. Red leads to a close encounter, Blue to the lake tower, and Yellow to the outer ruins.\n\nGrapple solid stonework, use the ground paths freely, and return to the shrine to rest. The guardian clearing is across the stream.",[["Return to the chamber",hud_layer.close_dialogue]])
		"ending": hud_layer.show_ending_offer()

func boss_defeated() -> void:
	if is_instance_valid(blossom): return
	blossom=Node3D.new();blossom.position=Vector3(26,0,12);add_child(blossom)
	var flowers=licensed_prop("flowers",blossom.position,.75,0,false)
	if flowers: flowers.reparent(blossom,true)
	thread_ring(blossom.position+Vector3.UP*.1,.7)
	notice("Guardian unraveled · the ending blossom awaits at the clearing edge")

func respawn_player() -> void:
	var point: Vector3=actor.checkpoint
	actor.combat.reset();actor.grapple.detach();actor.momentum.reset()
	actor.velocity=Vector3.ZERO;actor.global_position=point+Vector3.UP*.15
	actor.dash_time=0;actor.air_jump_available=true
	notice("Returned to the last resting point")

func reset_playtest() -> void:
	super.reset_playtest()
	collected.clear()
	for marker in thread_markers: marker.visible=true
	if is_instance_valid(blossom): blossom.queue_free()
	blossom=null

func flow_colors() -> Array[Color]:
	var result: Array[Color]=[]
	for key in ["Power","Balance","Essence"]:
		if collected.has(key): result.append({"Power":Color("c26b59"),"Balance":Color("719db2"),"Essence":Color("cfb66b")}[key])
	return result
