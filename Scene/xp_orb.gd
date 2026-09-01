class_name XpOrb
extends Area2D

@export var xp_value: int = 15
@export var magnet_speed: float = 400.0

var player: CharacterBody2D = null
var is_magnetized: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Start pulling toward player within 120 pixels
	if distance < 120.0:
		is_magnetized = true

	if is_magnetized:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)
		
		# Direct distance check for collection (guarantees pickup without relying on signals)
		if distance < 15.0:
			if player.has_method("add_xp"):
				player.add_xp(xp_value)
			queue_free()
