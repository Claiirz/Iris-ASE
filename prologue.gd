extends Control

@onready var story_label: Label = $Label

func _ready() -> void:
	play_cutscene()

func play_cutscene() -> void:
	story_label.text = "Year 202X. The world is in ruin..."
	await get_tree().create_timer(3.0).timeout # wait() for 3 seconds
	
	story_label.text = "Only one hero remains."
	await get_tree().create_timer(3.0).timeout
	
	# Cutscene finishes, go to difficulty screen
	choose_difficulty()

func choose_difficulty() -> void:
	# Load the Difficulty Select screen
	get_tree().change_scene_to_file("res://Scene/difficulty_select.tscn")

# Connect this to your Skip button
func _on_skip_button_pressed() -> void:
	choose_difficulty()
