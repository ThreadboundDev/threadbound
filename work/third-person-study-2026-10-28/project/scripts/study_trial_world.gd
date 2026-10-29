extends "res://scripts/study_demo_level.gd"
const TRIAL_HUD=preload("res://scripts/study_trial_hud.gd")
const RECEIVER=preload("res://scripts/study_weave_receiver.gd")
var puzzle_progress:=0
var puzzle_solved:=false
var bridge_body: Node3D
var receivers: Array[Node3D]=[]
var trial_environment: Environment
var bridge_tween: Tween
var route_checkpoints: Array[Node3D]=[]
var bridge_order: Array[String]=["Gold","Blue","Red"]

func hud() -> void:
	hud_layer=TRIAL_HUD.new();add_child(hud_layer)

func configure_inputs() -> void:
	super.configure_inputs()
	if not InputMap.has_action("interact"): InputMap.add_action("interact")
	var key:=InputEventKey.new();key.physical_keycode=KEY_G;InputMap.action_add_event("interact",key)
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_DPAD_UP;InputMap.action_add_event("interact",pad)

func _ready() -> void:
	get_tree().auto_accept_quit=false
	get_tree().root.close_requested.connect(shutdown)
	rng.seed=291026
	fx=FX.new();add_child(fx);audio=AUDIO.new();add_child(audio)
	configure_inputs()
	for item in [["grass","526c61"],["stone","6a7775"],["wood","534a40"],["planks","927e62"],["flax","c0b18b"],["indigo","405965"],["path","a29577"]]: palette[item[0]]=material(Color(item[1]))
	trial_lighting()
	terrain(-64,8,-64,64);terrain(13,65,-64,64)
	terrain(8,13,-64,-26);terrain(8,13,26,64)
	box("NorthRiverBank",Vector3(10.5,-.25,-26),Vector3(5,.5,3),palette.stone,true)
	box("SouthRiverBank",Vector3(10.5,-.25,26),Vector3(5,.5,3),palette.stone,true)
	box("DeepRiverbed",Vector3(10.5,-3,0),Vector3(5,.2,50),palette.stone,true)
	trial_water()
	trial_village()
	trial_route()
	trial_grove()
	bridge_body=box("WeaveBridge",Vector3(10.5,-2.7,-8),Vector3(5.4,.24,2.5),palette.planks,true)
	for z in [-9.35,-6.65]:
		box("BridgeApproach",Vector3(7.35,.12,z),Vector3(1.3,.22,.18),palette.wood,true)
	box("WestLanding",Vector3(7.4,.05,-8),Vector3(1.2,.15,3),palette.stone,true)
	box("EastLanding",Vector3(13.6,.05,-8),Vector3(1.2,.15,3),palette.stone,true)
	ramp(Vector3(7.1,.02,8),Vector3(10,-2.65,8),2.4)
	ramp(Vector3(11,-2.65,8),Vector3(14.1,.02,8),2.4)
	for data in [["Blue",Vector3(5.7,1.4,-5.8),Color("79bdc8")],["Red",Vector3(5.3,2.2,-11),Color("cb8b7a")],["Gold",Vector3(3.5,1.6,-8.5),Color("dfc678")]]:
		var receiver=RECEIVER.new();receiver.world=self;receiver.key=data[0];receiver.position=data[1];receiver.tint=data[2];add_child(receiver);receivers.append(receiver)
		box("SpoolSupport",Vector3(data[1].x+.55,data[1].y*.5,data[1].z),Vector3(.12,data[1].y+.5,.12),palette.wood,true)
		box("SpoolArm",data[1]+Vector3(.22,.43,0),Vector3(.8,.10,.12),palette.wood,true)
	actor=ACTOR.new();add_child(actor)
	exploration_spawn=Vector3(0,.3,15);actor.spawn=exploration_spawn;actor.reset_to_spawn()
	hud()
	spawn_enemy("reedhook",Vector3(.2,.1,4))
	spawn_enemy("reedhook",Vector3(-7,.1,-5),true)
	spawn_enemy("eave",Vector3(3.5,.1,-15))
	boss=spawn_enemy("boss",Vector3(19,.1,-12));boss.ai_enabled=false
	for enemy in get_tree().get_nodes_in_group("study_enemies"):
		exploration_homes[enemy]=enemy.home;exploration_armor[enemy]=enemy.armored
	initializing=false;build_navigation()
	audio.river.position=Vector3(10.5,-.2,2)
	hud_layer.show_dialogue("THREADBOUND · THE LOOM CROSSING\n\nAll three weapon roles are available: 1 sword/shield, 2 ranged thread staff, 3 balance spear. V / Y cycles them. LMB combos; Q specials, movement+Q directional specials.\n\nJump the scaffold route, zip with E or swing with Shift+E. Strike the hanging spools GOLD → BLUE → RED to raise the optional bridge. Swimming and grappling provide other crossings.\n\nDefeat the guardian across the river. F2 offers focused duels; H shows controls.",[["Begin the trial",hud_layer.close_dialogue],["Combat practice",show_practice_menu]])

