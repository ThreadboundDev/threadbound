@tool
extends "res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_model_2d.gd"
## Opt-in, same-room house entry. Other placements retain automatic cutaways.
const BOUNDARY_LAYER := 1 << 31
const HOUSE_META := &"lakeside_house_interior"
const FOCUS := preload("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_focus.gd")
const DOOR_VISUAL := preload("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door_visual.gd")
const DOOR_DURATION := 0.72
@export var use_door_entry := false
@export var floor_shape_path: NodePath
@export var house_collision_paths: Array[NodePath] = []
@export var outdoor_terrain_paths: Array[NodePath] = []

var inside_player: CharacterBody2D
var floor_shape: CollisionPolygon2D
var boundary_body: StaticBody2D
var _bodies: Array[PhysicsBody2D] = []
var _players: Array[CharacterBody2D] = []
var _owned_exceptions: Dictionary = {}
var _terrain_exceptions: Array[PhysicsBody2D] = []
var _boundary_was_enabled := false
var _return_position := Vector2.ZERO
var _transition_locked := false
var _cooldown := 0.0
var _configured_model := 0
var _occupied := false
var _transition_generation := 0
var _transition_player: CharacterBody2D
var interior_focus: Node
var door_visual: Node2D

func _ready() -> void:
	super._ready()
	$Door.visible = use_door_entry
	$Door.monitoring = use_door_entry and not Engine.is_editor_hint()
	if Engine.is_editor_hint() or not use_door_entry:
		return
	add_to_group("lakeside_door_houses")
	floor_shape = get_node(floor_shape_path) as CollisionPolygon2D
	for path: NodePath in house_collision_paths:
		var body := get_node(path) as PhysicsBody2D
		if body not in _bodies:
			_bodies.append(body)
	_build_boundaries()
	interior_focus = FOCUS.new()
	interior_focus.name = "InteriorFocus"
	add_child(interior_focus)
	door_visual = DOOR_VISUAL.new()
	door_visual.name = "DoorPresentation"
	$Door.add_child(door_visual)
	_track_players()

func _update_entry() -> void:
	if not use_door_entry:
		super._update_entry()

func _update_cutaway() -> void:
	if not use_door_entry:
		super._update_cutaway()
	elif is_instance_valid(render_model):
		render_model.set_cutaway(preview_inside or is_instance_valid(inside_player))

func _process(delta: float) -> void:
	super._process(delta)
	if not use_door_entry or Engine.is_editor_hint():
		return
	if is_instance_valid(render_model) and _configured_model != render_model.get_instance_id():
		_configured_model = render_model.get_instance_id()
		render_model.set_facade_foreground(false)
		_update_cutaway()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not use_door_entry:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_track_players()
	if is_instance_valid(_transition_player) and (_transition_player.get("is_dead") == true or _transition_player.global_position.distance_to($Door.global_position) > 220.0):
		_cancel_door_transition()
		if is_instance_valid(inside_player):
			leave_house(false)
	if is_instance_valid(inside_player):
		if inside_player.get("is_dead") == true or not entry_rect.grow(96.0).has_point(to_local(inside_player.global_position)):
			leave_house(false)
	elif _occupied:
		# The player may have been freed without another physics tick.
		_terrain_exceptions.clear()
		inside_player = null
		_occupied = false
		_update_cutaway()

func _track_players() -> void:
	for candidate in get_tree().get_nodes_in_group("player"):
		if not candidate is CharacterBody2D or candidate in _players:
			continue
		var player := candidate as CharacterBody2D
		_players.append(player)
		player.tree_exiting.connect(_untrack_player.bind(player))
		var owned: Array[PhysicsBody2D] = []
		for body: PhysicsBody2D in _bodies:
			# Door gating applies to interior floors, not exterior roof landings.
			# Roof outlines are already one-way, so walking past the facade stays free.
			if String(body.name).contains("Roof"):
				continue
			if body not in player.get_collision_exceptions():
				player.add_collision_exception_with(body)
				owned.append(body)
		_owned_exceptions[player.get_instance_id()] = owned

func _untrack_player(player: CharacterBody2D) -> void:
	if _transition_player == player:
		_cancel_door_transition()
	if inside_player == player:
		leave_house(false)
	for body: PhysicsBody2D in _owned_exceptions.get(player.get_instance_id(), []):
		if is_instance_valid(body):
			player.remove_collision_exception_with(body)
	_owned_exceptions.erase(player.get_instance_id())
	_players.erase(player)

