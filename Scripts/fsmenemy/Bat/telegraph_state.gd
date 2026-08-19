extends Node

var fsm: EnemyFSM
var enemy: CharacterBody2D

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.dash_direction = enemy.global_position.direction_to(enemy.player.global_position)
	
	# Flash warning
	var tween = create_tween()
	tween.tween_property(enemy.animated_sprite, "modulate", Color.YELLOW, enemy.telegraph_duration)
	
	await get_tree().create_timer(enemy.telegraph_duration).timeout
	enemy.animated_sprite.modulate = Color.WHITE
	fsm.transition_to("dash")

# ADD THIS: Prevents the "Nonexistent function 'update'" crash!
func update(_delta: float) -> void:
	pass

func exit() -> void:
	pass
