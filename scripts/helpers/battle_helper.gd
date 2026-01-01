class_name BattleHelper

static func calculate_base_attack_damage(attacker: BattleEntity, _target: BattleEntity) -> int:
    # Calculate damage from Power attribute
    var effective_attrs: Attributes = attacker.get_effective_attributes()
    var damage: int = effective_attrs.power
    
    # TODO: account for target DR
    
    return damage
