class_name EntityBattleState
extends RefCounted

var entity_id: String = ""
var current_hp: int = 0
var max_hp: int = 0
var status_effects: Array[StatusEffect] = []
var position: Vector2 = Vector2.ZERO

func from_entity(entity: BattleEntity) -> void:
    """Create battle state snapshot from entity."""
    entity_id = entity.entity_id
    current_hp = entity.health.current
    max_hp = entity.health.max_hp
    
    # Duplicate status effects
    status_effects.clear()
    for effect in entity.status_effects:
        status_effects.append(effect.duplicate())
    
    # Position would be set by combat system if needed
    position = Vector2.ZERO

func serialize() -> Dictionary:
    """Serialize to dictionary for save system."""
    var data: Dictionary = {
        "entity_id": entity_id,
        "current_hp": current_hp,
        "max_hp": max_hp,
        "position": {"x": position.x, "y": position.y}
    }
    
    # Serialize status effects (simplified - just store type and duration)
    var effects_data: Array[Dictionary] = []
    for effect in status_effects:
        effects_data.append({
            "type": effect.get_effect_name(),
            "duration": effect.duration,
            "stacks": effect.stacks,
            "magnitude": effect.magnitude
        })
    data["status_effects"] = effects_data
    
    return data

func deserialize(data: Dictionary) -> void:
    """Deserialize from dictionary."""
    entity_id = data.get("entity_id", "")
    current_hp = data.get("current_hp", 0)
    max_hp = data.get("max_hp", 0)
    
    var pos_data: Dictionary = data.get("position", {})
    position = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
    
    # Status effects would need to be reconstructed from type strings
    # For now, just clear - they'll be restored from entity state
    status_effects.clear()

