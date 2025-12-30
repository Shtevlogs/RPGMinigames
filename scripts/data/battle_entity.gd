class_name BattleEntity
extends RefCounted

var entity_id: String
var display_name: String
var attributes: Attributes
var health: Health
var status_manager: StatusEffectManager

func _init(p_entity_id: String = "", p_display_name: String = "", p_attributes: Attributes = null):
    entity_id = p_entity_id
    display_name = p_display_name
    attributes = p_attributes if p_attributes != null else Attributes.new()
    # Calculate max health from Power (placeholder formula: 10 + Power * 5)
    var max_hp: int = 10 + attributes.power * 5
    health = Health.new(max_hp, max_hp)
    # Initialize status effect manager
    status_manager = StatusEffectManager.new(self)

func get_effective_attributes() -> Attributes:
    # Base implementation: applies status effect alterations only
    # Subclasses can override to add equipment bonuses, etc.
    var base: Attributes = attributes.duplicate()
    # Apply status effect attribute modifications
    for effect in status_manager.status_effects:
        effect.on_modify_attributes(base)
    return base

var status_effects: Array[StatusEffect]:
    get:
        return status_manager.status_effects
    set(_value):
        # Read-only property for backward compatibility
        push_warning("status_effects is read-only, use status_manager methods instead")

func add_status_effect(effect: StatusEffect) -> void:
    status_manager.add_status_effect(effect)

func tick_status_effects() -> Dictionary:
    return status_manager.tick_status_effects()

func has_status_effect(effect_class: GDScript) -> bool:
    return status_manager.has_status_effect(effect_class)

func is_alive() -> bool:
    return health.is_alive()

func take_damage(amount: int) -> int:
    return health.take_damage(amount)

func is_party_member() -> bool:
    # Override in Character to return true
    return false

func duplicate() -> BattleEntity:
    push_error("duplicate() must be implemented in subclass")
    return null
