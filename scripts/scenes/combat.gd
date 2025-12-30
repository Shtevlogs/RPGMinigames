class_name Combat
extends Control

const MinigameModalScript = preload("res://scripts/ui/minigame_modal.gd")
const BURN_EFFECT = preload("res://scripts/data/status_effects/burn_effect.gd")
const SILENCE_EFFECT = preload("res://scripts/data/status_effects/silence_effect.gd")
const TAUNT_EFFECT = preload("res://scripts/data/status_effects/taunt_effect.gd")
const ALTER_ATTRIBUTE_EFFECT = preload("res://scripts/data/status_effects/alter_attribute_effect.gd")
const BERSERK_EFFECT = preload("res://scripts/data/status_effects/berserk_effect.gd")
const BATTLE_STATE = preload("res://scripts/data/battle_state.gd")
const ENTITY_BATTLE_STATE = preload("res://scripts/data/entity_battle_state.gd")
const MINIGAME_CONTEXT = preload("res://scripts/data/minigame_context.gd")
const BERSERKER_MINIGAME_CONTEXT = preload("res://scripts/data/berserker_minigame_context.gd")
const MONK_MINIGAME_CONTEXT = preload("res://scripts/data/monk_minigame_context.gd")
const TIME_WIZARD_MINIGAME_CONTEXT = preload("res://scripts/data/time_wizard_minigame_context.gd")
const WILD_MAGE_MINIGAME_CONTEXT = preload("res://scripts/data/wild_mage_minigame_context.gd")
const EFFECT_IDS = preload("res://scripts/data/effect_ids.gd")

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
var turn_order: Array[TurnOrderEntry] = []  # Will contain turn order entries (synced from battle_state)
var current_turn_index: int = 0  # Synced from battle_state
var is_selecting_target: bool = false  # State for target selection
var pending_attacker: BattleEntity = null  # BattleEntity waiting to attack
var pending_ability_character: Character = null  # Character waiting to use ability
var current_modal: Control = null  # Current open modal (MinigameModal)
var current_ability_target: BattleEntity = null  # Target for current ability
var is_input_blocked: bool = false  # Input blocking flag

func _ready() -> void:
    attack_button.pressed.connect(_on_attack_pressed)
    item_button.pressed.connect(_on_item_pressed)
    ability_button.pressed.connect(_on_ability_pressed)
    win_button.pressed.connect(_on_win_pressed)
    
    # Initialize combat if we have a run
    if GameManager.current_run != null:
        initialize_combat()
    else:
        # Ensure turn order display is initialized even if combat isn't ready
        update_turn_order_display()

func _input(event: InputEvent) -> void:
    """Handle input for canceling target selection."""
    if is_input_blocked:
        return  # Block input during delays and animations
    
    if event.is_action_pressed("ui_cancel") and is_selecting_target:
        cancel_target_selection()

func initialize_combat() -> void:
    # Load encounter based on run state
    if GameManager.current_run == null:
        push_error("No current run available")
        return
    
    # Get next encounter from EncounterManager
    current_encounter = EncounterManager.get_next_encounter(
        GameManager.current_run.current_land_theme,
        GameManager.current_run.current_land,
        GameManager.current_run.encounter_progress
    )
    
    if current_encounter == null:
        push_error("Failed to load encounter")
        return
    
    # Clear combat log for new encounter
    if combat_log != null:
        combat_log.clear_log()
    
    display_party()
    display_enemies()
    
    # Initialize battle state
    _initialize_battle_state()
    
    # Show encounter message with delay
    await _show_encounter_message()
    
    calculate_initial_turn_order()
    # Process first turn (in case it's an enemy turn)
    _process_current_turn()

func display_party() -> void:
    # Clear existing
    for child in party_container.get_children():
        child.queue_free()
    
    # Display party members
    if GameManager.current_run == null:
        return
    
    for character in GameManager.current_run.party:
        var char_ui: Node = preload("res://ui/character_display.tscn").instantiate()
        char_ui.set_character(character)
        party_container.add_child(char_ui)

func display_enemies() -> void:
    # Clear existing
    clear_enemies()
    
    # Check if encounter exists and has enemies
    if current_encounter == null:
        return
    
    if current_encounter.enemy_composition.is_empty():
        return
    
    # Display enemies using formation positions
    for i in range(current_encounter.enemy_composition.size()):
        var enemy: EnemyData = current_encounter.enemy_composition[i]
        var enemy_ui: Node = preload("res://ui/enemy_display.tscn").instantiate()
        
        # Cast to EnemyDisplay to access methods
        if enemy_ui is EnemyDisplay:
            var enemy_display: EnemyDisplay = enemy_ui as EnemyDisplay
            enemy_display.set_enemy(enemy)
            # Connect click signal for target selection
            enemy_display.enemy_clicked.connect(_on_enemy_target_selected)
        
        # Position using formation coordinates
        if i < current_encounter.enemy_formation.size():
            enemy_ui.position = current_encounter.enemy_formation[i]
        else:
            # Fallback positioning if formation array is shorter than composition
            enemy_ui.position = Vector2(i * 150, 0)
        
        enemy_container.add_child(enemy_ui)

func clear_enemies() -> void:
    # Remove all enemy display children
    for child in enemy_container.get_children():
        child.queue_free()

