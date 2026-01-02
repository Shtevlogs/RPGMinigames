class_name Combat
extends Control

@onready var party_container: HBoxContainer = $PartyContainer
@onready var enemy_container: Control = $EnemyContainer
@onready var turn_order_container: HBoxContainer = $TurnOrderContainer
@onready var attack_button: Button = $ActionPanel/AttackButton
@onready var item_button: Button = $ActionPanel/ItemButton
@onready var ability_button: Button = $ActionPanel/AbilityButton
@onready var win_button: Button = $ActionPanel/WinButton
@onready var combat_log: Node = $CombatLog  # CombatLog type - using Node to avoid linter false positives

var current_encounter: Encounter = null
var battle_state: BattleState = null  # Battle state as source of truth
var current_modal: Control = null  # Current open modal (MinigameModal)
var current_ability_target: BattleEntity = null  # Target for current ability
var is_input_blocked: bool = false  # Input blocking flag

# Combat system modules
var turn_manager: TurnManager = null
var combat_ui: CombatUI = null
var action_handler: ActionHandler = null
var target_selector: TargetSelector = null
var combat_initializer: CombatInitializer = null
var combat_state: CombatState = null

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	item_button.pressed.connect(_on_item_pressed)
	ability_button.pressed.connect(_on_ability_pressed)
	win_button.pressed.connect(_on_win_pressed)
	
	# Initialize combat if we have a run
	if GameManager.current_run != null:
		initialize_combat()

func _input(event: InputEvent) -> void:
	if is_input_blocked:
		return  # Block input during delays and animations
	
	if event.is_action_pressed("ui_cancel") and target_selector != null and target_selector.is_selecting:
		target_selector.cancel_target_selection()

func initialize_combat() -> void:
	# Get next encounter from EncounterManager
	current_encounter = EncounterManager.get_next_encounter(
		GameManager.current_run.current_land_theme,
		GameManager.current_run.current_land,
		GameManager.current_run.encounter_progress
	)
	
	# Clear combat log for new encounter
	combat_log.clear_log()
	
	# Initialize modules
	combat_initializer = CombatInitializer.new()
	battle_state = combat_initializer.initialize_combat(current_encounter, GameManager.current_run.party, combat_log)
	
	# Create module instances
	combat_ui = CombatUI.new(battle_state, party_container, enemy_container, turn_order_container)
	turn_manager = TurnManager.new(battle_state)
	action_handler = ActionHandler.new(battle_state, combat_log, combat_ui)
	target_selector = TargetSelector.new(battle_state, party_container, enemy_container)
	combat_state = CombatState.new(battle_state, combat_log)
	
	# Wire module signals
	combat_state.encounter_completed.connect(_on_encounter_completed)
	combat_state.party_wipe.connect(_on_party_wipe)
	action_handler.character_died.connect(_on_character_died)
	action_handler.enemy_died.connect(_on_enemy_died)
	
	# Setup displays (connect enemy clicks)
	combat_ui.display_party()
	combat_ui.display_enemies(current_encounter, _on_enemy_target_selected)
	
	# Show encounter message with delay
	combat_initializer.show_encounter_message(current_encounter, combat_log)
	await DelayManager.wait(DelayManager.ENCOUNTER_MESSAGE_DELAY)
	
	# Calculate initial turn order
	turn_manager.calculate_initial_turn_order()
	_auto_save_battle_state()
	combat_ui.update_turn_order_display()
	
	# Process first turn
	_process_current_turn()

func _on_attack_pressed() -> void:
	var attacker := turn_manager.get_current_turn_combatant() as CharacterBattleEntity
	
	# Start target selection
	await _animate_party_displays_down()
	await _close_action_menu()
	
	target_selector.start_target_selection(attacker)\
		.connect(_on_target_selected.bind(attacker), CONNECT_ONE_SHOT)
	attack_button.disabled = true
	item_button.disabled = true
	ability_button.disabled = true

func _on_item_pressed() -> void:
	# Placeholder
	if combat_log != null:
		combat_log.add_entry("Item action selected", combat_log.EventType.ITEM)

