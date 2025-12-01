extends Node

# Variables for starting, spared, and aborbed colors
var starting_archetype: String = "" # Red/ BLUE / YELLOW / Null
var absorbed: Dictionary = { "Red": false, "Blue": false, "Yellow": false }
var spared: Dictionary = { "Red": false, "Blue": false, "Yellow": false }
var true_color_unlocked: bool = false

signal palette_changed(new_color: Color)
signal boss_absorbed(Color: string)
signal boss_spared(Color:String)


func _ready():
	starting_archetype = ThreadType.RED
	absorbed ["Blue"] = true
	absorbed ["Yellow"] = true
	print("Current Palette", get_current_palette())

# Critical functions:
func get_current_palette() -> Color:
# Start with base color muted grey
	var base: Color = Color(.3,.3,.3)

# Check starting archetpye color and apply it 
	if starting_archetype == ThreadType.RED: base = Color(.5,.2,.2)
	if starting_archetype == ThreadType.BLUE: base = Color(.2,.2,.5)
	if starting_archetype == ThreadType.YELLOW: base = Color(.5,.5,.2)

# Add .5 of a color if/when boss is absorbed
	if absorbed["Red"]:
		base.r += 0.5
	if absorbed["Blue"]:
		base.g += 0.5
	if absorbed["Yellow"]:
		base.b += 0.5
		
# Step 4: Count how many bosses were spared
	var spared_count: int = 0
	if spared ["Yellow"]: spared_count += 1
	if spared ["Red"]: spared_count += 1
	if spared ["Blue"]: spared_count += 1
	
	# Step 5: Mercy desaturation (0 to 3 spares → 0.0 to 0.75 push toward white)
	var mercy_level: float = spared_count * .25
	base = base.lerp(Color.WHITE, mercy_level)
	# Step 6: Clamp everything to 0–1 (for now — overflow comes later)
	base.r = clamp(base.r, 0.0,1.0)
	base.g = clamp(base.g, 0.0,1.0)
	base.b = clamp(base.b, 0.0,1.0)
	
	return base
	
func absorb(color: String) -> void
	ThreadType.is_valid(color):
		push_error("Invalid color: " + color)
		return
			
	if absorbed[color]:
		 return
		
	aborbered[color]== true
		
	if color == starting_archetype and starting_archetype != "":
	
func spare(color: String) -> void:
	
	
#func is_colorless_run() -> bool:
pass
#func has_any_color() -> bool:
pass
#func get_dominant_channel() -> String: 
pass  # returns the highest R/G/B channel name, or "None"
#func get_ending_category() -> String:
pass    # rough bucket: "True", "Hybrid", "Mercy", "Devourer", "Mixed", etc.
