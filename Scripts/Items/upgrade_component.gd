class_name UpgradeComponent
extends Node

signal stats_updated

var upgrade_stacks: Dictionary = {}
@onready var player: CharacterBody2D = owner as CharacterBody2D


func apply_upgrade(upgrade: UpgradeData) -> void:
	if not upgrade:
		return

	# Track stacks by upgrade type
	var item_type = upgrade.type
	upgrade_stacks[item_type] = upgrade_stacks.get(item_type, 0) + 1

	# Tell StatsComponent to recalculate final stats
	stats_updated.emit()

	# Sync visuals (sword attack speed animation)
	sync_player_visuals()


func get_stack_count(type: UpgradeData.UpgradeType) -> int:
	return upgrade_stacks.get(type, 0)


func get_multiplier(type: UpgradeData.UpgradeType, percent_per_stack: float) -> float:
	var stacks: int = get_stack_count(type)
	return 1.0 + (stacks * percent_per_stack)


func sync_player_visuals() -> void:
	if not player or not player.sword_animation_player:
		return

	if player.stats_component:
		var base_cd: float = player.stats_component.base_attack_cooldown
		var cur_cd: float = player.stats_component.attack_cooldown

		if cur_cd > 0:
			var speed_scale: float = base_cd / cur_cd
			if player.is_time_slowed and player.slow_time_scale > 0:
				speed_scale *= (1.0 / player.slow_time_scale)
			player.sword_animation_player.speed_scale = speed_scale
