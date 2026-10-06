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
var can_move: bool = false
var last_stuck_check_pos: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var unstuck_vector: Vector2 = Vector2.ZERO
var unstuck_duration: float = 0.0
var external_pull_velocity: Vector2 = Vector2.ZERO

@onready var hurt_sfx: AudioStreamPlayer2D = get_node_or_null("HurtSFX")
@onready var dead_sfx: AudioStreamPlayer2D = get_node_or_null("DeadSFX")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_label: Label = $HPLabel
@onready var mutation_component: MutationComponent = $MutationComponent
@onready var separation_area: Area2D = $SeparationArea
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D  # Node alias for FSM compatibility
@onready var screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D")

var path_update_timer: float = 0.0

# --- LOOT DROP TESTING ---
@export var item_to_drop_scene: PackedScene
@export var possible_drops: Array[UpgradeData] = []

# --- LOOT & XP DROPS ---
@export var xp_orb_scene: PackedScene
@export var xp_drop_amount: int = 15
var is_dropping_items: bool = false

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if has_node("HitBox"):
		var hitbox = $HitBox as Area2D
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	can_move = false
	get_tree().create_timer(0.5).timeout.connect(func():
		can_move = true
	)

	await get_tree().physics_frame
	
	if nav_agent and nav_agent.has_signal("velocity_computed"):
		nav_agent.velocity_computed.connect(_on_velocity_computed)

	if animated_sprite and animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()

	# Duplicate & Setup Stats Safely
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()
		
		# Difficulty scaling per floor
		var floor_mult: float = 1.0 + ((GameManager.current_floor - 1) * 0.2)
		stats.current_max_health = int(stats.current_max_health * floor_mult)
		stats.current_attack = int(stats.current_attack * floor_mult)
		stats.health = stats.current_max_health
		
		if stats.health <= 0:
			stats.health = stats.current_max_health

		if not stats.health_depleted.is_connected(_on_health_depleted):
			stats.health_depleted.connect(_on_health_depleted)

		stats.health_changed.connect(_on_health_changed)
		_on_health_changed(stats.health, stats.current_max_health)

	if mutation_component:
		mutation_component.setup_mutation(self)

	if player and "is_time_stopped" in player and player.is_time_stopped:
		call_deferred("freeze_time")

	if screen_notifier:
		screen_notifier.screen_entered.connect(_on_screen_entered)
		screen_notifier.screen_exited.connect(_on_screen_exited)

	last_stuck_check_pos = global_position


func _physics_process(delta: float) -> void:
	if is_dead or is_frozen or not can_move:
		velocity = Vector2.ZERO
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if not player:
			return
	
	# --- 1. ANTI-STUCK LOGIC ---
	_process_anti_stuck(delta)

	# --- 2. NAVIGATION UPDATE ---
	path_update_timer += delta
	if path_update_timer >= 0.25:
		path_update_timer = 0.0
		if nav_agent:
			nav_agent.target_position = player.global_position

	# --- 3. MOVEMENT CALCULATIONS ---
	var desired_velocity = Vector2.ZERO

	if nav_agent and not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var move_direction = global_position.direction_to(next_path_pos)
		desired_velocity = move_direction * chase_speed
	else:
		var move_direction = global_position.direction_to(player.global_position)
		desired_velocity = move_direction * chase_speed

	desired_velocity += get_separation_vector() * separation_force

	if unstuck_duration > 0.0:
		unstuck_duration -= delta
		desired_velocity += unstuck_vector * unstuck_push_force

	# --- Whirlwind Pull Integration ---
	if external_pull_velocity != Vector2.ZERO:
		desired_velocity += external_pull_velocity
		external_pull_velocity = external_pull_velocity.move_toward(Vector2.ZERO, 600.0 * delta)

	# --- 4. APPLY VELOCITY ---
	if nav_agent and nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity
		_move_and_eject_walls()


