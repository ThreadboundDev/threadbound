## EquipManager (Autoload singleton)
## Central data for all 9 equips + tuning

extends Node

# Equip enum (for easy indexing)
enum EquipSlot { GLOVES = 0, BOOTS = 1, CHEST_HEAD = 2 }

# Thread color enum — renamed so it doesn't clash with built-in Color
enum ThreadColor { RED = 0, BLUE = 1, YELLOW = 2 }

# Current equipped (0-8: gloves-red=0, gloves-blue=1, ..., chest-yellow=8)
var current_equip: Array[int] = [0, 0, 0]  # [gloves, boots, chest] indices

# Equip data: cooldowns, names, colors (tune here!)
var equip_data: Dictionary = {
	# Gloves (0-2)
	0: { "name": "Red Grapple", "thread_color": ThreadColor.RED, "cooldown": 1.2 },
	1: { "name": "Blue Swing",   "thread_color": ThreadColor.BLUE, "cooldown": 0.8 },
	2: { "name": "Yellow Manifest", "thread_color": ThreadColor.YELLOW, "cooldown": 1.0 },
	# Boots (3-5)
	3: { "name": "Red Stomp",    "thread_color": ThreadColor.RED, "cooldown": 1.5 },
	4: { "name": "Blue Drift",   "thread_color": ThreadColor.BLUE, "cooldown": 0.6 },
	5: { "name": "Yellow Foothold", "thread_color": ThreadColor.YELLOW, "cooldown": 0.9 },
	# Chest/Head (6-8)
	6: { "name": "Red Rage",     "thread_color": ThreadColor.RED, "cooldown": 3.0 },
	7: { "name": "Blue Harmony", "thread_color": ThreadColor.BLUE, "cooldown": 2.5 },
	8: { "name": "Yellow Clone", "thread_color": ThreadColor.YELLOW, "cooldown": 2.0 }
}

# Color constants (for highlights, particles, etc.)
const THREAD_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.2),     # Red (slightly desaturated)
	Color(0.3, 0.6, 1.0),     # Blue
	Color(1.0, 0.9, 0.3)      # Yellow
]

# Get equip index from slot + thread color (e.g. gloves + red = 0)
static func get_equip_index(slot: EquipSlot, thread_color: ThreadColor) -> int:
	return int(slot) * 3 + int(thread_color)

# Get thread color value for a given equip index
static func get_thread_color(equip_index: int) -> Color:
	var thread_color_idx = equip_index % 3
	return THREAD_COLORS[thread_color_idx]

# Signal when any equip changes
signal equip_changed(slot: EquipSlot, new_equip_index: int)


func _ready() -> void:
	print("EquipManager loaded")
	print("Gloves + Red index: ", get_equip_index(EquipSlot.GLOVES, ThreadColor.RED))  # Should print 0
	print("Boots + Blue index: ", get_equip_index(EquipSlot.BOOTS, ThreadColor.BLUE))    # Should print 4
