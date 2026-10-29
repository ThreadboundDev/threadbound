extends Node3D
var world
var direction:=Vector3.FORWARD
var speed:=26.0
var damage:=22
var heavy:=false
var splash:=0.0
var life:=2.4
func _ready() -> void:
	var mesh:=MeshInstance3D.new()
	var shape:=SphereMesh.new()
	shape.radius=.13 if heavy else .055;shape.height=shape.radius*2
	mesh.mesh=shape;mesh.material_override=world.fx.glow(Color("d7c792") if heavy else Color("9fd9df"))
	add_child(mesh)
	var spindle:=MeshInstance3D.new()
	var capsule:=CapsuleMesh.new();capsule.radius=.018;capsule.height=.32
	spindle.mesh=capsule;spindle.material_override=world.fx.glow(Color("eee1b2"))
	add_child(spindle);spindle.quaternion=Quaternion(Vector3.UP,direction)
func hit_enemy(enemy) -> void:
	if enemy.dead or not enemy.visible: return
	enemy.receive_hit(damage,direction*(3 if heavy else 1.2),heavy)
	world.actor.combat.total_hits+=1
	if world.actor.combat.action in ["ranged","ranged_air","orb","volley"]: world.actor.combat.confirmed_strikes+=1
	if not enemy.last_hit_armored: enemy.freeze_impact(.06 if heavy else .025)
	world.actor.camera_kick=maxf(world.actor.camera_kick,.07 if heavy else .025)
func _physics_process(delta: float) -> void:
	life-=delta
	if life<=0: queue_free();return
	var next:=global_position+direction*speed*delta
	var query:=PhysicsRayQueryParameters3D.create(global_position,next,5,[world.actor.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): global_position=next;return
	global_position=hit.position
	if hit.collider.is_in_group("weave_receivers"): hit.collider.receive_pulse()
	if splash>0:
		world.fx.ring(global_position,.3,Color("c8b9e0"),.25)
		world.fx.burst(global_position,Color("e3d6ae"),true)
		for enemy in get_tree().get_nodes_in_group("study_enemies"):
			if enemy.global_position.distance_to(global_position)<splash and world.clear_sight(global_position+hit.normal*.08,enemy.global_position+Vector3.UP): hit_enemy(enemy)
	elif hit.collider.is_in_group("study_enemies"): hit_enemy(hit.collider)
	else: world.fx.burst(global_position,Color("bcdbd9"))
	queue_free()
