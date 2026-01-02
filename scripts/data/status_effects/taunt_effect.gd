class_name TauntEffect
extends StatusEffect

func _init():
    duration = 2
    stacks = 1
    magnitude = 1.0

func can_stack() -> bool:
    return false

func on_apply(p_target: BattleEntity, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)

func on_tick(_battle_state: BattleState) -> void:
    # No turn-based effects
    pass

func on_remove(_battle_state: BattleState) -> void:
    # No cleanup needed
    pass

func get_visual_data() -> StatusEffectVisualData:
    return StatusEffectVisualData.new("res://sprites/placeholder.png", Color.YELLOW, false)
