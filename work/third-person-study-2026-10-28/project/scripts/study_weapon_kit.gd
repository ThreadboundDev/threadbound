extends Node
const PROJECTILE=preload("res://scripts/study_thread_projectile.gd")
var actor
var world
var slot:=0
var fired:=false
var attachment: BoneAttachment3D
var held: Node3D
var weapon_trail
var ward: MeshInstance3D
var weapon_names: Array[String]=["Sword / Shield","Thread Staff","Balance Spear"]
func _ready() -> void:
	actor=get_parent();world=actor.get_parent()
	attachment=BoneAttachment3D.new();attachment.bone_name="hand.R";actor.skeleton.add_child(attachment)
	ward=MeshInstance3D.new()
	var ring:=TorusMesh.new();ring.inner_radius=.18;ring.outer_radius=.24;ring.rings=24;ring.ring_segments=6
	ward.mesh=ring;ward.material_override=world.fx.glow(Color("8ac4c5"));ward.visible=false
	world.add_child(ward)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_1,KEY_2,KEY_3]: set_slot(event.physical_keycode-KEY_1)
func _process(_delta: float) -> void:
	ward.visible=slot!=0 and actor.combat.guarding and not actor.combat.dead
	if ward.visible:
		ward.global_position=actor.grapple_origin()
		ward.quaternion=Quaternion(Vector3.UP,actor.facing())
func set_slot(value: int) -> bool:
	if actor.combat.action!="" or actor.dash_time>0 or actor.grapple.active: return false
	slot=posmod(value,3)
	if is_instance_valid(weapon_trail):
		world.fx.trails.erase(weapon_trail);weapon_trail.queue_free();weapon_trail=null
	if is_instance_valid(held): held.queue_free();held=null
	actor.set_weapons(actor.use_new_weapons)
	if slot!=0:
		for mesh in actor.model.find_children("*","MeshInstance3D",true,false):
			if String(mesh.name) in ["Study_Sword","Study_Shield","Threadborne_Sword","Threadborne_Shield_Combined_Test"]: mesh.visible=false
		var path: String="res://assets/weapons/ranged_staff.glb" if slot==1 else "res://assets/weapons/balance_spear.glb"
		held=load(path).instantiate();attachment.add_child(held);held.position=Vector3(0,.07,0)
		var hand: int=actor.skeleton.find_bone("hand.R")
		var index: int=actor.skeleton.find_bone("index.01.R")
		var pinky: int=actor.skeleton.find_bone("pinky.01.R")
		var across: Vector3=actor.skeleton.get_bone_global_rest(index).origin-actor.skeleton.get_bone_global_rest(pinky).origin
		var axis: Vector3=actor.skeleton.get_bone_global_rest(hand).basis.inverse()*across.normalized()
		held.quaternion=Quaternion(Vector3.UP,axis.normalized())
		if slot==2:
			var meshes=world.mesh_nodes(held)
			if not meshes.is_empty():
				var bounds: AABB=meshes[0].mesh.get_aabb()
				# This exported spear points +Y; the original sword points the other way.
				meshes[0].set_meta("blade_base_gltf",[0,bounds.end.y-.6,0])
				meshes[0].set_meta("blade_tip_gltf",[0,bounds.end.y,0])
				world.fx.watch_blade(actor,meshes[0]);weapon_trail=world.fx.trails.back()
	world.notice(weapon_names[slot]+" · LMB combo · Q special · movement+Q directional special")
	return true
func configure_basic() -> void:
	var c=actor.combat
	fired=false
	if slot==0 or actor.swimming: return
	if c.action=="air":
		if slot==1:
			c.action="ranged_air";c.active_start=.17;c.active_end=.21
		return
	if slot==1:
		if not is_instance_valid(actor.lock_target): actor.visual.rotation.y=actor.yaw+PI;c.strike_direction=actor.facing()
		c.action="ranged";c.duration=[.46,.43,.58][c.combo];c.active_start=.2;c.active_end=.24
		actor.play_clip("staff_cast" if c.combo!=1 else "casting_1",true)
	else:
		c.action="pole";c.duration=[.48,.52,.65][c.combo];c.active_start=[.18,.2,.26][c.combo];c.active_end=c.active_start+.14
		actor.play_clip(["pole_jab","pole_sweep","pole_finish"][c.combo],true)
	actor.animation.speed_scale=actor.animation.current_animation_length/c.duration
	c.clip_speed=actor.animation.speed_scale
func configure_special(directional: bool) -> void:
	if actor.swimming: return
	fired=false
	var c=actor.combat
	if slot==1:
		if not is_instance_valid(actor.lock_target): actor.visual.rotation.y=actor.yaw+PI;c.strike_direction=actor.facing()
		c.action="volley" if directional else "orb";c.duration=.8;c.active_start=.3;c.active_end=.36
		actor.play_clip("staff_cast",true);actor.animation.speed_scale=actor.animation.current_animation_length/c.duration
	elif slot==2 and directional:
		c.action="lance";actor.play_clip("pole_jab",true);actor.animation.speed_scale=actor.animation.current_animation_length/c.duration
	c.clip_speed=actor.animation.speed_scale
func fire_bolts() -> void:
	if fired: return
	fired=true
	var c=actor.combat
	var origin: Vector3=actor.grapple_origin()+actor.facing()*.2
	var aim: Vector3=actor.camera.global_position-actor.camera.global_basis.z*30
	var view: Vector3=-actor.camera.global_basis.z
	var ray_start: Vector3=actor.camera.global_position+view*maxf(0,(actor.global_position+Vector3.UP*1.4-actor.camera.global_position).dot(view))
	var query:=PhysicsRayQueryParameters3D.create(ray_start,aim,5,[actor.get_rid()])
	var hit: Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): aim=hit.position
	if is_instance_valid(actor.lock_target) and not actor.lock_target.dead: aim=actor.lock_target.global_position+Vector3.UP*actor.lock_target.target_height
	var direction: Vector3=(aim-origin).normalized()
	var count: int=3 if c.action=="volley" else 1
	for i in range(count):
		var bolt=PROJECTILE.new();bolt.world=world
		bolt.direction=direction.rotated(Vector3.UP,(i-1)*.1 if count>1 else 0)
		bolt.heavy=c.action=="orb" or (c.action in ["ranged","ranged_air"] and c.combo==2)
		bolt.damage=55 if c.action=="orb" else (20 if count>1 else [21,23,30][c.combo])
		bolt.speed=16 if bolt.heavy else 30;bolt.life=1.1 if bolt.heavy else .75;bolt.splash=2.6 if c.action=="orb" else 0
		world.add_child(bolt);bolt.global_position=origin
		c.hit_targets[bolt.get_instance_id()]=true
	world.audio.play("grapple_throw",origin,-16,1.25)
func _exit_tree() -> void:
	if is_instance_valid(ward): ward.queue_free()
