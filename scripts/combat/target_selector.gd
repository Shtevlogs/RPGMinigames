class_name TargetSelector
extends RefCounted

var battle_state: BattleState
var party_container: HBoxContainer
var enemy_container: Control

signal target_selected(target: BattleEntity)

var is_selecting: bool = false
var pending_attacker: BattleEntity = null
var pending_ability_character: CharacterBattleEntity = null

func _init(p_battle_state: BattleState, p_party_container: HBoxContainer, p_enemy_container: Control):
    battle_state = p_battle_state
    party_container = p_party_container
    enemy_container = p_enemy_container

func start_target_selection(attacker: CharacterBattleEntity) -> Signal:
    is_selecting = true
    pending_attacker = attacker
    pending_ability_character = null
    
    # Highlight selectable enemies
    _update_enemy_selectability(true)
    
    return target_selected

func cancel_target_selection() -> void:
    is_selecting = false
    pending_attacker = null
    pending_ability_character = null
    
    # Remove highlights
    _update_enemy_selectability(false)

func handle_enemy_click(enemy: EnemyBattleEntity) -> void:
    if not is_selecting:
        return
    
    # Cancel target selection UI (this will null pending_ability_character)
    cancel_target_selection()
    
    # Emit signal with target and action type
    target_selected.emit(enemy)

func _update_enemy_selectability(selectable: bool) -> void:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data != null and enemy_display.enemy_data.is_alive():
                enemy_display.set_selectable(selectable)
            else:
                enemy_display.set_selectable(false)
