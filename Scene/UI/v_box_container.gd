extends VBoxContainer

@export var selector_arrow: TextureRect

func _ready() -> void:
	for button in get_children():
		if button is Button:
			button.focus_entered.connect(_on_button_focused.bind(button))
			button.mouse_entered.connect(button.grab_focus) 
			
	if get_child_count() > 0:
		get_child(0).grab_focus()

func _on_button_focused(button: Button) -> void:
	var arrow_offset_x = 15 
	var arrow_y_center = button.global_position.y + (button.size.y / 2.0) - (selector_arrow.size.y / 2.0)
	
	selector_arrow.global_position = Vector2(button.global_position.x - arrow_offset_x, arrow_y_center)
