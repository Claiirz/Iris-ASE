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
		
		# FIX: Defer the transition logic so it runs safely AFTER the physics step
		call_deferred("_change_floor", player_node)
	else:
		print("[DEBUG Portal] Ignored non-player contact.")

# Moved the transition logic into its own safely-deferred function
func _change_floor(player_node: Node2D) -> void:
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
