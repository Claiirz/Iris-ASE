extends Node
class_name DieState

var fsm: EnemyFSM
var enemy: CharacterBody2D


func enter() -> void:
	if not enemy:
		enemy = owner as CharacterBody2D

	# 1. Stop movement
	enemy.velocity = Vector2.ZERO
	enemy.set_physics_process(false)

	# 2. Hide HP display
	if "hp_label" in enemy and enemy.hp_label:
		enemy.hp_label.hide()

	# 3. Disable collision shapes (body & hitbox)
	var col_shape = enemy.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.set_deferred("disabled", true)

	if enemy.has_node("HitBox"):
		for child in enemy.get_node("HitBox").get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", true)

	# 4. Spawn loot drops & give ammo
	if "dropped_sword_scene" in enemy and enemy.dropped_sword_scene and randf() <= 0.5:
		var drop = enemy.dropped_sword_scene.instantiate()
		drop.global_position = enemy.global_position
		enemy.get_tree().current_scene.call_deferred("add_child", drop)

	var player = enemy.get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_ammo"):
		player.add_ammo(1)

	# 5. Play death animation & free node on completion
	if enemy.animated_sprite:
		if not ("is_mutated" in enemy and enemy.is_mutated):
			enemy.animated_sprite.modulate = Color.WHITE

		enemy.animated_sprite.play("die")
		await enemy.animated_sprite.animation_finished

	enemy.queue_free()


func update(_delta: float) -> void:
	enemy.velocity = Vector2.ZERO
