class_name BurnEffect
extends StatusEffect

func _init(p_duration: int = 3, p_stacks: int = 1, p_magnitude: float = 1.0):
    duration = p_duration
    stacks = p_stacks
    magnitude = p_magnitude

func get_effect_name() -> String:
    return "Burn"

func can_stack() -> bool:
    return true

func on_apply(p_target: BattleEntity, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)

func on_tick(battle_state: BattleState) -> void:
    # Apply damage directly
    var damage: int = int(magnitude * stacks)
    if target != null and damage > 0:
        var actual_damage: int = target.take_damage(damage)
        
        # Log the damage
        if battle_state != null and battle_state.combat_log != null:
            battle_state.combat_log.add_entry("%s takes %d damage from Burn!" % [target.display_name, actual_damage], battle_state.combat_log.EventType.STATUS_EFFECT)

func on_remove(_battle_state: BattleState) -> void:
    # No cleanup needed
    pass

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://sprites/placeholder.png",
        "color": Color.ORANGE,
        "show_stacks": true
    }

func duplicate() -> StatusEffect:
    var dup = BurnEffect.new(duration, stacks, magnitude)
    return dup
