extends Area2D

func _ready() -> void:
	print("[DEBUG Portal] Portal initialized at position: ", global_position)
	body_entered.connect(_on_entity_entered)
	area_entered.connect(_on_entity_entered)

func _on_entity_entered(entity: Node2D) -> void:
	var player_node = _find_player_node(entity)

	if player_node:
		print("[DEBUG Portal] Player detected via ", entity.name, "! Triggering floor transition...")
		set_deferred("monitoring", false)
		# 1. Save player inventory/stats before reloading scene
		GameManager.save_player_data(player_node)
		
			# 2. Advance floor and reload level
		if GameManager.current_floor < GameManager.max_floors:
			GameManager.current_floor += 1
			print("[DEBUG Portal] Advancing to Floor: ", GameManager.current_floor)
			get_tree().reload_current_scene()
		else:
			print("[DEBUG Portal] All Floors Cleared! Victory!")
			GameManager.reset_run()
			get_tree().reload_current_scene()
	else:
		# Log non-player collisions for debugging without taking action
		print("[DEBUG Portal] Ignored non-player contact: ", entity.name, " | Groups: ", entity.get_groups())

# Helper function to check if the entity or its parent belongs to the 'player' group
func _find_player_node(node: Node) -> Node2D:
	if not node:
		return null
	if node.is_in_group("player"):
		return node as Node2D
	if node.get_parent() and node.get_parent().is_in_group("player"):
		return node.get_parent() as Node2D
	if node.owner and node.owner.is_in_group("player"):
		return node.owner as Node2D
	return null
