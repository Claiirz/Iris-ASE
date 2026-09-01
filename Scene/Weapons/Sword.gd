extends Node2D

@export var damage: int = 1
@export var sword_texture: Texture2D
@export var weapon_name: String = "Basic Sword"
@export var attack_speed: float = 1

@onready var hitbox: Area2D = $Hitbox
@onready var anim_player: AnimationPlayer = $AnimationPlayer # Ensure this path is correct

# Stores references to the ENEMY entities hit during this swing
var hit_entities: Array[Node] = []

func _ready() -> void:
	if hitbox:
		if not hitbox.area_entered.is_connected(_on_area_entered):
			hitbox.area_entered.connect(_on_area_entered)
		if not hitbox.body_entered.is_connected(_on_body_entered):
			hitbox.body_entered.connect(_on_body_entered)
	
	# 1. Initial sync
	apply_player_attack_speed()
	
	# 2. Connect to stats_changed to ensure updates whenever player stats change
	var player = get_parent()
	if player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if stats_comp.has_signal("stats_changed"):
			stats_comp.stats_changed.connect(apply_player_attack_speed)		


func _on_area_entered(area: Area2D) -> void:
	_process_hit(area)


func _on_body_entered(body: Node2D) -> void:
	_process_hit(body)


func _process_hit(node: Node) -> void:
	if node.is_in_group("player") or node == owner:
		return

	var entity: Node = node
	if not node.has_method("take_damage") and node.get_parent() and node.get_parent().has_method("take_damage"):
		entity = node.get_parent()

	if not entity.has_method("take_damage"):
		return

	if hit_entities.has(entity):
		return

	hit_entities.append(entity)

	# Calculate damage & check crit from Player's StatsComponent
	var damage_data = calculate_damage()
	
	# Pass damage and crit flag to enemy
	entity.take_damage(damage_data.damage, damage_data.is_crit)

func apply_player_attack_speed() -> void:
	# Use call_deferred to ensure we don't try to access nodes before they are ready
	call_deferred("_update_animation_speed")

func _update_animation_speed() -> void:
	var player = get_parent()
	var speed_multiplier: float = 1.0

	if player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		
		# Logic to calculate multiplier based on StatsComponent
		if "attack_cooldown" in stats_comp and stats_comp.attack_cooldown > 0:
			speed_multiplier = 1.0 / stats_comp.attack_cooldown
		elif "attack_speed" in stats_comp:
			speed_multiplier = stats_comp.attack_speed

	# Update the AnimationPlayer speed
	if anim_player:
		anim_player.speed_scale = attack_speed * speed_multiplier

func calculate_damage() -> Dictionary:
	var player = get_parent()
	var base_dmg: float = float(damage)
	var is_crit: bool = false

	# 1. Prioritize the curve-scaled attack power from your Stats resource!
	if player and player.get("stats") and player.stats:
		base_dmg = float(player.stats.current_attack)
	# Fallback to StatsComponent only if resource doesn't exist
	elif player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if "damage" in stats_comp:
			base_dmg = float(stats_comp.damage)

	# 2. Handle Crit calculation from StatsComponent safely
	if player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if "crit_rate" in stats_comp and "crit_damage" in stats_comp:
			if randf() < stats_comp.crit_rate:
				base_dmg *= stats_comp.crit_damage
				is_crit = true

	return {
		"damage": roundi(base_dmg),
		"is_crit": is_crit
	}

func reset_hit_targets() -> void:
	hit_entities.clear()