func _process_anti_stuck(delta: float) -> void:
	stuck_timer += delta
	if stuck_timer >= stuck_check_interval:
		stuck_timer = 0.0
		var dist_moved = global_position.distance_to(last_stuck_check_pos)
		
		# If trying to move but trapped on geometry
		if dist_moved < min_moved_distance and velocity.length() > 5.0:
			var random_angle = randf() * TAU
			unstuck_vector = Vector2(cos(random_angle), sin(random_angle))
			unstuck_duration = 0.35
			
		last_stuck_check_pos = global_position


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
	for area in separation_area.get_overlapping_areas():
		if area != separation_area and area.owner is CharacterBody2D:
			push_dir += area.global_position.direction_to(global_position)

	return push_dir.normalized()


func _on_health_changed(cur_hp: int, max_hp: int) -> void:
	if hp_label:
		if cur_hp <= 0:
			hp_label.hide()
		else:
			hp_label.show()
			hp_label.text = str(cur_hp) + "/" + str(max_hp)


func _play_hurt_sound() -> void:
	if hurt_sfx and hurt_sfx.stream:
		hurt_sfx.pitch_scale = randf_range(0.85, 1.15)
		hurt_sfx.play()


func _dead_hurt_sound() -> void:
	if dead_sfx and dead_sfx.stream:
		remove_child(dead_sfx)
		get_tree().current_scene.add_child(dead_sfx)
		dead_sfx.global_position = global_position
		dead_sfx.pitch_scale = randf_range(0.9, 1.1)
		dead_sfx.play()
		dead_sfx.finished.connect(dead_sfx.queue_free)


func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dead:
		return
	
	_play_hurt_sound()
	
	if stats:
		var final_damage = max(1, amount - stats.current_defense)
		stats.health -= final_damage
		_spawn_damage_popup(final_damage, is_crit)

		# Safeguard: Direct death trigger if signal fails
		if stats.health <= 0:
			die()
			return

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
	
	remove_from_group("enemies")
	
	# --- NOTIFY SPAWNER OF KILL ---
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner and spawner.has_method("notify_enemy_killed"):
		spawner.notify_enemy_killed(global_position)

	_drop_random_item()
	_dead_hurt_sound()

	if has_node("FSM"):
		var fsm = $FSM
		if fsm.has_method("transition_to"):
			fsm.transition_to("die")
		elif fsm.has_method("change_state"):
			fsm.change_state("die")
		
		# Fallback cleanup timer in case FSM state fails to queue_free
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)
	else:
		queue_free()


func _spawn_portal() -> void:
	var portal_scene = load("res://portal.tscn")
	if portal_scene:
		var portal = portal_scene.instantiate() as Node2D
		portal.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", portal)


func _on_screen_entered() -> void:
	set_physics_process(true)
	if has_node("FSM"):
		$FSM.set_physics_process(true)
	if animated_sprite:
		animated_sprite.play()


func _on_screen_exited() -> void:
	# Keep physics active so enemies pathfind toward screen instead of freezing!
	if animated_sprite:
		animated_sprite.pause()


func _drop_random_item() -> void:
	if is_dropping_items:
		return
	is_dropping_items = true
	call_deferred("_spawn_dropped_item")


func _spawn_dropped_item() -> void:
	# 1. Spawn Item Upgrade
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

	# 2. Spawn XP Orb
	if xp_orb_scene:
		var xp_instance = xp_orb_scene.instantiate() as Node2D
		if xp_instance:
			xp_instance.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
			if "xp_value" in xp_instance:
				xp_instance.xp_value = xp_drop_amount
			get_tree().current_scene.add_child(xp_instance)


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


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var damage_to_deal = stats.current_attack if stats else 1
		body.take_damage(damage_to_deal)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		var damage_to_deal = stats.current_attack if stats else 1
		area.take_damage(damage_to_deal)


func apply_pull(pull_velocity: Vector2) -> void:
	external_pull_velocity = pull_velocity
