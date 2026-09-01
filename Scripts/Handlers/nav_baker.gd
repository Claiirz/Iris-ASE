extends NavigationRegion2D

@export_group("Dependencies")
@export var object_layer: TileMapLayer #Drag Object layer here.

@export_group("Grid Dimensions")
@export var map_width: int = 100
@export var map_height: int = 100
@export var tile_size: Vector2 = Vector2(16, 16)

@export_group("Obstacle Footprint")
# Set to Vector2i(1, 1) for single tiles, or Vector2i(4, 4) if your prop spans 4x4.
@export var object_tile_span: Vector2i = Vector2i(1, 1)

#Extra pixel buffer around obstacles (Default: 3.0px).
@export var hole_padding: float = 0


func bake_map_navigation() -> void:
	global_position = Vector2.ZERO

	var nav_poly = NavigationPolygon.new()
	var source_geometry = NavigationMeshSourceGeometryData2D.new()

	# 1. Map Outer Boundary (-800px to +800px)(pojok).
	var half_w = (map_width * tile_size.x) / 2.0
	var half_h = (map_height * tile_size.y) / 2.0

	var outer_outline = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	source_geometry.add_traversable_outline(outer_outline)

	# 2. Build raw square boxes for all object cells.
	if object_layer:
		var object_cells = object_layer.get_used_cells()
		var p = hole_padding
		var raw_boxes: Array[PackedVector2Array] = []

		for cell in object_cells:
			var min_x = (cell.x * tile_size.x) - p
			var min_y = (cell.y * tile_size.y) - p
			var max_x = ((cell.x + object_tile_span.x) * tile_size.x) + p
			var max_y = ((cell.y + object_tile_span.y) * tile_size.y) + p

			var box = PackedVector2Array([
				Vector2(min_x, min_y),
				Vector2(max_x, min_y),
				Vector2(max_x, max_y),
				Vector2(min_x, max_y)
			])
			raw_boxes.append(box)

		# 3. Fuse touching/overlapping boxes into clean combined polygons.
		var merged_shapes = _merge_all_polygons(raw_boxes)

		# 4. Add clean merged outlines to geometry.
		for shape in merged_shapes:
			source_geometry.add_obstruction_outline(shape)

	# 5. Bake clean geometry without micro-slivers.
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)
	navigation_polygon = nav_poly

	print("NavMesh successfully baked with clean merged obstruction outlines!")

func _merge_all_polygons(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	if polygons.is_empty():
		return []

	var merged_list: Array[PackedVector2Array] = []

	for poly in polygons:
		var current = poly
		var i = merged_list.size() - 1
		
		while i >= 0:
			var merge_result = Geometry2D.merge_polygons(merged_list[i], current)
		
			if merge_result.size() == 1:
				current = merge_result[0]
				merged_list.remove_at(i)
				i = merged_list.size() - 1 
			else:
				i -= 1

		merged_list.append(current)

	return merged_list

func get_valid_spawn_position() -> Vector2:
	var valid_cell: Vector2i = Vector2i.ZERO
	var found_valid_spot: bool = false

	while not found_valid_spot:
		# Pick a random cell on your 100x100 floor (-50 to 50).
		var rand_x = randi_range(-map_width / 2, map_width / 2 - 1)
		var rand_y = randi_range(-map_height / 2, map_height / 2 - 1)
		var cell = Vector2i(rand_x, rand_y)

		# Check if the Object TileMapLayer has NO tile here (-1 means empty).
		if object_layer.get_cell_source_id(cell) == -1:
			valid_cell = cell
			found_valid_spot = true

	# Return center pixel position of the empty floor cell.
	return object_layer.map_to_local(valid_cell)
