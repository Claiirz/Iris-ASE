class_name ThreatSystem extends Node
# Threat system functions like an anti-camp zone. the longer the player stays/wanders around the same spot -
# the bar fills up
@export_category("Zone Settings")
@export var tile_size: float = 16.0         # Change to 32.0 if your tiles are 32x32
@export var zone_width_tiles: int = 5      # 10x10 tiles camping detection zone
@export var max_threat: float = 100.0

@export_category("Threat Scaling")
@export var base_threat_speed: float = 4.0   # Initial threat added per second
@export var acceleration_rate: float = 1.4    # How much faster it accumulates the longer the player stays
@export var decay_rate: float = 10.0         # How fast threat drops when moving away

var player: CharacterBody2D = null
var current_threat: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO
var time_camping: float = 0.0

# Signals for UI and Gameplay reactions.
signal threat_changed(current_threat: float, max_threat: float)
signal max_threat_reached()

func _ready() -> void:
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		anchor_position = player.global_position


func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	# Calculate pixel radius for a 10x10 tile box (half-width * tile size)
	var zone_radius = (zone_width_tiles * tile_size) / 2.0
	var distance_from_anchor = anchor_position.distance_to(player.global_position)

	if distance_from_anchor <= zone_radius:
		# When camping is detected
		time_camping += delta
		
		# Threat speed compounds exponentially the longer they stay in the same area.
		var dynamic_speed = base_threat_speed * pow(acceleration_rate, time_camping)
		current_threat += dynamic_speed * delta
	else:
		# When Player moving away
		# Ease out camping time, then shift anchor to the new location
		time_camping = max(0.0, time_camping - (delta * 2.0))
		if time_camping <= 0.0:
			anchor_position = player.global_position
			
		# Decay threat when moving continuously
		current_threat = max(0.0, current_threat - (decay_rate * delta))

	# Clamp and broadcast values
	current_threat = clamp(current_threat, 0.0, max_threat)
	threat_changed.emit(current_threat, max_threat)

	if current_threat >= max_threat:
		_trigger_threat_penalty()


func _trigger_threat_penalty() -> void:
	max_threat_reached.emit()
	print("WARNING: Threat maxed out! Spawning ambush or elite squad!")
	
	# Reset threat partly so it loops, or keep it maxed until they escape
	current_threat = max_threat * 0.5 
	time_camping = 1.0 # Keeps pressure high
