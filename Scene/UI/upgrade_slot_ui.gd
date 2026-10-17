extends TextureRect

@onready var count_label: Label = $CountLabel

func set_item(upgrade_data, count: int) -> void:
	texture = upgrade_data.icon
	
	if count > 1:
		count_label.text = "x%d" % count
		count_label.visible = true
	else:
		count_label.visible = false
