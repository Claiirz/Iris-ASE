class_name EnemyShootState
extends Node

var fsm: Node
var enemy: CharacterBody2D

@export var projectile_scene: PackedScene
# INCREASED to 80.0. Adjust this in the Inspector so it is slightly slower than your normal chase speed.
@export var shoot_speed: float = 50.0    
@export var attack_range: float = 200.0  
@export var fire_rate: float = 1.2       
@onready var shoot_sfx: AudioStreamPlayer2D = get_node_or_null("ShootSlime")

var shoot_timer: float = 0.0
var reposition_timer: float = 0.0
var random_offset: Vector2 = Vector2.ZERO

func enter() -> void:
	shoot_timer = 0.3
	reposition_timer = 0.0
	
	if enemy:
		shoot_sfx = enemy.get_node_or_null("ShootSlime")
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("chase")

func _shoot_sfx() -> void:
	if shoot_sfx:
		shoot_sfx.play()

func update(delta: float) -> void:
	if not enemy or not enemy.is_inside_tree():
		return
		
	# Safer player fetch that won't throw null errors
	var player = enemy.player if "player" in enemy and enemy.player else enemy.get_tree().get_first_node_in_group("player")
	var nav_agent = enemy.get_node_or_null("NavigationAgent2D")
	
	if not player or not nav_agent:
		return

	var distance = enemy.global_position.distance_to(player.global_position)

	if distance > attack_range:
		# Changed "Chase" to "chase". Ensure this matches the exact key in your FSM!
		fsm.transition_to("chase") 
		return

	reposition_timer -= delta
	if reposition_timer <= 0.0:
		reposition_timer = randf_range(1.5, 3.0)
		var random_angle = randf() * TAU
		var random_distance = randf_range(70, 140)
		random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance

	nav_agent.target_position = player.global_position + random_offset
	var next_pos = nav_agent.get_next_path_position()
	var dir = enemy.global_position.direction_to(next_pos)

	# REPLACED '5.0' with enemy.accel so the slime remains responsive, just with a lower top speed.
	var current_accel = enemy.get("accel") if "accel" in enemy else 10.0
	enemy.velocity = enemy.velocity.lerp(dir * shoot_speed, delta * current_accel)
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0

	enemy.move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = fire_rate
		_shoot_sfx()
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
