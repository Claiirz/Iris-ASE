extends Node

var current_floor: int = 1
var max_floors: int = 2 

var saved_player_data: Dictionary = {}
var has_saved_data: bool = false

var difficulty_level: String = "Normal"
var difficulty_multiplier: float = 1.0 

var saved_upgrade_resources: Dictionary = {}

func load_next_floor() -> void:
	current_floor += 1
	
	if current_floor >= 3:
		get_tree().change_scene_to_file("res://Scene/space_cutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://Scene/Test Scenes/game1.tscn")


func save_player_data(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return

	saved_player_data.clear()

	if player.stats:
		saved_player_data["level"] = player.stats.level
		saved_player_data["experience"] = player.stats.experience
		saved_player_data["health"] = player.stats.health
		saved_player_data["current_attack"] = player.stats.current_attack
		saved_player_data["current_defense"] = player.stats.current_defense

	saved_player_data["current_arrows"] = player.current_arrows
	saved_player_data["max_arrows"] = player.max_arrows

	if player.equipped_sword_scene and player.equipped_sword_scene.resource_path != "":
		saved_player_data["equipped_sword_path"] = player.equipped_sword_scene.resource_path

	if player.upgrade_component:
		saved_player_data["upgrade_stacks"] = player.upgrade_component.upgrade_stacks.duplicate(true)

	has_saved_data = true
	print("[DEBUG GameManager] Player stats, items, ammo, and weapon saved successfully!")
	
	if player.has_node("UpgradeComponent"):
		saved_upgrade_resources = player.get_node("UpgradeComponent").upgrade_resources.duplicate()

func restore_player_data(player: CharacterBody2D) -> void:
	if not has_saved_data or not is_instance_valid(player):
		return

	if player.stats:
		if "level" in saved_player_data: player.stats.level = saved_player_data["level"]
		if "experience" in saved_player_data: player.stats.experience = saved_player_data["experience"]
		if "health" in saved_player_data: player.stats.health = saved_player_data["health"]
		if "current_attack" in saved_player_data: player.stats.current_attack = saved_player_data["current_attack"]
		if "current_defense" in saved_player_data: player.stats.current_defense = saved_player_data["current_defense"]

	if "current_arrows" in saved_player_data:
		player.current_arrows = saved_player_data["current_arrows"]

	if "equipped_sword_path" in saved_player_data and saved_player_data["equipped_sword_path"] != "":
		var sword_res = load(saved_player_data["equipped_sword_path"]) as PackedScene
		if sword_res:
			player.equipped_sword_scene = sword_res

	if player.upgrade_component and "upgrade_stacks" in saved_player_data:
		player.upgrade_component.set_upgrade_stacks(saved_player_data["upgrade_stacks"])

	print("[DEBUG GameManager] Player stats and items restored on Floor ", current_floor)
	
	if player.has_node("UpgradeComponent") and not saved_upgrade_resources.is_empty():
		player.get_node("UpgradeComponent").upgrade_resources = saved_upgrade_resources.duplicate()

func reset_run() -> void:
	current_floor = 1
	has_saved_data = false
	saved_player_data.clear()
	saved_upgrade_resources.clear()
	print("[DEBUG GameManager] Run reset! Starting fresh on Floor 1.")
