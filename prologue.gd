extends Control

@export_category("Cutscene Assets")
# In the Inspector, set this array size to 5 and drag your 5 panel images in order
@export var panel_images: Array[Texture2D] = []

@export_category("Next Scene")
# Drag your Gameplay/Difficulty Select scene here
@export var next_scene: PackedScene 

@onready var panel_display: TextureRect = $PanelDisplay
@onready var caption_box: ColorRect = $CaptionBox
@onready var caption_text: Label = $CaptionBox/CaptionText

var current_panel: int = 0

func _ready() -> void:
	_show_panel(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		advance_cutscene()

func advance_cutscene() -> void:
	current_panel += 1
	
	if current_panel < panel_images.size():
		_show_panel(current_panel)
	else:
		_fade_to_black_and_start()

func _show_panel(index: int) -> void:
	panel_display.texture = panel_images[index]	
	panel_display.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(panel_display, "modulate", Color(1, 1, 1, 1), 0.3)

func _fade_to_black_and_start() -> void:
	set_process_input(false) 
	caption_box.hide()
	
	var tween = create_tween()
	tween.tween_property(panel_display, "modulate", Color(0, 0, 0, 1), 1.5)
	tween.finished.connect(func():
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
	)
