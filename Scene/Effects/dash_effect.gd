extends AnimatedSprite2D

func _ready() -> void:
	play("default")
	# Automatically destroy this node once the 9-frame animation ends
	animation_finished.connect(queue_free)
