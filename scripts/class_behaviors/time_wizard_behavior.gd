class_name TimeWizardBehavior
extends BaseClassBehavior

const TIME_WIZARD_MINIGAME_CONTEXT = preload("res://scripts/data/time_wizard_minigame_context.gd")

func needs_target_selection() -> bool:
    return true  # TimeWizard needs target selection

func build_minigame_context(character: Character, _target: Variant) -> MinigameContext:
    """Build context data for Time Wizard minigame."""
    var effective_attrs: Attributes = character.get_effective_attributes()
    var class_state = character.class_state
    
    # Calculate board size from Strategy (4x4 to 14x14)
    var board_size: int = clamp(4 + effective_attrs.strategy, 4, 14)
    
    # Calculate time limit from Speed
    var time_limit: float = 10.0 + (effective_attrs.speed * 0.5)
    
    # Calculate event count from Skill (1 to 11)
    var event_count: int = clamp(1 + effective_attrs.skill, 1, 11)
    
    var context = TIME_WIZARD_MINIGAME_CONTEXT.new(
        character,
        _target,
        class_state.get("board_state", []),  # Pre-cleared squares from basic attacks
        board_size,
        time_limit,
        event_count
    )
    
    return context

func get_minigame_scene_path() -> String:
    return "res://scenes/minigames/time_wizard_minigame.tscn"

func apply_attack_effects(_attacker: Character, _target: EnemyData, base_damage: int) -> int:
    """Time Wizard attack effects: partially clear board for next ability cast."""
    # TODO: Track board state and apply pre-cleared squares
    # For now, stubbed
    return base_damage

func format_minigame_result(character: Character, result: MinigameResult) -> Array[String]:
    """Format Time Wizard minigame results for logging."""
    var log_entries: Array[String] = []
    
    if result == null or result.metadata.is_empty():
        return log_entries
    
    var completion: float = result.metadata.get("completion_percentage", 0.0)
    var event_activated: bool = result.metadata.get("event_activated", false)
    var mega_burst: bool = result.metadata.get("mega_time_burst", false)
    var time_expired: bool = result.metadata.get("time_expired", false)
    
    if mega_burst:
        log_entries.append("%s completes the board and triggers MEGA TIME BURST! (%.1f%% completion)" % 
                          [character.display_name, completion * 100.0])
    elif event_activated:
        var symbol_text: String = result.metadata.get("event_symbol_text", "?")
        log_entries.append("%s activates timeline event %s! (%.1f%% completion)" % 
                          [character.display_name, symbol_text, completion * 100.0])
    elif time_expired:
        log_entries.append("%s's time expires - TIME BURST! (%.1f%% completion)" % 
                          [character.display_name, completion * 100.0])
    else:
        log_entries.append("%s completes the minigame (%.1f%% completion)" % 
                          [character.display_name, completion * 100.0])
    
    return log_entries

func get_ability_target(_character: Character, _result: MinigameResult) -> Variant:
    """Time Wizard needs a target, so return null (target should be provided)."""
    return null
