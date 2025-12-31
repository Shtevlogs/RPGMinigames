class_name BerserkerBehavior
extends BaseClassBehavior

const BERSERK_EFFECT = preload("res://scripts/data/status_effects/berserk_effect.gd")
const BERSERKER_MINIGAME_CONTEXT = preload("res://scripts/data/berserker_minigame_context.gd")
const BERSERKER_MINIGAME_RESULT_DATA = preload("res://scripts/data/berserker_minigame_result_data.gd")

func needs_target_selection() -> bool:
    return false  # Berserker doesn't need target selection

func build_minigame_context(character: CharacterBattleEntity, _target: BattleEntity) -> MinigameContext:
    """Build context data for Berserker minigame."""
    var class_state = character.class_state
    
    var context = BERSERKER_MINIGAME_CONTEXT.new(
        character,
        _target,
        class_state.get("effect_ranges", []),
        class_state.get("is_berserking", false),
        class_state.get("berserk_stacks", 0)
    )
    
    return context

func get_minigame_scene_path() -> String:
    return "res://scenes/minigames/berserker_minigame.tscn"

func apply_attack_effects(attacker: CharacterBattleEntity, _target: EnemyBattleEntity, base_damage: int) -> int:
    """Berserker attack effects: effect ranges (not berserking) or 1.5x damage + heal (berserking)."""
    var class_state = attacker.class_state
    var is_berserking: bool = class_state.get("is_berserking", false)
    
    if is_berserking:
        # Berserking: 1.5x damage, heal, remove stacks
        var modified_damage: int = int(base_damage * 1.5)
        
        # Heal 10% of max HP
        var heal_percentage: float = 0.1
        var heal_amount: int = int(attacker.health.max_hp * heal_percentage)
        attacker.health.heal(heal_amount)
        
        # Remove BerserkEffect (this will clean up class_state and attribute effects)
        _remove_berserk_effect(attacker)
        
        return modified_damage
    else:
        # Not berserking: add effect ranges to blackjack minigame
        # NOTE: Effect range generation will be implemented in backlog item 06_berserker_effect_ranges.md
        # For now, this is stubbed - the key requirement is that effect ranges are NOT generated while berserking
        # TODO: Track effect ranges for next ability use (see backlog item 06)
        return base_damage

func _remove_berserk_effect(character: CharacterBattleEntity) -> void:
    """Remove BerserkEffect from character, which will clean up class_state and attribute effects."""
    # Find and remove BerserkEffect using script comparison
    var to_remove: Array[StatusEffect] = []
    for effect in character.status_effects:
        if effect.get_script() == BERSERK_EFFECT:
            to_remove.append(effect)
    
    # Remove effects (call on_remove for cleanup)
    for effect in to_remove:
        effect.on_remove(battle_state)
        character.status_effects.erase(effect)

func format_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    """Format Berserker minigame results for logging."""
    var log_entries: Array[String] = []
    
    if result == null:
        return log_entries
    
    var data = result.result_data as BerserkerMinigameResultData
    if data == null:
        return log_entries
    
    # Log the hand result
    if data.blackjack:
        log_entries.append("%s scores BLACKJACK! (21 with %d cards)" % [character.display_name, data.cards_drawn])
    elif data.busted:
        log_entries.append("%s busts with %d! (drew %d cards)" % [character.display_name, data.hand_value, data.cards_drawn])
    else:
        log_entries.append("%s stands with %d (drew %d cards)" % [character.display_name, data.hand_value, data.cards_drawn])
    
    # Log berserk state if applicable
    if data.is_berserking and data.berserk_stacks > 0:
        if data.berserk_stacks == 1:
            log_entries.append("%s enters Berserk state! (+1 Power, +1 Speed)" % character.display_name)
        else:
            log_entries.append("%s's Berserk state intensifies! (%d stacks: +%d Power, +%d Speed)" % [character.display_name, data.berserk_stacks, data.berserk_stacks, data.berserk_stacks])
    
    return log_entries

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    """Berserker may hit all enemies/allies, so return null (target should be provided)."""
    return null
