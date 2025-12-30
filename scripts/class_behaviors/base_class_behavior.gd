class_name BaseClassBehavior
extends RefCounted

# Abstract base class for class-specific behaviors
# Each character class should have a corresponding behavior class

# Check if this class needs target selection before minigame
func needs_target_selection() -> bool:
    push_error("needs_target_selection() must be implemented in subclass")
    return false

# Build context for minigame (returns typed context)
func build_minigame_context(_character: Character, _target: Variant) -> MinigameContext:
    push_error("build_minigame_context() must be implemented in subclass")
    return null

# Get the scene path for this class's minigame
func get_minigame_scene_path() -> String:
    push_error("get_minigame_scene_path() must be implemented in subclass")
    return ""

# Apply on-attack effects (modifies damage, applies debuffs, etc.)
# Returns modified damage value
func apply_attack_effects(_attacker: Character, _target: EnemyData, base_damage: int) -> int:
    # Default: no modification
    return base_damage

# Format minigame result for logging
# Returns array of log entry strings
func format_minigame_result(_character: Character, _result: MinigameResult) -> Array[String]:
    # Default: no special formatting
    return []

# Get ability target if not provided
func get_ability_target(_character: Character, _result: MinigameResult) -> Variant:
    # Default: return null (target should be provided)
    return null
