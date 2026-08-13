class_name PlaytestSupportConfig
extends Resource

@export var playtest_report_url := ""
@export var bug_report_url := ""
@export var feedback_qr_texture: Texture2D

func has_playtest_report() -> bool:
	return not playtest_report_url.strip_edges().is_empty()

func has_bug_report() -> bool:
	return not bug_report_url.strip_edges().is_empty()
