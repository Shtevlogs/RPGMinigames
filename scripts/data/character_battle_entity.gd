class_name CharacterBattleEntity
extends BattleEntity

var class_type: String  # Berserker, TimeWizard, Monk, WildMage, etc.
var equipment: EquipmentSlots
var class_state: Dictionary = {}  # Class-specific state (effect ranges, berserk stacks, etc.)

func _init(p_class_type: String = "", p_attributes: Attributes = null, p_entity_id: String = "", p_display_name: String = ""):
    # Call super._init() to initialize base class properties
    super._init(p_entity_id if p_entity_id != "" else p_class_type, p_display_name if p_display_name != "" else p_class_type, p_attributes)
    class_type = p_class_type
    equipment = EquipmentSlots.new()
    class_state = {}

func get_effective_attributes() -> Attributes:
    # Returns attributes with equipment bonuses and status effect alterations applied
    # Get base from super (applies status effects)
    var base: Attributes = super.get_effective_attributes()
    # Add equipment bonuses
    var bonuses: Attributes = equipment.get_total_attribute_bonuses()
    base.power += bonuses.power
    base.skill += bonuses.skill
    base.strategy += bonuses.strategy
    base.speed += bonuses.speed
    base.luck += bonuses.luck
    return base

func add_status_effect(effect: StatusEffect) -> void:
    status_manager.add_status_effect(effect)

func tick_status_effects(battle_state: BattleState) -> void:
    status_manager.tick_status_effects(battle_state)

func has_status_effect(effect_class: GDScript) -> bool:
    return status_manager.has_status_effect(effect_class)

func is_party_member() -> bool:
    return true

func duplicate() -> CharacterBattleEntity:
    var dup: CharacterBattleEntity = CharacterBattleEntity.new(class_type, attributes.duplicate(), entity_id, display_name)
    dup.health = health.duplicate()
    dup.equipment = equipment.duplicate()
    # Duplicate status effects using manager helper
    var duplicated_effects = status_manager.duplicate_effects(dup)
    for effect in duplicated_effects:
        dup.status_manager.status_effects.append(effect)
    dup.class_state = class_state.duplicate()
    dup.position = position
    return dup

func serialize() -> Dictionary:
    """Serialize character to dictionary."""
    var data: Dictionary = super.serialize()
    data["class_type"] = class_type
    data["equipment"] = equipment.serialize() if equipment != null else {}
    data["class_state"] = class_state.duplicate()
    return data

func deserialize(data: Dictionary) -> void:
    """Deserialize character from dictionary."""
    super.deserialize(data)
    class_type = data.get("class_type", "")
    
    # Deserialize equipment
    var equipment_data: Dictionary = data.get("equipment", {})
    equipment = EquipmentSlots.new()
    equipment.deserialize(equipment_data)
    
    # Deserialize class_state
    class_state = data.get("class_state", {}).duplicate()
