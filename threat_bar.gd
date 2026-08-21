extends TextureProgressBar

@export var threat_system: ThreatSystem # Drag ThreatSystem node here in Inspector.

func _ready() -> void:
	if threat_system:
		threat_system.threat_changed.connect(_on_threat_changed)
		max_value = threat_system.max_threat
		value = 0.0


func _on_threat_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
	
	# Change bar color or make it flash when threat is high (> 75%).
	if current > maximum * 0.75:
		modulate = Color.RED
	else:
		modulate = Color.WHITE
