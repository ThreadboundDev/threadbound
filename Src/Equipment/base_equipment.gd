class_name BaseEquipment
extends Node

var player: CharacterBody2D
var slot_name: String = "None"

# ActionState enum lives here now
enum ActionState {
	PRESSED,
	RELEASED,
	HOLDING
}

func _init(_player: CharacterBody2D = null):
	player = _player

func on_equipped() -> void: pass
func on_unequipped() -> void: pass

func handle_primary(_delta: float, _state: ActionState) -> void: pass
func handle_secondary(_delta: float, _state: ActionState) -> void: pass

func thread_mechanic(_delta: float) -> void: pass
func process_passive(_delta: float) -> void: pass
