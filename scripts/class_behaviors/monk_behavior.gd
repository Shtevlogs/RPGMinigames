class_name MonkBehavior
extends BaseClassBehavior

func needs_target_selection() -> bool:
    return true  # Monk needs target selection

func build_minigame_context(character: CharacterBattleEntity, target: BattleEntity) -> MinigameContext:
    if target == null or not (target is EnemyBattleEntity):
        return null
    
    var enemy: EnemyBattleEntity = target as EnemyBattleEntity
    var effective_attrs: Attributes = character.get_effective_attributes()
    
    # Number of cards = Enemy effective Strategy - Monk Strategy (minimum 1)
    # Use effective attributes to account for Strategy debuffs
    var enemy_effective_attrs: Attributes = enemy.get_effective_attributes()
    var _card_count: int = max(1, enemy_effective_attrs.strategy - effective_attrs.strategy)
    
    # Redos available from Speed (0 at Speed 0, 1 at Speed 3, 2 at Speed 6, 3 at Speed 10)
    var redos: int = 0
    if effective_attrs.speed >= 10:
        redos = 3
    elif effective_attrs.speed >= 6:
        redos = 2
    elif effective_attrs.speed >= 3:
        redos = 1
    else:
        redos = 0
    
    var context = MonkMinigameContext.new(
        character,
        target,
        enemy_effective_attrs.strategy,
        [],  # Empty array - minigame will generate random cards
        enemy.entity_id,
        redos
    )
    
    return context

func get_minigame_scene_path() -> String:
    return "res://scenes/minigames/monk_minigame.tscn"

func format_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    var log_entries: Array[String] = []
    
    if result == null:
        return log_entries
    
    var data = result.result_data as MonkMinigameResultData
    if data == null:
        return log_entries
    
    var player_move_name: String = ""
    match data.player_move:
        "strike":
            player_move_name = "Strike"
        "grapple":
            player_move_name = "Grapple"
        "counter":
            player_move_name = "Counter"
        _:
            player_move_name = "Unknown"
    
    var enemy_card_name: String = ""
    match data.selected_enemy_card:
        "rock":
            enemy_card_name = "Rock"
        "paper":
            enemy_card_name = "Paper"
        "scissors":
            enemy_card_name = "Scissors"
        _:
            enemy_card_name = "Unknown"
    
    var outcome_text: String = ""
    match data.outcome:
        "win":
            outcome_text = "wins"
        "loss":
            outcome_text = "loses"
        "tie":
            outcome_text = "ties"
        _:
            outcome_text = "unknown"
    
    log_entries.append("%s uses %s against enemy's %s and %s!" % 
                      [character.display_name, player_move_name, enemy_card_name, outcome_text])
    
    return log_entries

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    return null

func get_attack_action(character: CharacterBattleEntity, target: BattleEntity, combat_log: CombatLog) -> Action:
    var attack_action := super.get_attack_action(character, target, combat_log)
    
    #TODO: add a way for an effect to be actually permanent
    var strategy_debuff = AlterAttributeEffect.new()
    strategy_debuff.attribute_name = "strategy"
    strategy_debuff.alteration_amount = -1
    strategy_debuff.duration = 99
    strategy_debuff.target = target
    attack_action.status_effects.append(strategy_debuff)
    
    return attack_action