func _on_ability_pressed() -> void:
	var current_combatant := turn_manager.get_current_turn_combatant() as CharacterBattleEntity
	
	# Determine if target selection is needed
	var needs_target: bool = _needs_target_selection(current_combatant.class_type)
	
	if needs_target:
		# Start target selection for ability
		await _animate_party_displays_down()
		await _close_action_menu()
		
		attack_button.disabled = true
		item_button.disabled = true
		ability_button.disabled = true
		
		target_selector.start_target_selection(current_combatant)\
			.connect(open_minigame_modal.bind(current_combatant), CONNECT_ONE_SHOT)
	else:
		# Open minigame modal directly
		open_minigame_modal(current_combatant, null)

func _on_win_pressed() -> void:
	# Temporary win button for testing progression
	print("Win button pressed - completing encounter")
	combat_state.complete_encounter()

func _on_encounter_completed() -> void:
	# Process rewards
	if current_encounter != null and current_encounter.rewards != null:
		_apply_rewards(current_encounter.rewards)
	
	# Update encounter progress
	GameManager.current_run.encounter_progress += 1
	
	# Transition to land screen instead of directly loading next encounter
	# The land screen will handle determining next encounter/land and transitioning back to combat
	SceneManager.go_to_land_screen()

func _on_party_wipe() -> void:
	GameManager.end_run(false)
	#TODO: display run stats w/e
	SceneManager.go_to_main_menu()

func _on_character_died(_character: CharacterBattleEntity) -> void:
	# TODO: is this necessary?
	combat_ui.update_party_displays()
	
	# Check for party wipe
	if combat_state.check_defeat():
		combat_state.handle_party_wipe()

func _on_enemy_died(enemy: EnemyBattleEntity) -> void:
	# Play death animation and sound
	SoundManager.play_sfx(SoundManager.SFX_ENEMY_DEATH)
	var effect_id = EffectIds.EffectIds.DEATH_EFFECT
	VfxManager.play_effect(effect_id, combat_ui.get_enemy_position(enemy))
	await DelayManager.wait(DelayManager.DEATH_ANIMATION_DURATION)
	
	# Remove from encounter composition (for cleanup)
	if current_encounter != null:
		current_encounter.enemy_composition.erase(enemy)
	
	# Remove from UI
	combat_ui.remove_enemy_display(enemy)
	
	# Check if encounter is complete (all enemies dead)
	if combat_state.check_victory():
		combat_state.complete_encounter()

func _on_target_selected(target: BattleEntity, source: BattleEntity) -> void:
	#TODO: handle targeting ally
	await execute_player_attack(source, target)

func _on_target_selection_canceled() -> void:
	await _animate_party_displays_up()
	await _open_action_menu()
	attack_button.disabled = false
	item_button.disabled = false
	ability_button.disabled = false

func _apply_rewards(rewards: Rewards) -> void:
	# Apply encounter rewards to run state
	if GameManager.current_run == null:
		return
	
	# Add items to inventory
	for item in rewards.items:
		GameManager.current_run.inventory.append(item)
	
	# Add currency
	GameManager.current_run.currency += rewards.currency
	
	# Equipment rewards would be handled here (future implementation)
	# For now, just add to inventory or handle separately

func _advance_to_next_land() -> void:
	# Advance to next land or complete run
	if GameManager.current_run == null:
		return
	
	# Check if run is complete (land 5 boss defeated)
	if GameManager.current_run.current_land >= 5:
		_complete_run()
		return
	
	# Advance to next land
	GameManager.current_run.current_land += 1
	GameManager.current_run.encounter_progress = 0
	
	# Set next land theme from sequence
	if GameManager.current_run.land_sequence.size() >= GameManager.current_run.current_land:
		GameManager.current_run.current_land_theme = GameManager.current_run.land_sequence[GameManager.current_run.current_land - 1]
	else:
		push_error("Land sequence incomplete, using fallback")
		GameManager.current_run.current_land_theme = "random"
	
	# Load first encounter of new land
	_load_next_encounter()

func _load_next_encounter() -> void:
	# Load next encounter in current land
	if GameManager.current_run == null:
		return
	
	# Get next encounter
	current_encounter = EncounterManager.get_next_encounter(
		GameManager.current_run.current_land_theme,
		GameManager.current_run.current_land,
		GameManager.current_run.encounter_progress
	)
	
	if current_encounter == null:
		push_error("Failed to load next encounter")
		return
	
	# Refresh display
	combat_ui.display_enemies(current_encounter, _on_enemy_target_selected)

