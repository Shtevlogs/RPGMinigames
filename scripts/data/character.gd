class_name Character
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

func tick_status_effects() -> Dictionary:
    return status_manager.tick_status_effects()

func has_status_effect(effect_class: GDScript) -> bool:
    return status_manager.has_status_effect(effect_class)

func is_party_member() -> bool:
    return true

func duplicate() -> Character:
    var dup: Character = Character.new(class_type, attributes.duplicate(), entity_id, display_name)
    dup.health = health.duplicate()
    dup.equipment = equipment.duplicate()
    # Duplicate status effects using manager helper
    var duplicated_effects = status_manager.duplicate_effects(dup)
    for effect in duplicated_effects:
        dup.status_manager.status_effects.append(effect)
    dup.class_state = class_state.duplicate()
    return dup
