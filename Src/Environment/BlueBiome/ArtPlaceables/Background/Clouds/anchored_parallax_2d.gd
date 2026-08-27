@tool
class_name AnchoredParallax2D
extends Parallax2D

## Makes room-space art placement agree with a chosen camera anchor while
## retaining the layer's normal Parallax2D scroll scale during play.
@export_node_path("Node2D") var placement_anchor_path: NodePath
@export var placement_offset := Vector2.ZERO


func _ready() -> void:
	_apply_anchor_offset()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	_apply_anchor_offset()


func _apply_anchor_offset() -> void:
	var anchor := get_node_or_null(placement_anchor_path) as Node2D
	if anchor == null:
		return
	var expected_offset := (
		-anchor.global_position * (Vector2.ONE - scroll_scale)
		+ placement_offset
	)
	if not scroll_offset.is_equal_approx(expected_offset):
		scroll_offset = expected_offset
