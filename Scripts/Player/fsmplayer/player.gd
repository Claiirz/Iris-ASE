extends CharacterBody2D

# --- Constants (Clean visual management) ---
const COLOR_NORMAL = Color.WHITE
const COLOR_BUFF = Color(2.0, 1.8, 0.4)
const COLOR_SLOW = Color(0.4, 1.8, 2.5)
const COLOR_STOP = Color(1.2, 0.3, 2.5)
const COLOR_DEAD = Color.RED

@export var stats: Stats
@export var max_speed: float = 100.0
@export var acceleration: float = 2000.0
@export var friction: float = 3000.0

# --- Dodge / Speed Boost Settings ---
@export var dodge_speed_multiplier: float = 2.0
@export var dodge_duration: float = 0.25
@export var dodge_cooldown: float = 1.0

var is_dodging: bool = false
var can_dodge: bool = true
var dodge_dir: Vector2 = Vector2.RIGHT

# --- Skill 1: Self-Buff Settings ---
@export var buff_duration: float = 5.0
@export var buff_cooldown: float = 10.0
@export var attack_buff_flat: int = 2
@export var attack_speed_multiplier: float = 1.5

var is_buffed: bool = false
var can_use_skill_1: bool = true
var base_attack_speed: float = 1.0

# --- Skill 2: Time Slow Settings ---
@export var skill_2_duration: float = 3.0
@export var skill_2_cooldown: float = 12.0
@export var slow_time_scale: float = 0.3

var is_time_slowed: bool = false
var can_use_skill_2: bool = true

# --- Skill 3: Time Stop Settings ---
@export var skill_3_duration: float = 3.0
@export var skill_3_cooldown: float = 15.0
var is_time_stopped: bool = false
var can_use_skill_3: bool = true

# --- Invincibility & Death Settings ---
@export var invincibility_time: float = 0.2
var is_invulnerable: bool = false
var is_dead: bool = false

# --- Nodes ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fsm: FiniteStateMachine = $FSM
@onready var sword: Node2D = $Sword
@onready var sword_animation_player: AnimationPlayer = $Sword/AnimationPlayer
@onready var hp_label: Label = $HPLabel
@onready var stats_component: StatsComponent = $StatsComponent
@onready var upgrade_component: UpgradeComponent = $UpgradeComponent
@onready var attack_timer: Timer = $AttackTimer

# --- Arrow & Bow Settings ---
@export var arrow_scene: PackedScene
@export var max_arrows: int = 5
@export var ammo_ui: CanvasLayer
var current_arrows: int

@export var dropped_sword_scene: PackedScene
@export var default_sword_scene: PackedScene
var equipped_sword_scene: PackedScene

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player")
	
	current_arrows = max_arrows
	equipped_sword_scene = default_sword_scene
	update_ui()

	if stats_component and upgrade_component:
		stats_component.setup(upgrade_component)
		stats_component.stats_changed.connect(_on_stats_changed)
		_on_stats_changed()

	if attack_timer and stats_component:
		attack_timer.wait_time = stats_component.attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	if stats:
		stats = stats.duplicate()
		stats.setup_stats()
		stats.health_changed.connect(_on_health_changed)
		stats.health_depleted.connect(die)
		_on_health_changed(stats.health, stats.current_max_health)

	if animated_sprite and animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()

	if fsm:
		fsm.init(self)

	_update_sword_speed()
	
func add_xp(amount: int) -> void:
	if stats:
		var old_level: int = stats.level
		stats.experience += amount
		
		print("Gained XP: ", amount, " | Total XP: ", stats.experience, " | Level: ", stats.level)
		
		# Check if leveling up occurred
		if stats.level > old_level:
			print("LEVEL UP! Reached Level: ", stats.level)
			# Fully restore health on level up as a reward
			stats.health = stats.current_max_health

func _unhandled_input(event: InputEvent) -> void:
	if is_dead: return

	# Unified Input Handling
	if event.is_action_pressed("attack"): trigger_attack()
	elif event.is_action_pressed("shoot"): shoot_arrow()
	elif event.is_action_pressed("dodge") and can_dodge and not is_dodging: _start_dodge()
	elif event.is_action_pressed("skill_1") and can_use_skill_1: activate_buff_skill()
	elif event.is_action_pressed("skill_2") and can_use_skill_2: activate_time_slow_skill()
	elif event.is_action_pressed("skill_3") and can_use_skill_3: activate_time_stop_skill()

func _physics_process(delta: float) -> void:
	if is_dead: return

	look_at_mouse()

	var input_direction := Input.get_vector("left", "right", "up", "down")
	var target_speed := get_current_move_speed()

	if is_dodging:
		velocity = dodge_dir * (target_speed * dodge_speed_multiplier)
	else:
		if input_direction != Vector2.ZERO:
			velocity = input_direction.normalized() * target_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, get_current_friction() * delta)
		
		# Cap speed efficiently
		velocity = velocity.limit_length(target_speed)

	if fsm:
		fsm.physics_update(delta)

	move_and_slide()
	_update_animations(input_direction)

