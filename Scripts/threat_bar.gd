extends TextureProgressBar

@export var threat_system: ThreatSystem # Drag ThreatSystem node here in Inspector.

@onready var eye_icon: TextureRect = $EyeIcon

# Preload your textures so the script can swap them instantly
var eye_dormant = preload("res://Asset/PlaceHolders/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/ui stufarrrasrrsr/sprites/icon_nemesis_dormant.png")
var eye_tracking = preload("res://Asset/PlaceHolders/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/ui stufarrrasrrsr/sprites/icon_nemesis_tracking.png")
var eye_hunting = preload("res://Asset/PlaceHolders/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/ui stufarrrasrrsr/sprites/icon_nemesis_hunting.png")

func _ready() -> void:
	if threat_system:
		threat_system.threat_changed.connect(_on_threat_changed)
		max_value = threat_system.max_threat
		value = 0.0


func _on_threat_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current

	# Calculate the percentage using the signal's float values
	var threat_percent = current / maximum
	
	# Swap the eye depending on the threat level
	if threat_percent >= 0.66:
		eye_icon.texture = eye_hunting
	elif threat_percent >= 0.33:
		eye_icon.texture = eye_tracking
	else:
		eye_icon.texture = eye_dormant
