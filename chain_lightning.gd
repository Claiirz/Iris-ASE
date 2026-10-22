extends Node2D

@export var bounce_radius: float = 150.0 
@export var max_bounces: int = 3
@export var lightning_damage: int = 5
@export var stun_duration: float = 2
@export var jump_delay: float = 0.05

@onready var line_2d: Line2D = $Line2D

var hit_targets: Array[Node2D] = []
var bounces_left: int = 0

func _ready() -> void:
	
	top_level = true 

func start_chain(start_pos: Vector2, initial_target: Node2D, stacks: int) -> void:
	global_position = start_pos

	bounces_left = max_bounces + (stacks - 1) 
	
	line_2d.clear_points()
	line_2d.add_point(Vector2.ZERO) 
	
	_hit_target(initial_target)

func _hit_target(target: Node2D) -> void:
	if not is_instance_valid(target):
		_end_chain()
		return
		
	hit_targets.append(target)

	line_2d.add_point(to_local(target.global_position))

	if target.has_method("take_damage"):
		target.take_damage(lightning_damage, false)

	if target.has_method("apply_stun"):
		target.apply_stun(stun_duration)
		
	bounces_left -= 1
	
	if bounces_left > 0:
		_jump_to_next.call_deferred(target)
	else:
		_end_chain()

func _jump_to_next(current_target: Node2D) -> void:
	await get_tree().create_timer(jump_delay, false).timeout
	
	if not is_instance_valid(current_target):
		_end_chain()
		return

	var next_target = _find_nearest_valid_enemy(current_target.global_position)
	if next_target:
		_hit_target(next_target)
	else:
		_end_chain()

func _find_nearest_valid_enemy(from_pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = bounce_radius
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not hit_targets.has(enemy):
			var dist = from_pos.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
				
	return nearest

func _end_chain() -> void:

	var tween = create_tween()
	tween.tween_property(line_2d, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
