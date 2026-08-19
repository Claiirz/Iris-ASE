extends Node

var fsm: EnemyFSM
var enemy: CharacterBody2D

func enter() -> void:
	# Wait for NavigationServer2D map synchronization
	await get_tree().physics_frame
	
	# If map is baking, wait until baking finishes
	var nav_region = get_tree().get_first_node_in_group("nav_region")
	if nav_region and nav_region.is_baking():
		await nav_region.bake_finished
		
	enemy.animated_sprite.play("fly")

func update(delta: float) -> void:
	if not enemy.player or not enemy.navigation_agent_2d:
		return

	enemy.navigation_agent_2d.target_position = enemy.player.global_position
	var next_pos = enemy.navigation_agent_2d.get_next_path_position()
	var dir = enemy.global_position.direction_to(next_pos)

	enemy.velocity = enemy.velocity.lerp(dir * enemy.chase_speed, delta * enemy.accel)
	
	if dir.x != 0:
		enemy.animated_sprite.flip_h = dir.x < 0

	enemy.move_and_slide()

	# Check distance to trigger Telegraph/Dash
	if enemy.global_position.distance_to(enemy.player.global_position) <= enemy.dash_trigger_distance and enemy.can_dash:
		fsm.transition_to("telegraph")
		
func exit() -> void:
	pass # Called when leaving the Chase state