func trial_lighting() -> void:
	var environment_node:=WorldEnvironment.new();trial_environment=Environment.new()
	trial_environment.background_mode=Environment.BG_SKY
	var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("597b90");sky_mat.sky_horizon_color=Color("c4d0bc")
	sky_mat.ground_horizon_color=Color("8a9d86");sky_mat.ground_bottom_color=Color("46594e")
	sky.sky_material=sky_mat;trial_environment.sky=sky
	trial_environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	trial_environment.ambient_light_color=Color("bac9b5");trial_environment.ambient_light_energy=.65
	trial_environment.fog_enabled=true;trial_environment.fog_light_color=Color("a3b7ad");trial_environment.fog_density=.004
	environment_node.environment=trial_environment;add_child(environment_node)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0);sun.light_color=Color("ffedd0");sun.light_energy=1.3;sun.shadow_enabled=true;add_child(sun)
	var probe:=ReflectionProbe.new();probe.position=Vector3(10.5,1.2,-4);probe.size=Vector3(24,12,42);probe.cull_mask=1;add_child(probe)

func trial_water() -> void:
	var noise:=FastNoiseLite.new();noise.seed=29;noise.frequency=.035
	var texture:=NoiseTexture2D.new();texture.width=256;texture.height=256;texture.seamless=true;texture.noise=noise
	var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/study_trial_water.gdshader");mat.set_shader_parameter("ripple_noise",texture)
	var water_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(5,50);plane.subdivide_width=12;plane.subdivide_depth=60
	water_mesh.mesh=plane;water_mesh.material_override=mat;water_mesh.position=Vector3(10.5,-.33,0);water_mesh.layers=2;add_child(water_mesh)

func trial_village() -> void:
	var workshop: Node3D=WORKSHOP.instantiate();workshop.name="WorkingVillageWorkshop";workshop.position=Vector3(-5,.12,11);add_child(workshop)
	for player in workshop.find_children("*","AnimationPlayer",true,false):
		worker_players.append(player)
		for clip in player.get_animation_list():
			if clip!="RESET": player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR;player.play(clip);break
	box("WorkshopInterior",Vector3(-5,1.3,8.6),Vector3(4.1,2.6,3.3),palette.stone,true,false)
	box("PorchFloor",Vector3(-5,.06,9.5),Vector3(4.4,.24,6),palette.wood,true,false)
	box("WorkbenchContact",Vector3(-4.35,.7,11.98),Vector3(1.3,1.25,.75),palette.wood,true,false)
	ramp(Vector3(-5,.02,14),Vector3(-5,.2,12.5),2.2)
	shrine_position=Vector3(-1.4,0,12);workshop_position=Vector3(-4.35,0,12)
	thread_ring(shrine_position+Vector3.UP*.06,.65)
	village_prop("cottage",Vector3(-15,0,13),4.2,.15,true)
	village_prop("stall_empty",Vector3(-10,0,14.4),2.0,.25,true)
	village_prop("crate_wooden",Vector3(-8.7,0,12.5),.6,.2,true)
	village_prop("barrel",Vector3(-10.7,0,12.6),.9,.1,true)
	village_prop("weaponstand",Vector3(-1.4,0,16.7),1.4,PI,true)
	sign_at("ALL WEAPONS AVAILABLE\n1 Sword · 2 Staff · 3 Spear\nG at the shrine to rest",Vector3(2.5,1.2,15))
	sign_at("LOOM CROSSING\nGold → Blue → Red\nStrike or pluck the spools",Vector3(1.7,1.4,-4.3))
	sign_at("RIVER ROUTE\nSpace up · C down\nBoth banks have exit ramps",Vector3(6.1,1.2,9))

