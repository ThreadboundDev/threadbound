extends Node

signal threads_changed

var _claimed_threads: Dictionary = {}

func claim_thread(thread_id: StringName) -> void:
	if String(thread_id).is_empty():
		return
	if _claimed_threads.has(thread_id):
		return

	_claimed_threads[thread_id] = true
	threads_changed.emit()

func has_thread(thread_id: StringName) -> bool:
	return _claimed_threads.has(thread_id)

func remaining_threads(required_threads: Array[StringName]) -> Array[StringName]:
	var remaining: Array[StringName] = []
	for thread_id in required_threads:
		if not has_thread(thread_id):
			remaining.append(thread_id)
	return remaining

func claimed_count(required_threads: Array[StringName]) -> int:
	return required_threads.size() - remaining_threads(required_threads).size()

func reset_demo_threads() -> void:
	_claimed_threads.clear()
	threads_changed.emit()
