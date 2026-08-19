class_name UpgradeData
extends Resource

# 1. Added CRIT_DAMAGE and CRIT_RATE to enum
enum UpgradeType { SPEED, DAMAGE, ATTACK_SPEED, CRIT_DAMAGE, CRIT_RATE }

@export var name: String = "Upgrade"
@export var icon: Texture2D
@export var type: UpgradeType
@export var stat_increase_percent: float = 0.05
