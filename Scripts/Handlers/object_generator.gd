extends Node2D

@export_group("Dependencies")
@export var ground_layer: TileMapLayer
@export var object_layer: TileMapLayer

@export_group("Density Settings")
@export_range(0.0, 1.0) var density: float = 0.08  # ~8% scatter.
@export var use_noise_clustering: bool = false   # Turn OFF for guaranteed random scatter.

@export_group("Tile Configuration")
@export var tile_source_id: int = 0
@export var object_tile_coords: Vector2i = Vector2i(5, 1)  # make sure this sprite exists in TileSet!!!!
@export var nav_region: NavigationRegion2D


func generate_objects() -> void:
	if not ground_layer or not object_layer:
		return

	object_layer.clear()
	var ground_cells: Array[Vector2i] = ground_layer.get_used_cells()

	if ground_cells.is_empty():
		return

	# Scatter object tiles across ground cells.
	for cell in ground_cells:
		if randf() <= density:
			object_layer.set_cell(cell, tile_source_id, object_tile_coords)

	# Trigger NavMesh baking safely after physics frame.
	if nav_region and nav_region.has_method("bake_map_navigation"):
		nav_region.call_deferred("bake_map_navigation")
