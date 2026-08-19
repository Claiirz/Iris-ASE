extends Node
class_name EnemyFSM

@export var initial_state: Node
var current_state: Node
var states: Dictionary = {}

func _ready() -> void:
	# Store all child states safely
	for child in get_children():
		if child is Node:
			states[child.name.to_lower()] = child
			
			# Safely set variables if declared on the state
			if "fsm" in child:
				child.fsm = self
			if "enemy" in child:
				child.enemy = owner

	await owner.ready
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
		
# Alias so both change_state() and transition_to() work
func change_state(state_name: String) -> void:
	transition_to(state_name)

func transition_to(state_name: String) -> void:
	# If we are already in the Die state, block all state transitions!
	if current_state and current_state.name.to_lower() == "die":
		return
		
	var new_state = states.get(state_name.to_lower())
	if not new_state or new_state == current_state:
		return

	if current_state and current_state.has_method("exit"):
		current_state.exit()

	current_state = new_state

	if current_state and current_state.has_method("enter"):
		current_state.enter()
