extends CanvasLayer

@onready var ammo_label: Label = $Control/AmmoLabel


func update_ammo_display(current_ammo: int, max_ammo: int) -> void:
	ammo_label.text = "Arrows: " + str(current_ammo) + " / " + str(max_ammo)
