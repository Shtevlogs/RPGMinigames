class_name CombatInitializer
extends RefCounted

const BATTLE_STATE = preload("res://scripts/data/battle_state.gd")

func initialize_combat(encounter: Encounter, party: Array[CharacterBattleEntity], combat_log: CombatLog) -> BattleState:
	"""Initialize battle state from encounter and party."""
	var battle_state: BattleState = BattleState.new()
	
	if encounter != null:
		battle_state.encounter_id = encounter.encounter_id
	
	# Initialize party states (store references to entities)
	battle_state.party_states.clear()
	for character in party:
		battle_state.party_states.append(character)
	
	# Initialize enemy states (store references to entities)
	battle_state.enemy_states.clear()
	if encounter != null:
		for enemy in encounter.enemy_composition:
			battle_state.enemy_states.append(enemy)
	
	battle_state.turn_count = 0
	battle_state.minigame_state = null
	battle_state.combat_log = combat_log  # Provide combat log reference for status effects
	
	# Set battle_state on all registered behaviors
	for behavior in MinigameRegistry.class_behaviors.values():
		if behavior is BaseClassBehavior:
			behavior.battle_state = battle_state
	
	return battle_state

# Display setup now handled directly in combat.gd

func show_encounter_message(encounter: Encounter, combat_log: CombatLog) -> void:
	"""Show encounter message with delay."""
	if encounter == null:
		return
	
	# TODO: Display encounter message UI
	# For now, just log it
	var message: String = encounter.encounter_name if encounter.encounter_name != "" else "Encounter begins!"
	if combat_log != null:
		combat_log.add_entry(message, combat_log.EventType.TURN_START)
	
	# Play sound cue
	SoundManager.play_sfx(SoundManager.SFX_ACTION_MENU_SELECT)  # Placeholder

