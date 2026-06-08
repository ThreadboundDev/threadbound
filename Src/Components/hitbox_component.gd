class_name HitboxComponent
extends Area2D

signal hit_landed(hurtbox: HurtboxComponent, damage: DamageData)

@export var damage: DamageData
@export var hitbox_owner_path: NodePath
@export var one_hit_per_activation := true

@onready var hitbox_owner: Node = get_node_or_null(hitbox_owner_path)

var active := false
var _hit_hurtboxes: Array[HurtboxComponent] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	disable()

func enable() -> void:
	active = true
	_hit_hurtboxes.clear()
	monitoring = true
	monitorable = false

func disable() -> void:
	active = false
	monitoring = false
	_hit_hurtboxes.clear()

func _on_area_entered(area: Area2D) -> void:
	if not active or not area is HurtboxComponent:
		return

	var hurtbox := area as HurtboxComponent
	if one_hit_per_activation and hurtbox in _hit_hurtboxes:
		return

	var hit_damage := damage
	if hit_damage:
		hit_damage = damage.duplicate_for_hit(hitbox_owner, global_position)
	else:
		hit_damage = DamageData.new()
		hit_damage.source = hitbox_owner
		hit_damage.hit_position = global_position

	if hurtbox.receive_hit(hit_damage):
		_hit_hurtboxes.append(hurtbox)
		hit_landed.emit(hurtbox, hit_damage)
