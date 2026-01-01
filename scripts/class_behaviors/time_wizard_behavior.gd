class_name TimeWizardBehavior
extends BaseClassBehavior

const TIME_WIZARD_MINIGAME_CONTEXT = preload("res://scripts/data/time_wizard_minigame_context.gd")
const TIME_WIZARD_MINIGAME_RESULT_DATA = preload("res://scripts/data/time_wizard_minigame_result_data.gd")

func needs_target_selection() -> bool:
    return true  # TimeWizard needs target selection

func build_minigame_context(character: CharacterBattleEntity, _target: BattleEntity) -> MinigameContext:
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

func format_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    var log_entries: Array[String] = []
    
    if result == null:
        return log_entries
    
    var data = result.result_data as TimeWizardMinigameResultData
    if data == null:
        return log_entries
    
    if data.mega_time_burst:
        log_entries.append("%s completes the board and triggers MEGA TIME BURST! (%.1f%% completion)" % 
                          [character.display_name, data.completion_percentage * 100.0])
    elif data.event_activated:
        log_entries.append("%s activates timeline event %s! (%.1f%% completion)" % 
                          [character.display_name, data.event_symbol_text, data.completion_percentage * 100.0])
    elif data.time_expired:
        log_entries.append("%s's time expires - TIME BURST! (%.1f%% completion)" % 
                          [character.display_name, data.completion_percentage * 100.0])
    else:
        log_entries.append("%s completes the minigame (%.1f%% completion)" % 
                          [character.display_name, data.completion_percentage * 100.0])
    
    return log_entries

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    return null

func get_attack_action(character: CharacterBattleEntity, target: BattleEntity, combat_log: CombatLog) -> Action:
    var attack_action := super.get_attack_action(character, target, combat_log)
    # TODO: Track board state and apply pre-cleared squares
    # For now, stubbed
    return attack_action
