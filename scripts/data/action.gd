class_name Action
extends RefCounted

var source: BattleEntity = null  # Source entity that performed the action (can be null)
var targets: Array[BattleEntity] = []
var damage: int = 0  # Damage before resistances, 0 if no damage
var status_effects: Array[StatusEffect] = []

func _init(p_source: BattleEntity = null, p_targets: Array[BattleEntity] = [], p_damage: int = 0, p_status_effects: Array[StatusEffect] = []):
	source = p_source
	targets = p_targets
	damage = p_damage
	status_effects = p_status_effects

