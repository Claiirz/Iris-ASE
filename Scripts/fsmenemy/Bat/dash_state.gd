extends Node

var fsm: EnemyFSM
var enemy: CharacterBody2D
var dash_timer: SceneTreeTimer = null

func enter() -> void:
	enemy.can_dash = false
	
	# Start dash duration
	dash_timer = get_tree().create_timer(enemy.dash_duration)
	dash_timer.timeout.connect(_on_dash_end)

func update(_delta: float) -> void:
	# Set velocity to current dash direction
	enemy.velocity = enemy.dash_direction * enemy.dash_speed
	
	# Move and check for collisions
	enemy.move_and_slide()

	# IF IT HITS A WALL: Bounce!
	if enemy.is_on_wall():
		# Get collision details from the last move_and_slide()
		var collision = enemy.get_last_slide_collision()
		if collision:
			# Bounce the dash direction off the wall's normal vector
			enemy.dash_direction = enemy.dash_direction.bounce(collision.get_normal())
			
			# Flip sprite according to the new bounced direction
			if enemy.dash_direction.x != 0:
				enemy.animated_sprite.flip_h = enemy.dash_direction.x < 0

func _on_dash_end() -> void:
	fsm.transition_to("chase")
	
	# Cooldown before allowed to dash again
	await get_tree().create_timer(2.0).timeout
	enemy.can_dash = true

func exit() -> void:
	pass
