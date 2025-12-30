class_name BerserkerBehavior
extends BaseClassBehavior

const BERSERK_EFFECT = preload("res://scripts/data/status_effects/berserk_effect.gd")
const BERSERKER_MINIGAME_CONTEXT = preload("res://scripts/data/berserker_minigame_context.gd")

func needs_target_selection() -> bool:
    return false  # Berserker doesn't need target selection

func build_minigame_context(character: Character, _target: Variant) -> MinigameContext:
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

func apply_attack_effects(attacker: Character, _target: EnemyData, base_damage: int) -> int:
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

func _remove_berserk_effect(character: Character) -> void:
    """Remove BerserkEffect from character, which will clean up class_state and attribute effects."""
    # Find and remove BerserkEffect using script comparison
    var to_remove: Array[StatusEffect] = []
    for effect in character.status_effects:
        if effect.get_script() == BERSERK_EFFECT:
            to_remove.append(effect)
    
    # Remove effects (call on_remove for cleanup if it exists)
    for effect in to_remove:
        if effect.has_method("on_remove"):
            effect.on_remove()
        character.status_effects.erase(effect)

func format_minigame_result(character: Character, result: MinigameResult) -> Array[String]:
    """Format Berserker minigame results for logging."""
    var log_entries: Array[String] = []
    
    if result == null or result.metadata.is_empty():
        return log_entries
    
    var hand_value: int = result.metadata.get("hand_value", 0)
    var busted: bool = result.metadata.get("busted", false)
    var blackjack: bool = result.metadata.get("blackjack", false)
    var cards_drawn: int = result.metadata.get("cards_drawn", 0)
    
    # Log the hand result
    if blackjack:
        log_entries.append("%s scores BLACKJACK! (21 with %d cards)" % [character.display_name, cards_drawn])
    elif busted:
        log_entries.append("%s busts with %d! (drew %d cards)" % [character.display_name, hand_value, cards_drawn])
    else:
        log_entries.append("%s stands with %d (drew %d cards)" % [character.display_name, hand_value, cards_drawn])
    
    # Log berserk state if applicable
    var is_berserking: bool = result.metadata.get("is_berserking", false)
    var berserk_stacks: int = result.metadata.get("berserk_stacks", 0)
    if is_berserking and berserk_stacks > 0:
        if berserk_stacks == 1:
            log_entries.append("%s enters Berserk state! (+1 Power, +1 Speed)" % character.display_name)
        else:
            log_entries.append("%s's Berserk state intensifies! (%d stacks: +%d Power, +%d Speed)" % [character.display_name, berserk_stacks, berserk_stacks, berserk_stacks])
    
    return log_entries

func get_ability_target(_character: Character, _result: MinigameResult) -> Variant:
    """Berserker may hit all enemies/allies, so return null (target should be provided)."""
    return null
