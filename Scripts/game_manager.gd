extends Node

var current_floor: int = 1
var max_floors: int = 10

var saved_player_data: Dictionary = {}
var has_saved_data: bool = false

func save_player_data(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return

	saved_player_data.clear()

	# 1. Save Stats Resource attributes
	if player.stats:
		saved_player_data["level"] = player.stats.level
		saved_player_data["experience"] = player.stats.experience
		saved_player_data["health"] = player.stats.health
		saved_player_data["current_attack"] = player.stats.current_attack
		saved_player_data["current_defense"] = player.stats.current_defense

	# 2. Save Ammo
	saved_player_data["current_arrows"] = player.current_arrows
	saved_player_data["max_arrows"] = player.max_arrows

	# 3. Save Equipped Sword Scene Path
	if player.equipped_sword_scene and player.equipped_sword_scene.resource_path != "":
		saved_player_data["equipped_sword_path"] = player.equipped_sword_scene.resource_path

	# 4. Save Upgrade Component Stacks (Items / Upgrades)
	if player.upgrade_component:
		saved_player_data["upgrade_stacks"] = player.upgrade_component.upgrade_stacks.duplicate(true)

	has_saved_data = true
	print("[DEBUG GameManager] Player stats, items, ammo, and weapon saved successfully!")

func restore_player_data(player: CharacterBody2D) -> void:
	if not has_saved_data or not is_instance_valid(player):
		return

	# 1. Restore Stats Resource
	if player.stats:
		if "level" in saved_player_data: player.stats.level = saved_player_data["level"]
		if "experience" in saved_player_data: player.stats.experience = saved_player_data["experience"]
		if "health" in saved_player_data: player.stats.health = saved_player_data["health"]
		if "current_attack" in saved_player_data: player.stats.current_attack = saved_player_data["current_attack"]
		if "current_defense" in saved_player_data: player.stats.current_defense = saved_player_data["current_defense"]

	# 2. Restore Ammo
	if "current_arrows" in saved_player_data:
		player.current_arrows = saved_player_data["current_arrows"]

	# 3. Restore Equipped Sword Scene
	if "equipped_sword_path" in saved_player_data and saved_player_data["equipped_sword_path"] != "":
		var sword_res = load(saved_player_data["equipped_sword_path"]) as PackedScene
		if sword_res:
			player.equipped_sword_scene = sword_res

	# 4. Restore Upgrade Component Stacks & Recalculate Component Stats
	if player.upgrade_component and "upgrade_stacks" in saved_player_data:
		player.upgrade_component.set_upgrade_stacks(saved_player_data["upgrade_stacks"])

	print("[DEBUG GameManager] Player stats and items restored on Floor ", current_floor)

func reset_run() -> void:
	current_floor = 1
	has_saved_data = false
	saved_player_data.clear()
	print("[DEBUG GameManager] Run reset! Starting fresh on Floor 1.")
