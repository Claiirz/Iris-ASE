class_name BossWalkState
extends State

@export var move_speed: float = 80.0
@export var attack_range: float = 100.0
@export var min_horizontal_offset: float = 40.0 # Lowered so it's easier to satisfy

func enter() -> void:
	if boss and boss.has_node("AnimatedSprite2D"):
		boss.get_node("AnimatedSprite2D").play("walk")

func physics_update(_delta: float) -> void:
	if not boss or not boss.player:
		return

	var player_pos = boss.player.global_position
	var boss_pos = boss.global_position
	var distance = boss_pos.distance_to(player_pos)
	
	# Transition back to idle if player runs too far away
	if distance > 500.0:
		fsm.transition_to("idle")
		return

	# --- SMART REPOSITIONING (FLANKING) ---
	var x_difference = abs(boss_pos.x - player_pos.x)
	var target_position = player_pos

	# If the boss is too close vertically or jammed directly on top of the player,
	# force the navigation target to step sideways. Make this push distance 
	# LARGER than your min_horizontal_offset!
	if x_difference < min_horizontal_offset:
		var side_dir = -1.0 if boss_pos.x < player_pos.x else 1.0
		if x_difference < 2.0: # Fallback if dead-center
			side_dir = -1.0 
		target_position = player_pos + Vector2(side_dir * 60.0, 0.0) # 60px flank distance

	# --- NAVIGATION MOVEMENT ---
	var nav_agent = boss.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if nav_agent:
		nav_agent.target_position = target_position
		var next_pos = nav_agent.get_next_path_position()
		var dir = boss.global_position.direction_to(next_pos)
		
		boss.velocity = dir * move_speed

		# Face the player/movement direction (Fixed your direction check here too)
		var face_left = player_pos.x > boss_pos.x
		boss.update_facing(face_left)

	# --- CONTROLLED ATTACK TRANSITION ---
	# Now that flank distance (60.0) is greater than min_horizontal_offset (40.0),
	# the boss will successfully pass this check and strike when close!
	if distance <= attack_range and x_difference >= min_horizontal_offset:
		fsm.transition_to("attack")
		return

	boss.move_and_slide()
