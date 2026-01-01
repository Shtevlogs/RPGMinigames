class_name BaseClassBehavior
extends RefCounted

# Abstract base class for class-specific behaviors
# Each character class should have a corresponding behavior class

var battle_state: BattleState = null  # Reference to current battle state, set by combat system

# Check if this class needs target selection before minigame
func needs_target_selection() -> bool:
    push_error("needs_target_selection() must be implemented in subclass")
    return false

# Build context for minigame (returns typed context)
func build_minigame_context(_character: CharacterBattleEntity, _target: BattleEntity) -> MinigameContext:
    push_error("build_minigame_context() must be implemented in subclass")
    return null

# Get the scene path for this class's minigame
func get_minigame_scene_path() -> String:
    push_error("get_minigame_scene_path() must be implemented in subclass")
    return ""

# Format minigame result for logging
# Returns array of log entry strings
func format_minigame_result(_character: CharacterBattleEntity, _result: MinigameResult) -> Array[String]:
    # Default: no special formatting
    return []

# Get ability target if not provided
func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    # Default: return null (target should be provided)
    return null

# Can be overridden in class behaviours to do class-specific on-hit effects
func get_attack_action(character: CharacterBattleEntity, target: BattleEntity, _combat_log: CombatLog) -> Action:
    var damage := BattleHelper.calculate_base_attack_damage(character, target)
    var action := Action.new(character, [target], damage, [])
    
    return action
