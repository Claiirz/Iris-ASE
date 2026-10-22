extends CanvasLayer

@onready var floor_label: Label = $VBoxContainer/FloorLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel

func _ready() -> void:
	get_tree().paused = true

func set_stats(floor_num: int, time_str: String) -> void:
	floor_label.text = "Floor Reached: " + str(floor_num)
	time_label.text = "Time Survived: " + time_str

func _on_restart_button_pressed() -> void:
	get_tree().paused = false 
	queue_free()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false 
	queue_free()
	get_tree().change_scene_to_file("res://Scene/UI/main_menu.tscn")
