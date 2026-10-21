extends Node2D

@export_group("Dependencies")
@export var ground_layer: TileMapLayer
@export var object_layer: TileMapLayer

@export_group("Density Settings")
@export_range(0.0, 1.0) var density: float = 0.03  
@export var use_noise_clustering: bool = false   

@export_group("Tile Configuration")
@export var tile_source_id: int = 0
@export var object_tile_coords: Vector2i = Vector2i(5, 1) 
@export var nav_region: NavigationRegion2D

func generate_objects() -> void:
	if not ground_layer or not object_layer:
		return

	object_layer.clear()
	var ground_cells: Array[Vector2i] = ground_layer.get_used_cells()

	if ground_cells.is_empty():
		return

	# 1. Scatter random object tiles across ground cells.
	for cell in ground_cells:
		if randf() <= density:
			object_layer.set_cell(cell, tile_source_id, object_tile_coords)

	# 2. Draw the solid barrier around the map
	_generate_borders()

	# 3. Trigger NavMesh baking safely after physics frame.
	if nav_region and nav_region.has_method("bake_map_navigation"):
		nav_region.call_deferred("bake_map_navigation")

# --- NEW FUNCTION ---
func _generate_borders() -> void:
	# get_used_rect() returns the exact bounding box of all currently drawn ground tiles
	var bounds = ground_layer.get_used_rect()
	
	# Calculate coordinates for 1 tile outside the ground area
	var min_x = bounds.position.x - 1
	var max_x = bounds.end.x
	var min_y = bounds.position.y - 1
	var max_y = bounds.end.y

	# Draw top and bottom walls
	for x in range(min_x, max_x + 1):
		object_layer.set_cell(Vector2i(x, min_y), tile_source_id, object_tile_coords)
		object_layer.set_cell(Vector2i(x, max_y), tile_source_id, object_tile_coords)
		
	# Draw left and right walls (skipping the corners we just drew above)
	for y in range(min_y + 1, max_y):
		object_layer.set_cell(Vector2i(min_x, y), tile_source_id, object_tile_coords)
		object_layer.set_cell(Vector2i(max_x, y), tile_source_id, object_tile_coords)
