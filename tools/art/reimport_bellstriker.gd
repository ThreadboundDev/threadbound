extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for i in range(20):
		await process_frame
	var filesystem := EditorInterface.get_resource_filesystem()
	while filesystem.is_scanning():
		await process_frame
	filesystem.reimport_files(PackedStringArray(["res://Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v2.glb"]))
	print("BELL_REIMPORT_OK")
	quit()
