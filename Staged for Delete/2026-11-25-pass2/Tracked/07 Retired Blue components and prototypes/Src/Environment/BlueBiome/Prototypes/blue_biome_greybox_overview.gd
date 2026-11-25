@tool
extends Node2D


func _ready() -> void:
	for room in $Rooms.get_children():
		var duplicate_reference := room.get_node_or_null("MacroReference") as CanvasItem
		if duplicate_reference:
			duplicate_reference.visible = false
		var player := room.get_node_or_null("Player") as CanvasItem
		if player:
			player.visible = false
	if not Engine.is_editor_hint():
		push_warning("BlueBiomeGreyboxOverview is an editor planning scene, not a runtime level.")
