class_name WildMageBehavior
extends BaseClassBehavior

const WILD_MAGE_MINIGAME_CONTEXT = preload("res://scripts/data/wild_mage_minigame_context.gd")
const WILD_MAGE_MINIGAME_RESULT_DATA = preload("res://scripts/data/wild_mage_minigame_result_data.gd")

func needs_target_selection() -> bool:
    return false  # WildMage doesn't need target selection

func build_minigame_context(character: CharacterBattleEntity, _target: BattleEntity) -> MinigameContext:
    var effective_attrs: Attributes = character.get_effective_attributes()
    var class_state = character.class_state
    
    # Hand size from Luck (4-14)
    var hand_size: int = clamp(4 + effective_attrs.luck, 4, 14)
    
    # Discards from Skill and Strategy
    var discards: int = int((effective_attrs.skill + effective_attrs.strategy) / 2.0)
    
    var context = WILD_MAGE_MINIGAME_CONTEXT.new(
        character,
        _target,
        class_state.get("pre_drawn_card", null),  # From basic attack state
        hand_size,
        discards
    )
    
    return context

func get_minigame_scene_path() -> String:
    return "res://scenes/minigames/wild_mage_minigame.tscn"

func format_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    var log_entries: Array[String] = []
    
    if result == null:
        return log_entries
    
    var data = result.result_data as WildMageMinigameResultData
    if data == null:
        return log_entries
    
    # Format hand type name
    var hand_type_name: String = ""
    match data.hand_type:
        "straight_flush":
            hand_type_name = "Straight Flush"
        "straight":
            hand_type_name = "Straight"
        "flush":
            hand_type_name = "Flush"
        "two_pair":
            hand_type_name = "Two Pair"
        "pair":
            hand_type_name = "Pair"
        "high_card":
            hand_type_name = "High Card"
    
    # Log the hand result
    log_entries.append("%s forms a %s! (%.1fx damage)" % [character.display_name, hand_type_name, data.multiplier])
    
    return log_entries

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    return null

func get_attack_action(character: CharacterBattleEntity, target: BattleEntity, combat_log: CombatLog) -> Action:
    var attack_action := super.get_attack_action(character, target, combat_log)
    # TODO: Track pre-drawn card state for next minigame
    # For now, stubbed
    return attack_action
