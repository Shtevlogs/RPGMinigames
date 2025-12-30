class_name WildMageBehavior
extends BaseClassBehavior

const WILD_MAGE_MINIGAME_CONTEXT = preload("res://scripts/data/wild_mage_minigame_context.gd")

func needs_target_selection() -> bool:
    return false  # WildMage doesn't need target selection

func build_minigame_context(character: CharacterBattleEntity, _target: BattleEntity) -> MinigameContext:
    """Build context data for Wild Mage minigame."""
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

func apply_attack_effects(_attacker: CharacterBattleEntity, _target: EnemyBattleEntity, base_damage: int) -> int:
    """Wild Mage attack effects: pre-draw a card for next minigame."""
    # TODO: Track pre-drawn card state for next minigame
    # For now, stubbed
    return base_damage

func format_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    """Format Wild Mage minigame results for logging."""
    # Use minigame's format_result() method if available
    # Otherwise, fall back to basic formatting
    var log_entries: Array[String] = []
    
    if result == null or result.metadata.is_empty():
        return log_entries
    
    # Try to use minigame's format_result method
    # This requires getting the minigame instance, which may not be available
    # For now, use basic formatting that matches the minigame's format_result
    
    var result_hand_type: String = result.metadata.get("hand_type", "high_card")
    var result_multiplier: float = result.metadata.get("multiplier", 1.0)
    
    # Format hand type name
    var hand_type_name: String = ""
    match result_hand_type:
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
    log_entries.append("%s forms a %s! (%.1fx damage)" % [character.display_name, hand_type_name, result_multiplier])
    
    return log_entries

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    """WildMage may hit all enemies/allies, so return null (target should be provided)."""
    return null
