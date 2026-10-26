extends Control

@export var win_screen_path: String = "res://Scene/win_screen.tscn"

@onready var player_sprite = $PlayerSprite
@onready var nemesis_sprite = $NemesisSprite
@onready var ending_text = $EndingUI/Label 

func _ready() -> void:

	if ending_text:
		ending_text.hide()
	
	nemesis_sprite.modulate = Color(1, 1, 1, 0) 
	player_sprite.modulate = Color(1, 1, 1, 1)  
	
	_play_transformation_sequence()

func _play_transformation_sequence() -> void:
	await get_tree().create_timer(1.5).timeout
	
	if ending_text:
		ending_text.text = "is this the end?"
		ending_text.show()
		
	await get_tree().create_timer(2.0).timeout
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(player_sprite, "modulate", Color(1, 1, 1, 0), 4.0)
	tween.tween_property(nemesis_sprite, "modulate", Color(1, 1, 1, 1), 4.0)

	await tween.finished
	await get_tree().create_timer(2.5).timeout
	
	get_tree().change_scene_to_file(win_screen_path)
