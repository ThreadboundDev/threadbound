@tool
extends MultiMeshInstance2D
## Draws a placed patch of textured grass. Each placement stores x, root y, and width.

const COLUMNS := 4
const ROWS := 5
const CONTACT_RADIUS := 84.0
const CONTACT_HEIGHT := 58.0
const TINTS := [Color(0.78, 0.88, 0.73), Color(0.93, 0.95, 0.75), Color(0.79, 0.89, 0.90)]

@export var placements := PackedVector3Array():
	set(value):
		placements = value
		if is_node_ready():
			_rebuild()

var _player: CharacterBody2D
var _player_collision: CollisionShape2D
var _phases := PackedFloat32Array()
var _bends := PackedFloat32Array()


func _ready() -> void:
	_rebuild()
	set_physics_process(not Engine.is_editor_hint())


func _rebuild() -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_2D
	instances.use_custom_data = true
	instances.use_colors = true
	instances.mesh = make_mesh()
	instances.instance_count = placements.size()
	_phases.resize(placements.size())
	_bends.resize(placements.size())
	var aspect := float(texture.get_height()) / texture.get_width() if texture else 1.0
	for index in placements.size():
		var placement := placements[index]
		var width := maxf(placement.z, 1.0)
		var root := Vector2(placement.x, placement.y)
		var style := hash(root)
		_phases[index] = float(posmod(style, 997)) / 997.0
		_bends[index] = 0.0
		instances.set_instance_transform_2d(index, Transform2D(0.0, Vector2(width, width * aspect), 0.0, root))
		instances.set_instance_color(index, TINTS[posmod(style, TINTS.size())])
		instances.set_instance_custom_data(index, Color(_phases[index], 0.5, 0.0, 1.0))
	multimesh = instances


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
		_player_collision = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D if _player else null
	if not is_instance_valid(_player_collision):
		return
	var player_feet := _player_collision.global_position
	var capsule := _player_collision.shape as CapsuleShape2D
	if capsule:
		player_feet.y += capsule.height * _player_collision.global_scale.y * 0.5
	var feet := to_local(player_feet)
	var direction := clampf(_player.velocity.x / 420.0, -1.0, 1.0)
	for index in placements.size():
		var plant := placements[index]
		var horizontal := 1.0 - smoothstep(16.0, CONTACT_RADIUS, absf(feet.x - plant.x))
		var vertical := 1.0 - smoothstep(18.0, CONTACT_HEIGHT, absf(feet.y - plant.y))
		var target := direction * horizontal * vertical
		var damping := 14.0 if absf(target) > absf(_bends[index]) else 6.5
		var bend := lerpf(_bends[index], target, 1.0 - exp(-damping * delta))
		if absf(bend) < 0.002:
			bend = 0.0
		if bend != _bends[index]:
			_bends[index] = bend
			multimesh.set_instance_custom_data(index, Color(_phases[index], 0.5 + bend * 0.5, 0.0, 1.0))


static func make_mesh(size := Vector2.ONE) -> ArrayMesh:
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(ROWS + 1):
		for column in range(COLUMNS + 1):
			var uv := Vector2(float(column) / COLUMNS, float(row) / ROWS)
			vertices.append((uv - Vector2(0.5, 1.0)) * size)
			uvs.append(uv)
	for row in ROWS:
		for column in COLUMNS:
			var top := row * (COLUMNS + 1) + column
			var bottom := top + COLUMNS + 1
			indices.append_array(PackedInt32Array([top, top + 1, bottom, top + 1, bottom + 1, bottom]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh
