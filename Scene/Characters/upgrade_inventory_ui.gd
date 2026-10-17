extends HFlowContainer

@export var slot_scene: PackedScene # Drag upgrade_slot_ui.tscn here
@export var upgrade_component: Node # Assign the player's UpgradeComponent here

# Keeps track of which UI slot belongs to which upgrade type
var active_slots: Dictionary = {}

func _ready() -> void:
	if upgrade_component and upgrade_component.has_signal("upgrade_added"):
		upgrade_component.upgrade_added.connect(_on_upgrade_added)
		
		# Optional: Clear placeholder slots from the editor
		for child in get_children():
			child.queue_free()

func _on_upgrade_added(upgrade, current_stacks: int) -> void:
	# If we already have a slot for this item, just update the number
	if active_slots.has(upgrade.type):
		var slot = active_slots[upgrade.type]
		slot.set_item(upgrade, current_stacks)
	else:
		# If it's a new item, spawn a new slot
		var slot = slot_scene.instantiate()
		add_child(slot)
		slot.set_item(upgrade, current_stacks)
		active_slots[upgrade.type] = slot

# Use this to clear the UI when starting a new run/restarting
func reset_ui() -> void:
	active_slots.clear()
	for child in get_children():
		child.queue_free()
