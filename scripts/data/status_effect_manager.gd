class_name StatusEffectManager
extends RefCounted

var status_effects: Array[StatusEffect] = []
var owner: BattleEntity = null  # Reference to BattleEntity (Character or EnemyData)

func _init(p_owner: BattleEntity = null):
    owner = p_owner

func add_status_effect(effect: StatusEffect) -> void:
    # Call on_apply which handles target setting, matching, and appending
    effect.on_apply(owner, status_effects)

func tick_status_effects() -> Dictionary:
    # Process status effects and return cumulative effects to apply
    var cumulative_effects: Dictionary = {"damage": 0}
    var to_remove: Array[StatusEffect] = []
    
    for effect in status_effects:
        # Call on_tick to get turn-based effects
        var tick_result: Dictionary = effect.on_tick(owner)
        
        # Accumulate effects
        if tick_result.has("damage"):
            cumulative_effects["damage"] = cumulative_effects.get("damage", 0) + tick_result["damage"]
        
        # Check if effect should be removed
        if tick_result.get("remove", false) or effect.tick():
            to_remove.append(effect)
    
    # Remove expired effects
    for effect in to_remove:
        status_effects.erase(effect)
    
    return cumulative_effects

func has_status_effect(effect_class: GDScript) -> bool:
    # Check if entity has a status effect of the given class type
    # For class_name types, we can use script comparison
    for effect in status_effects:
        if effect.get_script() == effect_class:
            return true
    return false

func duplicate_effects(target_owner: BattleEntity) -> Array[StatusEffect]:
    # Create a copy of all status effects with new target owner
    var duplicated_effects: Array[StatusEffect] = []
    for effect in status_effects:
        var dup_effect = effect.duplicate()
        dup_effect.target = target_owner
        duplicated_effects.append(dup_effect)
    return duplicated_effects

func clear_effects() -> void:
    # Clear all status effects (for death cleanup)
    status_effects.clear()
