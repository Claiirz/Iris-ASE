class_name IdleState
extends State

func enter() -> void:
	if player and player.animated_sprite:
		player.animated_sprite.play("idle")

func physics_update(delta: float) -> void:
	if player:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.friction * delta)
		player.move_and_slide()
		
		var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
		if input_dir != Vector2.ZERO:
			get_parent().change_state("Run")
