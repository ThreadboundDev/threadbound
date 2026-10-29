extends SceneTree
var world
var actor
var enemy
var checks: Array[Dictionary]=[]
func _initialize() -> void:
	create_timer(120).timeout.connect(func():quit(99))
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(label: String, ok: bool, detail=null) -> void:
	checks.append({"check":label,"passed":ok,"detail":detail});print("PASS " if ok else "FAIL ",label," ",detail)
func fixture(slot:=0,gap:=3.6) -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	world.enter_practice("reedhook",false)
	actor.global_position=Vector3(0,.1,12);actor.yaw=0;actor.pitch=-.15;actor.visual.rotation.y=PI
	enemy=world.practice_subject;enemy.ai_enabled=false;enemy.global_position=Vector3(0,.1,12-gap);enemy.home=enemy.global_position
	await frames(20)
	actor.combat.invulnerable=0;actor.momentum.reset();actor.kit.set_slot(slot)
	await frames(2)
func jump_to(point: Vector3) -> bool:
	var took_off:=false
	for frame in range(180):
		var difference: Vector3=point-actor.global_position
		var gap:=Vector2(difference.x,difference.z).length()
		if took_off and actor.is_on_floor() and absf(difference.y)<.12 and gap<1.35:
			Input.action_release("jump");Input.action_release("forward");return true
		if took_off and actor.is_on_floor() and frame>55:
			Input.action_release("jump");Input.action_release("forward");return false
		actor.yaw=atan2(-difference.x,-difference.z)
		Input.action_press("forward")
		if not took_off and actor.is_on_floor() and gap<3.5:
			Input.action_press("jump");took_off=true
		await frames(1)
	Input.action_release("jump");Input.action_release("forward");return false
