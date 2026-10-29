extends "res://tests/capture_3d_feel.gd"
## Source-only comparison against the preserved pre-edit library asset.
func run() -> void:
	world=load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(world)
	actor=world.actor
	for e in get_nodes_in_group("study_enemies"): e.ai_enabled=false
	await frames(35)
	actor.set_physics_process(false);actor.set_process(false)
	actor.global_position=Vector3(0,0,17);actor.visual.rotation.y=0
	world.hud_layer.visible=false
	actor.camera.reparent(world,true);actor.camera.top_level=true;actor.camera.fov=42
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	var reference:=ProjectSettings.globalize_path("res://../source/Threadborne_Pre3D_Reference.glb")
	if document.append_from_file(reference,state)!=OK:
		push_error("Preserved library reference could not be read")
		world.shutdown();return
	var original:=document.generate_scene(state)
	var player: AnimationPlayer=original.find_children("*","AnimationPlayer",true,false)[0]
	actor.animation.get_animation_library("").add_animation("library_reference",player.get_animation("run_1"))
	original.free()
	DirAccess.make_dir_recursive_absolute("res://captures/feel")
	for view in ["front","side"]:
		actor.camera.global_position=actor.global_position+(Vector3(0,1.05,3.7) if view=="front" else Vector3(3.7,1.05,0))
		actor.camera.look_at(actor.global_position+Vector3.UP*.95)
		for variant in [["original","library_reference"],["narrow","run_1"]]:
			actor.animation.play(variant[1]);actor.animation.pause()
			for i in range(12):
				actor.animation.seek(i/12.0*actor.animation.current_animation_length,true)
				actor.animation.advance(0)
				await process_frame
				await save("compare_"+view+"_"+variant[0]+"_"+str(i))
	world.shutdown()
