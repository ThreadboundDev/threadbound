class_name DemoEndingConfig
extends Resource

@export_group("Playtest Support")
@export var playtest_support: PlaytestSupportConfig

@export_group("Thank You")
@export var title := "THANK YOU FOR PLAYING"
@export_multiline var message := "Thank you for playing the Threadbound Demo.\n\nThreadbound is still in development, and your feedback is incredibly valuable."
@export_multiline var personal_note := ""

@export_group("Credits")
@export var credit_categories: PackedStringArray = []
@export var credit_entries: PackedStringArray = []
