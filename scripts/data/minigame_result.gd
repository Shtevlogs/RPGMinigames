class_name MinigameResult
extends RefCounted

var success: bool = false
var performance_score: float = 0.0  # 0.0-1.0 or similar scaling
var damage: int = 0  # if applicable
var effects: Array[Dictionary] = []  # Effect dictionaries with type, target, magnitude, duration
var metadata: Dictionary = {}  # class-specific additional data

func _init(p_success: bool = false, p_performance: float = 0.0):
    success = p_success
    performance_score = clamp(p_performance, 0.0, 1.0)

func add_effect(effect_type: String, target: Variant, magnitude: float, duration: int = 0) -> void:
    effects.append({
        "type": effect_type,
        "target": target,
        "magnitude": magnitude,
        "duration": duration
    })

func duplicate() -> MinigameResult:
    var dup = MinigameResult.new(success, performance_score)
    dup.damage = damage
    dup.effects = effects.duplicate()
    dup.metadata = metadata.duplicate()
    return dup
