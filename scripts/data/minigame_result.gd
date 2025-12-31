class_name MinigameResult
extends RefCounted

const STATUS_EFFECT = preload("res://scripts/data/status_effect.gd")

var success: bool = false
var performance_score: float = 0.0  # 0.0-1.0 or similar scaling
var damage: int = 0  # if applicable
var effects: Array[StatusEffect] = []  # StatusEffect instances with targets set
var result_data: MinigameResultData = null  # Class-specific typed result data

func _init(p_success: bool = false, p_performance: float = 0.0):
    success = p_success
    performance_score = clamp(p_performance, 0.0, 1.0)

func add_status_effect(effect: StatusEffect) -> void:
    """Add a StatusEffect instance to the effects array."""
    effects.append(effect)

func duplicate() -> MinigameResult:
    var dup = MinigameResult.new(success, performance_score)
    dup.damage = damage
    # Properly duplicate StatusEffect array
    dup.effects.clear()
    for effect in effects:
        dup.effects.append(effect.duplicate())
    # Result data is not duplicated (typically not needed for duplication)
    dup.result_data = result_data
    return dup
