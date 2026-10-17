extends Node2D

@export_group("Enemy Indicator Settings")
@export var enemy_arrow: Sprite2D # Drag your enemy arrow Sprite2D here
@export var tile_size: float = 16.0 # Your tile size in pixels
@export var near_tile_radius: float = 3.0 # Radius in tiles (e.g., 3 tiles = 48px)
@export var no_enemy_delay: float = 3.5 # Seconds before arrow appears
@export var arrow_ring_distance: float = 32.0 # Distance from player center
@export_group("Arrow Transform Settings")
@export var arrow_offset_distance: float = 40.0 # Distance in pixels from player center
@export_range(-180.0, 180.0) var texture_angle_offset_degrees: float = 0.0 # Set if your PNG doesn't point RIGHT by default
@export var portal_arrow: Sprite2D # Drag your portal arrow Sprite2D here

var no_enemy_timer: float = 0.0

func _ready() -> void:
	if enemy_arrow: enemy_arrow.visible = false
	if portal_arrow: portal_arrow.visible = false

func _process(delta: float) -> void:
	_update_enemy_indicator(delta)
	_update_portal_indicator()

func _update_enemy_indicator(delta: float) -> void:
	if not enemy_arrow: return

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		enemy_arrow.visible = false
		no_enemy_timer = 0.0
		return

	# Find the nearest enemy and check distance
	var nearest_enemy: Node2D = null
	var min_distance: float = INF
	var near_threshold: float = near_tile_radius * tile_size

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				nearest_enemy = enemy

	# Reset timer if an enemy is inside the near radius
	if min_distance <= near_threshold:
		no_enemy_timer = 0.0
		enemy_arrow.visible = false
	else:
		no_enemy_timer += delta
		if no_enemy_timer >= no_enemy_delay and nearest_enemy:
			enemy_arrow.visible = true
			_point_arrow_at(enemy_arrow, nearest_enemy.global_position)

func _update_portal_indicator() -> void:
	if not portal_arrow: return

	var portal = get_tree().get_first_node_in_group("portal")
	if portal and is_instance_valid(portal):
		portal_arrow.visible = true
		_point_arrow_at(portal_arrow, portal.global_position)
	else:
		portal_arrow.visible = false

func _point_arrow_at(arrow: Sprite2D, target_pos: Vector2) -> void:
	# 1. Calculate direction vector pointing from player to target
	var dir: Vector2 = global_position.direction_to(target_pos)

	# 2. Offset position: Push arrow outward along direction vector in LOCAL space
	arrow.position = dir * arrow_offset_distance

	# 3. Rotation: Facing target + compensation for base sprite texture angle
	var target_angle: float = dir.angle()
	var texture_offset_radians: float = deg_to_rad(texture_angle_offset_degrees)

	arrow.rotation = target_angle + texture_offset_radians
