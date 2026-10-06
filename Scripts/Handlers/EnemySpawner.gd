extends Node2D

@export var enemy_scenes: Array[PackedScene] = []        # Drag Enemy1.tscn and Enemy2.tscn here
@export var portal_scene: PackedScene                    # Drag portal.tscn here
@export var ground_layer: TileMapLayer                   # Drag TileMapLayer here
@export var player: CharacterBody2D                      # Drag Player here (or auto-found)

@export_group("Spawn Settings")
@export var min_spawn_distance: float = 250.0          # Off-camera distance threshold
@export var min_timer_delay: float = 1.0               # Minimum wave interval (seconds)
@export var max_timer_delay: float = 2.0               # Maximum wave interval (seconds)
@export var min_group_spawn: int = 2                   # Minimum enemies per wave
@export var max_group_spawn: int = 3                   # Maximum enemies per wave
@export var max_active_on_screen: int = 10             # Prevents lagging by limiting simultaneous active enemies

var total_enemies_this_floor: int = 30
var enemies_spawned_so_far: int = 0
var enemies_remaining_to_kill: int = 0

var used_cells: Array[Vector2i] = []
var spawn_timer: Timer

func _ready() -> void:
	add_to_group("spawner")
	call_deferred("setup_spawner")

func setup_spawner() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if ground_layer == null or enemy_scenes.is_empty():
		push_warning("EnemySpawner Warning: Missing 'ground_layer' or 'enemy_scenes' in Inspector!")
		return

	used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		push_warning("EnemySpawner Warning: No floor tiles found on Ground TileMapLayer!")
		return

	# Set floor target count (30 on Floor 1, +5 per floor after)
	if GameManager.has_method("get_max_enemies_for_floor"):
		total_enemies_this_floor = GameManager.get_max_enemies_for_floor()
	else:
		total_enemies_this_floor = 30 + ((GameManager.current_floor - 1) * 5)

	enemies_remaining_to_kill = total_enemies_this_floor
	enemies_spawned_so_far = 0

	print("Floor ", GameManager.current_floor, " started. Target to defeat: ", total_enemies_this_floor)

	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	start_random_timer()

func start_random_timer() -> void:
	# Stop timer once the floor's total enemy quota has finished spawning
	if enemies_spawned_so_far >= total_enemies_this_floor:
		return
		
	var wait_time = randf_range(min_timer_delay, max_timer_delay)
	spawn_timer.start(wait_time)

func _on_spawn_timer_timeout() -> void:
	# Pause spawn loops during Time Stop
	if is_instance_valid(player) and "is_time_stopped" in player and player.is_time_stopped:
		start_random_timer()
		return

	spawn_wave()
	start_random_timer()

func spawn_wave() -> void:
	if enemies_spawned_so_far >= total_enemies_this_floor:
		return

	# Performance Guard: Don't spawn if too many enemies are currently alive
	var current_active = get_tree().get_nodes_in_group("enemies").size()
	if current_active >= max_active_on_screen:
		return

	var amount_to_spawn = randi_range(min_group_spawn, max_group_spawn)

	for i in range(amount_to_spawn):
		if enemies_spawned_so_far >= total_enemies_this_floor:
			break
			
		if spawn_single_enemy():
			enemies_spawned_so_far += 1

func spawn_single_enemy() -> bool:
	if not player:
		return false

	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		attempts += 1
		
		var random_cell: Vector2i = used_cells.pick_random()
		var local_pos: Vector2 = ground_layer.map_to_local(random_cell)
		var world_pos: Vector2 = ground_layer.to_global(local_pos)

		if world_pos.distance_to(player.global_position) >= min_spawn_distance:
			if is_position_clear(world_pos):
				# Randomly picks either Enemy1 or Enemy2 from your array
				var chosen_enemy_scene = enemy_scenes.pick_random()
				if chosen_enemy_scene:
					var enemy = chosen_enemy_scene.instantiate() as Node2D
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

# Called by enemy scripts when an enemy dies
func notify_enemy_killed(death_position: Vector2) -> void:
	enemies_remaining_to_kill -= 1
	print("[DEBUG Spawner] Enemy killed! Remaining: ", enemies_remaining_to_kill, " / ", total_enemies_this_floor, " | Total Spawned: ", enemies_spawned_so_far)

	# STRICT CHECK: Only spawn portal if the spawner finished creating all floor enemies AND all are dead
	if enemies_spawned_so_far >= total_enemies_this_floor and enemies_remaining_to_kill <= 0:
		print("[DEBUG Spawner] All floor enemies defeated! Spawning portal now...")
		_spawn_portal(death_position)

func _spawn_portal(spawn_pos: Vector2) -> void:
	if portal_scene:
		var portal = portal_scene.instantiate() as Node2D
		portal.global_position = spawn_pos
		get_tree().current_scene.call_deferred("add_child", portal)
		print("[DEBUG Spawner] Portal successfully added to scene tree at: ", spawn_pos)
	else:
		push_error("[DEBUG Spawner ERROR] 'portal_scene' is NOT assigned in EnemySpawner Inspector!")
