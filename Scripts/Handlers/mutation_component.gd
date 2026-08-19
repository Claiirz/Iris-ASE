extends Node
class_name MutationComponent

enum MutationType { FAST, STRONG, HEAVY, RUTHLESS }

@export var can_mutate: bool = true
@export var mutation_chance: float = 0.3 # 30% chance to spawn as elite

var is_mutated: bool = false
var current_mutation: MutationType


func setup_mutation(enemy: CharacterBody2D, forced_type: int = -1) -> void:
	if not can_mutate:
		return

	# Roll for mutation chance (or apply if forced)
	if forced_type >= 0 or randf() <= mutation_chance:
		apply_mutation(enemy, forced_type)


func apply_mutation(enemy: CharacterBody2D, forced_type: int = -1) -> void:
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

	# Profile definitions
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

	# 1. Update Stats Resource
	if enemy.stats:
		enemy.stats.base_attack = int(enemy.stats.base_attack * atk_mult)
		enemy.stats.base_max_health = int(enemy.stats.base_max_health * hp_mult)
		enemy.stats.recalculate_stats()
		enemy.stats.health = enemy.stats.current_max_health

	# 2. Update Movement Speeds (Safely handles different enemy variable names)
	if "chase_speed" in enemy:
		enemy.chase_speed *= speed_mult
	if "dash_speed" in enemy:
		enemy.dash_speed *= speed_mult
	if "max_speed" in enemy:
		enemy.max_speed *= speed_mult

	# 3. Update Visuals
	enemy.scale *= scale_mult
	if enemy.animated_sprite:
		enemy.animated_sprite.modulate = tint_color
