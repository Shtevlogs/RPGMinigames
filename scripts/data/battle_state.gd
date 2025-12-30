class_name BattleState
extends RefCounted

var turn_order: Array[TurnOrderEntry] = []
var current_turn_index: int = 0
var party_states: Array[EntityBattleState] = []
var enemy_states: Array[EntityBattleState] = []
var minigame_state: MinigameBattleState = null
var encounter_id: String = ""
var turn_count: int = 0

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
    for state in party_states:
        party_states_data.append(state.serialize())
    data["party_states"] = party_states_data
    
    # Serialize enemy states
    var enemy_states_data: Array[Dictionary] = []
    for state in enemy_states:
        enemy_states_data.append(state.serialize())
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
    
    # Turn order and entity states would need to be reconstructed
    # from entity references - this is handled by combat system
    turn_order.clear()
    party_states.clear()
    enemy_states.clear()
    
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
