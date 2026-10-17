extends Control

func _on_easy_button_pressed() -> void:
	GameManager.difficulty_level = "Easy"
	GameManager.difficulty_multiplier = 0.75
	_start_game()

func _on_normal_button_pressed() -> void:
	GameManager.difficulty_level = "Normal"
	GameManager.difficulty_multiplier = 1.0
	_start_game()

func _on_hard_button_pressed() -> void:
	GameManager.difficulty_level = "Hard"
	GameManager.difficulty_multiplier = 1.5
	_start_game()

func _start_game() -> void:
	# Replace with the path to your Floor 1 / Main Game scene
	get_tree().change_scene_to_file("res://Scene/Test Scenes/game1.tscn")