func _on_attack_pressed() -> void:
    # Validate it's a player character's turn
    var current_combatant = get_current_turn_combatant()
    if current_combatant == null:
        print("No current combatant")
        return
    
    # Check if it's a party member's turn
    if turn_order.is_empty() or current_turn_index >= turn_order.size():
        print("Invalid turn state")
        return
    
    var current_entry = turn_order[current_turn_index]
    if not current_entry.is_party:
        print("Not a player character's turn")
        return
    
    var attacker: Character = current_combatant as Character
    if not attacker.is_alive():
        print("Attacker is dead")
        return
    
    # Start target selection
    start_target_selection(attacker)

func _on_item_pressed() -> void:
    # Placeholder
    if combat_log != null:
        combat_log.add_entry("Item action selected", combat_log.EventType.ITEM)
    # TODO: After item action completes, call advance_turn()
    # advance_turn()

func _on_ability_pressed() -> void:
    # Validate it's a player character's turn
    var current_combatant = get_current_turn_combatant()
    if current_combatant == null:
        print("No current combatant")
        return
    
    # Check if it's a party member's turn
    if turn_order.is_empty() or current_turn_index >= turn_order.size():
        print("Invalid turn state")
        return
    
    var current_entry = turn_order[current_turn_index]
    if not current_entry.is_party:
        print("Not a player character's turn")
        return
    
    var character: Character = current_combatant as Character
    if not character.is_alive():
        print("Character is dead")
        return
    
    # Check if modal is already open
    if current_modal != null:
        print("Modal already open")
        return
    
    # Determine if target selection is needed
    var needs_target: bool = _needs_target_selection(character.class_type)
    
    if needs_target:
        # Start target selection for ability
        start_ability_target_selection(character)
    else:
        # Open minigame modal directly
        open_minigame_modal(character, null)

func _on_win_pressed() -> void:
    # Temporary win button for testing progression
    print("Win button pressed - completing encounter")
    complete_encounter()

func complete_encounter() -> void:
    # Handle encounter completion
    if GameManager.current_run == null:
        push_error("No current run available")
        return
    
    # Process rewards
    if current_encounter != null and current_encounter.rewards != null:
        _apply_rewards(current_encounter.rewards)
    
    # Update encounter progress
    GameManager.current_run.encounter_progress += 1
    
    # Transition to land screen instead of directly loading next encounter
    # The land screen will handle determining next encounter/land and transitioning back to combat
    SceneManager.go_to_land_screen()

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
    display_enemies()

func _complete_run() -> void:
    # Handle run completion
    if GameManager.current_run == null:
        return
    
    print("Run completed! Victory!")
    GameManager.end_run(true)
    SceneManager.go_to_main_menu()

# Battle State Management
func _initialize_battle_state() -> void:
    """Initialize battle state from encounter and party."""
    battle_state = BattleState.new()
    
    if current_encounter != null:
        battle_state.encounter_id = current_encounter.encounter_id
    
    # Initialize party states
    battle_state.party_states.clear()
    if GameManager.current_run != null:
        for character in GameManager.current_run.party:
            var char_state: EntityBattleState = ENTITY_BATTLE_STATE.new()
            char_state.from_entity(character)
            battle_state.party_states.append(char_state)
    
    # Initialize enemy states
    battle_state.enemy_states.clear()
    if current_encounter != null:
        for enemy in current_encounter.enemy_composition:
            var enemy_state: EntityBattleState = ENTITY_BATTLE_STATE.new()
            enemy_state.from_entity(enemy)
            battle_state.enemy_states.append(enemy_state)
    
    battle_state.turn_count = 0
    battle_state.minigame_state = null

func _update_battle_state() -> void:
    """Update battle state after each action."""
    if battle_state == null:
        return
    
    # Sync turn order from battle state
    turn_order = battle_state.turn_order.duplicate()
    current_turn_index = battle_state.current_turn_index
    
    # Update party states
    if GameManager.current_run != null:
        for i in range(min(battle_state.party_states.size(), GameManager.current_run.party.size())):
            var character: Character = GameManager.current_run.party[i]
            var char_state: EntityBattleState = battle_state.party_states[i]
            char_state.from_entity(character)
    
    # Update enemy states
    if current_encounter != null:
        for i in range(min(battle_state.enemy_states.size(), current_encounter.enemy_composition.size())):
            var enemy: EnemyData = current_encounter.enemy_composition[i]
            var enemy_state: EntityBattleState = battle_state.enemy_states[i]
            enemy_state.from_entity(enemy)

func _sync_battle_state_to_entities() -> void:
    """Sync battle state changes back to entities."""
    if battle_state == null:
        return
    
    # Sync turn order to battle state
    battle_state.turn_order = turn_order.duplicate()
    battle_state.current_turn_index = current_turn_index
    
    # Sync party states back to characters (if needed)
    # For now, entities are source of truth, battle state is snapshot
    # This method is for future use if we need to restore from battle state

func _auto_save_battle_state() -> void:
    """Auto-save battle state after turn order is determined."""
    if battle_state == null or GameManager.current_run == null:
        return
    
    # Serialize battle state
    var battle_state_data: Dictionary = battle_state.serialize()
    
    # Store in run state's auto_save_data
    GameManager.current_run.auto_save_data["battle_state"] = battle_state_data
    
    # Trigger auto-save
    SaveManager.auto_save(GameManager.current_run)

