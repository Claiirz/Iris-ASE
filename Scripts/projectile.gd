class_name Projectile
extends Area2D

@export var speed: float = 350.0
var direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Move continuously in the fired direction
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(10) # Adjust damage as needed
		queue_free() # Destroy bullet on impact
	elif body is TileMapLayer:
		queue_free() # Destroy bullet if it hits walls
