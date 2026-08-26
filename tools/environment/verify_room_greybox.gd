extends Node

const BLOCK := preload("res://Src/Environment/Greybox/greybox_block.tscn")
const WATER := preload("res://Src/Environment/Greybox/greybox_water.tscn")
const HAZARD := preload("res://Src/Environment/Greybox/greybox_hazard.tscn")
const TILE_LAYER := preload("res://Src/Environment/Greybox/greybox_tile_layer.tscn")
const ROOM := preload("res://Src/Environment/BlueBiome/Prototypes/blue_village_room_01.tscn")


func _ready() -> void:
	var block := BLOCK.instantiate() as GreyboxBlock2D
	add_child(block)
	block.position = Vector2(-1000, 0)
	block.size = Vector2(384, 64)
	assert((block.get_node("CollisionShape2D").shape as RectangleShape2D).size == Vector2(384, 64))
	assert(block.block_color.get_luminance() < 0.3, "Large greybox blocks should be dark grey.")

	var tile_layer := TILE_LAYER.instantiate() as TileMapLayer
	add_child(tile_layer)
	assert(tile_layer.tile_set != null)
	assert(tile_layer.tile_set.tile_size == Vector2i(128, 128))
	var source := tile_layer.tile_set.get_source(0) as TileSetAtlasSource
	assert(source != null)
	assert(source.has_tile(Vector2i(0, 0)), "Solid terrain tile is missing.")
	assert(source.has_tile(Vector2i(1, 0)), "One-way terrain tile is missing.")
	var one_way_data := source.get_tile_data(Vector2i(1, 0), 0)
	assert(tile_layer.tile_set.get_physics_layers_count() == 3)
	assert(tile_layer.tile_set.get_physics_layer_collision_layer(1) == 8)
	assert(tile_layer.tile_set.get_physics_layer_collision_layer(2) == 4)
	assert(one_way_data.is_collision_polygon_one_way(0, 0), "One-way tile collision is not configured.")
	var one_way_points := one_way_data.get_collision_polygon_points(0, 0)
	assert(one_way_points.has(Vector2(-64, -64)))
	assert(one_way_points.has(Vector2(64, 64)), "One-way collision must fill the entire tile.")
	tile_layer.set_cell(Vector2i.ZERO, 0, Vector2i(1, 0), 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var tile_center := tile_layer.map_to_local(Vector2i.ZERO)
	var side_query := PhysicsRayQueryParameters2D.create(tile_center + Vector2(-96, 0), tile_center + Vector2(96, 0), 4)
	assert(not tile_layer.get_world_2d().direct_space_state.intersect_ray(side_query).is_empty(), "Grapple must hit a one-way tile from its side.")
	var below_query := PhysicsRayQueryParameters2D.create(tile_center + Vector2(0, 96), tile_center + Vector2(0, -96), 4)
	assert(not tile_layer.get_world_2d().direct_space_state.intersect_ray(below_query).is_empty(), "Grapple must hit a one-way tile from below.")
	assert(one_way_data.get_collision_polygons_count(0) == 1, "One-way tiles must not add solid seam polygons.")

	var water := WATER.instantiate() as GreyboxWater2D
	add_child(water)
	water.size = Vector2(640, 320)
	water.position = Vector2(100, 500)
	water.scale = Vector2(3, 2)
	assert((water.get_node("CollisionShape2D").shape as RectangleShape2D).size == Vector2(640, 320))
	assert(is_equal_approx(water.get_surface_global_y(), 180.0), "Scaled water surface is incorrect.")
	assert(water.z_index < tile_layer.z_index)
	assert(water.water_color.a == 1.0)

	var hazard := HAZARD.instantiate() as GreyboxHazard2D
	add_child(hazard)
	hazard.position = Vector2(13.5, 27.25)
	assert(hazard.position == Vector2(13.5, 27.25), "Hazards must support free placement.")
	var pogo_receiver := hazard.get_node_or_null("PogoReceiver") as HurtboxComponent
	assert(pogo_receiver != null, "Red hazards must expose a pogo attack receiver.")
	assert(pogo_receiver.hurtbox_owner == hazard)
	assert(pogo_receiver.collision_layer == 2)

	var room := ROOM.instantiate()
	add_child(room)
	var player := room.get_node("Player")
	assert(player.has_method("enter_prototype_water"))
	assert(room.get_node("Water") is GreyboxWater2D)
	assert(room.get_node("Hazards/PrototypeReeds") is GreyboxHazard2D)
	assert(room.get_node("Geometry/GreyboxTerrain") is TileMapLayer)
	var attack_hitbox := player.get_node("AttackHitbox") as HitboxComponent
	assert(player.get_collision_mask_value(1))
	assert(player.get_collision_mask_value(4))
	assert((int(player.current_gloves.get("grapple_collision_mask")) & 8) != 0)
	assert(player.call("_is_valid_ledge_wall_hit", {"normal": Vector2.LEFT}))
	assert(not player.call("_is_valid_ledge_wall_hit", {"normal": Vector2.UP}), "Platform centers must not count as climbable walls.")
	assert(player.call("_is_valid_ledge_top_hit", {"normal": Vector2.UP}))
	assert(not player.call("_is_valid_ledge_top_hit", {"normal": Vector2.LEFT}))
	player.set("_ledge_top", Vector2(200.0, 300.0))
	player.set("_ledge_direction", 1)
	player.call("_start_ledge_climb", false)
	var climb_target: Vector2 = player.get("_ledge_climb_target")
	var collision_bottom := float(player.call("_get_player_collision_bottom_offset"))
	assert(
		climb_target.y + collision_bottom < 300.0,
		"Ledge climb target must place the entire player above the platform surface."
	)
	player.set("is_ledge_climbing", false)
	var before_drop_y: float = (player as Node2D).global_position.y
	player.call("_begin_one_way_drop")
	assert(not player.get_collision_mask_value(1), "Drop-through must briefly ignore terrain collision.")
	assert(player.global_position.y > before_drop_y)
	player.call("_process_one_way_drop_input", player.one_way_drop_ignore_duration + 0.01)
	assert(player.get_collision_mask_value(1), "Terrain collision must restore after dropping.")
	player.set("current_action_points", 4)
	player.set("air_jump_available", false)
	player.set("current_attack_uses_air_double", true)
	player.set("is_attacking", true)
	player.set("attack_direction", Vector2.DOWN)
	attack_hitbox.enable()
	attack_hitbox.call("_on_area_entered", pogo_receiver)
	assert(
		is_equal_approx(player.velocity.y, -player.pogo_rebound_speed),
		"A downward hit on a red hazard must apply the full pogo rebound."
	)
	assert(player.pogo_rebound_gravity_timer > 0.0, "Pogo must start its gravity grace window.")
	assert(player.get("current_action_points") == 4, "Pogo must not change AP.")
	assert(not player.get("air_jump_available"), "Pogo must not restore the air jump.")
	assert(not player.get("current_attack_uses_air_double"))
	player.call("enter_prototype_water", water, 100.0)
	assert(player.call("is_in_prototype_water"))
	player.global_position.y = 100.0 + player.prototype_swim_surface_depth
	assert(player.call("_is_at_prototype_water_surface"))
	player.velocity.y = -player.prototype_swim_exit_jump_speed
	player.set("_prototype_swim_exit_lock_timer", player.prototype_swim_exit_lock_duration)
	player.call("_process_prototype_swim_vertical", 1.0 / 60.0)
	assert(
		is_equal_approx(player.velocity.y, -player.prototype_swim_exit_jump_speed),
		"Water exit lock must preserve the committed jump launch."
	)
	player.set("is_attacking", false)
	player.set("is_hurt", false)
	player.set("pogo_rebound_animation_timer", 0.0)
	player.set("current_attack_uses_grapple_strike", false)
	player.call("update_animations", 1.0)
	assert(player.current_body_anim == "Swim", "Moving in water should use the swim animation.")
	player.call("update_animations", 0.0)
	assert(player.current_body_anim == "Jump_Apex", "Floating in water should use Jump_Apex.")
	player.call("exit_prototype_water", water)
	assert(not player.call("is_in_prototype_water"))
	print("ROOM_GREYBOX_VERIFY_OK")
	room.queue_free()
	block.queue_free()
	water.queue_free()
	hazard.queue_free()
	tile_layer.queue_free()
	await get_tree().process_frame
	get_tree().quit()
