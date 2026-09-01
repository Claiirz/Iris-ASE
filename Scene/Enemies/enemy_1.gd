extends CharacterBody2D

# --- STATS RESOURCE ---
@export var stats: Stats

# --- MOVEMENT & DASH SETTINGS ---
@export var chase_speed: float = 30.0
@export var dash_speed: float = 125.0
@export var accel: float = 10.0
@export var dash_trigger_distance: float = 90.0
@export var dash_duration: float = 0.3
@export var telegraph_duration: float = 0.2

# --- LOOT DROPS ---
@export var dropped_sword_scene: PackedScene

# --- SEPARATION & COLLISION SETTINGS ---
@export var separation_force: float = 20.0
@export var enemy_collision_layer_bit: int = 3 # Physics Layer 3 for Enemies

# --- ANTI-STUCK SETTINGS ---
@export_group("Anti-Stuck")
@export var stuck_check_interval: float = 0.4  # Check position every 0.4 seconds
@export var min_moved_distance: float = 4.0    # Must move at least 4px per interval
@export var unstuck_push_force: float = 75.0   # Impulse force to break free

# --- STATE VARIABLES & NODE REFERENCES ---
var player: CharacterBody2D = null
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true
var is_dead: bool = false
var is_mutated: bool = false
var is_frozen: bool = false  # Keeps time-stop momentum locked at zero

var last_stuck_check_pos: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var unstuck_vector: Vector2 = Vector2.ZERO
var unstuck_duration: float = 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_label: Label = $HPLabel
@onready var mutation_component: MutationComponent = $MutationComponent
@onready var separation_area: Area2D = $SeparationArea
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D  # Node alias for FSM compatibility

# --- LOOT DROP TESTING ---
@export var item_to_drop_scene: PackedScene
@export var possible_drops: Array[UpgradeData] = [] # Drag Boots, Cutter, Gloves, Crowbar, Anvil here in Inspector

# --- LOOT & XP DROPS ---
@export var xp_orb_scene: PackedScene        # <-- Drag XpOrb.tscn here in Inspector
@export var xp_drop_amount: int = 15         # <-- How much XP this enemy gives
var is_dropping_items: bool = false # Guard flag to prevent double-spawning

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	#Wait 1 physics frame for NavigationServer to sync baked map data.
	await get_tree().physics_frame

	#Connect to avoidance signal for smooth pathfinding around objects.
	if nav_agent:
		nav_agent.velocity_computed.connect(_on_velocity_computed)

	#Unique material instance for hit-flash shader.
	if animated_sprite and animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()

	#Duplicate & Setup Stats Safely.
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


func _physics_process(delta: float) -> void:
	if is_dead or is_frozen:
		velocity = Vector2.ZERO
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if not player:
			return

	deal_contact_damage()

	# Navigation Pathfinding
	if nav_agent:
		nav_agent.target_position = player.global_position

		if not nav_agent.is_navigation_finished():
			var next_path_pos = nav_agent.get_next_path_position()
			var raw_direction = global_position.direction_to(next_path_pos)
			
			# 1. Base chase velocity
			var desired_velocity = raw_direction * chase_speed

			# 2. Add soft separation from nearby enemies
			desired_velocity += get_separation_vector() * separation_force

			# 3. Add Anti-Stuck Nudge Force if active
			if unstuck_duration > 0.0:
				unstuck_duration -= delta
				desired_velocity += unstuck_vector * unstuck_push_force

			if nav_agent.avoidance_enabled:
				nav_agent.set_velocity(desired_velocity)
			else:
				velocity = desired_velocity
				_move_and_eject_walls()


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


func execute_dash(target_direction: Vector2) -> void:
	if is_dead or is_frozen:
		return

	can_dash = false

	set_collision_mask_value(enemy_collision_layer_bit, false)

	velocity = target_direction * dash_speed
	_move_and_eject_walls()

	await get_tree().create_timer(dash_duration).timeout

	set_collision_mask_value(enemy_collision_layer_bit, true)

	await get_tree().create_timer(1.0).timeout
	can_dash = true


func get_safe_dash_direction(desired_dir: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var dash_distance = dash_speed * dash_duration

	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + (desired_dir * dash_distance),
		1 # Layer 1
	)
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)
	if result:
		var wall_normal = result.normal as Vector2
		return desired_dir.bounce(wall_normal).normalized()

	return desired_dir


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
	# 1. Create a Label dynamically via code
	var popup = Label.new()
	popup.text = str(amount) + ("!" if is_crit else "")
	
	# 2. Style the Label text and size using a unique LabelSettings resource
	var settings = LabelSettings.new()
	settings.font_size = 22 if is_crit else 16
	settings.font_color = Color.YELLOW if is_crit else Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	popup.label_settings = settings

	# 3. Position it slightly randomized above the enemy's head
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-15, 15), -25)

	# 4. Bind the tween to 'popup' so it survives enemy death
	var tween = popup.create_tween().set_parallel(true)
	tween.tween_property(popup, "global_position", popup.global_position + Vector2(randf_range(-20, 20), -40), 0.5)
	tween.tween_property(settings, "font_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(settings, "outline_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	# 5. Delete node when animation finishes to save memory
	await tween.finished
	popup.queue_free()


func deal_contact_damage() -> void:
	if not has_node("HitBox"):
		return

	var hitbox = $HitBox as Area2D
	var damage_to_deal = stats.current_attack if stats else 1

	# Detect Player Hurtbox (Area2D)
	for area in hitbox.get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage_to_deal)

	# Detect Player Body (CharacterBody2D)
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage_to_deal)


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
		if fsm.current_state and fsm.current_state.name.to_lower() == "die":
			return

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
	# Safe deferral to run after physics query flush finishes
	call_deferred("_spawn_dropped_item")

func _spawn_dropped_item() -> void:
	if not item_to_drop_scene:
		push_warning("Enemy Drop Warning: 'Item To Drop Scene' is missing in Inspector!")
		return
		
	if possible_drops.is_empty():
		push_warning("Enemy Drop Warning: 'Possible Drops' array is empty in Inspector!")
		return

	var item_instance = item_to_drop_scene.instantiate() as Node2D
	if not item_instance:
		return

	item_instance.global_position = global_position

	# Pick random upgrade resource
	var selected_drop: UpgradeData = possible_drops.pick_random()

	# Assign upgrade data to pickup
	if "upgrade_data" in item_instance:
		item_instance.upgrade_data = selected_drop
	elif "resource" in item_instance:
		item_instance.resource = selected_drop
	
	# 1. Spawn regular upgrade item if configured
	# 1. Spawn Regular Item Upgrade (Boots, Cutter, etc.) if assigned
	if item_to_drop_scene and not possible_drops.is_empty():
		
		if item_instance and item_instance.get_parent() == null:
			item_instance.global_position = global_position
			if "upgrade_data" in item_instance:
				item_instance.upgrade_data = selected_drop
			elif "resource" in item_instance:
				item_instance.resource = selected_drop
			get_tree().current_scene.add_child(item_instance)

	# 2. Spawn XP Orb if assigned
	if xp_orb_scene:
		var xp_instance = xp_orb_scene.instantiate() as Node2D
		if xp_instance and xp_instance.get_parent() == null:
			# Offset slightly so it doesn't overlap completely with the item drop
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
