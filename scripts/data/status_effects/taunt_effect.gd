class_name TauntEffect
extends StatusEffect

func _init(p_duration: int = 2):
    duration = p_duration
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    return "Taunt"

func can_stack() -> bool:
    return false

func on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)

func on_tick(_combatant: Variant = null) -> Dictionary:
    return {}  # No turn-based effects

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://sprites/placeholder.png",
        "color": Color.YELLOW,
        "show_stacks": false
    }

func duplicate() -> StatusEffect:
    var dup = TauntEffect.new(duration)
    return dup
