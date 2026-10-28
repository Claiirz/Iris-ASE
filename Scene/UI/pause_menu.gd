extends CanvasLayer

# Point to Main Menu since the Hub scene is unfinished
@export var main_menu_scene_path: String = "res://Scene/main_menu.tscn"

@onready var menu_root: Control = $DimOverlay
@onready var nav_buttons: VBoxContainer = $MainContainer/NavPanel/NavButtons
@onready var resume_button: Button = $MainContainer/NavPanel/NavButtons/ResumeButton
@onready var settings_button: Button = $MainContainer/NavPanel/NavButtons/SettingsButton
@onready var abandon_button: Button = $MainContainer/NavPanel/NavButtons/AbandonButton
@onready var selector_arrow: TextureRect = $MainContainer/NavPanel/SelectorArrow

@onready var vonis_value: Label = find_child("VonisValue", true, false) as Label
@onready var era_value: Label = find_child("EraValue", true, false) as Label
@onready var time_value: Label = find_child("TimeValue", true, false) as Label

@onready var confirm_modal: Control = $ConfirmModal
@onready var cancel_button: Button = find_child("CancelButton", true, false) as Button
@onready var yes_button: Button = find_child("YesButton", true, false) as Button
@onready var modal_subtitle: Label = find_child("ModalSubtitle", true, false) as Label

var is_paused: bool = false
var run_elapsed_time: float = 0.0

func _ready() -> void:
	self.hide()
	if menu_root: 
		menu_root.hide()
	if confirm_modal: 
		confirm_modal.hide()
	
	# Connect main navigation signals
	if nav_buttons:
		for btn in nav_buttons.get_children():
			if btn is Button:
				btn.focus_entered.connect(_on_button_focused.bind(btn))
				btn.mouse_entered.connect(btn.grab_focus)
				
	if resume_button:
		resume_button.pressed.connect(unpause_game)
	if abandon_button:
		abandon_button.pressed.connect(_show_abandon_confirmation)
	
	# Connect modal buttons
	if cancel_button:
		cancel_button.pressed.connect(_hide_abandon_confirmation)
	if yes_button:
		yes_button.pressed.connect(_abandon_run_and_exit)

func _process(delta: float) -> void:
	# Track run duration while unpaused
	if not is_paused:
		run_elapsed_time += delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC key
		if confirm_modal and confirm_modal.visible:
			_hide_abandon_confirmation()
		else:
			toggle_pause()

func toggle_pause() -> void:
	if is_paused:
		unpause_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	
	_update_run_stats_display()
	if menu_root: 
		menu_root.show()
	self.show()
	
	await get_tree().process_frame
	if resume_button:
		resume_button.grab_focus()

func unpause_game() -> void:
	is_paused = false
	get_tree().paused = false
	if menu_root: 
		menu_root.hide()
	if confirm_modal: 
		confirm_modal.hide()
	self.hide()

func _update_run_stats_display() -> void:
	# Format time into MM:SS
	var minutes: int = int(run_elapsed_time) / 60
	var seconds: int = int(run_elapsed_time) % 60
	if time_value:
		time_value.text = "%02d:%02d" % [minutes, seconds]
	
	# Fetch difficulty and era from GameManager safely
	if typeof(GameManager) != TYPE_NIL:
		if "difficulty_level" in GameManager and vonis_value:
			vonis_value.text = str(GameManager.difficulty_level).to_upper()
			
		# FIX: Look for current_floor instead of current_era
		if "current_floor" in GameManager and era_value:
			era_value.text = str(GameManager.current_floor)

func _on_button_focused(btn: Button) -> void:
	if selector_arrow and btn:
		var arrow_offset_x = 12
		var arrow_y_center = btn.global_position.y + (btn.size.y / 2.0) - (selector_arrow.size.y / 2.0)
		selector_arrow.global_position = Vector2(btn.global_position.x - arrow_offset_x, arrow_y_center)

func _show_abandon_confirmation() -> void:
	if modal_subtitle:
		modal_subtitle.text = "RUN DIHITUNG KALAH.\nKEMBALI KE MENU UTAMA?"
	if confirm_modal:
		confirm_modal.show()
	if cancel_button:
		cancel_button.grab_focus()

func _hide_abandon_confirmation() -> void:
	if confirm_modal:
		confirm_modal.hide()
	if abandon_button:
		abandon_button.grab_focus()

func _abandon_run_and_exit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)
