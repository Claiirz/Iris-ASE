extends TextureProgressBar

func _ready() -> void:
	# Wait one frame to ensure the player and stats are fully loaded
	await get_tree().process_frame 
	
	# $".." grabs the parent of this node (which is your Player)
	var player = $".." 
	
	# Check if the parent has the stats variable
	if player and player.get("stats"):
		# Set initial values
		max_value = player.stats.current_max_health
		value = player.stats.health
		
		# Listen for the damage signal
		if not player.stats.health_changed.is_connected(_on_health_changed):
			player.stats.health_changed.connect(_on_health_changed)

func _on_health_changed(cur_health: int, new_max_health: int) -> void:
	max_value = new_max_health
	value = cur_health
