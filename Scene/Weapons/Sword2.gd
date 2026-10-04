extends Node2D

@export var damage: int = 5
@export var sword_texture: Texture2D
@export var weapon_name: String = "Ruby Sword"
@export var attack_speed: float = 1

@onready var hitbox: Area2D = $Hitbox
@onready var anim_player: AnimationPlayer = $AnimationPlayer 
# To this (safe optional lookup):
@onready var combo_timer: Timer = get_node_or_null("ComboTimer")

# --- COMBO VARIABLES ---
var combo_step: int = 1
var is_attacking: bool = false

# Stores references to the ENEMY entities hit during this swing
var hit_entities: Array[Node] = []

func _ready() -> void:
	if hitbox:
		if not hitbox.area_entered.is_connected(_on_area_entered):
			hitbox.area_entered.connect(_on_area_entered)
		if not hitbox.body_entered.is_connected(_on_body_entered):
			hitbox.body_entered.connect(_on_body_entered)
	
	# Connect the Timer node's timeout signal to reset the combo
	if combo_timer:
		if not combo_timer.timeout.is_connected(_on_combo_timeout):
			combo_timer.timeout.connect(_on_combo_timeout)

	# 1. Initial sync
	apply_player_attack_speed()
	
	# 2. Connect to stats_changed to ensure updates whenever player stats change
	var player = get_parent()
	if player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if stats_comp.has_signal("stats_changed"):
			stats_comp.stats_changed.connect(apply_player_attack_speed)		


# --- COMBO ATTACK TRIGGER ---
# --- COMBO ATTACK TRIGGER ---
func trigger_attack() -> void:
	if is_attacking:
		return 

	is_attacking = true
	
	if combo_timer:
		combo_timer.stop() 

	# Play the correct animation based on the current combo step
	match combo_step:
		1:
			anim_player.play("sw1_1") # Slash Up
		2:
			anim_player.play("sw1_2") # Slash Down
		3:
			anim_player.play("sw1_3") # Spin

	# Wait for the current animation to finish playing
	await anim_player.animation_finished

	reset_hit_targets()

	# Advance combo step, loop back to 1 after the 3rd hit
	combo_step += 1
	if combo_step > 3:
		combo_step = 1
		
# --- RESET POSITION AFTER 3RD HIT FINISHES (WITH SMOOTH BLEND) ---
		if anim_player.has_animation("default"):
			anim_player.play("default", 0.15) # Added 0.15 blend to prevent snapping
		elif anim_player.has_animation("RESET"):
			anim_player.play("RESET", 0.15)

	is_attacking = false
	
	if combo_timer:
		combo_timer.start() 


func _on_combo_timeout() -> void:
	# If the player waits too long, reset the combo back to hit #1 and go back to default position
	combo_step = 1
	
	if not is_attacking:
		if anim_player.has_animation("default"):
			anim_player.play("default", 0.15) # Smooth cross-fade on timeout
		elif anim_player.has_animation("RESET"):
			anim_player.play("RESET", 0.15)


# --- HIT PROCESSING & STATS (Your Existing Code) ---
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

	var damage_data = calculate_damage()
	entity.take_damage(damage_data.damage, damage_data.is_crit)


func apply_player_attack_speed() -> void:
	call_deferred("_update_animation_speed")


func _update_animation_speed() -> void:
	var player = get_parent()
	var speed_multiplier: float = 1.0

	if player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if "attack_cooldown" in stats_comp and stats_comp.attack_cooldown > 0:
			speed_multiplier = 1.0 / stats_comp.attack_cooldown
		elif "attack_speed" in stats_comp:
			speed_multiplier = stats_comp.attack_speed

	if anim_player:
		anim_player.speed_scale = attack_speed * speed_multiplier


func calculate_damage() -> Dictionary:
	var player = get_parent()
	var base_dmg: float = float(damage)
	var is_crit: bool = false

	if player and player.get("stats") and player.stats:
		base_dmg = float(player.stats.current_attack)
	elif player and player.has_node("StatsComponent"):
		var stats_comp = player.get_node("StatsComponent")
		if "damage" in stats_comp:
			base_dmg = float(stats_comp.damage)

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

# --- EXCLUSIVE WEAPON SKILL (Whirlwind) ---
@export var whirlwind_scene: PackedScene # Drag whirlwind.tscn here in the Inspector

func use_skill() -> void:
	if not whirlwind_scene:
		push_warning("Ruby Sword Skill Warning: Whirlwind scene is missing in Inspector!")
		return

	var whirlwind = whirlwind_scene.instantiate() as Node2D
	# Spawn at the mouse's global screen position
	whirlwind.global_position = get_global_mouse_position()
	get_tree().current_scene.add_child(whirlwind)

func reset_hit_targets() -> void:
	hit_entities.clear()