func trial_route() -> void:
	var points=[Vector3(-4,.8,2),Vector3(-7.2,1.6,-.4),Vector3(-10,2.5,-3.2),Vector3(-7.1,3.1,-6.4),Vector3(-3.7,3.8,-9)]
	for p in points:
		box("JumpDeck",p-Vector3.UP*.14,Vector3(2.3,.28,2.3),palette.planks,true)
		for x in [-.8,.8]: box("DeckPost",Vector3(p.x+x,p.y*.5,p.z+.8),Vector3(.12,p.y,.12),palette.wood,true)
		thread_ring(p+Vector3.UP*.04,.4)
		var checkpoint:=Node3D.new();checkpoint.position=p+Vector3.UP*.15;checkpoint.add_to_group("study_checkpoints");add_child(checkpoint);route_checkpoints.append(checkpoint)
		box("GrappleBeam",p+Vector3(0,2.7,.8),Vector3(2.5,.18,.18),palette.wood,true)
		box("BeamMast",p+Vector3(.95,1.35,.8),Vector3(.14,2.7,.14),palette.wood,true)
	sign_at("SCAFFOLD RUN\nSpace jump / air jump\nE zip · Shift+E swing",Vector3(-3,1.2,5.3))
	licensed_prop("ruin_arch",Vector3(18,0,-6),4.2,PI/2)
	licensed_prop("ruin_wall",Vector3(23.8,0,-12),2.5,.15)
	licensed_prop("ruin_wall",Vector3(18,0,-19.4),2.0,PI/2)
	for point in [Vector3(15,0,-8),Vector3(23,0,-8),Vector3(15,0,-17),Vector3(23,0,-17)]: village_prop("banner_1",point,2.5,0,false)
	var circle:=MeshInstance3D.new();var disk:=CylinderMesh.new();disk.top_radius=4.8;disk.bottom_radius=4.8;disk.height=.05;disk.radial_segments=64;circle.mesh=disk;circle.material_override=palette.stone;circle.position=Vector3(19,.005,-12);add_child(circle)
	thread_ring(Vector3(19,.05,-12),4.75)

func trial_grove() -> void:
	for p in [Vector3(-22,0,19),Vector3(-21,0,10),Vector3(-23,0,0),Vector3(-20,0,-10),Vector3(-17,0,-18),Vector3(-8,0,-22),Vector3(0,0,-24),Vector3(23,0,20),Vector3(27,0,12),Vector3(27,0,3),Vector3(28,0,-8),Vector3(27,0,-20),Vector3(-17,0,22),Vector3(-8,0,23),Vector3(2,0,24)]:
		var tree: Node3D=TREE.instantiate();add_child(tree);var bounds:=model_bounds(tree)
		for mesh in mesh_nodes(tree):
			for surface in range(mesh.mesh.get_surface_count()):
				var old: Material=mesh.mesh.surface_get_material(surface)
				mesh.set_surface_override_material(surface,material(Color("315a48") if old and "leaf" in old.resource_name.to_lower() else Color("544237")))
		tree.scale=Vector3.ONE*(6.5/bounds.size.y);tree.position=p-Vector3.UP*bounds.position.y*tree.scale.y
		box("TreeTrunk",p+Vector3.UP,Vector3(.4,2,.4),palette.wood,true,false)
	for point in [Vector3(-25,0,17),Vector3(-24,0,-14),Vector3(-12,0,-24),Vector3(24,0,-23),Vector3(28,0,18)]: licensed_prop("rock_b",point,4.5,.2)
	for z in [-21,-17,-13,-3,1,15,20]:
		rock(Vector3(7.7,-.12,z),Vector3(.7,.5,1.2));rock(Vector3(13.4,-.12,z+.5),Vector3(.7,.5,1.2))
	for p in [Vector3(-12,0,18),Vector3(-18,0,5),Vector3(-15,0,-12),Vector3(23,0,2),Vector3(26,0,-16)]:
		var bush: Node3D=SHRUB.instantiate();bush.position=p;bush.scale=Vector3.ONE*.7;add_child(bush)

func is_swimming(point: Vector3) -> bool:
	return point.x>8.05 and point.x<12.95 and absf(point.z)<25 and point.y<-.75

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(actor): return
	if not practice_mode and not boss.dead and actor.global_position.x>13 and actor.global_position.distance_to(boss.home)<12: boss.ai_enabled=true
	if not practice_mode:
		for receiver in receivers:
			if actor.global_position.distance_to(receiver.global_position-Vector3.UP*.8)<1.8:
				nearby_kind="spool";nearby_label="Pluck the "+receiver.key+" spool";return

