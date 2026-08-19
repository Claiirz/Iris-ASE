extends PanelContainer

@export_group("Map Dimensions")
@export var map_width: int = 100
@export var map_height: int = 100
@export var tile_size: Vector2 = Vector2(16, 16)

@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D


func _ready() -> void:
	# Wait 1 frame so main World2D initializes
	await get_tree().process_frame

	# Share main game world with minimap
	sub_viewport.world_2d = get_viewport().world_2d

	# Center camera at world origin (0, 0)
	minimap_camera.global_position = Vector2.ZERO

	# Auto-calculate zoom to fit the entire map into the UI frame
	_fit_camera_to_map()


func _fit_camera_to_map() -> void:
	var total_map_pixel_width: float = map_width * tile_size.x
	var total_map_pixel_height: float = map_height * tile_size.y

	var viewport_size: Vector2 = sub_viewport.size

	# Calculate zoom scale required for both X and Y axes
	var zoom_x: float = viewport_size.x / total_map_pixel_width
	var zoom_y: float = viewport_size.y / total_map_pixel_height

	# Use the smaller ratio to fit the entire map inside the frame cleanly
	var final_zoom: float = min(zoom_x, zoom_y)
	minimap_camera.zoom = Vector2(final_zoom, final_zoom)