func block_input() -> void:
    """Block input during delays and animations."""
    is_input_blocked = true
    set_process_input(false)

func unblock_input() -> void:
    """Unblock input after delays and animations."""
    is_input_blocked = false
    set_process_input(true)

func _show_encounter_message() -> void:
    """Show encounter message with delay."""
    if current_encounter == null:
        return
    
    # TODO: Display encounter message UI
    # For now, just log it
    var message: String = current_encounter.encounter_name if current_encounter.encounter_name != "" else "Encounter begins!"
    if combat_log != null:
        combat_log.add_entry(message, combat_log.EventType.TURN_START)
    
    # Play sound cue
    SoundManager.play_sfx(SoundManager.SFX_ACTION_MENU_SELECT)  # Placeholder
    
    # Wait for delay
    await DelayManager.wait(DelayManager.ENCOUNTER_MESSAGE_DELAY)

func _highlight_current_turn(entry: TurnOrderEntry) -> void:
    """Highlight current turn combatant with delay."""
    if entry.is_party:
        var character: Character = entry.combatant as Character
        if character != null:
            _highlight_party_member(character, true)
            await DelayManager.wait(DelayManager.TURN_HIGHLIGHT_DURATION)
    else:
        var enemy: EnemyData = entry.combatant as EnemyData
        if enemy != null:
            _highlight_enemy(enemy, true)
            await DelayManager.wait(DelayManager.TURN_HIGHLIGHT_DURATION)
            # Remove highlight after delay for enemies
            _highlight_enemy(enemy, false)

func _highlight_party_member(character: Character, highlight: bool) -> void:
    """Highlight party member with border (persistent for party turns)."""
    for child in party_container.get_children():
        if child is CharacterDisplay:
            var char_display: CharacterDisplay = child as CharacterDisplay
            if char_display.character == character:
                char_display.set_highlighted(highlight)

func _highlight_enemy(enemy: EnemyData, highlight: bool) -> void:
    """Highlight enemy with glow effect (temporary for enemy turns)."""
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                enemy_display.set_highlighted(highlight)

func _animate_party_displays_down() -> void:
    """Animate party displays down (for target selection)."""
    # TODO: Implement actual animation
    # For now, just wait for delay
    await DelayManager.wait(DelayManager.TARGET_SELECTION_ARROW_DELAY)

func _animate_party_displays_up() -> void:
    """Animate party displays back up (after canceling target selection)."""
    # TODO: Implement actual animation
    # For now, just wait for delay
    await DelayManager.wait(DelayManager.TARGET_SELECTION_ARROW_DELAY)

func _open_action_menu() -> void:
    """Open action menu with slide-in animation."""
    # TODO: Implement actual slide-in animation
    # For now, just wait for delay
    await DelayManager.wait(DelayManager.ACTION_MENU_BEAT_DURATION)
    SoundManager.play_sfx(SoundManager.SFX_ACTION_MENU_SELECT)

func _close_action_menu() -> void:
    """Close action menu with slide-out animation."""
    # TODO: Implement actual slide-out animation
    # For now, just wait for delay
    await DelayManager.wait(DelayManager.ACTION_MENU_BEAT_DURATION)

# Turn Order System
func calculate_initial_turn_order() -> void:
    """Calculate initial turn order for all combatants at combat start."""
    turn_order.clear()
    
    # Add party members to turn order
    if GameManager.current_run != null:
        for character in GameManager.current_run.party:
            if character.is_alive():
                var speed: int = character.get_effective_attributes().speed
                var turn_value: int = _roll_turn_value(speed)
                var entry: TurnOrderEntry = TurnOrderEntry.new(
                    character,
                    turn_value,
                    true,
                    character.display_name
                )
                turn_order.append(entry)
    
    # Add enemies to turn order
    if current_encounter != null:
        for enemy in current_encounter.enemy_composition:
            if enemy.is_alive():
                var speed: int = enemy.get_effective_attributes().speed
                var turn_value: int = _roll_turn_value(speed)
                var entry: TurnOrderEntry = TurnOrderEntry.new(
                    enemy,
                    turn_value,
                    false,
                    enemy.display_name
                )
                turn_order.append(entry)
    
    # Sort by turn value (ascending - lower numbers first)
    turn_order.sort_custom(_sort_turn_order)
    
    # Reset turn index
    current_turn_index = 0
    
    # Sync to battle state
    if battle_state != null:
        battle_state.turn_order = turn_order.duplicate()
        battle_state.current_turn_index = current_turn_index
        battle_state.turn_count = 0
        _update_battle_state()  # Update entity states
    
    # Auto-save after turn order determined
    _auto_save_battle_state()
    
    # Update UI
    update_turn_order_display()

func _roll_turn_value(speed: int) -> int:
    """Roll for turn value: random(10-20) - speed. Lower values go first."""
    var roll: int = randi_range(10, 20)
    return roll - speed

