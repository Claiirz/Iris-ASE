class_name BossAttackState
extends State

@export_category("Attack Settings")
@export var attack_range: float = 70.0

func enter() -> void:
	boss.velocity = Vector2.ZERO

	# Hide walk/idle sprite, show attack sprite
	var anim_sprite = boss.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var attack_sprite = boss.get_node_or_null("AttackSprite") as Sprite2D

	if anim_sprite:
		anim_sprite.visible = false
	if attack_sprite:
		attack_sprite.visible = true

	# Initial facing direction on entry
	if boss.player:
		var face_left = boss.player.global_position.x < boss.global_position.x
		boss.update_facing(face_left)

	# Play the attack animation via AnimationPlayer
	if boss.animation_player:
		boss.animation_player.play("attackslashboss")
		if not boss.animation_player.animation_finished.is_connected(_on_attack_finished):
			boss.animation_player.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)


# This runs every physics frame WHILE the boss is attacking!
func physics_update(_delta: float) -> void:
	if boss and boss.player:
		# Constantly check where the player is and update facing direction
		var face_left = boss.player.global_position.x > boss.global_position.x
		boss.update_facing(face_left)


func exit() -> void:
	var anim_sprite = boss.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var attack_sprite = boss.get_node_or_null("AttackSprite") as Sprite2D

	# Restore sprite visibility when leaving attack state
	if anim_sprite:
		anim_sprite.visible = true
	if attack_sprite:
		attack_sprite.visible = false

	if boss.animation_player and boss.animation_player.animation_finished.is_connected(_on_attack_finished):
		boss.animation_player.animation_finished.disconnect(_on_attack_finished)
	
	boss.disable_hitbox()


func _on_attack_finished(_anim_name: String) -> void:
	if boss.is_dead:
		return
	fsm.transition_to("walk")
