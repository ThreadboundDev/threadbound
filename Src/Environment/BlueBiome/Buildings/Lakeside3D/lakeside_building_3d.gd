@tool
extends Node3D
## Approved GLB with facade/roof-center cutaway and smooth PBR texture filtering.
@export var preview_inside := false:
	set(value):
		preview_inside = value
		if is_node_ready():
			set_cutaway(value)

var facade_parts: Array[Node3D] = []
var is_cutaway := false
var facade_foreground := true

func _ready() -> void:
	for part in find_children("*Facade_Removable*", "Node3D", true, false):
		# Only the assembly root, not every mesh below it, owns visibility.
		if "Facade_Removable" not in str(part.get_parent().name):
			facade_parts.append(part)
	_set_layers(self, false)
	set_cutaway(preview_inside)

func _set_layers(node: Node, facade: bool, entry_foreground := false) -> void:
	facade = facade or "Facade_Removable" in str(node.name)
	entry_foreground = entry_foreground or "Entry_Foreground_Always" in str(node.name)
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).layers = 2 if entry_foreground or (facade and facade_foreground) else 1
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as BaseMaterial3D
			if material:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for child in node.get_children():
		_set_layers(child, facade, entry_foreground)

func set_cutaway(inside: bool) -> void:
	is_cutaway = inside
	for part in facade_parts:
		if is_instance_valid(part):
			part.visible = not inside

func set_facade_foreground(enabled: bool) -> void:
	if facade_foreground != enabled:
		facade_foreground = enabled
		_set_layers(self, false)
