extends Control

func _ready() -> void:
	$Button.grab_focus()
	$Button.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://Scene/UI/main_menu.tscn")