func _complete_run() -> void:
	# Handle run completion
	if GameManager.current_run == null:
		return
	
	print("Run completed! Victory!")
	GameManager.end_run(true)
	SceneManager.go_to_main_menu()

# Battle State Management - now handled by CombatInitializer

func _auto_save_battle_state() -> void:
	if battle_state == null or GameManager.current_run == null:
		return
	
	# Serialize battle state
	var battle_state_data: Dictionary = battle_state.serialize()
	
	# Store in run state's auto_save_data
	GameManager.current_run.auto_save_data["battle_state"] = battle_state_data
	
	# Trigger auto-save
	SaveManager.auto_save(GameManager.current_run)

func block_input() -> void:
	is_input_blocked = true
	set_process_input(false)

func unblock_input() -> void:
	is_input_blocked = false
	set_process_input(true)

func _highlight_current_turn(entry: TurnOrderEntry) -> void:
	var combatant: BattleEntity = entry.combatant
	if combatant == null:
		return
	
	if combatant.is_party_member():
		combat_ui.highlight_party_member(combatant as CharacterBattleEntity, true)
		await DelayManager.wait(DelayManager.TURN_HIGHLIGHT_DURATION)
	else:
		combat_ui.highlight_enemy(combatant as EnemyBattleEntity, true)
		await DelayManager.wait(DelayManager.TURN_HIGHLIGHT_DURATION)
		# Remove highlight after delay for enemies
		combat_ui.highlight_enemy(combatant as EnemyBattleEntity, false)

func _animate_party_displays_down() -> void:
	# TODO: Implement actual animation
	# For now, just wait for delay
	await DelayManager.wait(DelayManager.TARGET_SELECTION_ARROW_DELAY)

func _animate_party_displays_up() -> void:
	# TODO: Implement actual animation
	# For now, just wait for delay
	await DelayManager.wait(DelayManager.TARGET_SELECTION_ARROW_DELAY)

func _open_action_menu() -> void:
	# TODO: Implement actual slide-in animation
	# For now, just wait for delay
	await DelayManager.wait(DelayManager.ACTION_MENU_BEAT_DURATION)
	SoundManager.play_sfx(SoundManager.SFX_ACTION_MENU_SELECT)

func _close_action_menu() -> void:
	# TODO: Implement actual slide-out animation
	# For now, just wait for delay
	await DelayManager.wait(DelayManager.ACTION_MENU_BEAT_DURATION)

# Turn Order System - now handled by TurnManager

func _process_current_turn() -> void:
	if battle_state.turn_order.is_empty() or battle_state.current_turn_index >= battle_state.turn_order.size():
		return
	
	# Don't process turns if encounter is complete (check BattleState)
	if not combat_state.check_victory():
		var has_alive_enemies: bool = false
		for enemy in battle_state.enemy_states:
			if enemy.is_alive():
				has_alive_enemies = true
				break
		if not has_alive_enemies:
			return
	
	var current_entry = battle_state.turn_order[battle_state.current_turn_index]
	var current_combatant = current_entry.combatant
	
	# Log turn start
	if combat_log != null:
		combat_log.add_entry("%s's turn" % current_entry.display_name, combat_log.EventType.TURN_START)
	
	# Highlight current turn with delay
	await _highlight_current_turn(current_entry)
	
	# Process status effects at start of turn (unified for all combatants)
	if current_combatant != null and current_combatant.is_alive():
		_process_combatant_status_effects(current_combatant)
	
	# If it's an enemy's turn, execute their attack automatically
	if not current_entry.is_party:
		if current_combatant != null and current_combatant.is_alive():
			# Enemy highlight animation with delay
			await DelayManager.wait(DelayManager.ENEMY_ACTION_ANIMATION_DURATION)
			execute_enemy_attack(current_combatant as EnemyBattleEntity)
	else:
		# Enable action buttons for player turn
		var character: CharacterBattleEntity = current_combatant as CharacterBattleEntity
		if character != null and character.is_alive():
			attack_button.disabled = false
			item_button.disabled = false
			ability_button.disabled = false

