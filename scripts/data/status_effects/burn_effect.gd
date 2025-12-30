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

func on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)

func on_tick(_combatant: Variant = null) -> Dictionary:
    var damage: int = int(magnitude * stacks)
    return {"damage": damage}

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://sprites/placeholder.png",
        "color": Color.ORANGE,
        "show_stacks": true
    }

func duplicate() -> StatusEffect:
    var dup = BurnEffect.new(duration, stacks, magnitude)
    return dup
