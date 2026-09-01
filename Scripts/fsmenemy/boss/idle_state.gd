class_name BossIdleState
extends State

@export var aggro_range: float = 400.0

func enter() -> void:
	if boss and boss.has_node("AnimatedSprite2D"):
		boss.get_node("AnimatedSprite2D").play("idle")
	boss.velocity = Vector2.ZERO

func physics_update(_delta: float) -> void:
	if not boss or not boss.player:
		return
	
	# Check distance to the player to switch to walk state
	var distance = boss.global_position.distance_to(boss.player.global_position)
	if distance < aggro_range:
		fsm.transition_to("walk")
