extends SceneTree

const FeedbackLogger := preload("res://Src/DebugFeedback/feedback_logger.gd")

class TrailProbe extends "res://Src/VFX/thread_sword_sweep.gd":
	var cases := 0

	func _draw() -> void:
		for offset: Vector2 in [Vector2.ZERO, Vector2(-1582,4082), Vector2(100000,100000)]:
			for height: float in [0.0, .0001, .001, .01, 1.0, 50.0]:
				for direction: float in [-1.0,1.0]:
					var a := offset
					var b := offset+Vector2(100,0)
					var c := offset+Vector2(100,height*direction)
					var d := offset+Vector2(0,-height*direction)
					_draw_strip_quad(PackedVector2Array([a,b,c,d]),Color.WHITE)
					cases += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var logger := FeedbackLogger.new()
	OS.add_logger(logger)
	var probe := TrailProbe.new()
	root.add_child(probe)
	await process_frame
	await RenderingServer.frame_post_draw
	var errors := int(logger.snapshot()["errors_since_start"])
	print("THREAD_SWEEP_TRIANGLES cases=", probe.cases, " errors=", errors)
	var passed := probe.cases == 36 and errors == 0
	OS.remove_logger(logger)
	probe.free()
	quit(0 if passed else 1)