# --- Dynamic Stat Getters (Prevents Base Variable Mutation) ---
func get_current_move_speed() -> float:
	if max_speed <= 0: 
		return 0.0

	# Default to max_speed, but allow stats_component to exceed it when buffed by items
	var spd: float = max_speed
	if stats_component and stats_component.move_speed > 0:
		spd = stats_component.move_speed

	# Apply time-slow boost dynamically
	if is_time_slowed and slow_time_scale > 0:
		spd *= (1.0 / slow_time_scale)

	return spd

func get_current_friction() -> float:
	var multiplier = (1.0 / slow_time_scale) if is_time_slowed else 1.0
	return friction * (multiplier * multiplier)

# --- Dodge Logic ---
func _start_dodge() -> void:
	is_dodging = true
	can_dodge = false
	is_invulnerable = true

	var input_dir := Input.get_vector("left", "right", "up", "down")
	dodge_dir = input_dir.normalized() if input_dir else (Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT)
	animated_sprite.modulate.a = 0.5

	if fsm and fsm.has_method("change_state"):
		fsm.change_state("Dodge" if fsm.has_node("Dodge") else "dodge")

	get_tree().create_timer(dodge_duration, false).timeout.connect(_end_dodge)
	get_tree().create_timer(dodge_cooldown, false).timeout.connect(func(): can_dodge = true)

func _end_dodge() -> void:
	if not is_dodging: return
	is_dodging = false
	animated_sprite.modulate.a = 1.0

	if not is_time_slowed and not is_time_stopped:
		is_invulnerable = false

	var input_dir := Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * get_current_move_speed()

	if fsm and fsm.has_method("change_state"):
		fsm.change_state("Run" if input_dir != Vector2.ZERO else "Idle")

# --- Attack Logic ---
func _on_attack_timer_timeout() -> void:
	if not is_dead and _get_nearest_enemy() != null:
		trigger_attack()

func trigger_attack() -> void:
	if sword_animation_player and not sword_animation_player.is_playing():
		if sword and sword.has_method("reset_hit_targets"):
			sword.reset_hit_targets()

		var anim_name = "Slash" if sword_animation_player.has_animation("Slash") else "slash"
		if sword_animation_player.has_animation(anim_name):
			sword_animation_player.play(anim_name)

func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist := 150.0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
	return nearest

# --- Skill 1: Attack & Speed Buff ---
func activate_buff_skill() -> void:
	can_use_skill_1 = false
	is_buffed = true
	if stats: stats.current_attack += attack_buff_flat
	
	_update_sword_speed()
	_update_visual_state()

	get_tree().create_timer(buff_duration, false).timeout.connect(_remove_buff_skill)
	get_tree().create_timer(buff_cooldown, false).timeout.connect(func(): can_use_skill_1 = true)

func _remove_buff_skill() -> void:
	if not is_buffed: return
	is_buffed = false
	if stats: stats.current_attack = max(1, stats.current_attack - attack_buff_flat)
	
	_update_sword_speed()
	_update_visual_state()

# --- Skill 2: Time Slow ---
func activate_time_slow_skill() -> void:
	can_use_skill_2 = false
	is_time_slowed = true
	is_invulnerable = true
	Engine.time_scale = slow_time_scale

	animated_sprite.speed_scale = 1.0 / slow_time_scale
	_update_sword_speed()
	_update_visual_state()

	get_tree().create_timer(skill_2_duration, true, false, true).timeout.connect(_deactivate_time_slow_skill)
	get_tree().create_timer(skill_2_cooldown, true, false, true).timeout.connect(func(): can_use_skill_2 = true)

func _deactivate_time_slow_skill() -> void:
	if not is_time_slowed: return
	is_time_slowed = false
	if not is_dodging and not is_time_stopped:
		is_invulnerable = false

	Engine.time_scale = 1.0
	animated_sprite.speed_scale = 1.0
	_update_sword_speed()
	_update_visual_state()

# --- Skill 3: Time Stop ---
func activate_time_stop_skill() -> void:
	can_use_skill_3 = false
	is_time_stopped = true
	is_invulnerable = true

	get_tree().call_group("enemies", "freeze_time")
	get_tree().call_group("projectiles", "freeze_time")
	_update_visual_state()

	get_tree().create_timer(skill_3_duration, true, false, true).timeout.connect(_deactivate_time_stop_skill)
	get_tree().create_timer(skill_3_cooldown, true, false, true).timeout.connect(func(): can_use_skill_3 = true)

func _deactivate_time_stop_skill() -> void:
	if not is_time_stopped: return
	is_time_stopped = false
	if not is_dodging and not is_time_slowed:
		is_invulnerable = false

	get_tree().call_group("enemies", "unfreeze_time")
	get_tree().call_group("projectiles", "unfreeze_time")
	_update_visual_state()

