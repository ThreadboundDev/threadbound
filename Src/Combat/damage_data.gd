class_name DamageData
extends Resource

@export var amount: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var hitstun: float = 0.12
@export var hit_pause: float = 0.04
@export var allow_friendly_fire := false

var source: Node = null
var hit_position: Vector2 = Vector2.ZERO

func duplicate_for_hit(hit_source: Node, position: Vector2) -> DamageData:
	var copy := duplicate(true) as DamageData
	copy.source = hit_source
	copy.hit_position = position
	return copy
