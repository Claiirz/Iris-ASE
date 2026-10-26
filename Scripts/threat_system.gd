class_name ThreatSystem 
extends Node

@export_category("Zone Settings")
@export var tile_size: float = 16.0          
@export var zone_width_tiles: int = 5      
@export var max_threat: float = 100.0

@export_category("Threat Scaling")
@export var base_threat_speed: float = 4.0   
@export var acceleration_rate: float = 1.4    
@export var decay_rate: float = 10.0         

@export_category("Boss Spawn Settings")
@export var boss_scene: PackedScene        
@export var boss_spawn_distance: float = 250.0 
@export var environment_modulate: CanvasModulate 

@export var vignette: TextureRect
@export var threat_sound: AudioStreamPlayer
@export var threat_music: AudioStreamPlayer

@export_category("Stalker Entity Settings")
@export var stalker_scene: PackedScene
@export var stalker_spawn_delay: float = 30.0 

var player: CharacterBody2D = null
var current_threat: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO
var time_camping: float = 0.0

var is_boss_active: bool = false 

signal threat_changed(current_threat: float, max_threat: float)
signal max_threat_reached()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		anchor_position = player.global_position

func _process(delta: float) -> void:
	if get_tree().paused or not player or not is_instance_valid(player) or is_boss_active:
		return

	var zone_radius = (zone_width_tiles * tile_size) / 2.0
	var distance_from_anchor = anchor_position.distance_to(player.global_position)

	if distance_from_anchor <= zone_radius:
		time_camping += delta
		var dynamic_speed = base_threat_speed * pow(acceleration_rate, time_camping)
		current_threat += dynamic_speed * delta
	else:
		time_camping = max(0.0, time_camping - (delta * 2.0))
		if time_camping <= 0.0:
			anchor_position = player.global_position
			
		current_threat = max(0.0, current_threat - (decay_rate * delta))

	current_threat = clamp(current_threat, 0.0, max_threat)
	threat_changed.emit(current_threat, max_threat)

	if current_threat >= max_threat:
		_trigger_threat_penalty()

func _trigger_threat_penalty() -> void:
	is_boss_active = true
	current_threat = max_threat 
	threat_changed.emit(current_threat, max_threat)
	max_threat_reached.emit()
	
	if threat_sound:
		threat_sound.play()
	
	if threat_music:
		threat_music.play()

	if player and is_instance_valid(player):
		var player_light = player.get_node_or_null("PointLight2D")
		if player_light:
			_flicker_light(player_light)

	var tween = get_tree().create_tween()
	tween.set_parallel(true) 
	
	if environment_modulate:
		var dark_scary_color = Color(0.15, 0.05, 0.05) 
		tween.tween_property(environment_modulate, "color", dark_scary_color, 3.0)
		
	if vignette:
		vignette.modulate = Color(0.0, 0.0, 0.0, 1.0)
		tween.tween_property(vignette, "modulate", Color(0.1, 0.1, 0.1, 1.0), 3.0)

	await tween.finished 

	if boss_scene and player and is_instance_valid(player):
		var boss_instance = boss_scene.instantiate() as Node2D
		if boss_instance:
			var spawn_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * boss_spawn_distance
			boss_instance.global_position = player.global_position + spawn_offset
			get_tree().current_scene.add_child(boss_instance)
			
			boss_instance.tree_exited.connect(_on_boss_defeated)
	else:
		push_warning("ThreatSystem Warning: Boss Scene is not assigned in the Inspector!")

	if stalker_scene:
		get_tree().create_timer(stalker_spawn_delay, false).timeout.connect(_spawn_stalker)

func _on_boss_defeated() -> void:
	is_boss_active = false
	current_threat = 0.0
	time_camping = 0.0
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	if environment_modulate:
		tween.tween_property(environment_modulate, "color", Color(1.0, 1.0, 1.0), 2.0)
		
	if vignette:
		tween.tween_property(vignette, "modulate", Color(1.0, 1.0, 1.0, 0.0), 2.0)
		
func _flicker_light(light: PointLight2D) -> void:
	var flicker_count = randi_range(4, 7)
	for i in range(flicker_count):
		if not is_instance_valid(light): 
			return
			
		light.enabled = true
		await get_tree().create_timer(randf_range(0.05, 0.15), false).timeout
		
		if not is_instance_valid(light): 
			return
			
		light.enabled = false
		await get_tree().create_timer(randf_range(0.05, 0.25), false).timeout

	if is_instance_valid(light):
		light.enabled = true

func _spawn_stalker() -> void:
	if not is_boss_active: 
		return
		
	if player and is_instance_valid(player) and stalker_scene:
		var stalker = stalker_scene.instantiate() as Node2D
		var spawn_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 800.0
		stalker.global_position = player.global_position + spawn_offset
		
		get_tree().current_scene.add_child(stalker)
