class_name BattleState
extends GameStateSerializable

var turn_order: Array[TurnOrderEntry] = []
var current_turn_index: int = 0
var party_states: Array[CharacterBattleEntity] = []
var enemy_states: Array[EnemyBattleEntity] = []
var minigame_state: MinigameBattleState = null
var encounter_id: String = ""
var turn_count: int = 0
var combat_log: CombatLog = null  # Reference to CombatLog for status effects to use for logging

func serialize() -> Dictionary:
    """Serialize battle state to dictionary for save system."""
    var data: Dictionary = {
        "encounter_id": encounter_id,
        "turn_count": turn_count,
        "current_turn_index": current_turn_index
    }
    
    # Serialize turn order
    var turn_order_data: Array[Dictionary] = []
    for entry in turn_order:
        turn_order_data.append({
            "turn_value": entry.turn_value,
            "is_party": entry.is_party,
            "display_name": entry.display_name,
            "combatant_id": _get_combatant_id(entry.combatant, entry.is_party)
        })
    data["turn_order"] = turn_order_data
    
    # Serialize party states
    var party_states_data: Array[Dictionary] = []
    for entity in party_states:
        party_states_data.append(entity.serialize())
    data["party_states"] = party_states_data
    
    # Serialize enemy states
    var enemy_states_data: Array[Dictionary] = []
    for entity in enemy_states:
        enemy_states_data.append(entity.serialize())
    data["enemy_states"] = enemy_states_data
    
    # Serialize minigame state if present
    if minigame_state != null:
        data["minigame_state"] = minigame_state.serialize()
    else:
        data["minigame_state"] = null
    
    return data

func deserialize(data: Dictionary) -> void:
    """Deserialize battle state from dictionary."""
    encounter_id = data.get("encounter_id", "")
    turn_count = data.get("turn_count", 0)
    current_turn_index = data.get("current_turn_index", 0)
    
    # Deserialize party states
    party_states.clear()
    var party_states_data: Array = data.get("party_states", [])
    for entity_data in party_states_data:
        if entity_data is Dictionary:
            var character: CharacterBattleEntity = CharacterBattleEntity.new()
            character.deserialize(entity_data)
            party_states.append(character)
    
    # Deserialize enemy states
    enemy_states.clear()
    var enemy_states_data: Array = data.get("enemy_states", [])
    for entity_data in enemy_states_data:
        if entity_data is Dictionary:
            var enemy: EnemyBattleEntity = EnemyBattleEntity.new()
            enemy.deserialize(entity_data)
            enemy_states.append(enemy)
    
    # Turn order will be reconstructed by combat system from entity references
    turn_order.clear()
    
    # Deserialize minigame state if present
    var minigame_data = data.get("minigame_state", null)
    if minigame_data != null:
        minigame_state = MinigameBattleState.new()
        minigame_state.deserialize(minigame_data)
    else:
        minigame_state = null

func _get_combatant_id(combatant: BattleEntity, _is_party: bool) -> String:
    """Get ID string for combatant."""
    return combatant.entity_id
