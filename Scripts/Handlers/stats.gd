extends Resource
class_name Stats

enum BuffableStats {
	MAX_HEALTH,
	DEFENSE,
	ATTACK,
}

const STAT_CURVES: Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://dql1xb08mc02i"),
	BuffableStats.DEFENSE: preload("uid://cmsg7rlpslnx0"),
	BuffableStats.ATTACK: preload("uid://c2cmqpl268wvx"),
}

const BASE_LEVEL_EXP: float = 1.0

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

@export var base_max_health: int = 100
@export var base_defense: int = 10
@export var base_attack: int = 10
@export var experience: int = 0: set = _on_experience_set

var level: int:
	get(): return floor(max(1.0, sqrt(experience / BASE_LEVEL_EXP) + 0.5))

var current_max_health: int = 100
var current_defense: int = 10
var current_attack: int = 10

var health: int = 0: set = _on_health_set

var stat_buffs: Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()
	
func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health
	
func add_buff(buff : StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()
	
func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()
	
func recalculate_stats() -> void:
	# Map level (1 to 100) precisely to curve domain (0.0 to 1.0)
	var stat_sample_pos: float = clamp((float(level) - 1.0) / 99.0, 0.0, 1.0)
	
	# Sample base stats from curves (Y-axis acts as multiplier: Y=1.0 is 100% base stat)
	var sampled_hp: float = base_max_health * STAT_CURVES[BuffableStats.MAX_HEALTH].sample(stat_sample_pos)
	var sampled_def: float = base_defense * STAT_CURVES[BuffableStats.DEFENSE].sample(stat_sample_pos)
	var sampled_atk: float = base_attack * STAT_CURVES[BuffableStats.ATTACK].sample(stat_sample_pos)

	var stat_multipliers: Dictionary = {"max_health": 1.0, "defense": 1.0, "attack": 1.0}
	var stat_addends: Dictionary = {"max_health": 0.0, "defense": 0.0, "attack": 0.0}

	# Process active buffs
	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()
		if buff.buff_type == StatBuff.BuffType.ADD:
			stat_addends[stat_name] += buff.buff_amount
		else:
			stat_multipliers[stat_name] += buff.buff_amount

	# Calculate final values
	current_max_health = int((sampled_hp + stat_addends["max_health"]) * stat_multipliers["max_health"])
	current_defense = int((sampled_def + stat_addends["defense"]) * stat_multipliers["defense"])
	current_attack = int((sampled_atk + stat_addends["attack"]) * stat_multipliers["attack"])

	# Keep health within new bounds & notify UI
	health = clampi(health, 0, current_max_health)
	health_changed.emit(health, current_max_health)

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()
		
func _on_experience_set(new_value: int) -> void:
	var old_level: int = level
	experience = new_value
	
	if old_level != level:
		recalculate_stats()
