extends SceneTree
var world
var actor
var enemy
var checks: Array[Dictionary]=[]
func _initialize() -> void:
	create_timer(100).timeout.connect(func():quit(99))
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(label: String, ok: bool, detail=null) -> void:
	checks.append({"check":label,"passed":ok,"detail":detail})
	print("PASS " if ok else "FAIL ",label," ",detail)
func fixture(plate:=false,kind:="reedhook") -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	world.enter_practice(kind,plate)
	actor.global_position=Vector3(22,.1,10.8)
	enemy=world.practice_subject
	enemy.ai_enabled=false
	await frames(20)
	actor.combat.invulnerable=0
	actor.momentum.reset()
	enemy.visual.rotation.y=PI
func bot(reader: bool) -> Dictionary:
	await fixture(true)
	enemy.ai_enabled=true
	var dodges:=0
	for i in range(1500):
		Input.action_release("block");Input.action_release("forward")
		if actor.combat.dead or enemy.dead: break
		var gap: float=actor.global_position.distance_to(enemy.global_position)
		if not reader:
			if i%4==0: actor.combat.attack()
		elif (enemy.state=="windup" and enemy.timer<.11) or (enemy.state=="active" and enemy.combo==1):
			if enemy.combo==0:
				if actor.request_dash(actor.facing()): dodges+=1
			else: Input.action_press("block")
		elif enemy.state=="hurt" or (enemy.state=="recover" and enemy.combo>=1):
			if gap>2.0: Input.action_press("forward")
			elif enemy.state=="hurt" and actor.combat.available_ap()>=2:
				actor.combat.special(false)
			else: actor.combat.attack()
		await frames(1)
	return {"player_health":actor.combat.health,"enemy_health":enemy.health,"player_dead":actor.combat.dead,"enemy_dead":enemy.dead,"dodges":dodges,"parries":actor.combat.parries}
func run() -> void:
	world=load("res://scenes/chamber_demo.tscn").instantiate();root.add_child(world)
	actor=world.actor
	check("No invented player name in welcome",not world.hud_layer.dialogue_text.text.contains("Ruin"))
	world.hud_layer.close_dialogue();await frames(40)
	await fixture()
	check("Practice isolates one opponent",get_nodes_in_group("study_enemies").filter(func(e):return e.visible and e.ai_enabled).is_empty() and get_nodes_in_group("study_enemies").filter(func(e):return e.visible).size()==1)
	check("Mixamo combat clips available",actor.animation.has_animation("combat_strafe_left") and actor.animation.has_animation("combat_strafe_right") and actor.animation.has_animation("heavy_hit"))
	actor.global_position.y=3
	await frames(2)
	Input.action_press("jump")
	actor.combat.attack()
	check("Held jump produces forward air attack",actor.combat.air_direction=="forward" and actor.current_clip=="air_attack_forward")
	await fixture()
	actor.global_position.y=3;await frames(2);Input.action_press("air_up");actor.combat.attack()
	check("Explicit up modifier retains upward strike",actor.combat.air_direction=="up")
	await fixture()
	actor.combat.attack();await frames(6)
	var ap: int=actor.combat.available_ap()
	check("Attack commitment cannot be dodged out of",not actor.request_dash(Vector3.RIGHT) and actor.combat.available_ap()==ap)
	check("Hookshot cannot cancel a committed attack",not actor.grapple.fire())
	while actor.combat.action!="recover": await frames(1)
	var pose: float=actor.animation.current_animation_position
	await frames(4)
	check("Recovery holds follow-through instead of entering next swing",not actor.animation.is_playing() and is_equal_approx(pose,actor.animation.current_animation_position))
	await fixture(true)
	enemy.begin_attack();enemy.receive_hit(25,Vector3.FORWARD*2)
	check("Armor absorbs but does not erase damage",enemy.health==enemy.max_health-18)
	check("Light hit cannot interrupt armor",enemy.state=="windup" and enemy.last_hit_armored and enemy.impulse.length()<.2)
	check("Downloaded torso and bracers visibly plated",enemy.armor_surfaces.size()>=2 and enemy.armor_surfaces[0].mesh.get_surface_override_material(0).metallic>.7)
	enemy.receive_hit(25,Vector3.FORWARD*2,true)
	enemy.receive_hit(25,Vector3.FORWARD*2,true)
	check("Heavy pressure breaks stance",enemy.state=="hurt" and enemy.armor_exposed>0 and not enemy.last_hit_armored)
	await fixture(true)
	enemy.visual.rotation.y=0
	enemy.receive_hit(25,Vector3.FORWARD*2)
	check("Flanking bypasses frontal absorption",enemy.health==enemy.max_health-25 and not enemy.last_hit_armored)
	await fixture()
	actor.request_dash(Vector3.RIGHT)
	check("Dodge startup remains vulnerable",not actor.dodge_invulnerable())
	await frames(4)
	check("Timed middle of dodge protects",actor.dodge_invulnerable() and not actor.combat.receive_hit(20,actor.global_position+Vector3.LEFT))
	await frames(12)
	check("Dodge tail is punishable",not actor.dodge_invulnerable() and actor.combat.receive_hit(20,actor.global_position+Vector3.LEFT))
	await fixture()
	enemy.ai_enabled=true;enemy.begin_attack()
	await frames(20)
	check("Fast enemy windup stays readable",actor.combat.health==100)
	await frames(12)
	check("Enemy commits a damaging strike promptly",actor.combat.health==72 and enemy.attacks_connected>0,actor.combat.health)
	await fixture()
	enemy.ai_enabled=true;enemy.begin_attack()
	await frames(20)
	actor.request_dash(Vector3.RIGHT)
	await frames(16)
	check("Timed directional dodge beats actual attack",actor.combat.health==100 and actor.global_position.x>22.8)
	await fixture(false,"eave")
	enemy.ai_enabled=true;enemy.begin_attack();actor.combat.invulnerable=99
	var followup:=false
	for i in range(100):
		await frames(1)
		if enemy.combo==1: followup=true
	check("Runner follows with a second attack",followup)
	var mash: Dictionary=await bot(false)
	check("Blind light spam loses to armored opponent",mash.player_dead and not mash.enemy_dead,mash)
	var read: Dictionary=await bot(true)
	check("Reading attacks and using defenses can win",read.enemy_dead and not read.player_dead and read.dodges>0,read)
	world.leave_practice();await frames(2)
	check("Leaving practice restores exploration roster",not world.practice_mode and get_nodes_in_group("study_enemies").all(func(e):return e.visible and e.navigator.avoidance_enabled))
	var failed:=checks.filter(func(c):return not c.passed).size()
	FileAccess.open("res://committed_combat_test_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	print("COMMITTED_COMBAT_CHECKS ",checks.size()," FAILED ",failed)
	world.queue_free();await frames(2);OS.delay_msec(150)
	quit(1 if failed else 0)
