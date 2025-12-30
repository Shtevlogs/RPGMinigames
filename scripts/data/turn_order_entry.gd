class_name TurnOrderEntry
extends RefCounted

var combatant: BattleEntity
var turn_value: int
var is_party: bool
var display_name: String

func _init(p_combatant: BattleEntity, p_turn_value: int, p_is_party: bool, p_display_name: String):
    combatant = p_combatant
    turn_value = p_turn_value
    is_party = p_is_party
    display_name = p_display_name
