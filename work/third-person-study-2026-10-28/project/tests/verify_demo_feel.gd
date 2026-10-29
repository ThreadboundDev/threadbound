extends SceneTree
var world
var actor
var enemies: Array
var checks: Array[Dictionary]=[]
func _initialize() -> void:
	create_timer(120).timeout.connect(func():quit(99))
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(label: String, ok: bool, detail=null) -> void:
	checks.append({"check":label,"passed":ok,"detail":detail})
	print("PASS " if ok else "FAIL ",label," ",detail)
func fixture(point:=Vector3(0,.1,17)) -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	world.hud_layer.close_dialogue()
	world.reset_playtest()
	actor.set_physics_process(true)
	actor.global_position=point
	actor.velocity=Vector3.ZERO
	for i in range(enemies.size()):
		enemies[i].ai_enabled=false
		enemies[i].global_position=Vector3(30+i*2,0,-25)
	await frames(25)
	actor.momentum.reset()
	actor.combat.invulnerable=0
func run() -> void:
	world=load("res://scenes/chamber_demo.tscn").instantiate()
	root.add_child(world)
	actor=world.actor
	enemies=get_nodes_in_group("study_enemies")
	check("Demo opens with focused welcome",paused and world.hud_layer.dialogue.visible)
	world.hud_layer.close_dialogue()
	await frames(45)
	check("Safe tutorial spawn",actor.combat.health==100 and actor.global_position.distance_to(actor.spawn)<1)
	await fixture()
	Input.action_press("forward")
	await frames(25)
	check("Default athletic run without sprint",actor.current_clip=="demo_run" and absf(Vector2(actor.velocity.x,actor.velocity.z).length()-5.2*actor.momentum_multiplier("move"))<.1,[actor.current_clip,actor.velocity,actor.global_position,paused])
	Input.action_release("forward")
	check("Dedicated 3D model loaded",actor.visual.find_child("Threadborne_Rig",true,false)!=null and actor.MODEL.resource_path.ends_with("ruin_3d_demo.glb"))
	await fixture()
	actor.visual.rotation.y=PI
	var enemy=enemies[0]
	enemy.global_position=actor.global_position+Vector3(0,0,-1.65)
	actor.combat.attack()
	await frames(6)
	check("Early spam rejected",not actor.combat.attack() and not actor.combat.buffered)
	var frozen:=false
	for i in range(28):
		await frames(1)
		if actor.combat.impact_time>0:
			frozen=true
			check("Confirmed contact freezes both participants locally",enemy.impact_time>0 and Engine.time_scale==1.0)
			break
	check("Contact has impact feedback",frozen and world.feedback_hits>0 and enemy.health<enemy.max_health)
	await frames(45)
	check("Single strike cannot hit repeatedly",actor.combat.total_hits==1)
	await fixture()
	actor.visual.rotation.y=PI
	actor.combat.attack()
	for strike in range(3):
		while actor.combat.action=="light" and actor.combat.combo==strike and actor.combat.elapsed<actor.combat.duration-.13: await frames(1)
		if strike<2:
			check("Late deliberate tap accepted "+str(strike),actor.combat.attack())
			while actor.combat.action=="light" and actor.combat.combo==strike: await frames(1)
		else:
			check("Finisher cannot buffer endlessly",not actor.combat.attack())
			while actor.combat.action=="light": await frames(1)
	check("Three-hit chain has recovery",actor.combat.action=="recover" and actor.combat.recovery_time>.25)
	check("Recovery rejects attack spam",not actor.combat.attack())
	await frames(22)
	check("Recovery ends; basic attack costs no AP",actor.combat.action=="" and actor.combat.available_ap()==6)
	check("Whiffs have no false contact",actor.combat.impact_time==0 and actor.combat.hit_targets.is_empty())
	await fixture()
	world.box("StepFixture",Vector3(0,.09,15.5),Vector3(4,.18,.5),world.palette.planks,true)
	Input.action_press("forward")
	await frames(45)
	Input.action_release("forward")
	check("Capsule clears low debris without sticking",actor.global_position.z<14.9,[actor.global_position,actor.velocity,actor.current_clip,paused])
	world.box("WallFixture",Vector3(0,1.5,12),Vector3(4,3,.5),world.palette.planks,true)
	Input.action_press("forward")
	await frames(30)
	Input.action_release("forward")
	check("Full wall remains solid",actor.global_position.z>12.4,[actor.global_position,actor.velocity,actor.current_clip,paused])
	await fixture(Vector3(0,.1,10))
	actor.set_physics_process(false)
	actor.combat.invulnerable=99
	enemy.global_position=Vector3(0,.1,16)
	enemy.home=enemy.global_position
	enemy.state="chase";enemy.ai_enabled=true
	world.build_navigation()
	await frames(60)
	var start: Vector3=enemy.global_position
	await frames(420)
	check("Enemy navigates around solid wall",enemy.global_position.distance_to(actor.global_position)<3 and enemy.global_position.distance_to(start)>2,[enemy.global_position,enemy.state,enemy.desired_motion,enemy.safe_velocity,enemy.is_physics_processing(),paused])
	var curls: Array=[]
	for joint in ["index_01_r","index_02_r","index_03_r"]:
		curls.append(enemy.skeleton.get_bone_pose_rotation(enemy.skeleton.find_bone(joint)).get_angle())
	check("Sword fingers wrap the grip",curls.all(func(a):return a>.5),curls)
	check("Armed jog is a true loop",enemy.animation.get_animation("Jog_Armed").loop_mode==Animation.LOOP_LINEAR)
	await fixture(Vector3(-5,.1,17))
	actor.combat.invulnerable=99
	for i in range(2):
		enemies[i].global_position=Vector3(-6+i*1.1,.1,23)
		enemies[i].home=enemies[i].global_position
		enemies[i].ai_enabled=true;enemies[i].state="chase"
	await frames(180)
	check("Crowd agents both progress",enemies[0].global_position.z<20 and enemies[1].global_position.z<20,[enemies[0].global_position,enemies[1].global_position])
	check("Crowd capsules remain separate",enemies[0].global_position.distance_to(enemies[1].global_position)>.75)
	await fixture()
	for key in ["Essence","Power","Balance"]:
		var marker=world.thread_markers.filter(func(m):return m.get_meta("key")==key)[0]
		actor.global_position=marker.global_position-Vector3.UP*.75
		await frames(3)
		check("Open wing pickup "+key,world.collected.has(key))
	check("Collected channels color Flow independently",world.flow_colors().size()==3)
	actor.global_position=world.shrine_position
	actor.combat.health=20
	actor.combat.spend_ap(4)
	await frames(3)
	world.interact_nearby()
	check("Shrine restores health and AP",actor.combat.health==100 and actor.combat.available_ap()==6)
	var checkpoint: Vector3=actor.checkpoint
	actor.combat.invulnerable=0
	actor.combat.receive_hit(999,actor.global_position+Vector3.FORWARD)
	await frames(125)
	check("Death returns to rested checkpoint",not actor.combat.dead and actor.global_position.distance_to(checkpoint)<1,[actor.global_position,checkpoint,actor.combat.dead,paused,actor.is_physics_processing()])
	check("Death retains discovered threads",world.collected.size()==3)
	world.boss.ai_enabled=true
	world.boss.begin_attack()
	world.boss.receive_hit(1,Vector3.ZERO)
	check("Committed boss resists light stunlock",world.boss.state=="windup")
	world.boss.receive_hit(1,Vector3.ZERO,true)
	check("Deliberate heavy hit can stagger boss",world.boss.state=="hurt")
	world.boss.ai_enabled=false
	world.boss.receive_hit(999,Vector3.ZERO,true)
	check("Boss defeat grows ending blossom",is_instance_valid(world.blossom))
	actor.global_position=world.blossom.global_position+Vector3(-1.2,.2,0)
	await frames(25)
	check("Ending blossom reachable on foot",world.nearby_kind=="ending" and world.clear_sight(actor.global_position+Vector3.UP*.6,world.blossom.global_position+Vector3.UP*.6),str(actor.global_position))
	world.interact_nearby()
	check("End offer pauses and provides two choices",paused and world.hud_layer.choices.get_child_count()==2)
	world.hud_layer.close_dialogue()
	check("Keep exploring resumes",not paused and world.boss.dead)
	world.hud_layer.show_ending()
	check("Thank-you ending available",paused and world.hud_layer.ending)
	world.hud_layer.restart_demo()
	await frames(3)
	check("Restart restores full demo loop",not paused and world.collected.is_empty() and not world.boss.dead and not is_instance_valid(world.blossom))
	var failures:=checks.filter(func(c):return not c.passed).size()
	FileAccess.open("res://demo_feel_test_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failures},"\t"))
	print("DEMO_FEEL_CHECKS ",checks.size()," FAILED ",failures)
	world.queue_free();await frames(2);OS.delay_msec(150)
	quit(1 if failures else 0)
