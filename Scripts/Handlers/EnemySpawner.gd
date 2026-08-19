extends Node2D

@export var enemy_scene: PackedScene              #enemy_1.tscn
@export var ground_layer: TileMapLayer            # Drag TileMapLayer here
@export var player: CharacterBody2D                # Drag Player here

@export_group("Spawn Settings")
@export var max_enemies: int = 30                  # Total limit of enemies to spawn
@export var min_spawn_distance: float = 250.0      # Off-camera distance threshold
@export var min_timer_delay: float = 1.0           # Minimum interval (seconds)
@export var max_timer_delay: float = 2.0           # Maximum interval (seconds)
@export var min_group_spawn: int = 2               # Minimum enemies per interval
@export var max_group_spawn: int = 3               # Maximum enemies per interval

var current_spawned_count: int = 0
var used_cells: Array[Vector2i] = []
var spawn_timer: Timer

func _ready() -> void:
	call_deferred("setup_spawner")

func setup_spawner() -> void:
	if ground_layer == null or enemy_scene == null or player == null:
		print("EnemySpawner: Missing scene references in Inspector!")
		return

	used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		print("No floor tiles found on Ground TileMapLayer!")
		return

	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	start_random_timer()

func start_random_timer() -> void:
	if current_spawned_count >= max_enemies:
		return
		
	var wait_time = randf_range(min_timer_delay, max_timer_delay)
	spawn_timer.start(wait_time)

func _on_spawn_timer_timeout() -> void:
	# Skip spawning if Time Stop is active, but restart timer loop
	if is_instance_valid(player) and "is_time_stopped" in player and player.is_time_stopped:
		start_random_timer()
		return

	spawn_wave()
	start_random_timer()

func spawn_wave() -> void:
	if current_spawned_count >= max_enemies:
		return

	var amount_to_spawn = randi_range(min_group_spawn, max_group_spawn)

	for i in range(amount_to_spawn):
		if current_spawned_count >= max_enemies:
			break
			
		if spawn_single_enemy():
			current_spawned_count += 1

func spawn_single_enemy() -> bool:
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		attempts += 1
		
		var random_cell: Vector2i = used_cells.pick_random()
		var local_pos: Vector2 = ground_layer.map_to_local(random_cell)
		var world_pos: Vector2 = ground_layer.to_global(local_pos)

		if world_pos.distance_to(player.global_position) >= min_spawn_distance:
			if is_position_clear(world_pos):
				var enemy = enemy_scene.instantiate()
				enemy.global_position = world_pos
				get_tree().current_scene.add_child(enemy)
				return true

	return false

func is_position_clear(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	
	query.shape = circle
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1 

	var result = space_state.intersect_shape(query, 1)
	return result.is_empty()
