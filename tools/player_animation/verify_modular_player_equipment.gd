extends SceneTree
## Real player, shared skins, atomic outfit replacement, anchors and swap hooks.
const OUT := "res://ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func snapshot(visual, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	visual._viewport.get_texture().get_image().save_png(OUT+"/"+name+".png")

func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	await frames(5)
	player.set_physics_process(false)
	player.set_process(false)
	var visual = player.get_node("Live3DVisual")
	visual.set_process(false)
	var equipment = visual.equipment_visuals
	check(equipment != null, "Default player selects modular equipment when local assets exist")
	if not equipment:
		quit(1)
		return
	check(equipment.equipped.size() == 4, "Three clothing slots plus separate weapon")
	check(visual._skeleton.get_bone_count() == 62, "62 original bones retained")
	check(visual._animation_player.get_animation_list().size() >= 48, "Original animation library retained")
	check(equipment.find_children("*", "Skeleton3D", true, false).is_empty(), "Gear has no duplicate skeletons")
	check(equipment.find_children("*", "AnimationPlayer", true, false).is_empty(), "Gear has no duplicate animation clocks")
	var mesh_count := 0
	for node in equipment.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh_count += 1
		check(mesh.get_node(mesh.skeleton) == visual._skeleton, "Shared skeleton: "+mesh.name)
		check(mesh.skin != null and mesh.skin.get_bind_count() > 0, "Skin present: "+mesh.name)
		for index in mesh.skin.get_bind_count():
			check(visual._skeleton.find_bone(mesh.skin.get_bind_name(index)) >= 0, "Valid named binding: "+mesh.name+" "+str(index))
	check(mesh_count == 16, "All clothing, paired boots/bracers, weapons and grapple hardware installed")
	var outfit := equipment.equipped[&"head_chest"] as EquipmentVisualDefinition
	check(outfit.model_paths.size() == 3, "Cowl/tunic/pants form one outfit definition")
	check(equipment._roots[&"head_chest"].find_children("*", "MeshInstance3D", true, false).size() == 3, "One outfit root contains three meshes")
	var boots_root: Node = equipment._roots[&"boots"]
	var gloves_root: Node = equipment._roots[&"gloves"]
	var weapon_root: Node = equipment._roots[&"weapon"]
	var old_outfit_root: Node = equipment._roots[&"head_chest"]
	var replacement := outfit.duplicate() as EquipmentVisualDefinition
	replacement.item_id = &"outfit_swap_test"
	check(equipment.equip(replacement), "Complete outfit swaps in one call")
	check(old_outfit_root.get_parent() == null and not old_outfit_root.visible, "Old cowl/tunic/pants removed together")
	check(equipment._roots[&"boots"] == boots_root and equipment._roots[&"gloves"] == gloves_root and equipment._roots[&"weapon"] == weapon_root, "Outfit swap preserves other slots")
	var invalid := outfit.duplicate() as EquipmentVisualDefinition
	invalid.model_paths = PackedStringArray([outfit.model_paths[0], "res://missing_equipment.glb"])
	var good_root: Node = equipment._roots[&"head_chest"]
	check(not equipment.equip(invalid), "Missing outfit component rejects whole swap")
	check(equipment._roots[&"head_chest"] == good_root, "Rejected swap preserves complete old outfit")
	var invalid_root := Node3D.new()
	var unskinned := MeshInstance3D.new()
	unskinned.mesh = BoxMesh.new()
	invalid_root.add_child(unskinned)
	unskinned.owner = invalid_root
	var invalid_scene := PackedScene.new()
	invalid_scene.pack(invalid_root)
	ResourceSaver.save(invalid_scene, "res://tmp/modular-equipment-unskinned.tscn")
	invalid_root.free()
	invalid.model_paths = PackedStringArray([outfit.model_paths[0], "res://tmp/modular-equipment-unskinned.tscn"])
	check(not equipment.equip(invalid), "Unskinned component rejects a partially prepared outfit")
	check(equipment._roots[&"head_chest"] == good_root, "Binding failure preserves complete old outfit")
	check(equipment.equip(outfit), "Base outfit restored")
	var weapon := equipment.equipped[&"weapon"] as EquipmentVisualDefinition
	var gameplay_before: Array = root.get_node("EquipManager").current_equip.duplicate()
	equipment.clear_slot(&"weapon")
	check(equipment.get_blade_points().is_empty() and visual._sword_mesh == null, "Removing weapon clears blade/VFX reference")
	check(equipment.equip(weapon), "Separate sword/shield weapon item can be restored")
	check(root.get_node("EquipManager").current_equip == gameplay_before, "Weapon visual swap does not alter three ability selections")
	var variant := (equipment.equipped[&"gloves"] as EquipmentVisualDefinition).duplicate() as EquipmentVisualDefinition
	variant.item_id = &"glove_variant_test"
	check(equipment.register_variant(&"gloves", 3, variant), "Future authored glove variants register against existing selection")
	root.get_node("EquipManager").equip_changed.emit(0, 3)
	check(equipment.equipped[&"gloves"] == variant, "Existing equipment signal swaps registered visual")
	root.get_node("EquipManager").equip_changed.emit(0, 0)
	check(equipment.equipped[&"gloves"].item_id == &"base_bracers", "Existing base selection restores base bracers")
	check(not equipment.register_variant(&"boots", 3, variant), "Wrong-slot visual definition is rejected")
	check(not equipment.register_variant(&"gloves", 4, variant), "Wrong gameplay slot index is rejected")
	var boot_item := equipment.equipped[&"boots"] as EquipmentVisualDefinition
	var covered_boots := visual._model_root.find_child("Doll_Covered_Boots", true, false) as MeshInstance3D
	check(not covered_boots.visible, "Closed boots hide covered bare feet and toes")
	equipment.clear_slot(&"boots")
	check(covered_boots.visible, "Removing boots restores the original body shell")
	check(equipment.equip(boot_item) and not covered_boots.visible, "Replacing boots restores their coverage mask")
	var actions := ["idle_4","run_1","slash_2","block_idle_1","jump_1","swimming_1","air_attack_up","air_attack_down","casting_2","roll_1"]
	for action in actions:
		visual._play_action(StringName(action), &"", 0.0, true, 1.0, 0.0)
		var clip: StringName = visual._animation_player.current_animation
		for fraction in [0.0, .25, .5, .75]:
			visual._animation_player.seek(visual._animation_player.get_animation(clip).length*fraction, true)
			visual._animation_player.advance(0)
			var blade: PackedVector3Array = visual._get_blade_model_points()
			check(blade.size()==2 and blade[0].is_finite() and blade[1].is_finite(), "Finite new blade endpoints: "+action+str(fraction))
			check(absf(blade[0].distance_to(blade[1])-.63)<.001, "Rigid blade length: "+action+str(fraction))
			var origin: Vector3 = equipment.get_grapple_origin()
			check(origin.is_finite() and origin.length()<4, "Bounded shield-arm grapple origin: "+action+str(fraction))
			check(visual.get_grapple_origin_player_offset().is_finite(), "Projected grapple origin: "+action+str(fraction))
		visual._animation_player.pause()
		await snapshot(visual, "game_"+action)
	# Inspect the actual exported rest frame independently of animation poses.
	visual._skeleton.reset_bone_poses()
	var rest_blade: PackedVector3Array = equipment.get_blade_points()
	check(rest_blade[0].distance_to(Vector3(-.790,1.491,.105))<.002, "Blade base matches measured rest geometry")
	check(rest_blade[1].distance_to(Vector3(-.790,1.491,.735))<.002, "Blade tip matches measured rest geometry")
	check(equipment.get_grapple_origin().distance_to(Vector3(.708,1.519,.108))<.002, "Grapple exits the actual left bracer needle")
	var gloves = player.current_gloves
	check(gloves != null, "Actual gameplay gloves are attached")
	if gloves:
		var expected_origin: Vector2 = player.to_global(visual.get_grapple_origin_player_offset())
		gloves._start_grapple_fire()
		check(gloves.grapple_start_position.distance_to(expected_origin)<.01, "Actual fired grapple starts at the bracer needle")
		check(gloves.grapple_state == gloves.GrappleState.FIRING, "Existing grapple launch behavior is retained")
		visual._process(0.0)
		check(not equipment.find_child("Grapple_Needle_Tip",true,false).visible, "Stowed needle hides while the active grapple is launched")
		gloves._reset_active_grapple_visuals()
		visual._process(0.0)
		check(equipment.find_child("Grapple_Needle_Tip",true,false).visible, "Stowed needle returns after the grapple resets")
	visual._play_action(&"idle_4", &"", 0, true, 1, 0)
	visual._animation_player.seek(.2, true)
	visual._animation_player.advance(0)
	visual._animation_player.pause()
	visual._camera.size = 2.35
	visual._camera.position = Vector3(0,1.05,4)
	visual._camera.look_at(Vector3(0,1.05,0),Vector3.UP)
	await snapshot(visual, "front_review")
	visual._camera.position = Vector3(3,1.7,3)
	visual._camera.look_at(Vector3(0,1.05,0),Vector3.UP)
	await snapshot(visual, "three_quarter_review")
	visual._camera.size=.65
	var arm: Vector3 = equipment.get_grapple_origin()
	visual._camera.position=arm+Vector3(-.7,.3,-1)
	visual._camera.look_at(arm,Vector3.UP)
	await snapshot(visual, "bracer_review")
	var report := {"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"mesh_count":mesh_count,"sampled_poses":actions.size()*4}
	FileAccess.open(OUT+"/godot_"+DisplayServer.get_name()+"_report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MODULAR_EQUIPMENT_CHECKS ",JSON.stringify(report))
	stage.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
