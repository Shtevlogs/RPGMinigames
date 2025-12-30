class_name SilenceEffect
extends StatusEffect

func _init(p_duration: int = 2):
    duration = p_duration
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    return "Silence"

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

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://sprites/placeholder.png",
        "color": Color.GRAY,
        "show_stacks": false
    }

func duplicate() -> StatusEffect:
    var dup = SilenceEffect.new(duration)
    return dup
