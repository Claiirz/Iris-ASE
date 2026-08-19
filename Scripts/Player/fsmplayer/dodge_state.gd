class_name State_Dash extends State

@export var move_speed: float = 400.0
@export var dash_duration: float = 0.25  # Base duration in game-time
@export var effect_delay: float = 0.05
@export var dash_audio: AudioStream

@onready var idle_state: State = $"../Idle"
@onready var walk_state: State = $"../Run"

var direction: Vector2 = Vector2.ZERO
var next_state: State = null
var effect_timer: float = 0.0


func enter() -> void:
	player.is_invulnerable = true
	player.is_dodging = true

	# 1. Determine direction from input or player facing direction
	direction = Input.get_vector("left", "right", "up", "down")
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if (player.animated_sprite and player.animated_sprite.flip_h) else Vector2.RIGHT
	else:
		direction = direction.normalized()

	# 2. Play animation
	if player.has_method("update_animation"):
		player.update_animation("dash")
	elif player.animated_sprite:
		player.animated_sprite.play("dash")

	# 3. Audio
	if dash_audio and player.get("audio"):
		player.audio.stream = dash_audio
		player.audio.play()

	effect_timer = 0.0

	# 4. Standard timer (respects Engine.time_scale so game-time distance stays accurate)
	var dash_timer = get_tree().create_timer(dash_duration)
	dash_timer.timeout.connect(_on_dash_timeout)


func exit() -> void:
	player.is_invulnerable = false
	player.is_dodging = false

	#Reset velocity back to standard movement speed.
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	var normal_speed: float = player.get_current_move_speed() if player.has_method("get_current_move_speed") else player.max_speed

	if input_dir != Vector2.ZERO:
		player.velocity = input_dir.normalized() * normal_speed
	else:
		player.velocity = Vector2.ZERO

	next_state = null


func process(_delta: float) -> State:
	#Scale dash speed inversely with Engine.time_scale.
	#this keeps the final dash distance consistent relative to the slowd world.
	var time_scale = Engine.time_scale if Engine.time_scale > 0.0 else 0.1
	var adjusted_speed = (move_speed / time_scale)
	
	player.velocity = direction * adjusted_speed

	# Spawn ghost trail effect
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		spawn_effect()

	return next_state


func physics(_delta: float) -> State:
	return null


func handle_input(_event: InputEvent) -> State:
	return null


func _on_dash_timeout() -> void:
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")

	if input_dir != Vector2.ZERO and walk_state != null:
		next_state = walk_state
	elif idle_state != null:
		next_state = idle_state
	else:
		next_state = get_parent().get_child(0)


func spawn_effect() -> void:
	var effect: Node2D = Node2D.new()
	player.get_parent().add_child(effect)
	effect.global_position = player.global_position - Vector2(0, 0.1)
	effect.modulate = Color(1.5, 0.2, 1.25, 0.75)

	var sprite_ref = player.get_node_or_null("Sprite2D")
	if not sprite_ref:
		sprite_ref = player.animated_sprite

	if sprite_ref:
		var sprite_copy = sprite_ref.duplicate()
		effect.add_child(sprite_copy)

	var tween: Tween = player.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0.0), 0.2)
	tween.chain().tween_callback(effect.queue_free)