func _sort_turn_order(a: TurnOrderEntry, b: TurnOrderEntry) -> bool:
    """Sort function for turn order: lower turn_value first, then by speed if tied."""
    if a.turn_value != b.turn_value:
        return a.turn_value < b.turn_value
    
    # If turn values are equal, sort by speed (higher speed first)
    var a_speed: int = 0
    var b_speed: int = 0
    
    if a.is_party:
        a_speed = (a.combatant as Character).get_effective_attributes().speed
    else:
        a_speed = (a.combatant as EnemyData).attributes.speed
    
    if b.is_party:
        b_speed = (b.combatant as Character).get_effective_attributes().speed
    else:
        b_speed = (b.combatant as EnemyData).attributes.speed
    
    return a_speed > b_speed

func update_turn_order_after_action() -> void:
    """Update turn order after an action completes. Remove current turn and add new one."""
    if turn_order.is_empty():
        return
    
    # Get the combatant that just acted
    var current_entry: TurnOrderEntry = turn_order[current_turn_index]
    var combatant: BattleEntity = current_entry.combatant
    
    # Check if combatant is still alive
    var is_alive: bool = combatant.is_alive()
    
    # Remove current turn entry
    turn_order.remove_at(current_turn_index)
    
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
        turn_order.append(new_entry)
    
    # Remove any dead combatants from turn order
    _remove_dead_combatants()
    
    # Re-sort turn order
    turn_order.sort_custom(_sort_turn_order)
    
    # Update turn index (it should point to the next turn, which is now at index 0)
    current_turn_index = 0
    
    # Sync to battle state
    if battle_state != null:
        battle_state.turn_order = turn_order.duplicate()
        battle_state.current_turn_index = current_turn_index
        battle_state.turn_count += 1
        _update_battle_state()  # Update entity states
    
    # Auto-save after turn order determined
    _auto_save_battle_state()
    
    # Update UI
    update_turn_order_display()

func _remove_dead_combatants() -> void:
    """Remove dead combatants from turn order."""
    var to_remove: Array[int] = []
    for i in range(turn_order.size()):
        var entry: TurnOrderEntry = turn_order[i]
        var is_alive: bool = entry.combatant.is_alive()
        
        if not is_alive:
            to_remove.append(i)
    
    # Remove in reverse order to maintain indices
    to_remove.reverse()
    for i in to_remove:
        turn_order.remove_at(i)

func get_current_turn_combatant() -> BattleEntity:
    """Get the combatant whose turn it currently is."""
    if turn_order.is_empty() or current_turn_index >= turn_order.size():
        return null
    
    return turn_order[current_turn_index].combatant

func advance_turn() -> void:
    """Advance to the next turn. Should be called after an action completes."""
    update_turn_order_after_action()
    
    # Process next turn (handle enemy turns automatically)
    _process_current_turn()

func _process_current_turn() -> void:
    """Process the current turn - execute enemy attacks automatically."""
    if turn_order.is_empty() or current_turn_index >= turn_order.size():
        return
    
    # Don't process turns if encounter is complete
    if current_encounter != null and current_encounter.enemy_composition.is_empty():
        return
    
    var current_entry = turn_order[current_turn_index]
    var current_combatant = current_entry.combatant
    
    # Log turn start
    if combat_log != null:
        combat_log.add_entry("%s's turn" % current_entry.display_name, combat_log.EventType.TURN_START)
    
    # Highlight current turn with delay
    await _highlight_current_turn(current_entry)
    
    # Process status effects at start of turn
    if current_entry.is_party:
        var character: Character = current_combatant as Character
        if character != null and character.is_alive():
            _process_combatant_status_effects(character, true)
    else:
        var enemy: EnemyData = current_combatant as EnemyData
        if enemy != null and enemy.is_alive():
            _process_combatant_status_effects(enemy, false)
    
    # If it's an enemy's turn, execute their attack automatically
    if not current_entry.is_party:
        var enemy: EnemyData = current_entry.combatant as EnemyData
        if enemy != null and enemy.is_alive():
            # Enemy highlight animation with delay
            await DelayManager.wait(DelayManager.ENEMY_ACTION_ANIMATION_DURATION)
            execute_enemy_attack(enemy)
    else:
        # Enable action buttons for player turn
        var character: Character = current_combatant as Character
        if character != null and character.is_alive():
            attack_button.disabled = false
            item_button.disabled = false
            ability_button.disabled = false

func update_turn_order_display() -> void:
    """Update the turn order UI display."""
    if not is_node_ready():
        return
    
    if turn_order_container == null:
        return
    
    var container: HBoxContainer = turn_order_container
    # Clear existing children
    for child in container.get_children():
        child.queue_free()
    
    # Create UI entries for each turn order entry
    for i in range(turn_order.size()):
        var entry: TurnOrderEntry = turn_order[i]
        var entry_ui: Control = _create_turn_order_entry_ui(entry, i == current_turn_index)
        container.add_child(entry_ui)

