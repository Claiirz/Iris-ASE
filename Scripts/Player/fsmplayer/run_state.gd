class_name RunState
extends State

func enter() -> void:
	if player and player.animated_sprite:
		player.animated_sprite.play("run")

# Inside RunState.gd / MoveState.gd
func physics(_delta: float) -> State:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		player.velocity = input_dir.normalized() * player.get_current_move_speed()
	return null
