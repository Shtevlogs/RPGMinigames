class_name BattleEntity
extends GameStateSerializable

var entity_id: String
var display_name: String
var attributes: Attributes
var health: Health
var status_manager: StatusEffectManager
var position: Vector2 = Vector2.ZERO

func _init(p_entity_id: String = "", p_display_name: String = "", p_attributes: Attributes = null):
    entity_id = p_entity_id
    display_name = p_display_name
    attributes = p_attributes if p_attributes != null else Attributes.new()
    # Calculate max health from Power (placeholder formula: 10 + Power * 5)
    var max_hp: int = 10 + attributes.power * 5
    health = Health.new(max_hp, max_hp)
    # Initialize status effect manager
    status_manager = StatusEffectManager.new(self)
    position = Vector2.ZERO

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

func tick_status_effects(battle_state: BattleState) -> void:
    status_manager.tick_status_effects(battle_state)

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

func serialize() -> Dictionary:
    var data: Dictionary = {
        "entity_id": entity_id,
        "display_name": display_name,
        "attributes": attributes.serialize(),
        "health": health.serialize(),
        "status_effects": _serialize_status_effects(),
        "position": {"x": position.x, "y": position.y}
    }
    return data

func deserialize(data: Dictionary) -> void:
    entity_id = data.get("entity_id", "")
    display_name = data.get("display_name", "")
    
    # Deserialize attributes
    var attrs_data: Dictionary = data.get("attributes", {})
    attributes = Attributes.new()
    attributes.deserialize(attrs_data)
    
    # Deserialize health
    var health_data: Dictionary = data.get("health", {})
    var max_hp: int = health_data.get("max_hp", 10 + attributes.power * 5)
    health = Health.new(max_hp, health_data.get("current", max_hp))
    health.deserialize(health_data)
    
    # Deserialize position
    var pos_data: Dictionary = data.get("position", {})
    position = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
    
    # Reinitialize status manager (in case it wasn't initialized)
    if status_manager == null:
        status_manager = StatusEffectManager.new(self)
    
    # Deserialize status effects
    var effects_data : Array = data.get("status_effects", [])
    status_manager.status_effects.clear()
    
    for effect_data : Dictionary in effects_data:
        var effect := StatusEffect.deserialize_status(effect_data)
        effect.target = self
        status_manager.status_effects.append(effect)

func _serialize_status_effects() -> Array[Dictionary]:
    var effects_data: Array[Dictionary] = []
    for effect in status_manager.status_effects:
        # Use the effect's own serialize method
        var effect_data: Dictionary = effect.serialize()
        
        effects_data.append(effect_data)
    return effects_data
