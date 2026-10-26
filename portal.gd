extends Area2D

func _ready() -> void:
	add_to_group("portal")
	body_entered.connect(_on_entity_entered)
	area_entered.connect(_on_entity_entered)

func _on_entity_entered(entity: Node2D) -> void:
	var player_node = _find_player_node(entity)

	if player_node:
		print("[DEBUG Portal] Player detected via ", entity.name, "! Triggering floor transition...")
		set_deferred("monitoring", false)
		
		# Defer the transition logic so it runs safely AFTER the physics step
		call_deferred("_change_floor", player_node)
	else:
		print("[DEBUG Portal] Ignored non-player contact.")

func _change_floor(player_node: Node2D) -> void:
	# 1. Save player inventory/stats before changing scenes
	GameManager.save_player_data(player_node)
	
	# 2. Hand everything over to the GameManager's load_next_floor logic
	GameManager.load_next_floor()

func _find_player_node(node: Node) -> Node2D: # (or leave your existing helper)
	if not node:
		return null
	if node.is_in_group("player"):
		return node as Node2D
	if node.get_parent() and node.get_parent().is_in_group("player"):
		return node.get_parent() as Node2D
	if node.owner and node.owner.is_in_group("player"):
		return node.owner as Node2D
	return null
