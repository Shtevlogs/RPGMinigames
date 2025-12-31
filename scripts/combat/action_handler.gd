class_name ActionHandler
extends RefCounted

var battle_state: BattleState
var combat_log: CombatLog
var combat_ui: CombatUI

signal action_completed
signal entity_died(entity: BattleEntity)
signal character_died(character: CharacterBattleEntity)
signal enemy_died(enemy: EnemyBattleEntity)

func _init(p_battle_state: BattleState, p_combat_log: CombatLog, p_combat_ui: CombatUI):
    battle_state = p_battle_state
    combat_log = p_combat_log
    combat_ui = p_combat_ui

func execute_attack(attacker: BattleEntity, target: BattleEntity) -> void:
    """Execute an attack action. Handles damage, death, and cleanup."""
    if attacker == null or target == null:
        return
    
    if not attacker.is_alive() or not target.is_alive():
        return
    
    # Calculate damage from Power attribute
    var effective_attrs: Attributes = attacker.get_effective_attributes()
    var damage: int = effective_attrs.power
    
    # Apply class-specific on-attack effects (may modify damage)
    if attacker is CharacterBattleEntity:
        damage = _apply_class_specific_attack_effects(attacker as CharacterBattleEntity, target as EnemyBattleEntity, damage)
    
    # Apply damage
    var actual_damage: int = target.take_damage(damage)
    
    # Log attack and damage
    if combat_log != null:
        combat_log.add_entry("%s attacks %s" % [attacker.display_name, target.display_name], combat_log.EventType.ATTACK)
        combat_log.add_entry("%s attacks %s for %d damage!" % [attacker.display_name, target.display_name, actual_damage], combat_log.EventType.DAMAGE)
    
    # Update UI based on target type
    if target.is_party_member():
        combat_ui.update_party_displays()
    else:
        combat_ui.update_enemy_displays()
    
    # Check for death and handle it
    if not target.is_alive():
        handle_entity_death(target)
    
    action_completed.emit()

func execute_action(action: Action) -> void:
    """Execute a single action: apply damage and status effects, check for death."""
    if action == null:
        return
    
    # Get source entity name for logging (use source if available, otherwise fallback)
    var source_name: String = "Unknown"
    if action.source != null:
        source_name = action.source.display_name
    
    # Track entities that might die
    var entities_to_check: Array[BattleEntity] = []
    
    # Apply damage to all targets (if damage > 0)
    if action.damage > 0:
        for target in action.targets:
            if target != null and target.is_alive():
                var actual_damage: int = target.take_damage(action.damage)
                if combat_log != null:
                    combat_log.add_entry("%s deals %d damage to %s!" % [source_name, actual_damage, target.display_name], combat_log.EventType.DAMAGE)
                
                if not entities_to_check.has(target):
                    entities_to_check.append(target)
                
                # Update UI based on target type
                if target.is_party_member():
                    combat_ui.update_party_displays()
                else:
                    combat_ui.update_enemy_displays()
    
    # Apply status effects
    for effect in action.status_effects:
        if effect.target != null:
            effect.target.add_status_effect(effect)
            if combat_log != null:
                combat_log.add_entry("%s applies %s to %s!" % [source_name, effect.get_effect_name(), effect.target.display_name], combat_log.EventType.STATUS_EFFECT)
            
            # Track for death check
            if not entities_to_check.has(effect.target):
                entities_to_check.append(effect.target)
            
            # Update UI based on target type
            if effect.target.is_party_member():
                combat_ui.update_party_displays()
            else:
                combat_ui.update_enemy_displays()
        else:
            push_warning("Effect has no target: %s" % effect.get_effect_name())
    
    # Check for death on all affected entities
    for entity in entities_to_check:
        if not entity.is_alive():
            handle_entity_death(entity)
    
    action_completed.emit()

func execute_item(character: CharacterBattleEntity, item: Item, _target: BattleEntity) -> void:
    """Execute an item action."""
    # TODO: Implement item execution
    if combat_log != null:
        combat_log.add_entry("%s uses %s" % [character.display_name, item.item_name], combat_log.EventType.ITEM)
    
    action_completed.emit()

func select_enemy_target() -> CharacterBattleEntity:
    """AI target selection: prioritize taunt, otherwise random alive party member."""
    if battle_state == null:
        return null
    
    var alive_party: Array[CharacterBattleEntity] = []
    var taunted_party: Array[CharacterBattleEntity] = []
    
    # Find alive party members and check for taunt from BattleState
    for character in battle_state.party_states:
        if character.is_alive():
            alive_party.append(character)
            if character.has_status_effect(TauntEffect):
                taunted_party.append(character)
    
    # Prioritize taunted characters
    if not taunted_party.is_empty():
        return taunted_party[randi() % taunted_party.size()]
    
    # Otherwise random alive party member
    if not alive_party.is_empty():
        return alive_party[randi() % alive_party.size()]
    
    return null

func _apply_class_specific_attack_effects(attacker: CharacterBattleEntity, target: EnemyBattleEntity, base_damage: int) -> int:
    """Apply class-specific on-attack effects. Returns modified damage."""
    var behavior = MinigameRegistry.get_behavior(attacker.class_type)
    if behavior != null:
        return behavior.apply_attack_effects(attacker, target, base_damage)
    return base_damage



func handle_entity_death(entity: BattleEntity) -> void:
    """Handle entity death: cleanup status effects, log death, emit signals.
    Called after damage is applied (from actions or status effects)."""
    if entity == null:
        return
    
    # Log death
    if combat_log != null:
        combat_log.add_entry("%s has been defeated!" % entity.display_name, combat_log.EventType.DEATH)
    
    # Remove all status effects
    if battle_state != null:
        entity.status_manager.clear_effects(battle_state)
    
    # Emit appropriate signals
    entity_died.emit(entity)
    
    if entity is CharacterBattleEntity:
        character_died.emit(entity as CharacterBattleEntity)
    elif entity is EnemyBattleEntity:
        enemy_died.emit(entity as EnemyBattleEntity)
