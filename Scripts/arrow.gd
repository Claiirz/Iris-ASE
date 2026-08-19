extends Area2D

@export var speed: float = 400.0
@export var damage: int = 3
var direction: Vector2 = Vector2.RIGHT
var is_frozen: bool = false


func _ready() -> void:
	add_to_group("projectiles")

	# --- CONNECT COLLISION SIGNALS ---
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Check if spawned while Time Stop is active
	var player = get_tree().get_first_node_in_group("player")
	if player and "is_time_stopped" in player and player.is_time_stopped:
		call_deferred("freeze_time")


func _physics_process(delta: float) -> void:
	if is_frozen:
		return

	# Standard projectile movement
	position += direction * speed * delta


# --- COLLISION WITH BODIES (CharacterBody2D Enemies / TileMaps / Walls) ---
func _on_body_entered(body: Node2D) -> void:
	if is_frozen:
		return

	# If arrow hits player, ignore it
	if body.is_in_group("player"):
		return

	# Hit Enemy (CharacterBody2D)
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return

	# Hit Wall / Environment
	if body is TileMapLayer or body is TileMap or body is StaticBody2D:
		queue_free()


# --- COLLISION WITH AREAS (Enemy Hurtbox Area2D) ---
func _on_area_entered(area: Area2D) -> void:
	if is_frozen:
		return

	# Don't hit player's own hurtbox or other arrows
	if area.is_in_group("player") or area.is_in_group("projectiles"):
		return

	# Hit Enemy Hurtbox directly
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
		return

	# Hit Enemy Hurtbox attached to a parent enemy node
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		queue_free()


# --- TIME STOP SUPPORT ---
func freeze_time() -> void:
	is_frozen = true
	set_physics_process(false)

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.pause()
	if has_node("CpuParticles2D"):
		$CpuParticles2D.speed_scale = 0.0


func unfreeze_time() -> void:
	is_frozen = false
	set_physics_process(true)

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play()
	if has_node("CpuParticles2D"):
		$CpuParticles2D.speed_scale = 1.0