func interact_nearby() -> void:
	if nearby_kind=="spool":
		for receiver in receivers:
			if actor.global_position.distance_to(receiver.global_position-Vector3.UP*.8)<1.8: receiver.receive_pulse();return
	else: super.interact_nearby()

func receiver_pulse(key: String) -> void:
	if puzzle_solved: return
	if key==bridge_order[puzzle_progress]:
		puzzle_progress+=1;audio.play("grapple_connect",actor.global_position,-15,1+puzzle_progress*.12)
		if puzzle_progress==3:
			puzzle_solved=true;notice("Bridge woven · the river remains open to swimming and grappling")
			if is_instance_valid(bridge_tween): bridge_tween.kill()
			bridge_tween=create_tween();bridge_tween.tween_property(bridge_body,"position:y",.15,.8).set_trans(Tween.TRANS_CUBIC)
			bridge_tween.finished.connect(build_navigation)
		else: notice("Spool %d / 3 · Gold → Blue → Red" % puzzle_progress)
	else:
		puzzle_progress=1 if key=="Gold" else 0;audio.play("grapple_connect",actor.global_position,-18,.65);notice("Try again · Gold → Blue → Red")

func boss_defeated() -> void:
	if practice_mode: notice("Practice complete · F2 selects another opponent");return
	if is_instance_valid(blossom): return
	blossom=Node3D.new();blossom.position=Vector3(21,0,-17);add_child(blossom)
	var flowers=licensed_prop("flowers",blossom.position,.7,0,false)
	if flowers: flowers.reparent(blossom,true)
	thread_ring(blossom.position+Vector3.UP*.06,.6);notice("Guardian unraveled · the ending blossom awaits behind the clearing")

func enter_practice(kind: String, plate: bool) -> void:
	super.enter_practice(kind,plate)
	actor.spawn=Vector3(19,.2,-17.5);actor.reset_to_spawn();actor.checkpoint=actor.spawn;actor.yaw=PI;actor.pitch=-.12;actor.visual.rotation.y=0
	practice_subject.home=Vector3(19,.1,-12);practice_subject.reset_enemy();practice_subject.ai_enabled=true;actor.lock_target=practice_subject

func reset_playtest() -> void:
	super.reset_playtest()
	if practice_mode: return
	puzzle_progress=0;puzzle_solved=false
	if is_instance_valid(bridge_tween): bridge_tween.kill()
	if is_instance_valid(bridge_body): bridge_body.position.y=-2.7
	if is_instance_valid(boss): boss.ai_enabled=false

func on_enemy_hit(enemy) -> void:
	if not practice_mode: enemy.ai_enabled=true

func sign_at(text: String, point: Vector3) -> void:
	box("TrailPlaque",point,Vector3(2.8,.85,.08),palette.wood)
	var label:=Label3D.new();label.text=text;label.font_size=24;label.pixel_size=.004;label.outline_size=3;label.position=point+Vector3(0,0,.05);add_child(label)

func ramp(from: Vector3, to: Vector3, width: float) -> void:
	super.ramp(from,to,width)
	var node=get_child(get_child_count()-1)
	for mesh in node.find_children("*","MeshInstance3D",true,false): mesh.material_override=palette.stone if from.x>7 and to.x>7 else palette.planks

func terrain(x0: int,x1: int,z0: int,z1: int) -> void:
	super.terrain(x0,x1,z0,z1)
	var ground=get_child(get_child_count()-1)
	var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/study_trial_ground.gdshader")
	mat.set_shader_parameter("dirt_detail",preload("res://assets/textures/polyhaven_dirt_1k.jpg"))
	ground.material_override=mat

func wood_at(point: Vector3) -> bool:
	if puzzle_solved and point.x>7.8 and point.x<13.2 and absf(point.z+8)<1.4 and point.y>0: return true
	if absf(point.x+5)<2.3 and point.z>6.5 and point.z<12.7 and point.y>0: return true
	for checkpoint in route_checkpoints:
		if Vector2(point.x-checkpoint.global_position.x,point.z-checkpoint.global_position.z).length()<1.4 and absf(point.y-checkpoint.global_position.y)<.4: return true
	return false
