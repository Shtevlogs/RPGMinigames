class_name BurnEffect
extends StatusEffect

var magnitude := 1.0

func _init():
    duration = 3
    stacks = 1
    magnitude = 1.0

# For display
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

func get_visual_data() -> StatusEffectVisualData:
    return StatusEffectVisualData.new("res://sprites/placeholder.png", Color.ORANGE, true)