# Target Selection System - now handled by TargetSelector

func _needs_target_selection(class_type: GDScript) -> bool:
	var behavior = MinigameRegistry.get_behavior(class_type)
	if behavior == null:
		return false
	return behavior.needs_target_selection()

# Minigame Modal System
func open_minigame_modal(character: CharacterBattleEntity, target: BattleEntity) -> void:
	# Block input during minigame opening
	block_input()
	
	# Store target for later use
	current_ability_target = target
	
	# Get minigame scene path from registry
	var minigame_path: String = MinigameRegistry.get_minigame_scene_path(character.class_type)
	if minigame_path == "":
		var class_string = MinigameRegistry.get_class_type_string(character.class_type)
		push_error("Failed to get minigame scene path for class: " + class_string)
		unblock_input()
		return
	
	# Build typed context using behavior system
	var behavior = MinigameRegistry.get_behavior(character.class_type)
	var context: MinigameContext = null
	if behavior != null:
		context = behavior.build_minigame_context(character, target)
	else:
		var class_string = MinigameRegistry.get_class_type_string(character.class_type)
		push_error("Failed to get behavior for class: " + class_string)
		unblock_input()
		return
	
	# Create modal instance programmatically
	current_modal = MinigameModal.new()
	
	# Add modal to scene
	add_child(current_modal)
	
	# Wait for modal to be ready (so _ready() executes and creates UI structure)
	await get_tree().process_frame
	
	# Connect to modal signals
	if current_modal != null:
		current_modal.modal_closed.connect(_on_minigame_modal_closed)
		current_modal.minigame_result_received.connect(_on_minigame_completed)
		
		# Load minigame into modal (now that UI structure exists)
		current_modal.load_minigame(minigame_path, context)
	
	# Wait for minigame to fully open before accepting input
	await DelayManager.wait(DelayManager.MINIGAME_OPEN_BEAT_DURATION)
	SoundManager.play_sfx(SoundManager.SFX_MINIGAME_OPEN)
	
	# Unblock input (minigame can now accept input)
	unblock_input()
	
	# Disable action buttons while modal is open
	attack_button.disabled = true
	item_button.disabled = true
	ability_button.disabled = true
	
	# Log ability use
	if combat_log != null:
		combat_log.add_entry("%s uses ability" % character.display_name, combat_log.EventType.ABILITY)

# Context building is now handled directly by behavior classes - no conversion needed

func _on_minigame_modal_closed() -> void:
	# Clean up modal reference
	current_modal = null
	
	# Re-enable action buttons
	attack_button.disabled = false
	item_button.disabled = false
	ability_button.disabled = false

func _on_minigame_completed(result: MinigameResult) -> void:
	# Block input during minigame closing
	block_input()
	
	# Get character from current turn
	var current_combatant = turn_manager.get_current_turn_combatant()
	if current_combatant == null or not (current_combatant is CharacterBattleEntity):
		push_error("No valid character for minigame result")
		if current_modal != null:
			await close_minigame_modal()
		unblock_input()
		return
	
	var character: CharacterBattleEntity = current_combatant as CharacterBattleEntity
	
	# Get stored target
	var target: Variant = current_ability_target
	current_ability_target = null  # Clear after use
	
	# Close modal with delay
	if current_modal != null:
		await close_minigame_modal()
	
	# Wait for minigame effect animation
	await DelayManager.wait(DelayManager.MINIGAME_CLOSE_BEAT_DURATION)
	SoundManager.play_sfx(SoundManager.SFX_MINIGAME_CLOSE)
	
	# Apply minigame results
	_apply_minigame_result(character, result, target)
	
	# Unblock input
	unblock_input()
	
	# Advance turn
	turn_manager.advance_turn()
	_auto_save_battle_state()
	combat_ui.update_turn_order_display()
	_process_current_turn()

func _apply_minigame_result(character: CharacterBattleEntity, result: MinigameResult, _target: BattleEntity) -> void:
	if result == null:
		return
	
	# Log minigame result using behavior system
	_log_minigame_result(character, result)
	
	# Execute all actions in the result
	for action in result.actions:
		action_handler.execute_action(action)

