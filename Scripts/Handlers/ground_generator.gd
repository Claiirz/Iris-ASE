extends Node2D

@export_group("Dependencies")
@export var ground_layer: TileMapLayer
@export var object_generator: Node2D  # Drag ObjectGenerator here in Inspector

@export_group("Map Dimensions") 
@export var map_width: int = 150 # Map Size X 
@export var map_height: int = 150 # Map Size Y

@export_group("TileSet Configuration")
@export var source_id: int = 2

# We replace the random array with the exact location and size of your pattern
@export var pattern_base_coords: Vector2i = Vector2i(0, 0) # Top-left tile of the 4x4 block in the atlas
@export var pattern_size: Vector2i = Vector2i(4, 4)


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
			
			# posmod wraps the coordinates safely into a 0-3 grid loop
			var offset_x = posmod(x, pattern_size.x)
			var offset_y = posmod(y, pattern_size.y)
			
			# Add the offset to the base atlas coordinate
			var chosen_tile = pattern_base_coords + Vector2i(offset_x, offset_y)
			
			ground_layer.set_cell(cell, source_id, chosen_tile)

	# Trigger Object Spawning
	if object_generator and object_generator.has_method("generate_objects"):
		object_generator.generate_objects()
