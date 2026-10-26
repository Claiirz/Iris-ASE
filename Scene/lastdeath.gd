extends Node

@export_category("Ending Settings")
@export var nemesis_scene: PackedScene
@export var win_screen_path: String = "res://Scene/win_screen.tscn"

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var ending_text: Label = $EndingUI/Label

func _ready() -> void:
	if ending_text:
		ending_text.hide()

func start_fake_ending() -> void:

	if player:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)

	if ending_text:
		ending_text.text = "is this the end?"
		ending_text.show()


	await get_tree().create_timer(3.0).timeout
	if ending_text:
		ending_text.hide()


	if nemesis_scene and player:
		var nemesis = nemesis_scene.instantiate() as Node2D

		nemesis.global_position = player.global_position + Vector2(40, 0)
		add_child(nemesis)


	await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_file(win_screen_path)
