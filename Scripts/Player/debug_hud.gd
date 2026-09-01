extends Control

@onready var label: Label = $Label # Change path if your label is named differently
var player: CharacterBody2D = null

func _ready() -> void:
	# Ensure it renders above everything else
	z_index = 100

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if not player:
			return

	# Retrieve stats component references safely
	var stats_comp = player.get_node_or_null("StatsComponent")
	
	# Fallbacks for Level/Exp/Attack from player stats resource
	var current_lvl = 1
	var current_exp = 0
	var atk_dmg: int = 1
	
	if player.get("stats") and player.stats:
		current_lvl = player.stats.level
		current_exp = player.stats.experience
		atk_dmg = player.stats.current_attack # <--- Pulls scaled attack from resource!
	
	# Get final calculated movement speed
	var speed: float = player.get_current_move_speed() if player.has_method("get_current_move_speed") else player.max_speed

	# Default fallback values for other stats
	var crit_rate: float = 0.0
	var crit_dmg: float = 150.0
	var atk_cooldown: float = 1.0

	# Pull secondary stats (like crit and cooldown) from StatsComponent if it exists
	if stats_comp:
		if "crit_rate" in stats_comp: crit_rate = stats_comp.crit_rate * 100.0   # Convert to percentage
		if "crit_damage" in stats_comp: crit_dmg = stats_comp.crit_damage * 100.0 # Convert to percentage
		if "attack_cooldown" in stats_comp: atk_cooldown = stats_comp.attack_cooldown

	# Calculate Attack Speed factor (inverse of cooldown)
	var atk_speed: float = 1.0 / atk_cooldown if atk_cooldown > 0 else 1.0

	# Format and display text
	label.text = """--- DEBUG STATS ---
Level: %d
EXP: %d
Speed: %.1f
Atk Damage: %d
Attack Speed: %.2f (CD: %.2fs)
Crit Rate: %.1f%%
Crit Damage: %.1f%%
""" % [
		current_lvl, # Fixed: changed from player_level to current_lvl
		current_exp, 
		speed, 
		atk_dmg, 
		atk_speed, 
		atk_cooldown, 
		crit_rate, 
		crit_dmg
	]