func _create_turn_order_entry_ui(entry: TurnOrderEntry, is_current: bool) -> Control:
    """Create a UI element for a turn order entry."""
    var container: Control = Control.new()
    container.custom_minimum_size = Vector2(100, 60)
    
    # Background panel
    var panel: Panel = Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if is_current:
        panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
        var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
        style.bg_color = Color(1.0, 1.0, 0.0, 0.3)  # Semi-transparent yellow
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = Color.YELLOW
    container.add_child(panel)
    
    # Content container
    var content: VBoxContainer = VBoxContainer.new()
    content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content.add_theme_constant_override("separation", 2)
    container.add_child(content)
    
    # Name label
    var name_label: Label = Label.new()
    name_label.text = entry.display_name
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 14)
    if is_current:
        name_label.add_theme_color_override("font_color", Color.YELLOW)
    elif entry.is_party:
        name_label.add_theme_color_override("font_color", Color.CYAN)
    else:
        name_label.add_theme_color_override("font_color", Color.RED)
    content.add_child(name_label)
    
    # Turn value label
    var value_label: Label = Label.new()
    value_label.text = "Value: " + str(entry.turn_value)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value_label.add_theme_font_size_override("font_size", 12)
    value_label.add_theme_color_override("font_color", Color.WHITE)
    content.add_child(value_label)
    
    return container

# Target Selection System
func start_target_selection(attacker: Character) -> void:
    """Start target selection mode for player attack."""
    # Animate party displays down and close action menu with delays
    await _animate_party_displays_down()
    await _close_action_menu()
    
    is_selecting_target = true
    pending_attacker = attacker
    
    # Highlight selectable enemies
    _update_enemy_selectability(true)
    
    # Disable action buttons during target selection
    attack_button.disabled = true
    item_button.disabled = true
    ability_button.disabled = true

func cancel_target_selection() -> void:
    """Cancel target selection and return to normal state."""
    is_selecting_target = false
    pending_attacker = null
    pending_ability_character = null
    
    # Remove highlights
    _update_enemy_selectability(false)
    
    # Animate party displays back and reopen action menu with delays
    await _animate_party_displays_up()
    await _open_action_menu()
    
    # Re-enable action buttons
    attack_button.disabled = false
    item_button.disabled = false
    ability_button.disabled = false

func _update_enemy_selectability(selectable: bool) -> void:
    """Update enemy displays to show selectable state."""
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data != null and enemy_display.enemy_data.is_alive():
                enemy_display.set_selectable(selectable)
            else:
                enemy_display.set_selectable(false)

# Ability Target Selection
func start_ability_target_selection(character: Character) -> void:
    """Start target selection mode for ability."""
    # Animate party displays down and close action menu with delays
    await _animate_party_displays_down()
    await _close_action_menu()
    
    is_selecting_target = true
    pending_ability_character = character
    
    # Highlight selectable enemies
    _update_enemy_selectability(true)
    
    # Disable action buttons during target selection
    attack_button.disabled = true
    item_button.disabled = true
    ability_button.disabled = true

func _needs_target_selection(class_type: String) -> bool:
    """Check if a class type requires target selection before minigame."""
    var behavior = MinigameRegistry.get_behavior(class_type)
    if behavior == null:
        return false
    return behavior.needs_target_selection()

# Minigame Modal System
func open_minigame_modal(character: Character, target: BattleEntity) -> void:
    """Open minigame modal for the given character."""
    if current_modal != null:
        push_warning("Modal already open")
        return
    
    # Block input during minigame opening
    block_input()
    
    # Store target for later use
    current_ability_target = target
    
    # Get minigame scene path from registry
    var minigame_path: String = MinigameRegistry.get_minigame_scene_path(character.class_type)
    if minigame_path == "":
        push_error("Failed to get minigame scene path for class: " + character.class_type)
        unblock_input()
        return
    
    # Build context dictionary using behavior system
    var context: Dictionary = _build_minigame_context(character, target)
    
    # Create modal instance programmatically
    current_modal = MinigameModalScript.new()
    
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

func _build_minigame_context(character: Character, target: BattleEntity) -> Dictionary:
    """Build context dictionary for minigame (for backward compatibility with modal)."""
    # Get typed context from behavior
    var behavior = MinigameRegistry.get_behavior(character.class_type)
    var typed_context: MinigameContext = null
    if behavior != null:
        typed_context = behavior.build_minigame_context(character, target)
    
    # Convert typed context to dictionary for modal (backward compatibility)
    var context: Dictionary = {
        "character": character,
        "target": target,
        "data": {}
    }
    
    if typed_context != null:
        # Convert typed context to dictionary based on type
        var context_class = typed_context.get_script()
        if context_class == BERSERKER_MINIGAME_CONTEXT:
            var berserker_context = typed_context as BerserkerMinigameContext
            context["data"] = {
                "effect_ranges": berserker_context.effect_ranges,
                "is_berserking": berserker_context.is_berserking,
                "berserk_stacks": berserker_context.berserk_stacks
            }
        elif context_class == MONK_MINIGAME_CONTEXT:
            var monk_context = typed_context as MonkMinigameContext
            context["data"] = {
                "target_strategy": monk_context.target_strategy,
                "enemy_cards": monk_context.enemy_cards,
                "enemy_id": monk_context.enemy_id,
                "redos_available": monk_context.redos_available
            }
        elif context_class == TIME_WIZARD_MINIGAME_CONTEXT:
            var time_wizard_context = typed_context as TimeWizardMinigameContext
            context["data"] = {
                "board_state": time_wizard_context.board_state,
                "board_size": time_wizard_context.board_size,
                "time_limit": time_wizard_context.time_limit,
                "event_count": time_wizard_context.event_count
            }
        elif context_class == WILD_MAGE_MINIGAME_CONTEXT:
            var wild_mage_context = typed_context as WildMageMinigameContext
            context["data"] = {
                "pre_drawn_card": wild_mage_context.pre_drawn_card,
                "hand_size": wild_mage_context.hand_size,
                "discards_available": wild_mage_context.discards_available
            }
        else:
            context["data"] = {}
    else:
        context["data"] = {}
    
    return context

