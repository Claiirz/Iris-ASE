class_name Boss
extends CharacterBody2D

# --- STATS RESOURCE ---
@export var stats: Stats

# --- STATE VARIABLES & NODE REFERENCES ---
var player: CharacterBody2D = null
var is_dead: bool = false
var is_frozen: bool = false # Keeps time-stop momentum locked at zero
var hit_entities: Array[Node] = []
var is_lunging: bool = false
var lunge_velocity: Vector2 = Vector2.ZERO

@onready var fsm: Node = $FSM
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sprite: Sprite2D = $AttackSprite # Make sure your attack sprite node matches this name
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $HitBox

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	# Unique material instance for hit-flash shader.
	if animated_sprite and animated_sprite.material:
		animated_sprite.material = animated_sprite.material.duplicate()
	if attack_sprite and attack_sprite.material:
		attack_sprite.material = attack_sprite.material.duplicate()

	# Duplicate & Setup Stats Safely.
	if stats:
		stats = stats.duplicate()
		stats.setup_stats()

		# Safeguard: Ensure health isn't zero on spawn
		if stats.health <= 0:
			stats.health = stats.current_max_health

		if not stats.health_depleted.is_connected(_on_health_depleted):
			stats.health_depleted.connect(_on_health_depleted)

	# Setup Hitbox (Disabled by default, listens for Player's Hurtbox Area2D)
	if hitbox:
		hitbox.monitoring = false
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Check if spawned while Time Stop is active
	if player and "is_time_stopped" in player and player.is_time_stopped:
		call_deferred("freeze_time")


func _physics_process(_delta: float) -> void:
	if is_dead or is_frozen:
		velocity = Vector2.ZERO
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	if is_lunging:
		velocity = lunge_velocity
		move_and_slide()


# --- FACING & HITBOX MIRRORING ---
func update_facing(face_left: bool) -> void:
	if animated_sprite:
		animated_sprite.flip_h = face_left
	
	if attack_sprite:
		attack_sprite.flip_h = face_left

	# Mirror the HitBox shape/scale cleanly across the center
	if hitbox:
		hitbox.scale.x = -1.0 if face_left else 1.0


# --- ANIMATION PLAYER HITBOX TRIGGERS ---
func enable_hitbox() -> void:
	hit_entities.clear()
	if hitbox:
		hitbox.monitoring = true
		print("DEBUG: Hitbox ENABLED!") # <-- Check if this prints during attack

func disable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = false
		print("DEBUG: Hitbox DISABLED!")

func _on_hitbox_area_entered(area: Area2D) -> void:
	print("DEBUG: Something entered hitbox: ", area.name, " | Parent: ", area.get_parent().name)
	
	var target = area.owner if area.owner else area.get_parent()
	
	if target:
		print("DEBUG: Target found: ", target.name, " | In group 'player'? ", target.is_in_group("player"))
		if target.is_in_group("player") and not hit_entities.has(target):
			hit_entities.append(target)
			if target.has_method("take_damage"):
				var dmg = stats.current_attack if stats else 15
				target.take_damage(dmg)
				print("DEBUG: Dealt ", dmg, " damage to player!")


# --- DAMAGE & HIT EFFECTS ---
func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dead:
		return

	if stats:
		var final_damage = max(1, amount - stats.current_defense)
		stats.health -= final_damage
		print("Boss HP: ", stats.health, "/", stats.current_max_health)
		
		# Spawn damage indicator popup
		_spawn_damage_popup(final_damage, is_crit)

	# Hit flash effect on active sprites
	for sprite in [animated_sprite, attack_sprite]:
		if sprite and sprite.material:
			var sprite_material = sprite.material as ShaderMaterial
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
	settings.font_size = 26 if is_crit else 18
	settings.font_color = Color.YELLOW if is_crit else Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	popup.label_settings = settings

	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-20, 20), -40)

	var tween = popup.create_tween().set_parallel(true)
	tween.tween_property(popup, "global_position", popup.global_position + Vector2(randf_range(-25, 25), -50), 0.5)
	tween.tween_property(settings, "font_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(settings, "outline_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	await tween.finished
	popup.queue_free()


# --- DEFEAT & CLEANUP ---
func _on_health_depleted() -> void:
	die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	if has_node("FSM"):
		var fsm_node = $FSM
		if fsm_node.has_method("transition_to"):
			fsm_node.transition_to("die")
		elif fsm_node.has_method("change_state"):
			fsm_node.change_state("die")
		else:
			queue_free()
	else:
		queue_free()

func lunge_forward(speed: float = 320.0, duration: float = 0.12) -> void:
	if not player:
		return
	
	# Calculate direction straight toward the player
	var dir = global_position.direction_to(player.global_position)
	lunge_velocity = dir * speed
	is_lunging = true
	
	# Automatically cut off the lunge after a fraction of a second
	get_tree().create_timer(duration).timeout.connect(func():
		is_lunging = false
		lunge_velocity = Vector2.ZERO
	)

# --- TIME STOP SUPPORT (Skill 3) ---
func freeze_time() -> void:
	is_frozen = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	if animated_sprite:
		animated_sprite.pause()
	if attack_sprite:
		attack_sprite.pause()
	if animation_player:
		animation_player.pause()

	if has_node("FSM"):
		$FSM.set_physics_process(false)


func unfreeze_time() -> void:
	if is_dead:
		return

	is_frozen = false
	set_physics_process(true)

	if animated_sprite:
		animated_sprite.play()
	if attack_sprite:
		attack_sprite.play()
	if animation_player:
		animation_player.play()

	if has_node("FSM"):
		$FSM.set_physics_process(true)
