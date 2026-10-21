extends SceneTree
var host: SubViewport
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    host = SubViewport.new()
    host.size = Vector2i(2, 2)
    host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(host)
    var stage = load("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_art_stage_2d.tscn").instantiate()
    host.add_child(stage)
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    stage.world_stage.add_child(mesh)
    print("REPRO_PREVIEW_SIZE ", stage.far_view.size)
    for index in 3:
        await RenderingServer.frame_post_draw
    print("REPRO_FINISHED")
    host.queue_free()
    await process_frame
    quit()