# --- Helper State Managers ---
func _update_visual_state() -> void:
	if is_dead: return
	var target_color = COLOR_NORMAL
	
	if is_time_stopped: target_color = COLOR_STOP
	elif is_time_slowed: target_color = COLOR_SLOW
	elif is_buffed: target_color = COLOR_BUFF

	create_tween().set_ignore_time_scale(true).tween_property(animated_sprite, "modulate", target_color, 0.2)

func _update_sword_speed() -> void:
	if not sword_animation_player: return
	base_attack_speed = sword.get("attack_speed") if sword.get("attack_speed") != null else 1.0
	var final_speed := base_attack_speed
	
	if is_buffed: final_speed *= attack_speed_multiplier
	if is_time_slowed: final_speed *= (1.0 / slow_time_scale)
	
	sword_animation_player.speed_scale = final_speed

# --- Weapons & Ammo ---
func shoot_arrow() -> void:
	if current_arrows <= 0 or arrow_scene == null: return
	current_arrows -= 1
	update_ui()

	var arrow = arrow_scene.instantiate() as Area2D
	if is_time_stopped: arrow.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position

	var shoot_dir := global_position.direction_to(get_global_mouse_position())
	arrow.direction = shoot_dir
	arrow.rotation = shoot_dir.angle()

func swap_sword(new_sword_scene: PackedScene, drop_position: Vector2) -> void:
	if not new_sword_scene:
		return

	# 1. Drop old sword with a small random offset so it doesn't instantly re-trigger pickup.
	if dropped_sword_scene:
		var old_drop = dropped_sword_scene.instantiate() as Node2D
		
		# Offset position away from player center.
		var spawn_offset := Vector2(24, 0).rotated(randf() * TAU)
		old_drop.global_position = drop_position + spawn_offset
		
		if "sword_scene" in old_drop:
			old_drop.sword_scene = equipped_sword_scene if equipped_sword_scene else default_sword_scene
		
		get_tree().current_scene.add_child(old_drop)

	# 2. Update tracking variable.
	equipped_sword_scene = new_sword_scene

	# 3. Immediately unparent and free ALL existing sword nodes to prevent stacking.
	if is_instance_valid(sword):
		remove_child(sword)
		sword.queue_free()

	for child in get_children():
		if child.name.begins_with("Sword"):
			remove_child(child)
			child.queue_free()

	# 4. Instantiate and attach new sword
	sword = new_sword_scene.instantiate() as Node2D
	sword.name = "Sword"
	add_child(sword)

	sword_animation_player = sword.get_node_or_null("AnimationPlayer")
	_update_sword_speed()

# --- Health, Damage & Death ---
func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable: return

	if stats:
		stats.health -= max(1, amount - stats.current_defense)
		print("Player took damage! Current HP: ", stats.health)

	start_invincibility()
	flash_hit_effect()

func start_invincibility() -> void:
	is_invulnerable = true
	var tween = create_tween().set_loops(int(invincibility_time / 0.1))
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.05)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)

	get_tree().create_timer(invincibility_time, false).timeout.connect(func():
		if not is_dodging and not is_time_slowed and not is_time_stopped:
			is_invulnerable = false
			animated_sprite.modulate.a = 1.0
	)

func flash_hit_effect() -> void:
	var sprite_material = animated_sprite.material as ShaderMaterial
	if sprite_material:
		sprite_material.set_shader_parameter("flash", true)
		get_tree().create_timer(0.1, false).timeout.connect(func():
			if is_instance_valid(sprite_material):
				sprite_material.set_shader_parameter("flash", false)
		)

func die() -> void:
	if is_dead: return
	is_dead = true
	
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_physics_process(false)
	
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)
	if sword: sword.visible = false

	var death_tween = create_tween()
	death_tween.tween_property(animated_sprite, "modulate", COLOR_DEAD, 0.2)
	death_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.5)
	death_tween.finished.connect(func(): get_tree().reload_current_scene())

# --- Utilities ---
func look_at_mouse() -> void:
	var is_mouse_left = get_global_mouse_position().x < global_position.x
	animated_sprite.flip_h = is_mouse_left
	if sword:
		sword.look_at(get_global_mouse_position())
		sword.scale.y = -1 if is_mouse_left else 1

func update_ui() -> void:
	if ammo_ui and ammo_ui.has_method("update_ammo_display"):
		ammo_ui.update_ammo_display(current_arrows, max_arrows)

func add_ammo(amount: int) -> void:
	current_arrows = min(current_arrows + amount, max_arrows)
	update_ui()

func _on_stats_changed() -> void:
	if attack_timer and stats_component:
		attack_timer.wait_time = stats_component.attack_cooldown

func _on_health_changed(cur_hp: int, max_hp: int) -> void:
	if hp_label: hp_label.text = "%d/%d" % [cur_hp, max_hp]

func _update_animations(input_dir: Vector2) -> void:
	if not animated_sprite: return
	if input_dir != Vector2.ZERO:
		animated_sprite.play("run")
		if input_dir.x != 0:
			animated_sprite.flip_h = input_dir.x < 0
	else:
		animated_sprite.play("idle")