func _build_boundaries() -> void:
	# Layer 32 is unused by the project. Only an indoor player's body opts in;
	# enemy masks and the outdoor player never see these interior boundaries.
	boundary_body = StaticBody2D.new()
	boundary_body.name = "InteriorBounds"
	boundary_body.collision_layer = BOUNDARY_LAYER
	boundary_body.collision_mask = 0
	add_child(boundary_body)
	var bounds := floor_bounds()
	var top := entry_rect.position.y
	var floor_y := to_local(Vector2(bounds.get_center().x, bounds.position.y)).y
	var left := entry_rect.position.x
	var right := entry_rect.end.x
	_boundary("Floor", Vector2((left + right) * 0.5, floor_y + 6.0), Vector2(right - left + 24.0, 12.0))
	_boundary("Ceiling", Vector2((left + right) * 0.5, top - 6.0), Vector2(right - left + 24.0, 12.0))
	_boundary("LeftWall", Vector2(left - 6.0, (top + floor_y) * 0.5), Vector2(12.0, floor_y - top))
	_boundary("RightWall", Vector2(right + 6.0, (top + floor_y) * 0.5), Vector2(12.0, floor_y - top))

func _boundary(label: String, at: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.name = label
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = at
	boundary_body.add_child(shape)

func floor_bounds() -> Rect2:
	var bounds := Rect2(floor_shape.to_global(floor_shape.polygon[0]), Vector2.ZERO)
	for point: Vector2 in floor_shape.polygon:
		bounds = bounds.expand(floor_shape.to_global(point))
	return bounds

func foot_offset(player: CharacterBody2D) -> float:
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	return shape.to_global(Vector2(0.0, shape.shape.get_rect().end.y)).y - player.global_position.y

func inside_destination(player: CharacterBody2D) -> Vector2:
	var bounds := floor_bounds()
	var x := clampf($Door.global_position.x, bounds.position.x + 32.0, bounds.end.x - 32.0)
	return Vector2(x, bounds.position.y - foot_offset(player) - 2.0)

func outside_destination(player: CharacterBody2D) -> Vector2:
	var at: Vector2 = $Door.global_position
	var ignored: Array[RID] = [player.get_rid()]
	for body: PhysicsBody2D in _bodies:
		ignored.append(body.get_rid())
	var query := PhysicsRayQueryParameters2D.create(at - Vector2(0, 192), at + Vector2(0, 512), 1, ignored)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y < -0.4:
		return Vector2(at.x, hit.position.y - foot_offset(player) - 2.0)
	return at - Vector2(0, foot_offset(player))

func is_player_inside(player: Node2D) -> bool:
	return use_door_entry and is_instance_valid(inside_player) and player == inside_player

func interaction_exclusions(player: CharacterBody2D) -> Array[RID]:
	var ignored: Array[RID] = [player.get_rid()]
	if is_player_inside(player):
		for path: NodePath in outdoor_terrain_paths:
			ignored.append((get_node(path) as PhysicsBody2D).get_rid())
	return ignored

func can_use_door(player: CharacterBody2D) -> bool:
	if not use_door_entry or _transition_locked or _cooldown > 0.0 or player.get("is_dead") == true:
		return false
	if player.get("is_attacking") == true or player.get("is_hurt") == true or player.get("save_point_interaction_active") == true:
		return false
	if is_instance_valid(inside_player) and inside_player != player:
		return false
	if player.has_meta(HOUSE_META) and player.get_meta(HOUSE_META) != self:
		return false
	return player.is_on_floor() and $Door.get_overlapping_bodies().has(player)

func request_door(player: CharacterBody2D) -> void:
	if not can_use_door(player):
		return
	_transition_locked = true
	_transition_generation += 1
	_apply_door.call_deferred(player, _transition_generation)

func _apply_door(player: CharacterBody2D, generation: int) -> void:
	if generation != _transition_generation:
		return
	if not is_instance_valid(player) or not is_inside_tree() or player.get("is_dead") == true:
		_transition_locked = false
		return
	# Revalidate current position as an external teleport may precede this defer.
	var range_shape := $Door/Range as CollisionShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var door_bounds: Rect2 = range_shape.global_transform * range_shape.shape.get_rect()
	var player_bounds: Rect2 = player_shape.global_transform * player_shape.shape.get_rect()
	if not door_bounds.intersects(player_bounds):
		_transition_locked = false
		return
	if not player.begin_house_door_transition(self):
		_transition_locked = false
		return
	_transition_player = player
	var entering := not is_player_inside(player)
	var origin := player.global_position
	var visual: Node = player.get_node_or_null("Live3DVisual")
	if visual:
		visual.begin_house_door_transition(entering)
	var elapsed := 0.0
	var switched := false
	var expected := origin
	while elapsed < DOOR_DURATION:
		await get_tree().physics_frame
		if generation != _transition_generation or not is_instance_valid(player) or not is_inside_tree():
			return
		if player.global_position.distance_to(expected) > 96.0 or player.get("is_dead") == true:
			_cancel_door_transition()
			if is_player_inside(player):
				leave_house(false)
			return
		elapsed += get_physics_process_delta_time()
		var progress := minf(elapsed/DOOR_DURATION,1.0)
		if not switched:
			# A short approach to the center of this door, never to InsideSpawn.
			player.global_position.x = lerpf(origin.x,$Door.global_position.x,smoothstep(0.0,0.25,progress))
		if progress >= 0.61 and not switched:
			switched = true
			if entering:
				_enter_house(player)
			else:
				leave_house(true,true)
		door_visual.opening = smoothstep(0.08,0.40,progress)*(1.0-smoothstep(0.85,1.0,progress))
		door_visual.indoors = is_player_inside(player)
		door_visual.threshold = floor_bounds().position.y-$Door.global_position.y if door_visual.indoors else 0.0
		if visual:
			visual.set_house_door_progress(progress)
		expected = player.global_position
	player.end_house_door_transition(self)
	_transition_player = null
	door_visual.opening = 0.0
	_cooldown = 0.25
	_transition_locked = false

func _cancel_door_transition() -> void:
	_transition_generation += 1
	_transition_locked = false
	if is_instance_valid(_transition_player):
		_transition_player.end_house_door_transition(self)
	_transition_player = null
	if is_instance_valid(door_visual):
		door_visual.opening = 0.0

func _enter_house(player: CharacterBody2D) -> void:
	_return_position = player.global_position
	inside_player = player
	_occupied = true
	player.set_meta(HOUSE_META, self)
	_boundary_was_enabled = player.get_collision_mask_value(32)
	player.set_collision_mask_value(32, true)
	for body: PhysicsBody2D in _owned_exceptions.get(player.get_instance_id(), []):
		if is_instance_valid(body):
			player.remove_collision_exception_with(body)
	_terrain_exceptions.clear()
	for path: NodePath in outdoor_terrain_paths:
		var terrain := get_node(path) as PhysicsBody2D
		if terrain not in player.get_collision_exceptions():
			player.add_collision_exception_with(terrain)
			_terrain_exceptions.append(terrain)
	player.global_position = inside_destination(player)
	# Resolve the two-pixel placement clearance while the doorway hides the
	# player. Otherwise releasing the lock briefly enters an airborne pose before
	# gravity finds the floor, making the walk-to-idle handoff visibly jump.
	player.velocity = Vector2.DOWN * 3.0 / player.get_physics_process_delta_time()
	player.move_and_slide()
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	_update_cutaway()
	interior_focus.enter(player)
	door_visual.indoors = true
	door_visual.threshold = bounds_to_door_threshold()

func bounds_to_door_threshold() -> float:
	return floor_bounds().position.y-$Door.global_position.y

func leave_house(reposition := true, keep_transition := false) -> void:
	if not keep_transition:
		_cancel_door_transition()
	var player := inside_player
	inside_player = null
	_occupied = false
	if is_instance_valid(player):
		for terrain: PhysicsBody2D in _terrain_exceptions:
			if is_instance_valid(terrain):
				player.remove_collision_exception_with(terrain)
		player.set_collision_mask_value(32, _boundary_was_enabled)
		for body: PhysicsBody2D in _owned_exceptions.get(player.get_instance_id(), []):
			if is_instance_valid(body):
				player.add_collision_exception_with(body)
		if player.get_meta(HOUSE_META, null) == self:
			player.remove_meta(HOUSE_META)
		if reposition:
			player.global_position = _return_position
			player.velocity = Vector2.ZERO
			player.reset_physics_interpolation()
	_terrain_exceptions.clear()
	_update_cutaway()
	if is_instance_valid(interior_focus):
		interior_focus.leave(not reposition)
	if is_instance_valid(door_visual):
		door_visual.indoors = false

func _exit_tree() -> void:
	if use_door_entry and not Engine.is_editor_hint():
		leave_house(false)
		for player: CharacterBody2D in _players:
			if is_instance_valid(player):
				for body: PhysicsBody2D in _owned_exceptions.get(player.get_instance_id(), []):
					if is_instance_valid(body):
						player.remove_collision_exception_with(body)
	super._exit_tree()
