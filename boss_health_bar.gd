extends TextureProgressBar

func _ready() -> void:
	# Hide the health bar until the boss actually spawns
	hide()

func setup_boss(boss_node: Node2D) -> void:
	if not boss_node.get("stats"):
		push_warning("BossHealthBar: The spawned boss has no Stats resource!")
		return

	# Show the health bar
	show()
	
	# Set initial HP values
	var stats = boss_node.stats
	max_value = stats.current_max_health
	value = stats.health
	
	if not stats.health_changed.is_connected(_on_boss_health_changed):
		stats.health_changed.connect(_on_boss_health_changed)
		
	if not stats.health_depleted.is_connected(_on_boss_died):
		stats.health_depleted.connect(_on_boss_died)

func _on_boss_health_changed(cur_hp: int, _max_hp: int) -> void:

	var tween = create_tween()
	tween.tween_property(self, "value", cur_hp, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_boss_died() -> void:
	hide()
