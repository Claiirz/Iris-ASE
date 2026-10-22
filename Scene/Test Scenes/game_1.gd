extends Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	print("[DEBUG Game] Floor ", GameManager.current_floor, " loaded.")