func run() -> void:
	world=load("res://scenes/loom_crossing_trial.tscn").instantiate();root.add_child(world);actor=world.actor
	check("Trial opens with weapon and route instructions",paused and world.hud_layer.dialogue_text.text.contains("three weapon"))
	world.hud_layer.close_dialogue();await frames(40)
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	check("Safe village start",actor.combat.health==100 and actor.is_on_floor())
	check("Three field encounters and guardian",get_nodes_in_group("study_enemies").size()==4)
	check("Five checkpointed jump decks",world.route_checkpoints.size()==5)
	check("Working villager retained",not world.worker_players.is_empty() and world.worker_players[0].is_playing())
	actor.global_position=Vector3(-4,.1,4.3);actor.velocity=Vector3.ZERO;await frames(16)
	for index in range(world.route_checkpoints.size()):
		var point: Vector3=world.route_checkpoints[index].global_position-Vector3.UP*.15
		var reached: bool=await jump_to(point)
		check("Running jump deck %d" % (index+1),reached,[actor.global_position,point])
		if not reached: break
		await frames(1)
	await fixture(1)
	check("Staff held on real rig; shield hidden",is_instance_valid(actor.kit.held) and not actor.model.find_child("Study_Sword",true,false).visible)
	actor.combat.attack();await frames(44)
	check("Staff bolt collides and damages once",enemy.health==enemy.max_health-21,enemy.health)
	await fixture(1)
	check("Staff neutral special uses two AP",actor.combat.special(false) and actor.combat.available_ap()==4)
	await frames(75)
	check("Charged thread orb hits target",enemy.health<enemy.max_health-40,enemy.health)
	await fixture(1)
	actor.combat.special(true);await frames(65)
	check("Directional staff volley hits",enemy.health<enemy.max_health,enemy.health)
	await fixture(2,2.65)
	check("Spear mesh and existing animation installed",is_instance_valid(actor.kit.held) and actor.animation.has_animation("pole_sweep"))
	check("Spear full size, palm grip and forward-blade trail",world.model_bounds(actor.kit.held).size.y>2 and actor.kit.held.global_position.distance_to(actor.kit.attachment.global_position)<.1 and is_instance_valid(actor.kit.weapon_trail) and actor.kit.weapon_trail.references[1].point.y>1.5)
	actor.combat.attack();await frames(30)
	check("Spear reaches beyond sword range",enemy.health<enemy.max_health,enemy.health)
	await fixture(2,1.65)
	var hits: int=actor.combat.total_hits
	actor.combat.attack()
	for strike in range(2):
		while actor.combat.combo==strike and actor.combat.elapsed<actor.combat.duration-.12: await frames(1)
		actor.combat.attack()
		while actor.combat.combo==strike and actor.combat.action=="pole": await frames(1)
	await frames(70)
	check("Spear has a three-hit combo",actor.combat.combo==2 and actor.combat.total_hits>=hits+3,actor.combat.total_hits-hits)
	await fixture(2)
	var start: Vector3=actor.global_position
	actor.combat.special(true);await frames(40)
	check("Spear directional special lunges",actor.global_position.distance_to(start)>1 and actor.combat.available_ap()==4)
	await fixture(0)
	check("Sword and shield restore on swap",actor.model.find_child("Study_Sword",true,false).visible)
	world.leave_practice()
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	world.receiver_pulse("Blue")
	check("Wrong spool order resets gently",world.puzzle_progress==0 and not world.puzzle_solved)
	actor.global_position=Vector3(0,.1,-8.5);actor.lock_target=null;actor.combat.reset();actor.kit.set_slot(1)
	var gold: Vector3=world.receivers[2].global_position
	var aim: Vector3=gold-actor.camera_pivot.global_position
	actor.yaw=atan2(-aim.x,-aim.z);actor.pitch=atan2(aim.y,Vector2(aim.x,aim.z).length())
	await frames(4)
	actor.combat.attack();await frames(45)
	check("Staff projectile activates physical spool",world.puzzle_progress==1,world.puzzle_progress)
	actor.global_position=world.receivers[0].global_position-Vector3.UP*.8;actor.combat.reset();await frames(3)
	world.interact_nearby()
	check("Spools also accept close interaction",world.puzzle_progress==2,world.puzzle_progress)
	actor.global_position=Vector3(5.3,.1,-9.2);actor.combat.reset();actor.kit.set_slot(2);actor.visual.rotation.y=PI
	await frames(12)
	actor.combat.attack();await frames(35)
	await frames(65)
	check("Correct sequence raises physical bridge",world.puzzle_solved and world.puzzle_progress==3 and absf(world.bridge_body.position.y-.15)<.02,[world.puzzle_progress,actor.combat.action,actor.combat.air_direction,actor.global_position])
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(10.5,2,-8),Vector3(10.5,-3,-8),1)
	var bridge_hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
	check("Woven bridge supports collision",not bridge_hit.is_empty() and bridge_hit.position.y>0)
	actor.global_position=Vector3(10.5,-1.4,8);actor.velocity=Vector3.ZERO;actor.lock_target=null;actor.yaw=0
	await frames(5)
	actor.kit.set_slot(1);actor.combat.special(false)
	check("Swimming staff special keeps authored water animation",actor.swimming and actor.combat.action=="neutral" and actor.animation.current_animation.ends_with("/water_neutral_special"))
	await frames(90)
	var depth: float=actor.global_position.y
	Input.action_press("descend");await frames(10);Input.action_release("descend")
	check("Swimming supports deliberate dive",actor.global_position.y<depth-.2)
	Input.action_press("right");Input.action_press("jump");await frames(70)
	Input.action_release("right");Input.action_release("jump")
	await frames(40)
	check("Swimming ramp permits shore exit",actor.global_position.x>13 and not actor.swimming and actor.is_on_floor(),str(actor.global_position))
	await fixture()
	actor.global_position=Vector3(-4,1,2);actor.lock_target=null;actor.yaw=PI;actor.pitch=.5
	await frames(4)
	Input.action_press("sprint")
	var beam: Vector3=Vector3(-4,3.5,2.8)
	var direction: Vector3=beam-(actor.global_position+Vector3.UP*1.4)
	actor.yaw=atan2(-direction.x,-direction.z);actor.pitch=atan2(direction.y,Vector2(direction.x,direction.z).length())
	await frames(3)
	var fired: bool=actor.grapple.fire()
	check("Shift hook selects rope swing",fired and actor.grapple.mode=="swing")
	Input.action_release("sprint")
	await frames(40)
	check("Swing maintains live tether",actor.grapple.active and actor.grapple.connected)
	actor.global_position=Vector3(-2,1.6,1.0);actor.velocity=Vector3.ZERO
	actor.grapple.rope_length=actor.grapple.swing_origin().distance_to(actor.grapple.attach_position(actor.grapple.target))
	await frames(12)
	check("Swing gravity creates a real pendulum drop",actor.grapple.active and actor.velocity.y<-.5 and actor.global_position.y<1.5,[actor.velocity,actor.global_position])
	var swing_start: Vector3=actor.global_position
	Input.action_press("right");await frames(20);Input.action_release("right")
	check("Swing input produces tangential movement",actor.global_position.distance_to(swing_start)>.2)
	var anchor: Vector3=actor.grapple.attach_position(actor.grapple.target) if is_instance_valid(actor.grapple.target) else Vector3.INF
	check("Rope constraint limits distance",actor.grapple.active and actor.grapple.swing_origin().distance_to(anchor)<actor.grapple.rope_length+.5)
	actor.grapple.jump_release()
	check("Swing jump releases with upward motion",not actor.grapple.active and actor.velocity.y>3)
	world.leave_practice()
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	actor.global_position=Vector3(4,.1,-12);actor.velocity=Vector3.ZERO;actor.combat.reset();actor.combat.invulnerable=0;actor.lock_target=null
	world.boss.receive_hit(1,Vector3.ZERO,false)
	check("Ranged contact wakes distant guardian",world.boss.ai_enabled)
	await frames(15)
	check("Guardian warns before ranged pressure",world.boss.state=="ranged_windup" and actor.combat.health==100,[world.boss.state,actor.combat.health])
	await frames(40)
	check("Standing in telegraph takes meaningful damage",actor.combat.health==74,actor.combat.health)
	world.boss.reset_enemy();world.boss.state="chase";world.boss.ai_enabled=true
	actor.global_position=Vector3(4,.1,-12);actor.velocity=Vector3.ZERO;actor.combat.reset();actor.combat.invulnerable=0;actor.yaw=-PI/2
	await frames(15)
	Input.action_press("right");await frames(42);Input.action_release("right")
	check("Moving out of guardian telegraph avoids damage",actor.combat.health==100,actor.combat.health)
	world.boss.receive_hit(9999,Vector3.ZERO,true)
	check("Guardian leaves trial ending blossom",is_instance_valid(world.blossom) and world.blossom.global_position.z<0)
	var failed:=checks.filter(func(c):return not c.passed).size()
	FileAccess.open("res://loom_trial_test_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	print("LOOM_TRIAL_CHECKS ",checks.size()," FAILED ",failed)
	world.queue_free();await frames(2);OS.delay_msec(150);quit(1 if failed else 0)
