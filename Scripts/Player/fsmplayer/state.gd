class_name State
extends Node

# Reference to the player host
var player: CharacterBody2D

# Called when entering the state
func enter() -> void:
	pass

# Called when exiting the state
func exit() -> void:
	pass

# Replaces _physics_process while this state is active
func physics_update(_delta: float) -> void:
	pass
