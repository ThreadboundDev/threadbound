@tool
extends McpTestSuite

func suite_name() -> String:
	return "greybox_editor"

func test_reload_dock_and_wall_button() -> void:
	ResourceLoader.load("res://addons/room_greybox/room_greybox_dock.tscn", "", ResourceLoader.CACHE_MODE_REPLACE)
	EditorInterface.set_plugin_enabled("room_greybox", false)
	EditorInterface.set_plugin_enabled("room_greybox", true)
	assert_true(EditorInterface.is_plugin_enabled("room_greybox"), "Greybox plugin stays enabled")
	var found := false
	for dock in EditorInterface.get_base_control().find_children("RoomGreyboxDock", "Control", true, false):
		if dock.is_queued_for_deletion():
			continue
		var button := dock.get_node_or_null("%BreakableWall") as Button
		if button:
			found = button.pressed.get_connections().size() > 0
	assert_true(found, "The live dock exposes a connected Breakable Wall button")
