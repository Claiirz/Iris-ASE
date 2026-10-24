extends Node2D

@export_group("Dependencies")
@export var ground_layer: TileMapLayer
@export var object_layer: TileMapLayer

@export_group("Density Settings")
@export_range(0.0, 1.0) var density: float = 0.03  
@export var use_noise_clustering: bool = false   

@export_group("Tile Configuration")
@export var tile_source_id: int = 2
@export var border_tile_coords: Vector2i = Vector2i(5, 1)

@export_group("Large Object Models")
# Add your rock coordinates here. Index 0 matches Index 0 in the sizes array below.
@export var rock_base_coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(4, 0)]
# Add the matching sizes for the rocks here.
@export var rock_sizes_in_tiles: Array[Vector2i] = [Vector2i(2, 2), Vector2i(4, 4)]

@export var nav_region: NavigationRegion2D

func generate_objects() -> void:
	if not ground_layer or not object_layer:
		return

	# Failsafe: Prevent crashes if you forget to add a size for a new rock
	if rock_base_coords.size() != rock_sizes_in_tiles.size():
		push_error("MapGenerator: 'rock_base_coords' and 'rock_sizes_in_tiles' arrays must have the exact same number of items!")
		return

	object_layer.clear()
	var ground_cells: Array[Vector2i] = ground_layer.get_used_cells()

	if ground_cells.is_empty():
		return

	# Fast lookup dictionaries
	var valid_ground: Dictionary = {}
	for cell in ground_cells:
		valid_ground[cell] = true

	var occupied_cells: Dictionary = {}

	# 1. Scatter random large objects safely
	for cell in ground_cells:
		if randf() <= density:
			# Pick a random rock model from your arrays
			var random_index = randi() % rock_base_coords.size()
			var chosen_coords = rock_base_coords[random_index]
			var chosen_size = rock_sizes_in_tiles[random_index]
			
			_try_place_large_object(cell, chosen_coords, chosen_size, valid_ground, occupied_cells)

	# 2. Draw the solid barrier around the map
	_generate_borders()

	# 3. Trigger NavMesh baking safely after physics frame.
	if nav_region and nav_region.has_method("bake_map_navigation"):
		nav_region.call_deferred("bake_map_navigation")


func _try_place_large_object(base_cell: Vector2i, coords: Vector2i, size: Vector2i, valid_ground: Dictionary, occupied_cells: Dictionary) -> void:
	# Check if there is enough space for this specific object size
	for x in range(size.x):
		for y in range(size.y):
			var check_pos = base_cell + Vector2i(x, y)
			
			# Abort if the space is off the ground or already occupied by another rock
			if not valid_ground.has(check_pos) or occupied_cells.has(check_pos):
				return 

	# If we reach here, the space is clear! Assemble the rock piece by piece.
	for x in range(size.x):
		for y in range(size.y):
			var target_pos = base_cell + Vector2i(x, y)
			var atlas_pos = coords + Vector2i(x, y)
			
			object_layer.set_cell(target_pos, tile_source_id, atlas_pos)
			occupied_cells[target_pos] = true # Mark space as occupied


func _generate_borders() -> void:
	var bounds = ground_layer.get_used_rect()
	
	var min_x = bounds.position.x - 1
	var max_x = bounds.end.x
	var min_y = bounds.position.y - 1
	var max_y = bounds.end.y

	# Draw top and bottom walls
	for x in range(min_x, max_x + 1):
		object_layer.set_cell(Vector2i(x, min_y), tile_source_id, border_tile_coords)
		object_layer.set_cell(Vector2i(x, max_y), tile_source_id, border_tile_coords)
		
	# Draw left and right walls
	for y in range(min_y + 1, max_y):
		object_layer.set_cell(Vector2i(min_x, y), tile_source_id, border_tile_coords)
		object_layer.set_cell(Vector2i(max_x, y), tile_source_id, border_tile_coords)
