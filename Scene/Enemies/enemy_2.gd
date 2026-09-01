class_name Enemy2
extends CharacterBody2D

# --- STATS RESOURCE ---
@export var stats: Stats

# --- MOVEMENT & COMBAT SETTINGS ---
@export var chase_speed: float = 65.0
@export var accel: float = 10.0
@export var shoot_range: float = 280.0
@export var chase_range: float = 500.0

# --- LOOT DROPS ---
@export var dropped_sword_scene: PackedScene

# --- SEPARATION & COLLISION SETTINGS ---
@export var separation_force: float = 20.0
@export var enemy_collision_layer_bit: int = 3 # Physics Layer 3 for Enemies

# --- STATE VARIABLES & NODE REFERENCES ---
var player: CharacterBody2D = null
var is_dead: bool = false
var is_mutated: bool = false
var is_frozen: bool = false # Keeps time-stop momentum locked at zero

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_label: Label = $HPLabel
@onready var mutation_component: MutationComponent = $MutationComponent
@onready var separation_area: Area2D = $SeparationArea
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D # Node alias for FSM compatibility

# --- LOOT DROP TESTING ---
@export var item_to_drop_scene: PackedScene
@export var possible_drops: Array[UpgradeData] = [] # Drag upgrades here in Inspector

# --- LOOT & XP DROPS ---
@export var xp_orb_scene: PackedScene         # Drag XpOrb.tscn here in Inspector
@export var xp_drop_amount: int = 15          # XP given on death
var is_dropping_items: bool = false           # Guard flag to prevent double-spawning

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	# Wait 1 physics frame for NavigationServer to sync baked map data.
	await get_tree().physics_frame

	# Connect to avoidance signal for smooth pathfinding around objects.
	# if nav_agent:
	# 	nav_agent.velocity_computed.connect(_on_velocity_computed)

	# Unique material instance for hit-flash shader.
	if animated_sprite and animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()

	# Duplicate & Setup Stats Safely.
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()

		# Safeguard: Ensure health isn't zero on spawn
		if stats.health <= 0:
			stats.health = stats.current_max_health

		if not stats.health_depleted.is_connected(_on_health_depleted):
			stats.health_depleted.connect(_on_health_depleted)

		stats.health_changed.connect(_on_health_changed)
		_on_health_changed(stats.health, stats.current_max_health)

	# Trigger Mutation via external component
	if mutation_component:
		mutation_component.setup_mutation(self)

	# Check if spawned while Time Stop is active
	if player and "is_time_stopped" in player and player.is_time_stopped:
		call_deferred("freeze_time")


func _physics_process(_delta: float) -> void:
	if is_dead or is_frozen:
		velocity = Vector2.ZERO
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead or is_frozen:
		velocity = Vector2.ZERO
		return

	velocity = safe_velocity
	_move_and_eject_walls()


func _move_and_eject_walls() -> void:
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer:
			global_position += collision.get_normal() * 2.0


func get_separation_vector() -> Vector2:
	if not separation_area:
		return Vector2.ZERO

	var push_dir = Vector2.ZERO
	var overlapping_areas = separation_area.get_overlapping_areas()

	for area in overlapping_areas:
		if area != separation_area and area.owner is CharacterBody2D:
			var overlap_pos = area.global_position
			push_dir += overlap_pos.direction_to(global_position)

	return push_dir.normalized()


func _on_health_changed(cur_hp: int, max_hp: int) -> void:
	if hp_label:
		if cur_hp <= 0:
			hp_label.hide()
		else:
			hp_label.show()
			hp_label.text = str(cur_hp) + "/" + str(max_hp)


func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dead:
		return

	if stats:
		var final_damage = max(1, amount - stats.current_defense)
		stats.health -= final_damage
		
		# Spawn damage indicator popup
		_spawn_damage_popup(final_damage, is_crit)

	if animated_sprite:
		var sprite_material = animated_sprite.material as ShaderMaterial
		if sprite_material:
			sprite_material.set_shader_parameter("flash", true)
			get_tree().create_timer(0.1, true, false, true).timeout.connect(func():
				if is_instance_valid(sprite_material):
					sprite_material.set_shader_parameter("flash", false)
			)


func _spawn_damage_popup(amount: int, is_crit: bool) -> void:
	var popup = Label.new()
	popup.text = str(amount) + ("!" if is_crit else "")
	
	var settings = LabelSettings.new()
	settings.font_size = 22 if is_crit else 16
	settings.font_color = Color.YELLOW if is_crit else Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	popup.label_settings = settings

	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-15, 15), -25)

	var tween = popup.create_tween().set_parallel(true)
	tween.tween_property(popup, "global_position", popup.global_position + Vector2(randf_range(-20, 20), -40), 0.5)
	tween.tween_property(settings, "font_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(settings, "outline_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	await tween.finished
	popup.queue_free()


func _on_health_depleted() -> void:
	die()


func die() -> void:
	if is_dead:
		return

	is_dead = true

	# Drop item on death
	_drop_random_item()

	if has_node("FSM"):
		var fsm = $FSM
		if fsm.has_method("transition_to"):
			fsm.transition_to("die")
		elif fsm.has_method("change_state"):
			fsm.change_state("die")
	else:
		queue_free()


func _drop_random_item() -> void:
	if is_dropping_items:
		return
	is_dropping_items = true
	call_deferred("_spawn_dropped_item")

func _spawn_dropped_item() -> void:
	if item_to_drop_scene and not possible_drops.is_empty():
		var item_instance = item_to_drop_scene.instantiate() as Node2D
		if item_instance:
			item_instance.global_position = global_position
			var selected_drop: UpgradeData = possible_drops.pick_random()
			if "upgrade_data" in item_instance:
				item_instance.upgrade_data = selected_drop
			elif "resource" in item_instance:
				item_instance.resource = selected_drop
			get_tree().current_scene.add_child(item_instance)

	if xp_orb_scene:
		var xp_instance = xp_orb_scene.instantiate() as Node2D
		if xp_instance:
			xp_instance.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
			if "xp_value" in xp_instance:
				xp_instance.xp_value = xp_drop_amount
			get_tree().current_scene.add_child(xp_instance)


# --- TIME STOP SUPPORT (Skill 3) ---
func freeze_time() -> void:
	is_frozen = true
	velocity = Vector2.ZERO

	if nav_agent and nav_agent.avoidance_enabled:
		nav_agent.set_velocity(Vector2.ZERO)

	set_physics_process(false)

	if animated_sprite:
		animated_sprite.pause()

	if has_node("FSM"):
		$FSM.set_physics_process(false)


func unfreeze_time() -> void:
	if is_dead:
		return

	is_frozen = false
	set_physics_process(true)

	if animated_sprite:
		animated_sprite.play()

	if has_node("FSM"):
		$FSM.set_physics_process(true)