# Old class-specific context builders removed - now handled by behavior system

func _on_minigame_modal_closed() -> void:
    """Handle minigame modal closing."""
    # Clean up modal reference
    current_modal = null
    
    # Re-enable action buttons
    attack_button.disabled = false
    item_button.disabled = false
    ability_button.disabled = false

func _on_minigame_completed(result: MinigameResult) -> void:
    """Handle minigame completion - apply effects and advance turn."""
    # Block input during minigame closing
    block_input()
    
    # Get character from current turn
    var current_combatant = get_current_turn_combatant()
    if current_combatant == null or not (current_combatant is Character):
        push_error("No valid character for minigame result")
        if current_modal != null:
            await close_minigame_modal()
        unblock_input()
        return
    
    var character: Character = current_combatant as Character
    
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
    advance_turn()

func _apply_minigame_result(character: Character, result: MinigameResult, target: BattleEntity) -> void:
    """Apply minigame result effects to combat."""
    if result == null:
        return
    
    # Add class-specific minigame result logs
    _log_minigame_result(character, result)
    
    # Apply damage if applicable
    if result.damage > 0:
        # Use provided target or determine based on character class
        if target == null:
            target = _get_ability_target(character, result)
        
        if target != null:
            var actual_damage: int = target.take_damage(result.damage)
            if combat_log != null:
                combat_log.add_entry("%s deals %d damage to %s!" % [character.display_name, actual_damage, target.display_name], combat_log.EventType.DAMAGE)
            
            # Update UI based on target type
            if target.is_party_member():
                _update_party_displays()
                # Check if target died
                if not target.is_alive():
                    _handle_character_death(target as Character)
            else:
                _update_enemy_displays()
                # Check if target died
                if not target.is_alive():
                    _handle_enemy_death(target as EnemyData)
    
    # Apply effects
    for effect_dict in result.effects:
        _apply_effect(effect_dict, character)
    
    # Update UI
    _update_party_displays()
    _update_enemy_displays()

func _log_minigame_result(character: Character, result: MinigameResult) -> void:
    """Add combat log entries for minigame results based on character class."""
    if combat_log == null or result == null:
        return
    
    # Use behavior system to format results
    var behavior = MinigameRegistry.get_behavior(character.class_type)
    if behavior != null:
        var log_entries = behavior.format_minigame_result(character, result)
        for entry in log_entries:
            combat_log.add_entry(entry, combat_log.EventType.ABILITY)

# Old class-specific logging functions removed - now handled by behavior system

func _get_ability_target(character: Character, result: MinigameResult) -> BattleEntity:
    """Get the target for the ability based on character class."""
    var behavior = MinigameRegistry.get_behavior(character.class_type)
    if behavior != null:
        return behavior.get_ability_target(character, result)
    return null  # Target should be provided from minigame context

func _process_combatant_status_effects(combatant: BattleEntity, _is_party: bool) -> void:
    """Process status effects for a combatant at the start of their turn."""
    var tick_result: Dictionary = combatant.tick_status_effects()
    
    # Apply damage from status effects
    if tick_result.has("damage") and tick_result["damage"] > 0:
        var damage: int = tick_result["damage"]
        var actual_damage: int = combatant.take_damage(damage)
        if combat_log != null:
            combat_log.add_entry("%s takes %d damage from status effects!" % [combatant.display_name, actual_damage], combat_log.EventType.STATUS_EFFECT)
        
        # Update UI based on combatant type
        if combatant.is_party_member():
            _update_party_displays()
            # Check if character died
            if not combatant.is_alive():
                _handle_character_death(combatant as Character)
        else:
            _update_enemy_displays()
            # Check if enemy died
            if not combatant.is_alive():
                _handle_enemy_death(combatant as EnemyData)

