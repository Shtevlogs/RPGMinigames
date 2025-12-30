class_name StatusEffectManager
extends RefCounted

var status_effects: Array[StatusEffect] = []
var owner: BattleEntity = null  # Reference to BattleEntity (CharacterBattleEntity or EnemyBattleEntity)

func _init(p_owner: BattleEntity = null):
    owner = p_owner

func add_status_effect(effect: StatusEffect) -> void:
    # Call on_apply which handles target setting, matching, and appending
    effect.on_apply(owner, status_effects)

func tick_status_effects(battle_state: BattleState) -> void:
    # Process status effects - effects apply their changes directly
    var to_remove: Array[StatusEffect] = []
    
    for effect in status_effects:
        # Call on_tick - effects apply their changes directly
        effect.on_tick(battle_state)
        
        # Check if effect should be removed (expired duration)
        if effect.tick():
            to_remove.append(effect)
    
    # Call on_remove() and remove expired effects
    for effect in to_remove:
        effect.on_remove(battle_state)
        status_effects.erase(effect)

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

func clear_effects(battle_state: BattleState) -> void:
    # Clear all status effects (for death cleanup)
    # Call on_remove() for each effect before clearing
    for effect in status_effects:
        effect.on_remove(battle_state)
    status_effects.clear()
