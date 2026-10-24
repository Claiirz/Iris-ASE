extends Area2D

@export var speed: float = 350.0 # Very fast!

@onready var jumpscare_ui: CanvasLayer = $JumpscareUI
@onready var scream_audio: AudioStreamPlayer = $JumpscareUI/AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D # Change to AnimatedSprite2D if using animations

var player: CharacterBody2D
var is_killing: bool = false

func _ready() -> void:
	jumpscare_ui.hide()
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	# Connect the collision signal
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Stop moving if we caught the player or the player is gone
	if is_killing or not player or not is_instance_valid(player):
		return
		
	# Move directly towards the player (ignoring all walls/obstacles)
	var direction = global_position.direction_to(player.global_position)
	global_position += direction * speed * delta
	
	# Flip the sprite to face the player
	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0

func _on_body_entered(body: Node2D) -> void:
	if is_killing: return
	
	if body.is_in_group("player"):
		is_killing = true
		
		# 1. Freeze the entire game so the player can't run away
		get_tree().paused = true 
		
		# 2. Show Jumpscare and play sound
		jumpscare_ui.show()
		if scream_audio and scream_audio.stream:
			scream_audio.play()
			
		# 3. Wait for 1.5 seconds while the player looks at the scary image
		# (We set ignore_pause to true so the timer still runs while the game is frozen)
		await get_tree().create_timer(1.5, true, false, true).timeout
		
		# 4. Unpause and Insta-kill
		get_tree().paused = false
		
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage"):
			body.take_damage(9999) # Fallback massive damage
			
		queue_free()
