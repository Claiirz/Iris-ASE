class_name FSM
extends Node

@export var initial_state: State

var current_state: State = null
var states: Dictionary = {}

func _ready() -> void:
	# Wait for parent node (Boss) to be ready
	await owner.ready
	
	# Register all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.fsm = self
			child.boss = owner as CharacterBody2D

	if initial_state:
		transition_to(initial_state.name.to_lower())

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	var target_key = target_state_name.to_lower()
	if not states.has(target_key):
		push_warning("Fsm Warning: State '%s' does not exist!" % target_state_name)
		return

	if current_state:
		current_state.exit()

	current_state = states[target_key]
	current_state.enter()

# Compatibility alias for code checking change_state()
func change_state(target_state_name: String) -> void:
	transition_to(target_state_name)
