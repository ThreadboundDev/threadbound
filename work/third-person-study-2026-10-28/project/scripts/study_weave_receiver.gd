extends StaticBody3D
var world
var key:=""
var tint:=Color.WHITE
var cooldown:=0.0
var ring: MeshInstance3D
func _ready() -> void:
	add_to_group("weave_receivers")
	collision_layer=1
	var collider:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=.43;collider.shape=sphere;add_child(collider)
	ring=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.23;torus.outer_radius=.38;torus.rings=32;torus.ring_segments=8
	ring.mesh=torus;ring.rotation.x=PI/2;ring.material_override=world.fx.glow(tint);add_child(ring)
	var core:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.10;ball.height=.2;core.mesh=ball;core.material_override=world.fx.glow(tint.lightened(.2));add_child(core)
func _process(delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
	ring.rotation.z+=delta*.25
func receive_pulse() -> void:
	if cooldown>0: return
	cooldown=.25
	world.receiver_pulse(key)
	world.fx.burst(global_position,tint)
	var tween:=create_tween();tween.tween_property(ring,"scale",Vector3.ONE*1.18,.08);tween.tween_property(ring,"scale",Vector3.ONE,.18)