func _log_minigame_result(character: CharacterBattleEntity, result: MinigameResult) -> void:
	if combat_log == null or result == null:
		return
	
	# Use behavior system to format results
	var behavior = MinigameRegistry.get_behavior(character.class_type)
	if behavior != null:
		var log_entries = behavior.format_minigame_result(character, result)
		for entry in log_entries:
			combat_log.add_entry(entry, combat_log.EventType.ABILITY)

func _process_combatant_status_effects(combatant: BattleEntity) -> void:
	# Store health before processing to detect changes
	var health_before: int = combatant.health.current
	
	# Process status effects - effects apply their changes directly
	if battle_state != null:
		combatant.tick_status_effects(battle_state)
	
	# Check if health changed (effects may have applied damage)
	var health_after: int = combatant.health.current
	if health_before != health_after:
		# Update UI based on combatant type
		if combatant.is_party_member():
			combat_ui.update_party_displays()
		else:
			combat_ui.update_enemy_displays()
		
		# Check if combatant died (status effects can cause death)
		if not combatant.is_alive():
			# Handle death via ActionHandler's death handling
			action_handler.handle_entity_death(combatant)


func close_minigame_modal() -> void:
	if current_modal != null:
		current_modal.close_modal()
		current_modal = null
		# Wait for close animation
		await DelayManager.wait(DelayManager.MINIGAME_CLOSE_BEAT_DURATION)

func _on_enemy_target_selected(enemy: EnemyBattleEntity) -> void:
	target_selector.handle_enemy_click(enemy)

# Player Attack Implementation
func execute_player_attack(attacker: CharacterBattleEntity, target: EnemyBattleEntity) -> void:
	# Block input during attack
	block_input()
	
	# Shake party member display
	await _shake_party_display(attacker)
	
	# Flash target and play attack animation
	await _flash_target(target)
	await DelayManager.wait(DelayManager.ATTACK_ANIMATION_DURATION)
	
	# Create attack action
	var behavior := MinigameRegistry.get_behavior(attacker.class_type)
	var action := behavior.get_attack_action(attacker, target, combat_log)
	
	# Execute attack via ActionHandler (handles damage and death)
	action_handler.execute_action(action)
	
	# Visual feedback
	_show_damage_feedback(target, 0)  # Damage already logged by ActionHandler
	
	# Unblock input
	unblock_input()
	
	# Advance turn
	turn_manager.advance_turn()
	_auto_save_battle_state()
	combat_ui.update_turn_order_display()
	_process_current_turn()

func _shake_party_display(_character: CharacterBattleEntity) -> void:
	# TODO: Implement actual shake animation
	# For now, just wait for delay
	await DelayManager.wait(0.1)

func _flash_target(_target: BattleEntity) -> void:
	# TODO: Implement actual flash animation (toggle alpha)
	# For now, just wait for delay
	await DelayManager.wait(0.1)

# Enemy Attack Implementation
func execute_enemy_attack(attacker: EnemyBattleEntity) -> void:
	if attacker == null:
		return
	
	if not attacker.is_alive():
		return
	
	# Select target (AI targeting)
	var target: CharacterBattleEntity = action_handler.select_enemy_target()
	if target == null:
		print("No valid target for enemy attack")
		turn_manager.advance_turn()
		_auto_save_battle_state()
		combat_ui.update_turn_order_display()
		_process_current_turn()
		return
	
	# Calculate Damage
	var damage = BattleHelper.calculate_base_attack_damage(attacker, target)
	
	# Execute attack via ActionHandler (handles damage and death)
	var action := Action.new(attacker, [target], damage, [])
	action_handler.execute_action(action)
	
	# Visual feedback
	_show_damage_feedback(target, 0)
	
	# Advance turn
	turn_manager.advance_turn()
	_auto_save_battle_state()
	combat_ui.update_turn_order_display()
	_process_current_turn()

# Visual Feedback and UI Updates
func _show_damage_feedback(_target: BattleEntity, _damage: int) -> void:
	# TODO: Implement floating damage numbers or damage popup
	pass

# UI updates now handled by CombatUI

# Death Handling - now handled by ActionHandler signals
