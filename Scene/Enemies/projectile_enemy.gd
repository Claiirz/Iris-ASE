class_name Projectile
extends Area2D

@export var speed: float = 350.0
@export var damage: int = 10
var direction: Vector2 = Vector2.ZERO
var is_frozen: bool = false

func _ready() -> void:
	# Change this to match your arrow's group so time-stop finds it!
	add_to_group("projectiles")
	add_to_group("enemy_projectiles")
	# --- CONNECT COLLISION SIGNALS ---
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Check if spawned while Time Stop is active
	var player = get_tree().get_first_node_in_group("player")
	if player and "is_time_stopped" in player and player.is_time_stopped:
		call_deferred("freeze_time")


func _physics_process(delta: float) -> void:
	if is_frozen:
		return

	# Move continuously in the fired direction
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if is_frozen:
		return

	# If it hits the player, deal damage and destroy
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage) 
		queue_free() 
		return

	# Destroy bullet if it hits walls or tilemaps
	if body is TileMapLayer or body is TileMap or body is StaticBody2D:
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
