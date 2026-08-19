class_name FiniteStateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func init(player: CharacterBody2D) -> void:
	# Gather all child State nodes
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = player

	# Start initial state
	if initial_state:
		current_state = initial_state
		current_state.enter()

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func change_state(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state or new_state == current_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
