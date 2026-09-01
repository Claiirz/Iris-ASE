class_name EnemyShootState
extends Node

var fsm: Node
var enemy: CharacterBody2D

@export var projectile_scene: PackedScene
@export var shoot_speed: float = 60.0    # Slows down while shooting
@export var attack_range: float = 200.0  # Distance threshold: if player exceeds this, switch back to Chase
@export var fire_rate: float = 1.2       # Seconds between shots

var shoot_timer: float = 0.0
var reposition_timer: float = 0.0
var random_offset: Vector2 = Vector2.ZERO

func enter() -> void:
	shoot_timer = 0.3
	reposition_timer = 0.0
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("chase") # Or your walking animation

func update(delta: float) -> void:
	if not enemy:
		return
		
	var player = enemy.get("player") if "player" in enemy else enemy.get_tree().get_first_node_in_group("player")
	var nav_agent = enemy.get_node_or_null("NavigationAgent2D")
	
	if not player or not nav_agent:
		return

	var distance = enemy.global_position.distance_to(player.global_position)

	# --- 1. CHECK IF PLAYER FLED ---
	# If the player moves further away than attack_range, switch back to Chase state!
	if distance > attack_range:
		fsm.transition_to("Chase") # NOTE: Make sure this matches your FSM node name ("Chase" or "chase")
		return

	# --- 2. RANDOM REPOSITIONING LOGIC ---
	reposition_timer -= delta
	if reposition_timer <= 0.0:
		reposition_timer = randf_range(1.5, 3.0)
		var random_angle = randf() * TAU
		var random_distance = randf_range(70, 140)
		random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance

	nav_agent.target_position = player.global_position + random_offset
	var next_pos = nav_agent.get_next_path_position()
	var dir = enemy.global_position.direction_to(next_pos)

	enemy.velocity = enemy.velocity.lerp(dir * shoot_speed, delta * 5.0)
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0

	enemy.move_and_slide()

	# --- 3. PROJECTILE FIRING LOGIC ---
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = fire_rate
		shoot_projectile(player)


func shoot_projectile(player: Node2D) -> void:
	if not projectile_scene:
		push_warning("ShootState Warning: Projectile Scene is not assigned in the Inspector!")
		return

	var proj = projectile_scene.instantiate()
	if not proj:
		return

	proj.global_position = enemy.global_position
	
	var fire_dir = enemy.global_position.direction_to(player.global_position)
	if "direction" in proj:
		proj.direction = fire_dir

	enemy.get_tree().current_scene.add_child(proj)
