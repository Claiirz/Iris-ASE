extends Control

@onready var card_container: BoxContainer = $VBoxContainer 
@onready var focus_bracket: NinePatchRect = $FocusBracket
@onready var accept_button: Button = $AcceptButton

var selected_index: int = 1

func _ready() -> void:
	var index = 0

	for btn in card_container.get_children():
		if btn is BaseButton:
			btn.focus_entered.connect(_on_button_focused.bind(btn, index))
			btn.mouse_entered.connect(btn.grab_focus) 

			if not btn.pressed.is_connected(btn.grab_focus):
				btn.pressed.connect(btn.grab_focus)
				
			index += 1

	accept_button.pressed.connect(_on_accept_pressed)

	await get_tree().process_frame
	if card_container.get_child_count() > 1:
		card_container.get_child(1).grab_focus()

func _on_button_focused(btn: BaseButton, index: int) -> void:
	selected_index = index

	for card in card_container.get_children():
		card.pivot_offset = card.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if focus_bracket:
		var padding = 8 
		var target_pos = btn.global_position - Vector2(padding, padding)
		var target_size = btn.size + Vector2(padding * 2, padding * 2)
		
		tween.tween_property(focus_bracket, "global_position", target_pos, 0.2)
		tween.tween_property(focus_bracket, "size", target_size, 0.2)

	for sibling in card_container.get_children():
		if sibling == btn:
			sibling.z_index = 1 
			tween.tween_property(sibling, "scale", Vector2(1.0, 1.0), 0.2)
			tween.tween_property(sibling, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
		else:
			sibling.z_index = 0 
			tween.tween_property(sibling, "scale", Vector2(0.85, 0.85), 0.2)
			tween.tween_property(sibling, "modulate", Color(0.4, 0.4, 0.4, 1.0), 0.2)


func _on_accept_pressed() -> void:
	match selected_index:
		0: # Easy
			GameManager.difficulty_level = "Easy"
			GameManager.difficulty_multiplier = 0.5
		1: # Normal
			GameManager.difficulty_level = "Normal"
			GameManager.difficulty_multiplier = 1.0
		2: # Hard
			GameManager.difficulty_level = "Hard"
			GameManager.difficulty_multiplier = 2.5
			
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://Scene/Test Scenes/game1.tscn")
