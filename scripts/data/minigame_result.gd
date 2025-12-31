class_name MinigameResult
extends RefCounted

var success: bool = false
var performance_score: float = 0.0  # 0.0-1.0 or similar scaling
var actions: Array[Action] = []  # Array of Action instances
var result_data: MinigameResultData = null  # Class-specific typed result data

func _init(p_success: bool = false, p_performance: float = 0.0):
    success = p_success
    performance_score = clamp(p_performance, 0.0, 1.0)

func duplicate() -> MinigameResult:
    var dup = MinigameResult.new(success, performance_score)
    # Duplicate actions array
    dup.actions.clear()
    for action in actions:
        # Create new action with duplicated properties
        var dup_action = Action.new()
        dup_action.source = action.source
        dup_action.targets = action.targets.duplicate()
        dup_action.damage = action.damage
        dup_action.status_effects.clear()
        for effect in action.status_effects:
            dup_action.status_effects.append(effect.duplicate())
        dup.actions.append(dup_action)
    # Result data is not duplicated (typically not needed for duplication)
    dup.result_data = result_data
    return dup
