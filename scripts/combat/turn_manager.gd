class_name TurnManager
extends RefCounted

var battle_state: BattleState

func _init(p_battle_state: BattleState):
	battle_state = p_battle_state

func calculate_initial_turn_order() -> void:
	"""Calculate initial turn order for all combatants at combat start."""
	battle_state.turn_order.clear()
	
	# Add party members to turn order from BattleState
	for character in battle_state.party_states:
		if character.is_alive():
			var speed: int = character.get_effective_attributes().speed
			var turn_value: int = _roll_turn_value(speed)
			var entry: TurnOrderEntry = TurnOrderEntry.new(
				character,
				turn_value,
				true,
				character.display_name
			)
			battle_state.turn_order.append(entry)
	
	# Add enemies to turn order from BattleState
	for enemy in battle_state.enemy_states:
		if enemy.is_alive():
			var speed: int = enemy.get_effective_attributes().speed
			var turn_value: int = _roll_turn_value(speed)
			var entry: TurnOrderEntry = TurnOrderEntry.new(
				enemy,
				turn_value,
				false,
				enemy.display_name
			)
			battle_state.turn_order.append(entry)
	
	# Sort by turn value (ascending - lower numbers first)
	battle_state.turn_order.sort_custom(_sort_turn_order)
	
	# Reset turn index
	battle_state.current_turn_index = 0
	battle_state.turn_count = 0

func update_turn_order_after_action() -> void:
	"""Update turn order after an action completes. Remove current turn and add new one."""
	if battle_state.turn_order.is_empty():
		return
	
	# Get the combatant that just acted
	var current_entry: TurnOrderEntry = battle_state.turn_order[battle_state.current_turn_index]
	var combatant: BattleEntity = current_entry.combatant
	
	# Check if combatant is still alive
	var is_alive: bool = combatant.is_alive()
	
	# Remove current turn entry
	battle_state.turn_order.remove_at(battle_state.current_turn_index)
	
	# If combatant is still alive, add new turn entry
	if is_alive:
		var speed: int = combatant.get_effective_attributes().speed
		
		# Roll new turn value and add it to the previous turn value
		# This makes the next action happen at a later time
		var previous_turn_value: int = current_entry.turn_value
		var new_roll: int = _roll_turn_value(speed)
		var turn_value: int = previous_turn_value + new_roll
		
		var new_entry: TurnOrderEntry = TurnOrderEntry.new(
			combatant,
			turn_value,
			current_entry.is_party,
			current_entry.display_name
		)
		battle_state.turn_order.append(new_entry)
	
	# Remove any dead combatants from turn order
	remove_dead_combatants()
	
	# Re-sort turn order
	battle_state.turn_order.sort_custom(_sort_turn_order)
	
	# Update turn index (it should point to the next turn, which is now at index 0)
	battle_state.current_turn_index = 0
	battle_state.turn_count += 1

func advance_turn() -> void:
	"""Advance to the next turn. Updates turn order after action."""
	update_turn_order_after_action()

func get_current_turn_combatant() -> BattleEntity:
	"""Get the combatant whose turn it currently is."""
	if battle_state.turn_order.is_empty() or battle_state.current_turn_index >= battle_state.turn_order.size():
		return null
	
	return battle_state.turn_order[battle_state.current_turn_index].combatant

func remove_dead_combatants() -> void:
	"""Remove dead combatants from turn order."""
	var to_remove: Array[int] = []
	for i in range(battle_state.turn_order.size()):
		var entry: TurnOrderEntry = battle_state.turn_order[i]
		var is_alive: bool = entry.combatant.is_alive()
		
		if not is_alive:
			to_remove.append(i)
	
	# Remove in reverse order to maintain indices
	to_remove.reverse()
	for i in to_remove:
		battle_state.turn_order.remove_at(i)

func _roll_turn_value(speed: int) -> int:
	"""Roll for turn value: random(10-20) - speed. Lower values go first."""
	var roll: int = randi_range(10, 20)
	return roll - speed

func _sort_turn_order(a: TurnOrderEntry, b: TurnOrderEntry) -> bool:
	"""Sort function for turn order: lower turn_value first, then by speed if tied."""
	if a.turn_value != b.turn_value:
		return a.turn_value < b.turn_value
	
	# If turn values are equal, sort by speed (higher speed first)
	# Use get_effective_attributes() from base BattleEntity class
	var a_speed: int = a.combatant.get_effective_attributes().speed
	var b_speed: int = b.combatant.get_effective_attributes().speed
	
	return a_speed > b_speed

