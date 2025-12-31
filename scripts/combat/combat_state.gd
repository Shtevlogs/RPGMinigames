class_name CombatState
extends RefCounted

var battle_state: BattleState
var combat_log: CombatLog

signal encounter_completed
signal party_wipe

func _init(p_battle_state: BattleState, p_combat_log: CombatLog):
	battle_state = p_battle_state
	combat_log = p_combat_log

func check_victory() -> bool:
	"""Check if all enemies are dead."""
	if battle_state == null:
		return false
	
	for enemy in battle_state.enemy_states:
		if enemy.is_alive():
			return false
	
	return true

func check_defeat() -> bool:
	"""Check if all party members are dead."""
	if battle_state == null:
		return true
	
	for character in battle_state.party_states:
		if character.is_alive():
			return false
	
	return true

func complete_encounter() -> void:
	"""Handle encounter completion."""
	encounter_completed.emit()

func handle_party_wipe() -> void:
	"""Handle party wipe: trigger run failure."""
	# Log party wipe
	if combat_log != null:
		combat_log.add_entry("Party wipe! Run failed.", combat_log.EventType.DEATH)
	
	party_wipe.emit()

# Death handling moved to ActionHandler - all deaths occur during actions

