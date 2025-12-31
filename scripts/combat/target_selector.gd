class_name TargetSelector
extends RefCounted

var battle_state: BattleState
var party_container: HBoxContainer
var enemy_container: Control

signal target_selected(target: BattleEntity, is_ability: bool)
signal selection_canceled

var is_selecting: bool = false
var pending_attacker: BattleEntity = null
var pending_ability_character: CharacterBattleEntity = null

func _init(p_battle_state: BattleState, p_party_container: HBoxContainer, p_enemy_container: Control):
    battle_state = p_battle_state
    party_container = p_party_container
    enemy_container = p_enemy_container

func start_target_selection(attacker: CharacterBattleEntity) -> void:
    """Start target selection mode for player attack."""
    is_selecting = true
    pending_attacker = attacker
    pending_ability_character = null
    
    # Highlight selectable enemies
    _update_enemy_selectability(true)

func start_ability_target_selection(character: CharacterBattleEntity) -> void:
    """Start target selection mode for ability."""
    is_selecting = true
    pending_ability_character = character
    pending_attacker = null
    
    # Highlight selectable enemies
    _update_enemy_selectability(true)

func cancel_target_selection() -> void:
    """Cancel target selection and return to normal state."""
    is_selecting = false
    pending_attacker = null
    pending_ability_character = null
    
    # Remove highlights
    _update_enemy_selectability(false)
    
    selection_canceled.emit()

func handle_enemy_click(enemy: EnemyBattleEntity) -> void:
    """Handle enemy target selection for player attack or ability."""
    if not is_selecting:
        return
    
    # Check if this is for an ability
    if pending_ability_character != null:
        # Store reference before cancel_target_selection() nulls it
        # TODO: maybe delete?
        var _ability_character: CharacterBattleEntity = pending_ability_character
        
        # Validate target
        if enemy == null or not enemy.is_alive():
            print("Invalid target selected")
            return
        
        # Validate target is in BattleState
        if battle_state == null or not battle_state.enemy_states.has(enemy):
            print("Target not in current encounter")
            return
        
        # Cancel target selection UI (this will null pending_ability_character)
        cancel_target_selection()
        
        # Emit signal with target and action type
        target_selected.emit(enemy, true)
        return
    
    # Otherwise, handle as attack
    if pending_attacker == null or not pending_attacker.is_party_member():
        cancel_target_selection()
        return
    
    #TODO: maybe delete?
    var _attacker: CharacterBattleEntity = pending_attacker as CharacterBattleEntity
    
    # Validate target
    if enemy == null or not enemy.is_alive():
        print("Invalid target selected")
        return
    
    # Validate target is in BattleState
    if battle_state == null or not battle_state.enemy_states.has(enemy):
        print("Target not in current encounter")
        return
    
    # Cancel target selection UI
    is_selecting = false
    pending_attacker = null
    _update_enemy_selectability(false)
    
    # Emit signal with target and action type
    target_selected.emit(enemy, false)

func _update_enemy_selectability(selectable: bool) -> void:
    """Update enemy displays to show selectable state."""
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data != null and enemy_display.enemy_data.is_alive():
                enemy_display.set_selectable(selectable)
            else:
                enemy_display.set_selectable(false)
