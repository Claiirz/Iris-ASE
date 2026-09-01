extends Node2D

@export_group("Dependencies")
@export var ground_layer: TileMapLayer
@export var object_generator: Node2D  # Drag ObjectGenerator here in Inspector

@export_group("Map Dimensions") 
@export var map_width: int = 100 # Map Size X 
@export var map_height: int = 100 # Map Size Y

@export_group("TileSet Configuration")
@export var source_id: int = 0

@export var floor_tiles: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)
]


func _ready() -> void:
	generate_floor()


func generate_floor() -> void:
	if not ground_layer:
		push_error("GroundGenerator: Missing Ground reference!")
		return

	ground_layer.clear()

	# Center bounds: -50 to +50
	var half_w: int = map_width / 2
	var half_h: int = map_height / 2

	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			var cell = Vector2i(x, y)
			var chosen_tile = floor_tiles.pick_random() if not floor_tiles.is_empty() else Vector2i.ZERO
			ground_layer.set_cell(cell, source_id, chosen_tile)

	# Trigger Object Spawning
	if object_generator and object_generator.has_method("generate_objects"):
		object_generator.generate_objects()