func _apply_effect(effect_dict: Dictionary, source: Character) -> void:
    """Apply a single effect from minigame result."""
    var effect_type: String = effect_dict.get("type", "")
    var effect_class_name: String = effect_dict.get("class", "")
    var target: BattleEntity = effect_dict.get("target", null)
    var magnitude: float = effect_dict.get("magnitude", 1.0)
    var duration: int = effect_dict.get("duration", 1)
    var stacks: int = effect_dict.get("stacks", 1)
    
    # Determine target if not provided
    if target == null:
        target = _get_ability_target(source, null)
    
    if target == null:
        push_warning("No target for effect application")
        return
    
    # Create effect instance based on type/class name
    var effect: StatusEffect = null
    var effect_identifier: String = effect_class_name if effect_class_name != "" else effect_type
    
    match effect_identifier.to_lower():
        "burneffect", "burn":
            effect = BURN_EFFECT.new(duration, stacks, magnitude)
        "silenceeffect", "silence":
            effect = SILENCE_EFFECT.new(duration)
        "taunteffect", "taunt":
            effect = TAUNT_EFFECT.new(duration)
        "alterattributeeffect", "alterattribute", "alter_attribute":
            var attribute_name: String = effect_dict.get("attribute_name", "")
            var alteration_amount: int = effect_dict.get("alteration_amount", 0)
            effect = ALTER_ATTRIBUTE_EFFECT.new(attribute_name, alteration_amount, duration)
        "berserkeffect", "berserk":
            var berserk_stacks: int = effect_dict.get("berserk_stacks", 1)
            effect = BERSERK_EFFECT.new(berserk_stacks)
        _:
            push_warning("Unknown effect type: %s or class: %s" % [effect_type, effect_class_name])
            if combat_log != null:
                combat_log.add_entry("Unknown effect type: %s" % effect_type, combat_log.EventType.ABILITY)
            return
    
    # Apply effect to target
    target.add_status_effect(effect)
    if combat_log != null:
        combat_log.add_entry("%s applies %s to %s!" % [source.display_name, effect.get_effect_name(), target.display_name], combat_log.EventType.STATUS_EFFECT)
    
    # Update UI based on target type
    if target.is_party_member():
        _update_party_displays()
    else:
        _update_enemy_displays()

func close_minigame_modal() -> void:
    """Close the current minigame modal."""
    if current_modal != null:
        current_modal.close_modal()
        current_modal = null
        # Wait for close animation
        await DelayManager.wait(DelayManager.MINIGAME_CLOSE_BEAT_DURATION)

func _on_enemy_target_selected(enemy: EnemyData) -> void:
    """Handle enemy target selection for player attack or ability."""
    if not is_selecting_target:
        return
    
    # Check if this is for an ability
    if pending_ability_character != null:
        # Store reference before cancel_target_selection() nulls it
        var ability_character: Character = pending_ability_character
        
        # Validate target
        if enemy == null or not enemy.is_alive():
            print("Invalid target selected")
            return
        
        if not current_encounter.enemy_composition.has(enemy):
            print("Target not in current encounter")
            return
        
        # Cancel target selection UI (this will null pending_ability_character)
        cancel_target_selection()
        
        # Open minigame modal with target using stored reference
        open_minigame_modal(ability_character, enemy)
        return
    
    # Otherwise, handle as attack
    if pending_attacker == null or not pending_attacker.is_party_member():
        cancel_target_selection()
        return
    
    var attacker: Character = pending_attacker as Character
    
    # Validate target
    if enemy == null or not enemy.health.is_alive():
        print("Invalid target selected")
        return
    
    if not current_encounter.enemy_composition.has(enemy):
        print("Target not in current encounter")
        return
    
    # Cancel target selection UI (but don't reopen menu)
    is_selecting_target = false
    pending_attacker = null
    _update_enemy_selectability(false)
    
    # Execute player attack with delays
    await execute_player_attack(attacker, enemy)

# Player Attack Implementation
func execute_player_attack(attacker: Character, target: EnemyData) -> void:
    """Execute a player character's basic attack."""
    if attacker == null or target == null:
        return
    
    if not attacker.is_alive() or not target.is_alive():
        return
    
    # Block input during attack
    block_input()
    
    # Shake party member display
    await _shake_party_display(attacker)
    
    # Flash target and play attack animation
    await _flash_target(target)
    await DelayManager.wait(DelayManager.ATTACK_ANIMATION_DURATION)
    
    # Check if berserk state will be cleared (for logging)
    var was_berserking: bool = false
    if attacker.class_type == "Berserker":
        was_berserking = attacker.class_state.get("is_berserking", false)
    
    # Calculate damage from Power attribute
    var effective_attrs: Attributes = attacker.get_effective_attributes()
    var damage: int = effective_attrs.power
    
    # Apply class-specific on-attack effects (may modify damage)
    damage = _apply_class_specific_attack_effects(attacker, target, damage)
    
    # Log berserk state clearing if applicable
    if was_berserking and combat_log != null:
        combat_log.add_entry("%s's Berserk state ends! (stacks cleared)" % attacker.display_name, combat_log.EventType.ABILITY)
    
    # Apply damage
    var actual_damage: int = target.take_damage(damage)
    
    # Log attack and damage
    if combat_log != null:
        combat_log.add_entry("%s attacks %s" % [attacker.display_name, target.display_name], combat_log.EventType.ATTACK)
        combat_log.add_entry("%s attacks %s for %d damage!" % [attacker.display_name, target.display_name, actual_damage], combat_log.EventType.DAMAGE)
    
    # Visual feedback
    _show_damage_feedback(target, actual_damage)
    
    # Update UI
    _update_enemy_displays()
    _update_party_displays()
    
    # Check if target died
    if not target.is_alive():
        await _handle_enemy_death(target)
    
    # Unblock input
    unblock_input()
    
    # Advance turn
    advance_turn()

func _shake_party_display(_character: Character) -> void:
    """Shake party member display during action execution."""
    # TODO: Implement actual shake animation
    # For now, just wait for delay
    await DelayManager.wait(0.1)

func _flash_target(_target: BattleEntity) -> void:
    """Flash target during attack animation."""
    # TODO: Implement actual flash animation (toggle alpha)
    # For now, just wait for delay
    await DelayManager.wait(0.1)

