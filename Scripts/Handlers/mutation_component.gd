extends Node
class_name MutationComponent

enum MutationType { FAST, STRONG, HEAVY, RUTHLESS }

@export var can_mutate: bool = true

@export_category("Mutation Spawn Rates")
@export var base_mutation_chance: float = 0.3 # 30% chance on Floor 1
@export var chance_increase_per_floor: float = 0.1 # +10% per floor

@export_category("Floor Scaling Strength")
@export var stat_scaling_per_floor: float = 0.10 # +10% HP and Attack per floor
@export var speed_scaling_per_floor: float = 0.03 # +3% Speed per floor (kept low to prevent physics clipping)
@export var size_scaling_per_floor: float = 0.02 # +2% Size per floor (kept low to prevent getting stuck in walls)

var is_mutated: bool = false
var current_mutation: MutationType


# Pass the current floor_level from your enemy spawner or Game Manager
func setup_mutation(enemy: CharacterBody2D, floor_level: int = 1, forced_type: int = -1) -> void:
	if not can_mutate:
		return

	# Calculate dynamic spawn chance (+10% for every floor past the 1st)
	var current_chance = base_mutation_chance + (chance_increase_per_floor * (floor_level - 1))
	
	# Clamp to 1.0 (100%) so the math doesn't break on extreme high floors
	current_chance = clampf(current_chance, 0.0, 1.0)

	# Roll for mutation chance (or apply if forced)
	if forced_type >= 0 or randf() <= current_chance:
		apply_mutation(enemy, floor_level, forced_type)


func apply_mutation(enemy: CharacterBody2D, floor_level: int = 1, forced_type: int = -1) -> void:
	is_mutated = true

	# Pick random type or use specified override
	if forced_type >= 0 and forced_type < MutationType.size():
		current_mutation = forced_type as MutationType
	else:
		current_mutation = randi() % MutationType.size() as MutationType

	var atk_mult: float = 1.0
	var speed_mult: float = 1.0
	var hp_mult: float = 1.25
	var scale_mult: float = 1.0
	var tint_color: Color = Color.WHITE

	# 1. Base Profile definitions
	match current_mutation:
		MutationType.FAST:
			speed_mult = 1.6
			atk_mult = 0.75
			scale_mult = 0.95
			tint_color = Color(0.4, 1.8, 2.5) # Electric Cyan

		MutationType.STRONG:
			speed_mult = 1.0
			atk_mult = 1.6
			hp_mult = 1.5
			scale_mult = 1.25
			tint_color = Color(2.5, 0.4, 0.4) # Crimson Red

		MutationType.HEAVY:
			speed_mult = 0.65
			atk_mult = 2.2
			hp_mult = 2.0
			scale_mult = 1.45
			tint_color = Color(1.8, 1.2, 0.4) # Bronze Gold

		MutationType.RUTHLESS:
			speed_mult = 1.8
			atk_mult = 1.4
			hp_mult = 1.35
			scale_mult = 1.15
			tint_color = Color(1.8, 0.3, 2.5) # Cosmic Purple

	# 2. Apply Floor Scaling Enhancements
	var floors_cleared = floor_level - 1
	
	# Add the extra strength to the base multipliers
	atk_mult += (stat_scaling_per_floor * floors_cleared)
	hp_mult += (stat_scaling_per_floor * floors_cleared)
	speed_mult += (speed_scaling_per_floor * floors_cleared)
	scale_mult += (size_scaling_per_floor * floors_cleared)

	# 3. Update Stats Resource
	if enemy.stats:
		enemy.stats.base_attack = int(enemy.stats.base_attack * atk_mult)
		enemy.stats.base_max_health = int(enemy.stats.base_max_health * hp_mult)
		enemy.stats.recalculate_stats()
		enemy.stats.health = enemy.stats.current_max_health

	# 4. Update Movement Speeds (Safely handles different enemy variable names)
	if "chase_speed" in enemy:
		enemy.chase_speed *= speed_mult
	if "dash_speed" in enemy:
		enemy.dash_speed *= speed_mult
	if "max_speed" in enemy:
		enemy.max_speed *= speed_mult

	# 5. Update Visuals
	enemy.scale *= scale_mult
	if enemy.animated_sprite:
		enemy.animated_sprite.modulate = tint_color
