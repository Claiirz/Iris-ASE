extends Area2D

@export var pull_strength: float = 250.0
@export var damage_per_tick: int = 3
@export var lifetime: float = 3.0

var trapped_bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Destroy whirlwind after its lifetime expires
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	# Damage tick timer
	var dmg_timer = Timer.new()
	dmg_timer.wait_time = 0.4
	dmg_timer.timeout.connect(_deal_tick_damage)
	add_child(dmg_timer)
	dmg_timer.start()

	# --- FIX 1: Catch enemies already overlapping when spawned at the mouse ---
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _physics_process(delta: float) -> void:
	# Pull trapped enemies toward the center of the whirlwind smoothly
	for body in trapped_bodies:
		if is_instance_valid(body):
			var dir = body.global_position.direction_to(global_position)
			var pull_velocity = dir * pull_strength
			
			if body.has_method("apply_pull"):
				body.apply_pull(pull_velocity)
			else:
				# --- FIX 2: Removed extra * delta so the fallback actually moves them ---
				body.global_position += dir * pull_strength * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not trapped_bodies.has(body):
		trapped_bodies.append(body)
		print("Enemy trapped in whirlwind: ", body.name) # Debug print to verify

func _on_body_exited(body: Node2D) -> void:
	if trapped_bodies.has(body):
		trapped_bodies.erase(body)

func _deal_tick_damage() -> void:
	for body in trapped_bodies:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
