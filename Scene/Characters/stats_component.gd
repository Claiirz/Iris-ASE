class_name StatsComponent
extends Node

signal stats_changed

# --- BASE STATS ---
@export_group("Base Movement & Attack")
@export var base_move_speed: float = 100.0
@export var base_damage: int = 10
@export var base_attack_cooldown: float = 1.0

@export_group("Base Criticals")
@export var base_crit_rate: float = 0.05   # 5% base
@export var base_crit_damage: float = 1.5  # 150% base

# --- CALCULATED FINAL STATS ---
var move_speed: float
var damage: int
var attack_cooldown: float
var crit_rate: float
var crit_damage: float

var upgrade_component: UpgradeComponent = null


func setup(upgrades: UpgradeComponent) -> void:
	upgrade_component = upgrades
	if upgrade_component:
		upgrade_component.stats_updated.connect(recalculate_stats)

	recalculate_stats()


func recalculate_stats() -> void:
	if not upgrade_component:
		_apply_default_stats()
		return

	# 1. Boots (Speed - 5% per stack)
	var speed_mult = upgrade_component.get_multiplier(UpgradeData.UpgradeType.SPEED, 0.05)
	move_speed = base_move_speed * speed_mult

	# 2. Cutter (Base Damage - 5% per stack)
	var damage_mult = upgrade_component.get_multiplier(UpgradeData.UpgradeType.DAMAGE, 0.05)
	damage = roundi(base_damage * damage_mult)

	# 3. Gloves (Attack Speed - 5% per stack)
	var atk_speed_mult = upgrade_component.get_multiplier(UpgradeData.UpgradeType.ATTACK_SPEED, 0.05)
	attack_cooldown = base_attack_cooldown / atk_speed_mult

	# 4. Crowbar (Crit Rate - 2% per stack)
	var crowbar_stacks = upgrade_component.get_stack_count(UpgradeData.UpgradeType.CRIT_RATE)
	crit_rate = base_crit_rate + (crowbar_stacks * 0.02)

	# 5. Anvil (Crit Damage - 5% per stack)
	var anvil_stacks = upgrade_component.get_stack_count(UpgradeData.UpgradeType.CRIT_DAMAGE)
	crit_damage = base_crit_damage + (anvil_stacks * 0.05)

	stats_changed.emit()


func _apply_default_stats() -> void:
	move_speed = base_move_speed
	damage = base_damage
	attack_cooldown = base_attack_cooldown
	crit_rate = base_crit_rate
	crit_damage = base_crit_damage


# Calculates hit damage and determines if hit was critical
func calculate_attack_damage() -> Dictionary:
	var is_crit: bool = randf() <= crit_rate
	var final_damage: int = damage

	if is_crit:
		final_damage = roundi(damage * crit_damage)

	return {
		"damage": final_damage,
		"is_crit": is_crit
	}
