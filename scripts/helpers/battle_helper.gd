class_name BattleHelper

static func calculate_base_attack_damage(attacker: BattleEntity, target: BattleEntity) -> int:
    # Calculate damage from Power attribute
    var effective_attrs: Attributes = attacker.get_effective_attributes()
    var damage: int = effective_attrs.power
    
    # Apply class-specific on-attack effects (may modify damage)
    if attacker is CharacterBattleEntity:
        var behavior = MinigameRegistry.get_behavior(attacker.class_type)
        damage = behavior.apply_attack_effects(attacker, target, damage)
    
    return damage
