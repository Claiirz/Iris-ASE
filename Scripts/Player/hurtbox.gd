extends Area2D

func take_damage(amount: int) -> void:
	if owner and owner.has_method("take_damage"):
		owner.take_damage(amount)
