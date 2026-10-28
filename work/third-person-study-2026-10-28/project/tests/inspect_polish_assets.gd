extends SceneTree
func _initialize() -> void:
	for path in ["res://assets/enemies/woven_swordsman.glb","res://assets/enemies/woven_pikewarden.glb","res://assets/local_licensed/armored_golem.glb"]:
		var model = load(path).instantiate()
		root.add_child(model)
		var player: AnimationPlayer = model.find_children("*","AnimationPlayer",true,false)[0]
		print(path)
		for clip in player.get_animation_list(): print(clip," ",player.get_animation(clip).length)
		model.free()
	quit()
