class_name EnemyBattleEntity
extends BattleEntity

var enemy_type: String = ""  # For categorization
var abilities: Array[String] = []  # Ability IDs

func _init(p_id: String = "", p_name: String = "", p_attributes: Attributes = null):
	# Call super._init() to initialize base class properties
	super._init(p_id, p_name, p_attributes)
	enemy_type = ""
	abilities = []

func add_status_effect(effect: StatusEffect) -> void:
	status_manager.add_status_effect(effect)

func tick_status_effects(battle_state: BattleState) -> void:
	status_manager.tick_status_effects(battle_state)

func has_status_effect(effect_class: GDScript) -> bool:
	return status_manager.has_status_effect(effect_class)

func duplicate() -> EnemyBattleEntity:
	var dup = EnemyBattleEntity.new(entity_id, display_name, attributes.duplicate())
	dup.health = health.duplicate()
	dup.enemy_type = enemy_type
	dup.abilities = abilities.duplicate()
	# Duplicate status effects using manager helper
	var duplicated_effects = status_manager.duplicate_effects(dup)
	for effect in duplicated_effects:
		dup.status_manager.status_effects.append(effect)
	dup.position = position
	return dup

func serialize() -> Dictionary:
    """Serialize enemy to dictionary."""
	var data: Dictionary = super.serialize()
	data["enemy_type"] = enemy_type
	data["abilities"] = abilities.duplicate()
	return data

func deserialize(data: Dictionary) -> void:
    """Deserialize enemy from dictionary."""
	super.deserialize(data)
	enemy_type = data.get("enemy_type", "")
	abilities = data.get("abilities", []).duplicate()
