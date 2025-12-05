extends Node

var starting_archetype: String = ""
var absorbed: Dictionary = {
	ThreadType.RED: false,
	ThreadType.BLUE: false,
	ThreadType.YELLOW: false
}
var spared: Dictionary = {
	ThreadType.RED: false,
	ThreadType.BLUE: false,
	ThreadType.YELLOW: false
}

const BASE_GRAY: float = 0.2
const CHOICE_BOOST: float = 0.4
const ABSORB_BOOST: float = 0.4
const SPARE_PENALTY: float = 0.2

signal palette_changed(new_color: Color)
signal boss_absorbed(color: String)
signal boss_spared(color: String)

func _ready():
	starting_archetype = ThreadType.RED
	absorb(ThreadType.RED)
	spare(ThreadType.BLUE)
	spare(ThreadType.YELLOW)
	print("TRUE RED FINAL COLOR:", get_current_palette())  # Should be (1, 0, 0, 1)

func get_current_palette() -> Color:
	var r: float = BASE_GRAY
	var g: float = BASE_GRAY
	var b: float = BASE_GRAY

	if starting_archetype == ThreadType.RED:
		r += CHOICE_BOOST
	if starting_archetype == ThreadType.BLUE:
		g += CHOICE_BOOST
	if starting_archetype == ThreadType.YELLOW:
		b += CHOICE_BOOST

	if absorbed[ThreadType.RED]:    r += ABSORB_BOOST
	if absorbed[ThreadType.BLUE]:   g += ABSORB_BOOST
	if absorbed[ThreadType.YELLOW]: b += ABSORB_BOOST

	if spared[ThreadType.RED]:    r -= SPARE_PENALTY
	if spared[ThreadType.BLUE]:   g -= SPARE_PENALTY
	if spared[ThreadType.YELLOW]: b -= SPARE_PENALTY

	return Color(r, g, b)

func absorb(color: String) -> void:
	if not ThreadType.is_valid(color):
		push_error("Invalid absorb color: " + color)
		return
	if absorbed[color]:
		return
	absorbed[color] = true
	palette_changed.emit(get_current_palette())
	boss_absorbed.emit(color)

func spare(color: String) -> void:
	if not ThreadType.is_valid(color):
		push_error("Invalid spare color: " + color)
		return
	if spared[color]:
		return
	spared[color] = true
	palette_changed.emit(get_current_palette())
	boss_spared.emit(color)
