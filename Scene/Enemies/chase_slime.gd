extends Node

var fsm: Node
var enemy: CharacterBody2D

func enter() -> void:
	await get_tree().physics_frame
	
	var nav_region = get_tree().get_first_node_in_group("nav_region")
	if nav_region and nav_region.is_baking():
		await nav_region.bake_finished
		
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("chase")

func update(delta: float) -> void:
	# Safely fetch player and navigation agent without crashing
	var player = enemy.get("player") if "player" in enemy else enemy.get_tree().get_first_node_in_group("player")
	var nav_agent = enemy.get_node_or_null("NavigationAgent2D")
	
	if not player or not nav_agent:
		return

	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	var dir = enemy.global_position.direction_to(next_pos)

	# Get speed and accel safely with fallbacks
	var chase_speed = enemy.get("chase_speed") if "chase_speed" in enemy else 60.0
	var accel = enemy.get("accel") if "accel" in enemy else 10.0

	enemy.velocity = enemy.velocity.lerp(dir * chase_speed, delta * accel)
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0

	enemy.move_and_slide()

	# Transition to Shoot state when close to the player
	var shoot_range = enemy.get("shoot_range") if "shoot_range" in enemy else 220.0
	if enemy.global_position.distance_to(player.global_position) <= shoot_range:
		fsm.transition_to("Shoot")
		
func exit() -> void:
	pass
