extends SceneTree
func _initialize():
    for key in ["NetMender", "Boatwright"]:
        var node = load("res://Assets/BlueBiome/Villagers/Models/" + key + ".glb").instantiate()
        for mesh in node.find_children("*", "MeshInstance3D", true, false):
            for i in mesh.mesh.get_surface_count():
                var mat = mesh.mesh.surface_get_material(i)
                print(key, " ", i, " ", mat.resource_name, " ", mat.albedo_color, " vertex=", mat.vertex_color_use_as_albedo, " srgb=", mat.vertex_color_is_srgb)
        node.free()
    quit()
