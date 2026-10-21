extends Area2D

@export var upgrade_data: UpgradeData:
	set(value):
		upgrade_data = value
		_update_visuals()

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visuals()

func _update_visuals() -> void:
	if not sprite_2d:
		sprite_2d = get_node_or_null("Sprite2D")
		
	if sprite_2d and upgrade_data and upgrade_data.icon:
		# 1. Assign the texture from the resource
		sprite_2d.texture = upgrade_data.icon
		
		# 2. Calculate the original size of the assigned texture
		var original_size = sprite_2d.texture.get_size()
		
		# 3. Apply the scale multiplier to force it to exactly 16x16 pixels
		if original_size.x > 0 and original_size.y > 0:
			sprite_2d.scale = Vector2(32.0 / original_size.x, 32.0 / original_size.y)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Directly call UpgradeComponent on the player
		var upgrade_comp = body.get_node_or_null("UpgradeComponent")
		if upgrade_comp and upgrade_comp.has_method("apply_upgrade"):
			upgrade_comp.apply_upgrade(upgrade_data)
		elif body.has_method("apply_upgrade"):
			body.apply_upgrade(upgrade_data)
		queue_free()