# Enemy Attack Implementation
func execute_enemy_attack(attacker: EnemyData) -> void:
    """Execute an enemy's basic attack."""
    if attacker == null:
        return
    
    if not attacker.is_alive():
        return
    
    # Select target (AI targeting)
    var target: Character = _select_enemy_target()
    if target == null:
        print("No valid target for enemy attack")
        advance_turn()
        return
    
    # Calculate damage from Power attribute
    var damage: int = attacker.attributes.power
    
    # Apply damage
    var actual_damage: int = target.take_damage(damage)
    
    # Log attack and damage
    if combat_log != null:
        combat_log.add_entry("%s attacks %s" % [attacker.display_name, target.display_name], combat_log.EventType.ATTACK)
        combat_log.add_entry("%s attacks %s for %d damage!" % [attacker.display_name, target.display_name, actual_damage], combat_log.EventType.DAMAGE)
    
    # Visual feedback
    _show_damage_feedback(target, actual_damage)
    
    # Update UI
    _update_party_displays()
    _update_enemy_displays()
    
    # Check if target died
    if not target.is_alive():
        _handle_character_death(target)
    
    # Check for party wipe
    if _is_party_wipe():
        _handle_party_wipe()
        return
    
    # Advance turn
    advance_turn()

func _select_enemy_target() -> Character:
    """AI target selection: prioritize taunt, otherwise random alive party member."""
    if GameManager.current_run == null:
        return null
    
    var alive_party: Array[Character] = []
    var taunted_party: Array[Character] = []
    
    # Find alive party members and check for taunt
    for character in GameManager.current_run.party:
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

# Class-Specific Attack Effects
func _apply_class_specific_attack_effects(attacker: Character, target: EnemyData, base_damage: int) -> int:
    """Apply class-specific on-attack effects. Returns modified damage."""
    var behavior = MinigameRegistry.get_behavior(attacker.class_type)
    if behavior != null:
        return behavior.apply_attack_effects(attacker, target, base_damage)
    return base_damage

# Old class-specific attack effect functions removed - now handled by behavior system

# Visual Feedback and UI Updates
func _show_damage_feedback(_target: BattleEntity, _damage: int) -> void:
    """Show damage feedback (placeholder - can be enhanced with floating text later)."""
    # TODO: Implement floating damage numbers or damage popup
    pass

func _update_enemy_displays() -> void:
    """Update all enemy displays."""
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            enemy_display.update_display()

func _update_party_displays() -> void:
    """Update all party member displays."""
    for child in party_container.get_children():
        if child is CharacterDisplay:
            var char_display: CharacterDisplay = child as CharacterDisplay
            char_display.update_display()

# Death Handling
func _handle_enemy_death(enemy: EnemyData) -> void:
    """Handle enemy death: remove from encounter and UI."""
    # Play death animation and sound
    SoundManager.play_sfx(SoundManager.SFX_ENEMY_DEATH)
    var effect_id = EFFECT_IDS.EffectIds.DEATH_EFFECT
    VfxManager.play_effect(effect_id, _get_enemy_position(enemy))
    await DelayManager.wait(DelayManager.DEATH_ANIMATION_DURATION)
    
    # Log enemy death
    if combat_log != null:
        combat_log.add_entry("%s has been defeated!" % enemy.display_name, combat_log.EventType.DEATH)
    
    # Remove all status effects
    if not enemy.status_manager.status_effects.is_empty():
        enemy.status_manager.clear_effects()
        if combat_log != null:
            combat_log.add_entry("%s's status effects are removed" % enemy.display_name, combat_log.EventType.STATUS_EFFECT)
    
    # Remove from encounter composition
    if current_encounter != null:
        current_encounter.enemy_composition.erase(enemy)
    
    # Remove from UI
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                child.queue_free()
                break
    
    # Check if encounter is complete (all enemies dead)
    if current_encounter != null and current_encounter.enemy_composition.is_empty():
        complete_encounter()

func _get_enemy_position(enemy: EnemyData) -> Vector2:
    """Get enemy position for VFX."""
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                return enemy_display.global_position + enemy_display.size / 2
    return Vector2.ZERO

func _handle_character_death(character: Character) -> void:
    """Handle character death: update UI and remove status effects."""
    # Log character death
    if combat_log != null:
        combat_log.add_entry("%s has been defeated!" % character.display_name, combat_log.EventType.DEATH)
    
    # Remove all status effects
    if not character.status_manager.status_effects.is_empty():
        character.status_manager.clear_effects()
        if combat_log != null:
            combat_log.add_entry("%s's status effects are removed" % character.display_name, combat_log.EventType.STATUS_EFFECT)
    
    # UI will update automatically via _update_party_displays()
    # Dead characters are automatically removed from turn order in _remove_dead_combatants()

func _is_party_wipe() -> bool:
    """Check if all party members are dead."""
    if GameManager.current_run == null:
        return true
    
    for character in GameManager.current_run.party:
        if character.is_alive():
            return false
    
    return true

func _handle_party_wipe() -> void:
    """Handle party wipe: trigger run failure."""
    # Log party wipe
    if combat_log != null:
        combat_log.add_entry("Party wipe! Run failed.", combat_log.EventType.DEATH)
    GameManager.end_run(false)
    SceneManager.go_to_main_menu()
