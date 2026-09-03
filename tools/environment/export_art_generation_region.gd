extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Usage: godot --headless --script export_art_generation_region.gd -- <scene.tscn> [output.json]")
		quit(1)
		return
	var scene_path := args[0]
	var output_path := args[1] if args.size() > 1 else "res://ArtSource/BlueBiome/generation_regions.json"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % scene_path)
		quit(1)
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	var regions: Array[Dictionary] = []
	_collect_regions(root, regions)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write: %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify({"scene": scene_path, "regions": regions}, "  ", false))
	print("Exported %d art generation region(s) to %s" % [regions.size(), output_path])
	root.queue_free()
	quit()


func _collect_regions(node: Node, output: Array[Dictionary]) -> void:
	if node is ArtGenerationRegion2D:
		output.append((node as ArtGenerationRegion2D).get_generation_spec())
	for child in node.get_children():
		_collect_regions(child, output)
