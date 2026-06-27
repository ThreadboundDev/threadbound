extends Area2D

@export var boss_path: NodePath
@export var entrance_door_path: NodePath

var _locked := false

@onready var boss: Node = get_node_or_null(boss_path)
@onready var entrance_door: Node = get_node_or_null(entrance_door_path)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if boss and boss.get("health_component"):
		var health_component := boss.get("health_component") as HealthComponent
		if health_component and not health_component.died.is_connected(_on_boss_died):
			health_component.died.connect(_on_boss_died)

func _on_body_entered(body: Node2D) -> void:
	if _locked or not body.is_in_group("player"):
		return

	_locked = true
	if entrance_door and entrance_door.has_method("lock_closed_for_boss"):
		entrance_door.lock_closed_for_boss()

func _on_boss_died(_damage: DamageData) -> void:
	if entrance_door and entrance_door.has_method("open_silently"):
		entrance_door.open_silently()
