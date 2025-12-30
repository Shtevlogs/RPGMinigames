class_name MonkBehavior
extends BaseClassBehavior

const ALTER_ATTRIBUTE_EFFECT = preload("res://scripts/data/status_effects/alter_attribute_effect.gd")
const MONK_MINIGAME_CONTEXT = preload("res://scripts/data/monk_minigame_context.gd")

func needs_target_selection() -> bool:
    return true  # Monk needs target selection

func build_minigame_context(character: CharacterBattleEntity, target: BattleEntity) -> MinigameContext:
    """Build context data for Monk minigame."""
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
    
    var context = MONK_MINIGAME_CONTEXT.new(
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

func apply_attack_effects(_attacker: CharacterBattleEntity, target: EnemyBattleEntity, base_damage: int) -> int:
    """Monk attack effects: reduce target's Strategy by 1 (stacking)."""
    # Apply AlterAttributeEffect to reduce Strategy by 1
    # Duration of 99 turns (effectively until end of encounter or removed)
    var strategy_debuff = ALTER_ATTRIBUTE_EFFECT.new("strategy", -1, 99)
    target.add_status_effect(strategy_debuff)
    return base_damage

func format_minigame_result(_character: CharacterBattleEntity, result: MinigameResult) -> Array[String]:
    """Format Monk minigame results for logging."""
    # The minigame's format_result() method handles formatting
    # This method can add behavior-specific formatting if needed
    if result == null:
        return []
    
    # Call minigame's format_result if available
    # For now, return empty (minigame handles its own formatting)
    return []

func get_ability_target(_character: CharacterBattleEntity, _result: MinigameResult) -> Variant:
    """Monk needs a target, so return null (target should be provided)."""
    return null
