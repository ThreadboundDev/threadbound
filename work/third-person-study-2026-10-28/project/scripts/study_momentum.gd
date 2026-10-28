extends RefCounted
## Port of the live player's base Momentum/Flow rules, with metres replacing pixels.
const GAINS := {"movement": 0.24, "jump": 1.7, "dash": 7.5, "grapple": 8.0, "attack": 3.2, "pogo": 6.5, "utility": 2.4, "swap": 1.5, "use_after_swap": 7.0}
const MULTIPLIERS := {
	"ap": [0.9, 1.0, 1.24, 1.32], "move": [0.92, 1.0, 1.14, 1.2],
	"jump": [0.94, 1.0, 1.09, 1.12], "air": [0.9, 1.0, 1.16, 1.22],
	"grapple_speed": [0.94, 1.0, 1.16, 1.22], "grapple_pull": [0.92, 1.0, 1.16, 1.24],
	"attack_speed": [0.94, 1.0, 1.10, 1.15], "damage": [1.0, 1.0, 1.05, 1.10],
	"dash": [0.95, 1.0, 1.14, 1.18], "iframe": [0.9, 1.0, 1.15, 1.3]}
var amount := 0.0
var flow := false
var flow_time := 0.0
var stale := {}
var recent: Array[String] = []
var pending_swap := 0.0
var movement_clock := 0.16
var movement_distance := 0.0

func reset() -> void:
	amount = 0
	flow = false
	flow_time = 0
	stale.clear()
	recent.clear()
	pending_swap = 0
	movement_distance = 0
	movement_clock = 0.16

func change(value: float) -> void:
	amount = clampf(amount+value, 0, 100)
	if amount >= 100 and not flow:
		flow = true
		flow_time = 0
	if amount <= 0: flow = false

func multiplier(key: String) -> float:
	var values: Array = MULTIPLIERS[key]
	if flow: return values[3]
	if key in ["attack_speed", "damage"] and amount >= 70: return values[2]
	if amount <= 30: return lerpf(values[0], values[1], amount/30.0)
	if amount < 70: return values[1]
	return lerpf(values[1], values[2], (amount-70)/30.0)

func report(category: String, strength := 1.0) -> void:
	if not GAINS.has(category) or strength <= 0: return
	var movement := category == "movement"
	var span := 5.0 if movement else 7.0
	var staleness: float = stale.get(category, 0.0)
	var curve := 1.05 if amount < 30 else (1.0 if amount < 70 else (lerpf(0.58, 0.22, (amount-70)/30) if amount < 100 else 0.15))
	var distinct := {}
	if not recent.is_empty() and recent.back() != category:
		for item in recent:
			if item != category: distinct[item] = true
	var weave := 1.0 if movement else 1.0+minf(0.6, distinct.size()*0.16)
	change(GAINS[category]*strength*maxf(0, 1-staleness/span)*curve*weave - (1.35 if not movement and staleness >= span else 0))
	for item in stale:
		if item != category: stale[item] = maxf(0, stale[item]-(5.0 if item == "movement" else 7.0)*0.25)
	stale[category] = minf(span, staleness+0.16) if movement else span
	recent.append(category)
	while recent.size() > 4: recent.pop_front()
	if category == "swap": pending_swap = 2.5
	elif pending_swap > 0 and category not in ["movement", "use_after_swap"]:
		pending_swap = 0
		report("use_after_swap")

func tick(delta: float, distance: float, moving: bool) -> void:
	pending_swap = maxf(0, pending_swap-delta)
	movement_distance += distance if moving else 0.0
	movement_clock -= delta
	if movement_clock <= 0:
		var speed := movement_distance/0.16
		if speed >= 1.5: report("movement", clampf(speed/8.667, 0.15, 1.6))
		movement_clock = 0.16
		movement_distance = 0
	if flow:
		flow_time += delta
		if flow_time >= 1.35: change(-minf(3.0+(flow_time-1.35)*0.72, 13.0)*delta)
